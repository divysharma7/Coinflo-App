import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<PaisaTransaction> transactions;
  final DateTime weekStart;
  final void Function(DateTime day)? onBarTap;

  const WeeklyBarChart({
    super.key,
    required this.transactions,
    required this.weekStart,
    this.onBarTap,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _growCtrl;
  late final Animation<double> _growAnim;

  @override
  void initState() {
    super.initState();
    _growCtrl = AnimationController(
      vsync: this,
      duration: SpendlerMotion.barGrow,
    );
    _growAnim = CurvedAnimation(parent: _growCtrl, curve: SpendlerMotion.barGrowCurve);
    _growCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart old) {
    super.didUpdateWidget(old);
    if (old.weekStart != widget.weekStart) {
      _growCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _growCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyTotals = _computeDailyTotals();
    final maxVal = dailyTotals.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 1000.0 : maxVal * 1.2;
    final today = DateTime.now();
    final todayIndex = today.weekday - 1;
    final highestIndex = dailyTotals.indexOf(dailyTotals.reduce((a, b) => a > b ? a : b));

    return AnimatedBuilder(
      animation: _growAnim,
      builder: (context, _) {
        return SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchCallback: (event, response) {
                  if (event.isInterestedForInteractions &&
                      response?.spot != null &&
                      widget.onBarTap != null) {
                    final dayIndex = response!.spot!.touchedBarGroupIndex;
                    widget.onBarTap!(widget.weekStart.add(Duration(days: dayIndex)));
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '\$${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                        color: SpendlerColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final i = value.toInt();
                      final isToday = i == todayIndex &&
                          widget.weekStart.add(Duration(days: todayIndex)).day ==
                              today.day;
                      final isHighlight = i == todayIndex || i == highestIndex;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[i],
                          style: TextStyle(
                            fontSize: SpendlerTypo.microSize,
                            fontWeight:
                                isToday ? FontWeight.bold : SpendlerTypo.microWeight,
                            color: isHighlight
                                ? SpendlerColors.accentYellow
                                : SpendlerColors.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: List.generate(7, (i) {
                final isToday = i == todayIndex &&
                    widget.weekStart.add(Duration(days: todayIndex)).day ==
                        today.day;
                final isHighest = i == highestIndex && maxVal > 0;
                final isAccent = isToday || isHighest;

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: dailyTotals[i] * _growAnim.value,
                      color: isAccent
                          ? SpendlerColors.accentYellow
                          : SpendlerColors.textTertiary,
                      width: 28,
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
      },
    );
  }

  List<double> _computeDailyTotals() {
    final totals = List.filled(7, 0.0);
    for (final t in widget.transactions) {
      if (t.amount < 0) {
        final dayIndex = t.happenedAt.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          totals[dayIndex] += t.amount.abs();
        }
      }
    }
    return totals;
  }
}
