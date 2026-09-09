import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/report_timeframe_utils.dart';

class WealthLineChart extends StatelessWidget {
  final ReportData reportData;

  const WealthLineChart({
    super.key,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = reportData.buckets;

    if (buckets.isEmpty || buckets.every((b) => b.cumulativeNetWorth == 0)) {
      return const _EmptyChartCard(
        title: 'Wealth Trend',
        message: 'No transactions yet to plot a wealth trend.',
      );
    }

    final values = buckets.map((b) => b.cumulativeNetWorth).toList();
    final double maxY = values.reduce((a, b) => a > b ? a : b);
    final double minY = values.reduce((a, b) => a < b ? a : b);
    // Add headroom so the line/dots never touch the chart edges.
    final double span = (maxY - minY).abs();
    final double padding = span == 0 ? (maxY.abs() * 0.2 + 10) : span * 0.2;
    final double chartMaxY = maxY + padding;
    final double chartMinY = (minY - padding) < 0 && minY >= 0 ? 0 : minY - padding;

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
              Text('Wealth Trend', style: AppStyles.headingSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${reportData.growthPercent >= 0 ? '+' : ''}${reportData.growthPercent.toStringAsFixed(1)}% growth',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (chartMaxY - chartMinY) == 0 ? 1 : (chartMaxY - chartMinY) / 4,
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
                      interval: (chartMaxY - chartMinY) == 0 ? 1 : (chartMaxY - chartMinY) / 4,
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= buckets.length) return null;
                      final bucket = buckets[index];
                      return LineTooltipItem(
                        '${bucket.label}\n\$${bucket.cumulativeNetWorth.toStringAsFixed(2)}',
                        AppStyles.bodySmall.copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < buckets.length; i++)
                        FlSpot(i.toDouble(), buckets[i].cumulativeNetWorth),
                    ],
                    isCurved: true,
                    color: AppColors.deepPurple,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: index == buckets.length - 1 ? 5 : 3,
                        color: AppColors.deepPurple,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.deepPurple.withOpacity(0.18),
                          AppColors.deepPurple.withOpacity(0.0),
                        ],
                      ),
                    ),
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
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';
    if (absValue >= 1000) {
      return '$sign\$${(absValue / 1000).toStringAsFixed(absValue % 1000 == 0 ? 0 : 1)}k';
    }
    return '$sign\$${absValue.toStringAsFixed(0)}';
  }
}

class _EmptyChartCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyChartCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.headingSmall),
          const SizedBox(height: 40),
          Center(
            child: Text(
              message,
              style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
