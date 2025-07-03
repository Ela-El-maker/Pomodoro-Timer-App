import 'dart:async';
import 'package:flutter/material.dart';

import 'main.dart';
import 'pomodoroService.dart';
import 'pomodoroSession.dart';
import 'taskService.dart';

class TimerService extends ChangeNotifier {
  Timer? timer;

// Title
  String taskTitle = "";

  // Constants
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
  String currentState = "FOCUS";

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
    if (_taskId == null || currentDuration <= 0)
      return; // Prevent running empty timer

    // Always check if task is completed before starting
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
    autoContinue = true; //running normally

    notifyListeners();

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentDuration <= 1) {
        stop();
        handleNextRound(auto: true); // natural completion
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

    if (save && _taskId != null && _sessionStart != null) {
      _saveSession(interrupted: true); // 👈 new parameter
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
    stop();
    currentState = "FOCUS";
    selectedTime = userSelectedFocusTime;
    currentDuration = selectedTime;
    // rounds = 0;
    // goal = 0;
    _taskId = null;
    _sessionStart = null;
    _currentTask = null;
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
    // Check if task is completed before saving session

    if (_currentTask?.isCompleted == true) {
      debugPrint("❌ Cannot Continue - Task is completed...");
      reset();
      return;
    }

    if (_taskId != null && _sessionStart != null) {
      await _saveSession();
    }

    if (currentState == "FOCUS") {
      currentState = "BREAK";
      currentDuration = shortBreakDuration.toDouble();
      selectedTime = shortBreakDuration.toDouble();
    } else if (currentState == "BREAK") {
      currentState = "FOCUS";
      currentDuration = userSelectedFocusTime;
      selectedTime = userSelectedFocusTime;
    } else if (currentState == "LONGBREAK") {
      currentState = "FOCUS";
      currentDuration = userSelectedFocusTime;
      selectedTime = userSelectedFocusTime;
    }

    notifyListeners();

    if (auto || _autoContinue) {
      start(); // ✅ Auto-start only if not manually paused
    }
  }

  Future<void> _saveSession({bool interrupted = false}) async {
    
    // Dont Save session if task is completed
    if(_currentTask?.isCompleted == true)
  {
    debugPrint("❌ Not saving session - task is completed");
    return;
  }
    
    final now = DateTime.now();
    final secondsElapsed = now.difference(_sessionStart!).inSeconds;

    final session = PomodoroSession(
      taskId: _taskId!,
      mode: currentState,
      duration: interrupted ? secondsElapsed : selectedTime.toInt(),
      startedAt: _sessionStart!,
      completedAt: now,
      wasCompleted: !interrupted,
    );

    try {
      await PomodoroService().createSession(session);

      // 🎯 Track session against task progress
      if (_taskId != null) {
        final result = await PomodoroService().trackTaskSession(_taskId!);

        final goalReached = result['goal_reached'] ?? false;
        final context = navigatorKey.currentContext;

        if (goalReached && !_isTaskMarkedCompleted(result['task'])) {
          if (context != null) {
            await _showGoalReachedPrompt(context, result['task']);
          }

          // _showGoalReachedPrompt(navigatorKey.currentContext!, result['task']);

          // _showGoalReachedPrompt(result['task']);
          // Show notification or toast
          print(
              "🎉 Goal reached! Prompt user to continue or mark task as done.");
          // Optionally trigger UI prompt later
        }
      }
    } catch (e) {
      print("Failed to save or track session: $e");
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

                if(_currentTask != null)
                {
                  _currentTask = Task(id: _currentTask!.id, title: _currentTask!.title, description: _currentTask!.description, targetGoals: _currentTask!.targetGoals, completedRounds: _currentTask!.completedRounds, completedGoals: _currentTask!.completedGoals, isCompleted: true,updatedAt: _currentTask!.updatedAt);
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
      // ✅ Task was marked complete — reset everything
      reset(); // Reset timer, session, task state
      // Optionally: navigate away or show a toast/snackbar
      Navigator.of(context).pop();
    } else {
      // ▶️ Resume timer if user chose to continue
      start();
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
