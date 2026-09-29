import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/transaction_model.dart';
import '../../widgets/report_timeframe_utils.dart';
import '../../widgets/charts/income_expense_bar_chart.dart';

class ReportsScreen extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ReportsScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // 0 = Weekly, 1 = Monthly, 2 = Yearly
  int _selectedIndex = 1;

  final List<String> _timeframeTitles = ['Weekly', 'Monthly', 'Yearly'];

  // convert the selected index to a ReportTimeframe
  ReportTimeframe _getTimeframe() {
    if (_selectedIndex == 0) {
      return ReportTimeframe.weekly;
    } else if (_selectedIndex == 2) {
      return ReportTimeframe.yearly;
    } else {
      return ReportTimeframe.monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    // group the transactions once, everything below uses this data
    ReportData reportData = buildReportData(
      widget.transactions,
      _getTimeframe(),
    );

    // total income and expense of all buckets
    double totalIncome = 0;
    double totalExpense = 0;
    for (int i = 0; i < reportData.buckets.length; i++) {
      totalIncome += reportData.buckets[i].income;
      totalExpense += reportData.buckets[i].expense;
    }

    // net worth is taken from the last bucket
    double netWorth = 0;
    if (reportData.buckets.isNotEmpty) {
      netWorth = reportData.buckets.last.cumulativeNetWorth;
    }

    bool isGrowthPositive = reportData.growthPercent >= 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // weekly / monthly / yearly selector
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimeframeChip(_timeframeTitles[0], 0),
                      _buildTimeframeChip(_timeframeTitles[1], 1),
                      _buildTimeframeChip(_timeframeTitles[2], 2),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // summary cards
              Row(
                children: [
                  _buildSummaryCard('Income', totalIncome, Colors.green),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Expense', totalExpense, Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryCard(
                      'Net Worth', netWorth, AppColors.deepPurple),
                  const SizedBox(width: 12),
                  _buildGrowthCard(reportData.growthPercent, isGrowthPositive),
                ],
              ),
              const SizedBox(height: 20),

              // bar chart
              IncomeExpenseBarChart(reportData: reportData),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // one button of the timeframe selector
  Widget _buildTimeframeChip(String title, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: AppStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // small card showing a title and an amount
  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount.toStringAsFixed(2),
              style: AppStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // card showing growth percent with an up or down arrow
  Widget _buildGrowthCard(double growthPercent, bool isPositive) {
    Color color = isPositive ? Colors.green : Colors.red;
    IconData icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${growthPercent.abs().toStringAsFixed(1)}%',
                  style: AppStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
