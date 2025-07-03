import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  int focusDuration = 1500;
  int shortBreakDuration = 300;
  int longBreakDuration = 900;
  bool autoStart = false;
  bool darkMode = false;
  int dailyGoal = 4;
  bool notifications = true;

  final String baseUrl = 'https://letscode.felixeladi.co.ke/api';

  Future<void> fetchSettings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user-settings'), // ✅ Correct endpoint

      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    print("🚀 Headers: ${{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }}");

    // final res = await http.get(
    //   Uri.parse('$baseUrl/debug-token'),
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Accept': 'application/json',
    //   },
    // );
    // print(res.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      focusDuration = data['focus_duration'] ?? 1500;
      shortBreakDuration = data['short_break_duration'] ?? 300;
      longBreakDuration = data['long_break_duration'] ?? 900;
      autoStart = data['auto_start_next_session'] is bool
          ? data['auto_start_next_session']
          : data['auto_start_next_session'] == 1;
      darkMode = data['dark_mode'] is bool
          ? data['dark_mode']
          : data['dark_mode'] == 1;
      dailyGoal = data['daily_goal'] ?? 4;
      notifications = data['notifications_enabled'] is bool
          ? data['notifications_enabled']
          : data['notifications_enabled'] == 1;

      notifyListeners();
    } else {
      throw Exception("Failed to fetch user settings: ${response.body}");
    }
  }

  Future<void> saveSettings() async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/user-settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'focus_duration': focusDuration,
        'short_break_duration': shortBreakDuration,
        'long_break_duration': longBreakDuration,
        'auto_start_next_session': autoStart,
        'dark_mode': darkMode,
        'daily_goal': dailyGoal,
        'notifications_enabled': notifications,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save settings");
    }

    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("🛡️ Using token: $token");
    return token;
  }
}
