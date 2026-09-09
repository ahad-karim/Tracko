import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/cards/activity_tile.dart';
import '../../widgets/cards/category_tile.dart';

class TransactionsScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onAddTransaction;

  const TransactionsScreen({
    super.key,
    //ahad
    required this.transactions,
    this.onAddTransaction,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Expense, 2: Income
  String _selectedRange = 'This month';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categories = CategoryModel.dummyCategories;

    // Filter transactions by tab and search
    final filteredTransactions = widget.transactions.where((tx) {
      if (_selectedFilterIndex == 1 && tx.type != TransactionType.expense) return false;
      if (_selectedFilterIndex == 2 && tx.type != TransactionType.income) return false;
      if (_searchQuery.isNotEmpty &&
          !tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !tx.categoryName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.deepPurple),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: AppStyles.borderRadiusMedium,
                  boxShadow: AppStyles.cardShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search transaction or category...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Pill Tab Toggle & Range Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pill Tab Controls
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.palePurple,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        _buildFilterPill('All', 0),
                        _buildFilterPill('Expense', 1),
                        _buildFilterPill('Income', 2),
                      ],
                    ),
                  ),
                  // Dropdown Range Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRange,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.deepPurple, size: 20),
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRange = newValue;
                            });
                          }
                        },
                        items: <String>['This week', 'This month', 'Custom']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Category Breakdown Header
              if (_selectedFilterIndex != 2) ...[
                Text(
                  'Category Breakdown',
                  style: AppStyles.headingMedium,
                ),
                const SizedBox(height: 12),
                ...categories.map((cat) => CategoryTile(category: cat)),
                const SizedBox(height: 20),
              ],
              // All Transactions Header
              Text(
                'Transaction History',
                style: AppStyles.headingMedium,
              ),
              const SizedBox(height: 12),
              if (filteredTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text('No transactions found', style: AppStyles.bodyMedium),
                    ],
                  ),
                )
              else
                ...filteredTransactions.map((tx) => ActivityTile(transaction: tx)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
