import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../report_timeframe_utils.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final ReportData reportData;

  const IncomeExpenseBarChart({
    super.key,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = reportData.buckets;
    // check if there is any transaction in this period
    bool hasData = false;
    for (int i = 0; i < buckets.length; i++) {
      if (buckets[i].income > 0 || buckets[i].expense > 0) {
        hasData = true;
      }
    }

    // find the biggest value so the chart height fits
    double maxVal = 0;
    for (int i = 0; i < buckets.length; i++) {
      if (buckets[i].income > maxVal) {
        maxVal = buckets[i].income;
      }
      if (buckets[i].expense > maxVal) {
        maxVal = buckets[i].expense;
      }
    }

    // keep some space above the tallest bar
    double chartMaxY = 10;
    if (maxVal != 0) {
      chartMaxY = maxVal * 1.2;
    }
    // show the chart if there is data, otherwise show a message
    Widget bodyWidget;
    if (hasData) {
      bodyWidget = _buildChart(chartMaxY);
    } else {
      bodyWidget = _buildEmptyMessage();
    }

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
          _buildHeader(),
          const SizedBox(height: 16),
          bodyWidget,
        ],
      ),
    );
  }

  // title on the left, legend on the right
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Income vs Expense', style: AppStyles.headingSmall),
        const Row(
          children: [
            _LegendDot(color: AppColors.incomeGreen, label: 'Income'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.deepPurple, label: 'Expense'),
          ],
        ),
      ],
    );
  }

  // shown when there is no data
  Widget _buildEmptyMessage() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          'No transactions in this period yet.',
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // the bar chart
  Widget _buildChart(double chartMaxY) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: chartMaxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: chartMaxY / 4,
                getTitlesWidget: _buildLeftTitle,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: _buildBottomTitle,
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: _getTooltipItem,
            ),
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  // numbers on the left side (like $2k)
  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return Text(
      _formatCompact(value),
      style: AppStyles.bodySmall.copyWith(fontSize: 10),
    );
  }

  // labels under the bars (like Jan, Feb)
  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final buckets = reportData.buckets;
    int index = value.toInt();
    // if index is out of range, show nothing
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
  }

  // text shown when the user touches a bar
  BarTooltipItem? _getTooltipItem(
    BarChartGroupData group,
    int groupIndex,
    BarChartRodData rod,
    int rodIndex,
  ) {
    final buckets = reportData.buckets;
    int index = group.x.toInt();

    if (index < 0 || index >= buckets.length) {
      return null;
    }
    final bucket = buckets[index];

    // first rod is income, second rod is expense
    double value;
    String label;
    if (rodIndex == 0) {
      value = bucket.income;
      label = 'Income';
    } else {
      value = bucket.expense;
      label = 'Expense';
    }

    return BarTooltipItem(
      '${bucket.label}\n$label: \$${value.toStringAsFixed(2)}',
      AppStyles.bodySmall.copyWith(color: Colors.white),
    );
  }

  // one group (income bar + expense bar) for each bucket
  List<BarChartGroupData> _buildBarGroups() {
    final buckets = reportData.buckets;
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < buckets.length; i++) {
      BarChartRodData incomeRod = BarChartRodData(
        toY: buckets[i].income,
        color: AppColors.incomeGreen,
        width: 7,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3),
        ),
      );
      BarChartRodData expenseRod = BarChartRodData(
        toY: buckets[i].expense,
        color: AppColors.deepPurple,
        width: 7,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3),
        ),
      );

      BarChartGroupData group = BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [incomeRod, expenseRod],
      );
      groups.add(group);
    }

    return groups;
  }

  // 1500 -> $1.5k, 200 -> $200
  String _formatCompact(double value) {
    if (value >= 1000) {
      int decimals = 1;
      if (value % 1000 == 0) {
        decimals = 0;
      }
      return '\$${(value / 1000).toStringAsFixed(decimals)}k';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}

// small colored dot with a label, used in the legend
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
