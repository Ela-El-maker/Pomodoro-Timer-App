import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pomodoroSession.dart';

class PomodoroService {
  // final String baseUrl = 'http://10.0.2.2:8000/api'; // Adjust for real device
final String baseUrl = "https://letscode.felixeladi.co.ke/api";
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> createSession(PomodoroSession session) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/pomodoro-sessions');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'task_id': session.taskId.toString(),
        'mode': session.mode,
        'duration': session.duration.toString(),
        'started_at': session.startedAt.toIso8601String(),
        'completed_at': session.completedAt?.toIso8601String(),
        'was_completed': session.wasCompleted ? '1' : '0',
      },
    );

    print('Saving session for task ${session.taskId}');
    print('Response code: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response.statusCode == 201;
  }

  Future<List<PomodoroSession>> getSessionsForTask(int taskId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/tasks/$taskId/sessions');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['sessions'] as List)
          .map((json) => PomodoroSession.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  Future<Map<String, dynamic>> trackTaskSession(int taskId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/tasks/$taskId/track-session');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Track session failed: ${response.body}');
      throw Exception("Failed to track task session");
    }
  }

  // Future<void> deleteSession(int sessionId, String token) async {
  //   final url = Uri.parse('$baseUrl/pomodoro-sessions/$sessionId');

  //   final response = await http.delete(
  //     url,
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Accept': 'application/json',
  //     },
  //   );

  //   if (response.statusCode != 200) {
  //     throw Exception("Failed to delete session");
  //   }
  // }

  // Future<void> deleteSession(int sessionId, String token) async {
  //   // if (sessionId == null) throw Exception("Session ID is null");

  //   final url = Uri.parse("$baseUrl/sessions/$sessionId");

  //   final response = await http.delete(url, headers: {
  //     'Authorization': 'Bearer $token',
  //     'Accept': 'application/json',
  //   });

  //   if (response.statusCode != 200) {
  //     throw Exception("Failed to delete session. Code: ${response.statusCode}");
  //   }
  // }

  Future<void> deleteSession(int sessionId, [String? token]) async {
    token ??= await _getToken();

    if (token == null) throw Exception("Auth token is null");

    final url = Uri.parse("$baseUrl/pomodoro-sessions/$sessionId");

    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception("Failed to delete session. Code: ${response.statusCode}");
    }
  }
}
