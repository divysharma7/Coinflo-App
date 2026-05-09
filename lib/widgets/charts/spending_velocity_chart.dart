import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// Two racing lines — this month vs last month cumulative spending.
/// If this month's line is above last month's, you're spending faster.
class SpendingVelocityChart extends StatelessWidget {
  final List<double> thisMonth;
  final List<double> lastMonth;

  const SpendingVelocityChart({
    super.key,
    required this.thisMonth,
    required this.lastMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (thisMonth.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Month just started.',
            style: TextStyle(color: PaisaColors.textTertiary),
          ),
        ),
      );
    }

    // Only show up to today's day index
    final today = DateTime.now().day;
    final thisMonthTrimmed = thisMonth.take(today).toList();

    final allValues = [
      ...thisMonthTrimmed,
      ...lastMonth,
    ];
    final maxY = allValues.isEmpty
        ? 1000.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.15;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1000,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: PaisaColors.border,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt() + 1;
                  if (day == 1 || day == 8 || day == 15 || day == 22 || day == 29) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          fontSize: PaisaTypo.microSize,
                          color: PaisaColors.textTertiary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final text = value >= 1000
                      ? '${(value / 1000).toStringAsFixed(0)}k'
                      : value.toStringAsFixed(0);
                  return Text(
                    text,
                    style: const TextStyle(
                      fontSize: PaisaTypo.microSize,
                      color: PaisaColors.textTertiary,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Last month — muted, dashed-style (thinner)
            LineChartBarData(
              spots: List.generate(
                lastMonth.length,
                (i) => FlSpot(i.toDouble(), lastMonth[i]),
              ),
              isCurved: true,
              color: PaisaColors.textTertiary,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 4],
            ),
            // This month — bold yellow
            LineChartBarData(
              spots: List.generate(
                thisMonthTrimmed.length,
                (i) => FlSpot(i.toDouble(), thisMonthTrimmed[i]),
              ),
              isCurved: true,
              color: PaisaColors.yellow,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) =>
                    spot.x == thisMonthTrimmed.length - 1, // only last dot
                getDotPainter: (spot, pct, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: PaisaColors.yellow,
                  strokeWidth: 2,
                  strokeColor: PaisaColors.scaffold,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: PaisaColors.yellow.withValues(alpha: 0.06),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final isThis = spot.barIndex == 1;
                  return LineTooltipItem(
                    '₹${spot.y.toStringAsFixed(0)}',
                    TextStyle(
                      color: isThis ? PaisaColors.yellow : PaisaColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
