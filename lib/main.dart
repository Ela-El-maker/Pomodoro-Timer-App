import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pomodoro/dailyStatsScreen.dart';
import 'package:pomodoro/loginScreen.dart';
import 'package:pomodoro/timerService.dart';
import 'package:provider/provider.dart';
import 'UserSettingsService.dart';
import 'authService.dart';
import 'dailyStatsService.dart';
import 'taskListScreen.dart';
import 'taskService.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>(); // 👈 Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  print("App started");

  final authService = AuthService();
  final autoLoggedIn = await authService.tryAutoLogin();

  if (autoLoggedIn) {
    await authService.fetchUser(); // fetch and wait BEFORE UI
  }

  final settingsService = SettingsService();
  if (authService.isAuthenticated) {
    await settingsService.fetchSettings();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<DailyStatsService>(create: (_) => DailyStatsService()),
        ChangeNotifierProvider(
          create: (_) => TimerService(
            focusDuration: settingsService.focusDuration,
            shortBreakDuration: settingsService.shortBreakDuration,
            longBreakDuration: settingsService.longBreakDuration,
            autoContinue: settingsService.autoStart,
          ),
        ),
        ChangeNotifierProvider<TaskService>(create: (_) => TaskService()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final settings = Provider.of<SettingsService>(context); // 👈 FIXED

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/tasks': (_) => const TaskListScreen(),
        '/daily': (_) => const DailyStatsScreen(),
      },
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode:
          settings.darkMode ? ThemeMode.dark : ThemeMode.light, // ✅ FIXED
      home: auth.isAuthenticated ? const TaskListScreen() : const LoginScreen(),
    );
  }
}
