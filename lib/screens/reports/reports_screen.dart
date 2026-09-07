import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/transaction_model.dart';
import '../../widgets/charts/income_expense_bar_chart.dart';
import '../../widgets/charts/wealth_line_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    final double totalIncome = widget.transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final double totalExpense = widget.transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final double netWorth = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.deepPurple),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report exported to PDF successfully!')),
              );
            },
          ),
        ],
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
                    child: Row(
                      children: [
                        _buildTimeframeChip('Weekly', 0),
                        _buildTimeframeChip('Monthly', 1),
                        _buildTimeframeChip('Yearly', 2),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Wealth Growth Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.deepPurple,
                      AppColors.primaryPurple.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: AppStyles.borderRadiusMedium,
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Net Worth',
                          style: AppStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${netWorth.toStringAsFixed(2)}',
                          style: AppStyles.headingLarge.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '0.0%',
                            style: AppStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total Wealth Line Chart Widget
              const WealthLineChart(),
              const SizedBox(height: 20),

              // Income vs Expense Cashflow Header Summary
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward_rounded, color: AppColors.incomeGreen, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('Total Income', style: AppStyles.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${totalIncome.toStringAsFixed(2)}',
                            style: AppStyles.headingSmall.copyWith(color: AppColors.incomeGreen),
                          ),
                          const SizedBox(height: 2),
                          Text('Real-time updates', style: AppStyles.bodySmall.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEBEE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward_rounded, color: AppColors.expenseRed, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('Total Expense', style: AppStyles.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${totalExpense.toStringAsFixed(2)}',
                            style: AppStyles.headingSmall.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text('Real-time updates', style: AppStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Income vs Expense Dual Bar Chart Widget
              const IncomeExpenseBarChart(),
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
