import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// 7 bars showing average spending per day of week.
/// Reveals behavioral patterns: "I spend 3x more on Saturdays."
class DayOfWeekChart extends StatelessWidget {
  /// 7 values, Mon=0 .. Sun=6
  final List<double> averages;

  const DayOfWeekChart({super.key, required this.averages});

  @override
  Widget build(BuildContext context) {
    if (averages.every((v) => v == 0)) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Two weeks of data needed.',
            style: TextStyle(color: SpendlerColors.textTertiary),
          ),
        ),
      );
    }

    final maxVal = averages.reduce((a, b) => a > b ? a : b);
    final maxIndex = averages.indexOf(maxVal);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal == 0 ? 1000 : maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(0)}/week',
                  const TextStyle(
                    color: SpendlerColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  final isMax = i == maxIndex;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days[i],
                      style: TextStyle(
                        fontSize: SpendlerTypo.microSize,
                        fontWeight: isMax ? FontWeight.w700 : FontWeight.w400,
                        color: isMax
                            ? SpendlerColors.yellow
                            : SpendlerColors.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(7, (i) {
            final isMax = i == maxIndex;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: averages[i],
                  color: isMax ? SpendlerColors.yellow : SpendlerColors.textTertiary,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SpendlerRadii.barTop),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
