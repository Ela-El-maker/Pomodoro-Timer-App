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
  switch (currentState) {
    case "FOCUS":
      return Color(0xAA0D1B2A); // Glassmorphic dark blue
    case "BREAK":
      return Color(0xAA5D6D7E); // a muted, sophisticated blue-gray

    case "LONGBREAK":
      return Colors.greenAccent;
    default:
      return Colors.grey;
  }
}


/// Converts internal state label to user-friendly text.
String formatStateLabel(String state) {
  switch (state) {
    case "FOCUS":
      return "Focus";
    case "BREAK":
      return "Short Break";
    case "LONGBREAK":
      return "Long Break";
    default:
      return state;
  }
}
