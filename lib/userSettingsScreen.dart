import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'UserSettingsService.dart';
import 'timerService.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final String baseUrl = "https://letscode.felixeladi.co.ke/api";
  bool loading = true;

  // Settings fields
  int? focusDuration;
  int? shortBreak;
  int? longBreak;
  int? dailyGoal;
  bool autoStart = false;
  bool darkMode = false;
  bool notifications = true;

  @override
  void initState() {
    super.initState();

    final settingsService =
        Provider.of<SettingsService>(context, listen: false);

    settingsService.fetchSettings().then((_) {
      setState(() {
        focusDuration = settingsService.focusDuration;
        shortBreak = settingsService.shortBreakDuration;
        longBreak = settingsService.longBreakDuration;
        dailyGoal = settingsService.dailyGoal;
        autoStart = settingsService.autoStart;
        darkMode = settingsService.darkMode;
        notifications = settingsService.notifications;
        loading = false;
      });
    });
  }

  // Future<void> _loadSettings() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');

  //   final response = await http.get(
  //     Uri.parse('$baseUrl/user-settings'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Accept': 'application/json',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     setState(() {
  //       focusDuration = data['focus_duration'];
  //       shortBreak = data['short_break_duration'];
  //       longBreak = data['long_break_duration'];
  //       dailyGoal = data['daily_goal'];
  //       autoStart = data['auto_start_next_session'] ?? false;
  //       darkMode = data['dark_mode'] ?? false;
  //       notifications = data['notifications_enabled'] ?? true;
  //       loading = false;
  //     });
  //   } else {
  //     setState(() => loading = false);
  //   }
  // }

  Future<void> _saveSettings() async {
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);

    settingsService.focusDuration = focusDuration!;
    settingsService.shortBreakDuration = shortBreak!;
    settingsService.longBreakDuration = longBreak!;
    settingsService.dailyGoal = dailyGoal!;
    settingsService.autoStart = autoStart;
    settingsService.darkMode = darkMode;
    settingsService.notifications = notifications;

    try {
      await settingsService.saveSettings();
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.updateFromSettings(
        focus: settingsService.focusDuration,
        shortBreak: settingsService.shortBreakDuration,
        longBreak: settingsService.longBreakDuration,
        autoStart: settingsService.autoStart,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save settings: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Settings")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("Focus Duration (minutes)"),
                Slider(
                  value: (focusDuration ?? 1500) / 60,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: "${(focusDuration ?? 1500) ~/ 60} min",
                  onChanged: (val) {
                    setState(() => focusDuration = (val * 60).round());
                  },
                ),
                const Text("Short Break (minutes)"),
                Slider(
                  value: (shortBreak ?? 300) / 60,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: "${(shortBreak ?? 300) ~/ 60} min",
                  onChanged: (val) {
                    setState(() => shortBreak = (val * 60).round());
                  },
                ),
                const Text("Long Break (minutes)"),
                Slider(
                  value: (longBreak ?? 900) / 60,
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: "${(longBreak ?? 900) ~/ 60} min",
                  onChanged: (val) {
                    setState(() => longBreak = (val * 60).round());
                  },
                ),
                const Text("Daily Goal (Pomodoros)"),
                Slider(
                  value: (dailyGoal ?? 4).toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: "$dailyGoal goals",
                  onChanged: (val) {
                    setState(() => dailyGoal = val.toInt());
                  },
                ),
                SwitchListTile(
                  title: const Text("Auto-start next session"),
                  value: autoStart,
                  onChanged: (val) => setState(() => autoStart = val),
                ),
                SwitchListTile(
                  title: const Text("Enable Notifications"),
                  value: notifications,
                  onChanged: (val) => setState(() => notifications = val),
                ),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: darkMode,
                  onChanged: (val) => setState(() => darkMode = val),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text("Save Settings"),
                )
              ],
            ),
    );
  }
}
