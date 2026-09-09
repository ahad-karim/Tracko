import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/report_timeframe_utils.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final ReportData reportData;

  const IncomeExpenseBarChart({
    super.key,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = reportData.buckets;
    final hasData = buckets.any((b) => b.income > 0 || b.expense > 0);

    final double maxVal = buckets.fold<double>(
      0,
      (max, b) => [max, b.income, b.expense].reduce((a, c) => a > c ? a : c),
    );
    final double chartMaxY = maxVal == 0 ? 10 : maxVal * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income vs Expense', style: AppStyles.headingSmall),
                  Text(
                    'Cashflow balance',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Row(
                children: [
                  _LegendDot(color: AppColors.incomeGreen, label: 'Income'),
                  SizedBox(width: 12),
                  _LegendDot(color: AppColors.deepPurple, label: 'Expense'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No transactions in this period yet.',
                  style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: chartMaxY / 4,
                        getTitlesWidget: (value, meta) => Text(
                          _formatCompact(value),
                          style: AppStyles.bodySmall.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              buckets[index].label,
                              style: AppStyles.bodySmall.copyWith(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final index = group.x.toInt();
                        if (index < 0 || index >= buckets.length) return null;
                        final bucket = buckets[index];
                        final isIncome = rodIndex == 0;
                        final value = isIncome ? bucket.income : bucket.expense;
                        final label = isIncome ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '${bucket.label}\n$label: \$${value.toStringAsFixed(2)}',
                          AppStyles.bodySmall.copyWith(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[i].income,
                            color: AppColors.incomeGreen,
                            width: 7,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                          BarChartRodData(
                            toY: buckets[i].expense,
                            color: AppColors.deepPurple,
                            width: 7,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ],
                        barsSpace: 4,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatCompact(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppStyles.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}
