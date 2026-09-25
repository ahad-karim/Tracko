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
  int _selectedTimeframeIndex = 1; // 0: Weekly, 1: Monthly, 2: Yearly

  ReportTimeframe get _selectedTimeframe {
    switch (_selectedTimeframeIndex) {
      case 0:
        return ReportTimeframe.weekly;
      case 2:
        return ReportTimeframe.yearly;
      case 1:
      default:
        return ReportTimeframe.monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Single source of truth: bucket the transactions once for the
    // selected timeframe, then derive every number on screen from it.
    final ReportData reportData = buildReportData(
      widget.transactions,
      _selectedTimeframe,
    );

    final double periodIncome =
    reportData.buckets.fold(0.0, (sum, b) => sum + b.income);
    final double periodExpense =
    reportData.buckets.fold(0.0, (sum, b) => sum + b.expense);
    final double netWorth = reportData.buckets.isNotEmpty
        ? reportData.buckets.last.cumulativeNetWorth
        : 0.0;
    final bool isGrowthPositive = reportData.growthPercent >= 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
                    ),

                  ),
                ],
              ),
              const SizedBox(height: 20),
              IncomeExpenseBarChart(reportData: reportData),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeChip(String title, int index) {
    final isSelected = _selectedTimeframeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeframeIndex = index),
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
}