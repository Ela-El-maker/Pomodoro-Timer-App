import 'package:flutter/material.dart';
import 'package:pomodoro/progressWidget.dart';
import 'package:pomodoro/taskDetailScreen.dart';
import 'package:pomodoro/timeCard.dart';
import 'package:pomodoro/timeController.dart';
import 'package:pomodoro/timeOptions.dart';
import 'package:pomodoro/timerService.dart';
import 'package:pomodoro/utils.dart';
import 'package:provider/provider.dart';
import 'pomodoroService.dart';
import 'taskService.dart';

class PomodoroScreen extends StatefulWidget {
  final Task task;

  const PomodoroScreen({super.key, required this.task});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with WidgetsBindingObserver {
  late TimerService _timerService;
  int completedRounds = 0;
  int completedGoals = 0;
  int targetGoals = 1;
  Task? _currentTask;

  late TextEditingController _titleController;
  bool _loading = true;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    print("🕹️ PomodoroScreen started for task ID: ${widget.task.id}");
    _titleController = TextEditingController(text: widget.task.title);
    _currentTask = widget.task;

    if (widget.task.isCompleted) {
      print("❌ Blocked! Task is completed.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTaskCompletedDialog();
      });
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _timerService = Provider.of<TimerService>(context, listen: false);

    // Setup task only once
    Future.microtask(() async {
      try {
        final latestTask = await TaskService().getTaskById(widget.task.id);
        if (latestTask.isCompleted) {
          setState(() {
            _loading = false;
            _isBlocked = true;
          });
          return;
        }

        _currentTask = latestTask;
        _timerService.setActiveTask(widget.task.id);
        _timerService.setTaskTitle(widget.task.title);
        _timerService.setCurrentTask(latestTask);
        await _loadCompletedFocusRounds();
        setState(() {
          completedGoals = latestTask.completedGoals;
          targetGoals = latestTask.targetGoals;
          _loading = false;

          print("$completedRounds Test Completed Rounds");
        });
      } catch (e) {
        print("⚠️ Error checking task status: $e");
        _showErrorDialog("Error loading task details");
      }
    });
  }

  Future<void> _loadCompletedFocusRounds() async {
    try {
      final sessions =
          await PomodoroService().getSessionsForTask(widget.task.id);

      final completedFocus =
          sessions.where((s) => s.mode == "focus" && s.wasCompleted).toList();

      print("✅ Found ${sessions.length} sessions");
      for (var s in sessions) {
        print("🧪 Session: mode=${s.mode}, completed=${s.wasCompleted}");
      }

      print("✅ Focus Completed: ${completedFocus.length}");

      setState(() {
        completedRounds = completedFocus.length ~/ 4; // ✅ Integer division
      });
    } catch (e) {
      debugPrint("❌ Failed to load sessions: $e");
    }
  }

  void _showTaskCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Task Completed"),
        content: const Text(
            "This task is already completed. You can't start a Pomodoro session for it. Please create a new task or select an incomplete task."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit PomodoroScreen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit PomodoroScreen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _timerService.addListener(_handleCompletionCheck);
  }

  // void _handleCompletionCheck() {
  //   if (!mounted) return;

  //   final timerService = _timerService;

  //   if (timerService.taskMarkedComplete) {
  //     timerService.clearTaskCompletionFlag();

  //     if (mounted && Navigator.canPop(context)) {
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text("Task completed")),
  //           );

  //           Navigator.of(context).pop();
  //         }
  //       });
  //     }
  //   }
  // }

  void _handleCompletionCheck() {
    if (!mounted) return;

    final timerService = _timerService;

    if (timerService.taskMarkedComplete) {
      timerService.clearTaskCompletionFlag();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task completed")),
        );

        Navigator.of(context).pop(true); // send result to previous screen
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();

    WidgetsBinding.instance.removeObserver(this);
    _timerService.removeListener(_handleCompletionCheck);

    if (_timerService.timerPlaying && _currentTask?.isCompleted != true) {
      _timerService.stop(save: true);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        _timerService.timerPlaying) {
      _timerService.stop(save: true);
    }
  }

  Future<bool> _onWillPop() async {
    // 🔧 Check if task is completed
    if (_currentTask?.isCompleted == true) {
      return true; // Allow immediate exit
    }

    if (_timerService.timerPlaying) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Exit Timer?"),
          content: const Text(
              "You have an active session. Do you want to stop and save progress?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                print("⬅️ Returning from TaskDetailScreen");

                _timerService.stop(save: true);
                Navigator.pop(context, true);
                print("⬅️ Returning from TaskDetailScreen");
              },
              child: const Text("Stop & Exit"),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimerService>(context);
// 🔧 Show loading or error state if task is completed
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isBlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Task Completed"),
          backgroundColor: Colors.grey,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text(
                "This task is completed!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text("Please select a different task to continue."),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: renderColor(provider.currentState.name),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: renderColor(provider.currentState.name),
          title: Text(
            "Pomodoro Timer",
            style: textStyle(25, Colors.white, FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                final timerService =
                    Provider.of<TimerService>(context, listen: false);

                final wasPlaying = timerService.timerPlaying;
                if (wasPlaying) timerService.stop(); // pause before dialog

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Reset Timer"),
                    content:
                        Text("Are you sure you want to refresh the session?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Refresh"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  timerService.reset();
                }
              },
            ),
            IconButton(
              onPressed: () => _showSettings(context),
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: "Settings",
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
              
                ),
                Text(
                  "🎯 $completedRounds rounds ($completedGoals / $targetGoals goals)",
                  style: textStyle(16, Colors.white, FontWeight.w500),
                ),
                Text(
                  "🧠 Focus Sessions This Round: ${provider.completedFocusCount % 4}/4",
                  style: textStyle(14, Colors.white70, FontWeight.w400),
                ),
                if (provider.isBonusMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "⭐ You're now in bonus mode — sessions won't count toward goals!",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                TimerCard(),
                const SizedBox(height: 40),
                TimeOptions(),
                const SizedBox(height: 30),
                TimeController(),
                const SizedBox(height: 30),
                ProgressWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Auto-start next round",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Consumer<TimerService>(
                builder: (context, timerService, _) => Switch(
                  value: timerService.autoContinue,
                  onChanged: (value) {
                    timerService.autoContinue = value;
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
