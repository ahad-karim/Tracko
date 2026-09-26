import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/transaction_model.dart';
import '../../widgets/cards/activity_tile.dart';
import '../../widgets/cards/balance_card.dart';

class HomeScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToReports;

  const HomeScreen({
    super.key,
    required this.transactions,
    this.onNavigateToTransactions,
    this.onNavigateToReports,
  });

  Future<void> _takePicture(BuildContext context) async {
    final picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // compress a bit; drop this line for full quality
      );

      if (photo == null) return; // user cancelled

      debugPrint('Captured image at: ${photo.path}');
      // TODO: hand this path off to your Riverpod provider / Drift table
      // e.g. attach it to a new transaction as a receipt image.

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            insetPadding: const EdgeInsets.all(16),
            content: Image.file(File(photo.path)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to capture image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalIncome = transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final double totalExpense = transactions
        .where((tx) => !tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final double currentBalance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepPurple,
        onPressed: () => _takePicture(context),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.palePurple,
                          border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: const ClipOval(
                          child: Icon(Icons.person_rounded,
                              color: AppColors.deepPurple, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adnan',
                            style: AppStyles.headingMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'TRACKO',
                            style: AppStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      shape: BoxShape.circle,
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Balance Card
              BalanceCard(
                totalBalance: currentBalance,
                percentageIncrease: 0.0,
                onDetailsTap: onNavigateToReports,
              ),
              const SizedBox(height: 40),

              Text(
                'Recent Transactions',
                style: AppStyles.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: AppStyles.borderRadiusMedium,
                    border:
                        Border.all(color: AppColors.divider.withOpacity(0.5)),
                  ),
                )
              else
                ...transactions
                    .take(4)
                    .map((tx) => ActivityTile(transaction: tx)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppStyles.cardShadow,
              border: Border.all(color: AppColors.divider.withOpacity(0.6)),
            ),
            child: Icon(icon, color: AppColors.deepPurple, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
