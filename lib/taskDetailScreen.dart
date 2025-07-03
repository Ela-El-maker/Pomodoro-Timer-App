import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'authService.dart';
import 'pomodoroService.dart';
import 'pomodoroSession.dart';
import 'taskService.dart';
import 'timerService.dart';
import 'pomodoroScreen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Future<List<PomodoroSession>> _sessionsFuture;
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _sessionsFuture = PomodoroService().getSessionsForTask(widget.task.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh sessions whenever dependencies change (like when returning from PomodoroScreen)
    _sessionsFuture = PomodoroService().getSessionsForTask(widget.task.id);
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // void _deleteTask(BuildContext context) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Delete Sessions"),
  //       content: const Text("Are you sure you want to delete this sessions?"),
  //       actions: [
  //         TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text("Cancel")),
  //         TextButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: const Text("Delete", style: TextStyle(color: Colors.red))),
  //       ],
  //     ),
  //   );

  //   if (confirmed == true) {
  //     await Provider.of<TaskService>(context, listen: false)
  //         .deleteTask(widget.task.id);
  //     Provider.of<TimerService>(context, listen: false).reset();
  //     if (mounted) Navigator.pop(context);
  //   }
  // }

  // void _deleteSession(BuildContext context, PomodoroSession session) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Delete Session"),
  //       content: const Text("Are you sure you want to delete this session?"),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text("Cancel"),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text("Delete", style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed == true) {
  //     try {
  //       final authService = Provider.of<AuthService>(context, listen: false);
  //       await PomodoroService().deleteSession(session.id!, authService.token!);

  //       setState(() {
  //         _sessionsFuture =
  //             PomodoroService().getSessionsForTask(widget.task.id);
  //       });
  //     } catch (e) {
  //       print(e);
  //       print("Failed to delete: $e");
  //       ScaffoldMessenger.of(context)
  //           .showSnackBar(SnackBar(content: Text("Failed to delete session")));
  //     }
  //   }
  // }

  void _deleteSession(BuildContext context, PomodoroSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Session"),
        content: const Text("Are you sure you want to delete this session?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (session.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Session ID is null. Cannot delete.")),
          );
          return;
        }

        // final authService = Provider.of<AuthService>(context, listen: false);
        // final token = authService.token;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token == null) {
          throw Exception("Auth token is null");
        }

        await PomodoroService().deleteSession(session.id!, token);

        setState(() {
          _sessionsFuture =
              PomodoroService().getSessionsForTask(widget.task.id);
        });
      } catch (e) {
        debugPrint("Delete failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete session")),
        );
      }
    }
  }

  // void _navigateToPomodoro(BuildContext context) async {
  //   print("📍 Trying to navigate to Pomodoro for Task ID: ${widget.task.id}");

  //   // Show loading dialog
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => const Center(child: CircularProgressIndicator()),
  //   );

  //   try {
  //     final latestTask = await Provider.of<TaskService>(context, listen: false)
  //         .getTaskById(widget.task.id);

  //     Navigator.of(context).pop(); // close the loading dialog
  //     print("🧠 Latest Task.isCompleted = ${latestTask.isCompleted}");

  //     if (latestTask.isCompleted) {

  //       setState(() {
  //         _currentTask = latestTask;
  //       });
  //       print("❌ Task is completed. Blocking Pomodoro access.");

  //       showDialog(
  //         context: context,
  //         builder: (_) => AlertDialog(
  //           title: const Text("Task Completed"),
  //           content: const Text(
  //               "This task is already completed. Start a new task to continue."),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text("OK"),
  //             ),
  //           ],
  //         ),
  //       );
  //       return;
  //     }

  //     print("✅ Task is not completed. Navigating to PomodoroScreen...");

  //     Provider.of<TimerService>(context, listen: false).reset();

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => PomodoroScreen(task: latestTask)),
  //     ).then((result) async {
  //       if (result == true) {
  //         print("🔄 Returned from PomodoroScreen. Refreshing sessions...");

  //         try {
  //           final refreshedTask = await Provider.of<TaskService>(context,listen: false).getTaskById(widget.task.id);
  //           setState(() {
  //             _currentTask = refreshedTask;
  //             _sessionsFuture = PomodoroService().getSessionsForTask(widget.task.id);
  //           });
  //         } catch (e) {
  //           print("⚠️ Error refreshing task: $e");

  //         }
  //       }
  //     });
  //   } catch (e) {
  //     Navigator.of(context).pop(); // close loading dialog
  //     print("⚠️ Error fetching task: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Error loading task details")),
  //     );
  //   }
  // }

  void _startPomodoro(BuildContext context, Task task) async {
    print("📍 Trying to navigate to Pomodoro for Task ID: ${task.id}");

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final latestTask = await TaskService().getTaskById(task.id);

      Navigator.of(context).pop(); // Close loading dialog

      if (latestTask.isCompleted) {
        print("❌ Task is completed. Blocking Pomodoro access.");

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Task Completed"),
            content: const Text(
                "This task is already completed. Please create a new task to continue."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );

        // Update local state to reflect completion
        setState(() {
          _currentTask = latestTask;
        });
        return;
      }

      print("✅ Task is not completed. Navigating to PomodoroScreen...");

      Provider.of<TimerService>(context, listen: false).reset();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PomodoroScreen(task: latestTask),
        ),
      ).then((result) async {
        if (result == true) {
          final refreshedTask = await TaskService().getTaskById(task.id);
          setState(() {
            _currentTask = refreshedTask;
            _sessionsFuture =
                PomodoroService().getSessionsForTask(widget.task.id);
          });
        }
      });
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if failed
      print("⚠️ Error fetching task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading task details")),
      );
    }
  }

  void _showFullDescription(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Description'),
        content: SingleChildScrollView(child: Text(description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(List<PomodoroSession> sessions) {
    final focusSessions = sessions.where((s) => s.mode == "focus").toList();
    final completedFocus = focusSessions.where((s) => s.wasCompleted).toList();

    final totalTime = completedFocus.fold<int>(0, (sum, s) => sum + s.duration);
    final minutes = totalTime ~/ 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("✅ Completed Focus Sessions: ${completedFocus.length}"),
        Text("🕒 Total Focus Time: $minutes minutes"),
        const SizedBox(height: 8),
        Text(
            "🔥 Goals: ${_currentTask.completedGoals}/${_currentTask.targetGoals}"),
        Text("⏱️ Rounds: ${completedFocus.length}"),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTask.title),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text(
            _currentTask.isCompleted ? "Task Completed" : "Start Pomodoro"),
        icon: const Icon(Icons.timer),
        backgroundColor: _currentTask.isCompleted
            ? Colors.grey
            : Theme.of(context).primaryColor,
        // onPressed: () => _navigateToPomodoro(context),
        onPressed: _currentTask.isCompleted
            ? null
            : () => _startPomodoro(context, _currentTask),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<PomodoroSession>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final sessions = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentTask.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showFullDescription(_currentTask.description),
                  child: Text(
                    _currentTask.description.length > 80
                        ? _currentTask.description.substring(0, 80) +
                            '... (tap to view)'
                        : _currentTask.description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Session Summary",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                _buildStats(sessions),
                const Text("Pomodoro Sessions",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Expanded(
                  child: sessions.isEmpty
                      ? const Center(child: Text("No sessions yet."))
                      : ListView.builder(
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                    "${session.mode} - ${session.duration ~/ 60} min"),
                                subtitle: Text(
                                  session.completedAt != null
                                      ? "Started: ${formatDateTime(session.startedAt)}\nCompleted: ${formatDateTime(session.completedAt!)}"
                                      : "Started: ${formatDateTime(session.startedAt)}\nNot completed",
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Icon(
                                      session.wasCompleted
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: session.wasCompleted
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteSession(context, session),
                                      tooltip: 'Delete session',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
