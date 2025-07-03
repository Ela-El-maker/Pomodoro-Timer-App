import 'package:flutter/material.dart';
import 'package:pomodoro/timerService.dart';
import 'package:pomodoro/utils.dart';
import 'package:provider/provider.dart';

class ProgressWidget extends StatelessWidget {
  const ProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimerService>(context);

    // final roundText = "${provider.rounds}/${TimerService.maxRounds}";
    // final goalText = "${provider.goal}/12";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     _buildProgressBox(context, roundText, 'ROUNDS'),
          //     _buildProgressBox(context, goalText, 'GOALS'),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildProgressBox(
      BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: textStyle(
            30,
            Colors.white.withOpacity(0.9),
            FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: textStyle(
            20,
            Colors.white54,
            FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
