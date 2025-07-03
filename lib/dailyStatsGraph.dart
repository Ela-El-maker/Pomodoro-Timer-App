import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyStatsGraph extends StatelessWidget {
  final List<Map<String, dynamic>> stats;

  const DailyStatsGraph({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              // tooltipBackgroundColor: Colors.black87, // ✅ use this
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= stats.length) return null;
                  final date = stats[index]['date'].substring(5);
                  final minutes =
                      (stats[index]['total_focus_seconds'] ?? 0) ~/ 60;
                  return LineTooltipItem(
                    "$date\n$minutes min",
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.length)
                    return const SizedBox.shrink();
                  final date = stats[index]['date'] as String;
                  return SideTitleWidget(
                    meta: meta, // ✅ required
                    child: Text(date.substring(5),
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.teal,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.teal.withOpacity(0.2),
              ),
              spots: List.generate(stats.length, (i) {
                final minutes = (stats[i]['total_focus_seconds'] ?? 0) / 60.0;
                return FlSpot(i.toDouble(), minutes);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// squiggly_line_chart

class SquigglyLineChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const SquigglyLineChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final focusSeconds = stats['total_focus_seconds'] ?? 0;
    final breakSeconds = stats['total_break_seconds'] ?? 0;
    final sessions = stats['total_sessions'] ?? 0;
    final interrupted = stats['interrupted_sessions'] ?? 0;

    final data = [
      focusSeconds / 60.0,
      breakSeconds / 60.0,
      sessions.toDouble(),
      interrupted.toDouble(),
    ];

    final labels = ["Focus (min)", "Break (min)", "Sessions", "Interrupted"];

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      index >= 0 && index < labels.length ? labels[index] : '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), data[i]),
              ),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              belowBarData:
                  BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
