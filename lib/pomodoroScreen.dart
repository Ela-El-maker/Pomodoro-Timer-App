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
            onPressed: () =>
                Provider.of<TimerService>(context, listen: false).reset(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Reset Timer",
          ),
          IconButton(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: "Settings",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter task title...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    Provider.of<TimerService>(context, listen: false)
                        .setTaskTitle(value);
                  },
                ),
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

void _showSettings(BuildContext context) {
  final provider = Provider.of<TimerService>(context, listen: false);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Auto-start next round",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Consumer<TimerService>(
              builder: (context, timerService, _) => Switch(
                value: timerService.autoContinue,
                onChanged: (value) {
                  timerService.autoContinue = value;
                },
              ),
            )
          ],
        ),
      );
    },
  );
}
