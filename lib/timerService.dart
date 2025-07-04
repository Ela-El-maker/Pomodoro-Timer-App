import 'dart:async';
import 'package:flutter/material.dart';

import 'main.dart';
import 'pomodoroService.dart';
import 'pomodoroSession.dart';
import 'taskService.dart';

enum PomodoroMode {
  focus,
  shortBreak,
  longBreak,
}

String _mapModeToBackend(PomodoroMode mode) {
  switch (mode) {
    case PomodoroMode.focus:
      return 'focus';
    case PomodoroMode.shortBreak:
      return 'short_break';
    case PomodoroMode.longBreak:
      return 'long_break';
  }
}

class TimerService extends ChangeNotifier {
  Timer? timer;

// Title
  String taskTitle = "";

  // Constants
  int roundCount = 0;
  int completedFocusCount = 0; // 💡 Used to track sessions in current round
  int focusDuration; // 25 mins
  int shortBreakDuration; // 5 mins
  int longBreakDuration; // 25 mins (adjust as needed)
  int maxRounds = 4;
  bool _autoContinue = true;
  bool get autoContinue => _autoContinue;

  // State
  late double currentDuration;
  late double selectedTime;
  late double userSelectedFocusTime;

  bool timerPlaying = false;
  // int rounds = 0;
  // int goal = 0;
  PomodoroMode currentState = PomodoroMode.focus;

  TimerService({
    required this.focusDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required bool autoContinue,
  }) : _autoContinue = autoContinue {
    selectedTime = focusDuration.toDouble();
    currentDuration = selectedTime;
    userSelectedFocusTime = focusDuration.toDouble();
  }

  int? _taskId;
  DateTime? _sessionStart;
  Task? _currentTask;

  bool _bonusMode = false;

  void enterBonusMode() {
    _bonusMode = true;
  }

  void exitBonusMode() {
    _bonusMode = false;
  }

  bool get isBonusMode => _bonusMode;

  void setActiveTask(int taskId) {
    _taskId = taskId;
    notifyListeners();
  }

  set autoContinue(bool value) {
    _autoContinue = value;
    notifyListeners();
  }

  void setTaskTitle(String title) {
    taskTitle = title;
    notifyListeners();
  }

  void setCurrentTask(Task task) {
    _currentTask = task;
    notifyListeners();
  }

