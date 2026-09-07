import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/transaction_model.dart';
import 'package:intl/intl.dart';

class ActivityTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final formattedAmount = '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}';
    final formattedDate = DateFormat('MMM dd, hh:mm a').format(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: transaction.iconBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.icon,
            color: isIncome ? AppColors.incomeGreen : AppColors.deepPurple,
            size: 24,
          ),
        ),
        title: Text(
          transaction.title,
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${transaction.categoryName} • $formattedDate',
          style: AppStyles.bodySmall,
        ),
        trailing: Text(
          formattedAmount,
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isIncome ? AppColors.incomeGreen : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
