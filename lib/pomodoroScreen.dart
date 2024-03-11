import 'package:flutter/material.dart';
import 'package:pomodoro/progressWidget.dart';
import 'package:pomodoro/timeCard.dart';
import 'package:pomodoro/timeController.dart';
import 'package:pomodoro/timeOptions.dart';
import 'package:pomodoro/timerService.dart';
import 'package:pomodoro/utils.dart';
import 'package:provider/provider.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimerService>(context);
    return Scaffold(
      backgroundColor: renderColor(provider.currentState),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: renderColor(provider.currentState),
        title: Text(
          "Pomodoro Timer",
          style: textStyle(25, Colors.white, FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => Provider.of<TimerService>(context, listen: false).reset(),
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(
                height: 15,
              ),
              TimerCard(),
              SizedBox(height: 40),
              TimeOptions(),
              SizedBox(height: 30),
              TimeController(),
              SizedBox(height: 30),
              ProgressWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
