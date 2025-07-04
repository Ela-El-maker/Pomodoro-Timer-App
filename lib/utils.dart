import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Generates consistent styled text.
TextStyle textStyle(double size, [Color? color, FontWeight? fw]) {
  return GoogleFonts.montserrat(
    fontSize: size,
    color: color,
    fontWeight: fw,
  );
}

/// List of selectable durations in seconds (5 mins to 1 hr)
List<String> selectableTimes = [
  '300',   // 5 min
  '600',   // 10 min
  '900',   // 15 min
  '1200',  // 20 min
  '1500',  // 25 min (Pomodoro default)
  '1800',  // 30 min
  '2100',
  '2400',
  '2700',
  '3000',
  '3300',
  '3600',  // 1 hour
];

/// Returns background color depending on current state.
Color renderColor(String currentState) {
  final normalized = currentState.toLowerCase();

  switch (normalized) {
    case "focus":
      return const Color(0xFF1A1A40); // Deep Indigo
    case "shortbreak":
    case "break":
      return const Color(0xFFA8D5BA); // Misty Sage
    case "longbreak":
      return const Color(0xFFFFD6A5); // Warm Coral
    default:
      return Colors.grey.shade400;
  }
}





/// Converts internal state label to user-friendly text.
String formatStateLabel(String state) {
  final normalized = state.toLowerCase();

  switch (normalized) {
    case "focus":
      return "Focus";
    case "shortbreak":
    case "break":
      return "Short Break";
    case "longbreak":
      return "Long Break";
    default:
      return state;
  }
}

