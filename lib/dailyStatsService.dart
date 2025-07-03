import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DailyStats {
  final DateTime date;
  final int totalRounds;
  final int totalGoals;
  final int totalFocusSeconds;
  final List<dynamic> taskBreakdown;

  DailyStats({
    required this.date,
    required this.totalRounds,
    required this.totalGoals,
    required this.totalFocusSeconds,
    required this.taskBreakdown,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date']),
      totalRounds: json['total_rounds'],
      totalGoals: json['total_goals'],
      totalFocusSeconds: json['total_focus_seconds'],
      taskBreakdown: json['task_breakdown'] ?? [],
    );
  }
}

class DailyStatsService with ChangeNotifier {
  final String baseUrl = "https://letscode.felixeladi.co.ke/api";
  DailyStats? _dailyStats;
  DateTime _selectedDate = DateTime.now();

  DailyStats? get dailyStats => _dailyStats;
  DateTime get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    _selectedDate = date;
    fetchStatsForDate(date);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchStatsForDate(DateTime date) async {
    final token = await _getToken();
    final formatted = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse('$baseUrl/daily-stats/$formatted'),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _dailyStats = DailyStats.fromJson(data);
      notifyListeners();
    } else {
      print('Failed to fetch daily stats: ${response.statusCode}');
      print('Response: ${response.body}');
      throw Exception("Failed to fetch daily stats");
    }
  }
}
