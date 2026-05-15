import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// Reusable bar chart used across home & reports.
class SpendBarChart extends StatelessWidget {
  const SpendBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor = AppColors.black,
    this.height = 180,
    this.currencySymbol = '\$',
    this.onBarTap,
  });

  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final double height;
  final String currencySymbol;
  final void Function(int index)? onBarTap;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray400)),
        ),
      );
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '$currencySymbol${rod.toY.toStringAsFixed(0)}',
                  AppTextStyles.bodyS.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            touchCallback: onBarTap == null
                ? null
                : (FlTouchEvent event, BarTouchResponse? response) {
                    if (event is FlTapUpEvent &&
                        response != null &&
                        response.spot != null) {
                      onBarTap!(response.spot!.touchedBarGroupIndex);
                    }
                  },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: AppTextStyles.labelS.copyWith(
                        color: AppColors.gray400,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            final isToday = _isTodayIndex(i);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: values[i] > 0
                      ? (isToday ? barColor : barColor.withValues(alpha: 0.5))
                      : AppColors.gray200,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }

  bool _isTodayIndex(int i) {
    if (labels.length == 7) {
      return i == DateTime.now().weekday - 1;
    }
    return false;
  }
}
