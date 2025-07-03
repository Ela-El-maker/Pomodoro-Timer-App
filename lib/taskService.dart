import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// import 'authService.dart';

class Task {
  final int id;
  final String title;
  final String description;
  final int targetGoals;
  final int completedRounds;
  final int completedGoals;
  final bool isCompleted;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.targetGoals,
    required this.completedRounds,
    required this.completedGoals,
    required this.isCompleted,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    debugPrint("🧩 Task JSON: $json");

    return Task(
      id: int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetGoals: int.tryParse(json['target_goals'].toString()) ?? 0,
      completedRounds: int.tryParse(json['completed_rounds'].toString()) ?? 0,
      completedGoals: int.tryParse(json['completed_goals'].toString()) ?? 0,
      isCompleted: json['is_completed'].toString() == '1' ||
          json['is_completed'] == true ||
          json['is_completed'] == 'true',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(), // fallback to prevent crash
    );
  }
}

class TaskService with ChangeNotifier {
  final String baseUrl =
      "https://letscode.felixeladi.co.ke/api"; // Adjust for real device
  List<Task> _tasks = [];
  Task? _selectedTask;

  List<Task> get tasks => _tasks;
  Task? get selectedTask => _selectedTask;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _tasks = data.map((json) => Task.fromJson(json)).toList();

      // ✅ Sort by updatedAt (latest first)
      _tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      notifyListeners();
    } else {
      debugPrint('Failed to fetch tasks: ${response.body}');
      throw Exception('Failed to fetch tasks: ${response.body}');
    }
  }

  Future<void> createTask(String title, String description,
      {int? targetGoals}) async {
    final token = await _getToken();
    final body = {
      "title": title,
      "description": description,
      if (targetGoals != null) "target_goals": targetGoals.toString(),
    };

    final response = await http.post(
      Uri.parse("$baseUrl/tasks"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 201) {
      final task = Task.fromJson(json.decode(response.body));
      _tasks.add(task);
      notifyListeners();
    } else {
      print('Failed to create task: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception("Failed to create task");
    }
  }

  Future<void> updateTask(int id, String title, String description,
      {int? targetGoals}) async {
    final token = await _getToken();
    final body = {
      "title": title,
      "description": description,
      if (targetGoals != null) "target_goals": targetGoals.toString(),
    };

    final response = await http.put(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final updatedTask = Task.fromJson(json.decode(response.body));
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } else {
      print('Failed to update task: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception("Failed to update task");
    }
  }

  Future<void> deleteTask(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();
    } else {
      print('Failed to delete task: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception("Failed to delete task");
    }
  }

  void selectTask(Task task) {
    _selectedTask = task;
    notifyListeners();
  }

  void clearSelectedTask() {
    _selectedTask = null;
    notifyListeners();
  }

  Future<Task> getTaskById(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch task");
    }
  }

  Future<void> incrementRounds(int taskId) async {
    final token = await _getToken();
    await http.post(
      Uri.parse("$baseUrl/tasks/$taskId/increment-round"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  Future<void> markTaskCompleted(int taskId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/tasks/$taskId');

    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // ✅ Add this
      },
      body: jsonEncode({
        'is_completed': true,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Failed to complete task: ${response.body}');
      throw Exception('Failed to mark task as completed');
    }
  }

  Future<Map<String, dynamic>> fetchTaskProgress(int taskId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'completedRounds': data['completed_rounds'],
        'completedGoals': data['completed_goals'],
        'targetGoals': data['target_goals'],
        'isCompleted': data['is_completed'],
      };
    } else {
      throw Exception('Failed to fetch task progress');
    }
  }
}
