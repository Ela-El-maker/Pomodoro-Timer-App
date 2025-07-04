import 'package:flutter/material.dart';
import 'package:pomodoro/userSettingsScreen.dart';
import 'package:provider/provider.dart';

import 'authService.dart';
import 'dailyStatsScreen.dart';
import 'taskDetailScreen.dart';
import 'taskFormScreen.dart';
import 'taskService.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) 
    async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user != null) {
      await _loadTasks();
    } else {
      // wait a little and try again
      Future.delayed(Duration(milliseconds: 300), () async {
        if (mounted) await _loadTasks();
      });
    }
  });
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      await Provider.of<TaskService>(context, listen: false).fetchTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading tasks: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
 
    final user = context.watch<AuthService>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Daily Stats",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyStatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final success =
                    await Provider.of<AuthService>(context, listen: false)
                        .logout();

                if (success) {
                  Fluttertoast.showToast(
                    msg: "Logout successful",
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    gravity: ToastGravity.BOTTOM,
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: "Logout failed",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    gravity: ToastGravity.BOTTOM,
                  );
                }

                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
          ),
        ],
      ),
      body:user == null && _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              buildUserCard(user),
              Expanded(
                child: ListView.builder(
                  itemCount: taskService.tasks.length,
                  itemBuilder: (context, index) {
                    final task = taskService.tasks[index];
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(task.title)),
                          if (task.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Done",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        task.description.isNotEmpty
                            ? task.description
                            : "No description.",
                      ),
                      onTap: () {
                        print(
                            "➡️ Navigating to TaskDetailScreen (Task ID: ${task.id})");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(task: task),
                          ),
                        ).then((result) {
                          // Refresh the task list when returning from TaskDetailScreen
                          _loadTasks();
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await taskService.deleteTask(task.id);
                          await _loadTasks(); // refresh after delete
                        },
                      ),
                    );
                  },
                ),
              )
            ]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TaskFormScreen(),
          ),
        ).then((_) => _loadTasks()), // Refresh when returning from form
      ),
    );
  }

  Widget buildUserCard(Map<String, dynamic>? user) {
  if (user == null) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 12),
          Text("Loading user..."),
        ],
      ),
    );
  }

  return Card(
    color: Colors.blueGrey.shade100,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown User',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}
