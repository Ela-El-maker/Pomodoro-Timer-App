import 'package:flutter/material.dart';
import 'package:pomodoro/timerService.dart';
import 'package:pomodoro/utils.dart';
import 'package:provider/provider.dart';

class TimerCard extends StatelessWidget {
  const TimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimerService>(context);
    final seconds = provider.currentDuration % 60;
    return Column(
      children: [
        Text(
          provider.currentState,
          style:
              // textStyle(35, Color.fromARGB(255, 28, 196, 101), FontWeight.w700),
            textStyle(35, 
    provider.currentState == "FOCUS" ? Colors.lightBlueAccent : Colors.redAccent,
    FontWeight.w700,
  ),
        ),
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 3.2,
              height: 170,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 4,
                      blurRadius: 4,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ]),
              child: Center(
                child: Text(
                  ((provider.currentDuration ~/ 60).toString()),
                  style: textStyle(70, renderColor(provider.currentState), FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              ':',
              style: textStyle(60, Colors.red[200], FontWeight.bold),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              width: MediaQuery.of(context).size.width / 3.2,
              height: 170,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 4,
                      blurRadius: 4,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ]),
              child: Center(
                child: Text(
                  seconds == 0
                      ? "${seconds.round()}0"
                      : seconds.round().toString(),
                  style: textStyle(70, renderColor(provider.currentState), FontWeight.bold),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
