import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/transaction_model.dart';
import 'home/home_screen.dart';
import 'transactions/transactions_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Shared state list for transactions
  final List<TransactionModel> _transactions = TransactionModel.dummyTransactions;

  void _addTransaction(TransactionModel transaction) {
    setState(() {
      _transactions.insert(0, transaction);
    });
  }

  void _showAddTransactionBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    String selectedCategory = 'Groceries';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Transaction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Segmented control Income / Expense
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Expense')),
                          selected: selectedType == TransactionType.expense,
                          selectedColor: AppColors.primaryPurple,
                          labelStyle: TextStyle(
                            color: selectedType == TransactionType.expense ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedType = TransactionType.expense);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Income')),
                          selected: selectedType == TransactionType.income,
                          selectedColor: AppColors.incomeGreen,
                          labelStyle: TextStyle(
                            color: selectedType == TransactionType.income ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedType = TransactionType.income);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Merchant',
                      hintText: 'e.g. Coffee, Supermarket, Client Payment',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (\$)',
                      hintText: '0.00',
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Rent & Utilities', child: Text('Rent & Utilities')),
                      DropdownMenuItem(value: 'Impulse Buys', child: Text('Impulse Buys')),
                      DropdownMenuItem(value: 'Income', child: Text('Income')),
                      DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                    ],
                    onChanged: (value) {
                      if (value != null) setModalState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (title.isNotEmpty && amount > 0) {
                          _addTransaction(
                            TransactionModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: title,
                              categoryName: selectedCategory,
                              amount: amount,
                              date: DateTime.now(),
                              type: selectedType,
                              icon: selectedType == TransactionType.income
                                  ? Icons.account_balance_wallet_rounded
                                  : Icons.shopping_bag_rounded,
                              iconBackgroundColor: selectedType == TransactionType.income
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF0ECF6),
                            ),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction added successfully!')),
                          );
                        }
                      },
                      child: const Text('Save Transaction'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        transactions: _transactions,
        onNavigateToTransactions: () => setState(() => _currentIndex = 1),
        onNavigateToReports: () => setState(() => _currentIndex = 2),
      ),
      TransactionsScreen(
        transactions: _transactions,
        onAddTransaction: () => _showAddTransactionBottomSheet(context),
      ),
      ReportsScreen(transactions: _transactions),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionBottomSheet(context),
        backgroundColor: AppColors.primaryPurple,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.cardSurface,
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.grid_view_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.receipt_long_rounded, label: 'Transactions', index: 1),
              const SizedBox(width: 32), // Space for FAB
              _buildNavItem(icon: Icons.bar_chart_rounded, label: 'Reports', index: 2),
              _buildNavItem(icon: Icons.settings_rounded, label: 'Settings', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.deepPurple : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.deepPurple : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
