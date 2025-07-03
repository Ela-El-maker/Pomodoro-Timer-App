import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dailyStatsGraph.dart';
import 'horizontalDatePicker.dart';

class DailyStatsScreen extends StatefulWidget {
  const DailyStatsScreen({super.key});

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

enum ChartMode { focusOverWeek, breakVsInterrupt }

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? stats;
  bool loading = false;
  final String baseUrl = "https://letscode.felixeladi.co.ke/api";
  ChartMode currentMode = ChartMode.breakVsInterrupt;
  List<Map<String, dynamic>> recentStats = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchRecentStats();
  }

  Future<void> _fetchStats() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-stats/$dateStr'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() => stats = json.decode(response.body));
      } else {
        setState(() => stats = null);
      }
    } catch (e) {
      print("Error fetching stats: $e");
      setState(() => stats = null);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _fetchRecentStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-stats'), // index returns 30 days
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() => recentStats = List<Map<String, dynamic>>.from(json.decode(response.body)));
      }
    } catch (e) {
      print("Error fetching recent stats: $e");
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      stats = null;
    });
    _fetchStats();
  }

  String formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Stats")),
      body: Column(
        children: [
          HorizontalDatePicker(
            selectedDate: selectedDate,
            onDateSelected: _onDateChanged,
          ),
          const SizedBox(height: 12),

          // 👇 Toggle buttons for chart mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ToggleButtons(
              isSelected: [
                currentMode == ChartMode.breakVsInterrupt,
                currentMode == ChartMode.focusOverWeek
              ],
              onPressed: (index) {
                setState(() {
                  currentMode = ChartMode.values[index];
                });
              },
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: Colors.blue,
              color: Colors.black87,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Break vs Interruption"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Focus Over Week"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : stats == null
                    ? const Center(child: Text("No data available"))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text("Total Rounds: ${stats!['total_rounds'] ?? 0}"),
                          Text("Total Goals: ${stats!['total_goals'] ?? 0}"),
                          Text("Focus Time: ${formatTime(stats!['total_focus_seconds'] ?? 0)}"),
                          Text("Break Time: ${formatTime(stats!['total_break_seconds'] ?? 0)}"),
                          Text("Sessions: ${stats!['total_sessions'] ?? 0}"),
                          Text("Interrupted: ${stats!['interrupted_sessions'] ?? 0}"),
                          const SizedBox(height: 24),

                          Text("Productivity Graph", style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 240,
                            child: currentMode == ChartMode.breakVsInterrupt
                                ? SquigglyLineChart(stats: stats!)
                                : DailyStatsGraph(stats: recentStats),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