  void start() async {
    if (_taskId == null || currentDuration <= 0) return;

    try {
      final latestTask = await TaskService().getTaskById(_taskId!);
      if (latestTask.isCompleted) {
        debugPrint("❌ Cannot start timer - Task is Completed");
        return;
      }

      _currentTask = latestTask;
    } catch (e) {
      debugPrint("⚠️ Error checking task status: $e");
      return;
    }

    timerPlaying = true;
    _sessionStart = DateTime.now();
    autoContinue = true;

    debugPrint("▶️ Starting ${currentState.name} session");

    notifyListeners();

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentDuration <= 1) {
        stop();
        handleNextRound(auto: true);
      } else {
        currentDuration--;
        notifyListeners();
      }
    });
  }

  // void stop() {
  //   timer?.cancel();
  //   timerPlaying = false;
  //   autoContinue = false;
  //   notifyListeners();
  // }
  void stop({bool save = false}) {
    timer?.cancel();
    timerPlaying = false;
    autoContinue = false;

    final PomodoroMode modeAtStop = currentState; // Snapshot the mode
    final sessionStartAtStop = _sessionStart; // Snapshot the start time

    debugPrint("⏹️ Stopped ${modeAtStop.name} session manually. Save: $save");

    if (save && _taskId != null && sessionStartAtStop != null) {
      _saveSession(
        interrupted: true,
        mode: modeAtStop, // 💡 Pass snapshot to ensure correct mode
      );
    }

    notifyListeners();
  }

  void selectTime(double seconds) {
    if (seconds < 60) return; // prevent very short times or 0
    userSelectedFocusTime = seconds;
    selectedTime = seconds;
    currentDuration = seconds;
    notifyListeners();
  }

  void reset() {
    exitBonusMode();
    stop();
    currentState = PomodoroMode.focus;
    selectedTime = userSelectedFocusTime;
    currentDuration = selectedTime;
    _taskId = null;
    _sessionStart = null;
    _currentTask = null;
    completedFocusCount = 0; // 👈 Reset focus session
    notifyListeners();
  }

  // void handleNextRound({bool auto = false}) async {
  //   if (_taskId != null && _sessionStart != null) {
  //     await _saveSession();
  //   }

  //   if (currentState == "FOCUS") {
  //     rounds++;
  //     if (goal < 12) {
  //       goal++;
  //     } else {
  //       // Show message
  //       print("🎯 Daily goal completed!"); // Or trigger a toast/snackbar
  //     }

  //     if (rounds < maxRounds) {
  //       currentState = "BREAK";
  //       currentDuration = shortBreakDuration.toDouble();
  //       selectedTime = shortBreakDuration.toDouble();
  //     } else {
  //       currentState = "LONGBREAK";
  //       currentDuration = longBreakDuration.toDouble();
  //       selectedTime = longBreakDuration.toDouble();
  //       rounds = 0; // ✅ Reset rounds here
  //     }
  //   } else {
  //     currentState = "FOCUS";
  //     currentDuration = userSelectedFocusTime;
  //     selectedTime = userSelectedFocusTime;
  //   }

  //   notifyListeners();

  //   if (auto || autoContinue) {
  //     start(); // ✅ auto-start only if not paused manually
  //   }
  // }

  void handleNextRound({bool auto = false}) async {
    if (_currentTask?.isCompleted == true) {
      debugPrint("❌ Cannot Continue - Task is completed...");
      reset();
      return;
    }

    final PomodoroMode prevMode = currentState; // 👈 snapshot BEFORE changing

    // Save session before switching state
    if (_taskId != null && _sessionStart != null) {
      await _saveSession(mode: prevMode);
    }

    // 🔄 STATE TRANSITION
    switch (currentState) {
      case PomodoroMode.focus:
        roundCount++;
        debugPrint("✅ Finished Focus. Round count: $roundCount");

        if (roundCount < maxRounds) {
          currentState = PomodoroMode.shortBreak;
          currentDuration = shortBreakDuration.toDouble();
          selectedTime = shortBreakDuration.toDouble();
          debugPrint("⏸️ Switching to Short Break...");
        } else {
          currentState = PomodoroMode.longBreak;
          currentDuration = longBreakDuration.toDouble();
          selectedTime = longBreakDuration.toDouble();
          roundCount = 0;
          debugPrint("⏹️ Switching to Long Break...");
        }
        break;

      case PomodoroMode.shortBreak:
      case PomodoroMode.longBreak:
        currentState = PomodoroMode.focus;
        currentDuration = userSelectedFocusTime;
        selectedTime = userSelectedFocusTime;
        debugPrint("🧠 Switching back to Focus session...");
        break;
    }

    notifyListeners();

    if (auto || _autoContinue) {
      start();
    }
  }

  Future<void> _saveSession(
      {required PomodoroMode mode, bool interrupted = false}) async {
    if (_bonusMode || _currentTask?.isCompleted == true) {
      debugPrint("⏭ Skipping save in bonus mode");
      return;
    }

    final now = DateTime.now();
    final secondsElapsed = now.difference(_sessionStart!).inSeconds;

    // Track completed focus sessions
    if (mode == PomodoroMode.focus && !interrupted) {
      completedFocusCount++;
      debugPrint("🎯 Completed focus session. Total: $completedFocusCount");
    }

    final session = PomodoroSession(
      taskId: _taskId!,
      mode: _mapModeToBackend(mode),
      duration: interrupted ? secondsElapsed : selectedTime.toInt(),
      startedAt: _sessionStart!,
      completedAt: now,
      wasCompleted: !interrupted,
    );

    debugPrint(
        "💾 Saving session of type: ${mode.name}, interrupted: $interrupted");

    try {
      await PomodoroService().createSession(session);

      if (_taskId != null) {
        final result = await PomodoroService().trackTaskSession(_taskId!);
        debugPrint("📡 Tracking task session...");

        final goalReached = result['goal_reached'] ?? false;
        final context = navigatorKey.currentContext;

        if (goalReached && !_isTaskMarkedCompleted(result['task'])) {
          if (context != null) {
            await _showGoalReachedPrompt(context, result['task']);
          }

          debugPrint(
              "🎉 Goal reached! Prompt user to continue or mark task as done.");
        }
      }
    } catch (e) {
      print("❌ Failed to save or track session: $e");
    }

    _sessionStart = null;
  }

  bool _isTaskMarkedCompleted(Map task) {
    return task['is_completed'] == true;
  }

  bool _taskMarkedComplete = false;
  bool get taskMarkedComplete => _taskMarkedComplete;

  void markTaskAsCompleted() {
    _taskMarkedComplete = true;
    notifyListeners();
  }

  void updateFromSettings({
    required int focus,
    required int shortBreak,
    required int longBreak,
    required bool autoStart,
  }) {
    focusDuration = focus;
    shortBreakDuration = shortBreak;
    longBreakDuration = longBreak;
    autoContinue = autoStart;

    userSelectedFocusTime = focus.toDouble();
    selectedTime = focus.toDouble();
    currentDuration = focus.toDouble();

    notifyListeners();
  }

  Future<void> _showGoalReachedPrompt(BuildContext context, Map task) async {
    stop(); // pause the timer

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎯 Goal Reached!"),
        content: const Text(
            "You've reached your goal. Would you like to continue or mark the task as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Continue
            child: const Text("Continue"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await TaskService().markTaskCompleted(task['id']);

                // Update current task status

                if (_currentTask != null) {
                  _currentTask = Task(
                      id: _currentTask!.id,
                      title: _currentTask!.title,
                      description: _currentTask!.description,
                      targetGoals: _currentTask!.targetGoals,
                      completedRounds: _currentTask!.completedRounds,
                      completedGoals: _currentTask!.completedGoals,
                      isCompleted: true,
                      updatedAt: _currentTask!.updatedAt);
                }
                markTaskAsCompleted();
                notifyListeners();
                Navigator.pop(context, true); // Mark complete
              } catch (e) {
                debugPrint("Failed to mark task as completed: $e");
                Navigator.pop(context, false); // Fallback: just continue
              }
            },
            child: const Text("Mark as Done"),
          ),
        ],
      ),
    );

    if (result == true) {
      reset(); // ✅ Task marked complete
      Navigator.of(context).pop();
    } else {
      enterBonusMode(); // ⭐ User chose to continue
      start(); // ▶️ Resume timer
    }
  }

  void clearTaskCompletionFlag() {
    _taskMarkedComplete = false;
  }

  Future<void> refreshTaskProgress() async {
    if (_taskId != null) {
      try {
        final result = await PomodoroService().trackTaskSession(_taskId!);
        notifyListeners(); // UI reacts if needed
      } catch (e) {
        print("Failed to refresh task progress: $e");
      }
    }
  }
}
