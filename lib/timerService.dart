import 'dart:async';
import 'package:flutter/material.dart';

class TimerService extends ChangeNotifier {
  Timer? timer;

  // Constants
  static const int focusDuration = 1500; // 25 mins
  static const int shortBreakDuration = 300; // 5 mins
  static const int longBreakDuration = 1500; // 25 mins (adjust as needed)
  static const int maxRounds = 4;

  // State
  double currentDuration = focusDuration.toDouble();
  double selectedTime = focusDuration.toDouble(); // Current selected duration
  double userSelectedFocusTime =
      focusDuration.toDouble(); // Saved original focus time

  bool timerPlaying = false;
  int rounds = 0;
  int goal = 0;
  String currentState = "FOCUS";

  // bool autoContinue = true;
  bool _autoContinue = true;

  bool get autoContinue => _autoContinue;

  set autoContinue(bool value) {
    _autoContinue = value;
    notifyListeners();
  }

  void start() {
    if (currentDuration <= 0) return; // Prevent running empty timer
    timerPlaying = true;

    autoContinue = true; //running normally

    notifyListeners();

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentDuration <= 1) {
        stop();
        handleNextRound(auto: true); // natural completion
      } else {
        currentDuration--;
        notifyListeners();
      }
    });
  }

  void stop() {
    timer?.cancel();
    timerPlaying = false;
    autoContinue = false;
    notifyListeners();
  }

  void selectTime(double seconds) {
    if (seconds < 60) return; // prevent very short times or 0
    userSelectedFocusTime = seconds;
    selectedTime = seconds;
    currentDuration = seconds;
    notifyListeners();
  }

  void reset() {
    stop();
    currentState = "FOCUS";
    selectedTime = userSelectedFocusTime;
    currentDuration = selectedTime;
    rounds = 0;
    goal = 0;
    notifyListeners();
  }

  void handleNextRound({bool auto = false}) {
    if (currentState == "FOCUS") {
      rounds++;
      goal++;

      if (rounds < maxRounds) {
        currentState = "BREAK";
        currentDuration = shortBreakDuration.toDouble();
        selectedTime = shortBreakDuration.toDouble();
      } else {
        currentState = "LONGBREAK";
        currentDuration = longBreakDuration.toDouble();
        selectedTime = longBreakDuration.toDouble();
      }
    } else {
      currentState = "FOCUS";
      currentDuration = userSelectedFocusTime;
      selectedTime = userSelectedFocusTime;

      if (rounds >= maxRounds) {
        rounds = 0;
      }
    }

    notifyListeners();

    if (auto || autoContinue) {
      start(); // ✅ auto-start only if not paused manually
    }
  }
}
