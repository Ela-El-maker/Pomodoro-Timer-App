import 'package:flutter/material.dart';
import 'package:pomodoro/timerService.dart';
import 'package:pomodoro/utils.dart';
import 'package:provider/provider.dart';

class TimerCard extends StatelessWidget {
  const TimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimerService>(context);

    final totalMinutes =
        (provider.selectedTime ~/ 60).clamp(1, double.infinity);
    final minutesRemaining = (provider.currentDuration ~/ 60);
    final secondsRemaining = (provider.currentDuration % 60).floor();

    final minuteProgress = (totalMinutes - minutesRemaining) / totalMinutes;
    final secondProgress = (60 - secondsRemaining) / 60;

    final timeString =
        "${minutesRemaining.toString().padLeft(2, '0')}:${secondsRemaining.toString().padLeft(2, '0')}";

    return Column(
      children: [
        Text(
          provider.taskTitle.isEmpty ? "No Task" : provider.taskTitle,
          style: textStyle(20, Colors.white70, FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Text(
          formatStateLabel(provider.currentState.name),
          style: textStyle(
            35,
            renderColor(provider.currentState.name),
            FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: minuteProgress.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey[300]!,
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: secondProgress.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    renderColor(provider.currentState.name),
                  ),
                ),
              ),
              Text(
                timeString,
                style: textStyle(40, Colors.white, FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //   children: [
        //     _buildProgressRing(
        //       context,
        //       label: 'ROUND',
        //       current: provider.rounds,
        //       total: 4,
        //       color: Colors.blueAccent,
        //     ),
        //     _buildProgressRing(
        //       context,
        //       label: 'GOAL',
        //       current: provider.goal,
        //       total: 12,
        //       color: Colors.deepOrangeAccent,
        //     ),
        //   ],
        // )
      ],
    );
  }

  Widget _buildProgressRing(
    BuildContext context, {
    required String label,
    required int current,
    required int total,
    required Color color,
  }) {
    final progress = current / total;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              "$current/$total",
              style: textStyle(14, Colors.white, FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: textStyle(16, Colors.white70, FontWeight.w500),
        ),
      ],
    );
  }
}
