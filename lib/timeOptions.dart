import 'package:flutter/material.dart';
import 'package:pomodoro/timerService.dart';
import 'package:pomodoro/utils.dart';
import 'package:provider/provider.dart';

class TimeOptions extends StatelessWidget {
  const TimeOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimerService>(context);
    final selected = provider.selectedTime;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: selectableTimes.map((time) {
          final seconds = double.parse(time);
          final isSelected = seconds == selected;

          return GestureDetector(
            onTap: () {
              if (!provider.timerPlaying) {
                provider.selectTime(seconds);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pause the timer to change time"),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: isSelected
                    ? null
                    : Border.all(
                        width: 2.5,
                        color: Colors.white30,
                      ),
              ),
              child: Center(
                child: Text(
                  (seconds ~/ 60).toString(), // convert to minutes
                  style: textStyle(
                    25,
                    isSelected
                        ? renderColor(provider.currentState)
                        : Colors.white,
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
