import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:speech_to_text/speech_to_text.dart';
import '../constants/app_colors.dart';
import '../models/transaction_model.dart';
import '../providers/database_provider.dart';
import '../database/database.dart' as db;
import '../services/nlp_service.dart';
import 'home/home_screen.dart';
import 'transactions/transactions_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final NLPService _nlpService = NLPService();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _nlpService.initializeModel();
    _speechEnabled = await _speechToText.initialize();
  }

  void _showAddTransactionBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    String selectedCategory = 'Food';
    
    bool isListening = false;
    Timer? recordTimer;

    void saveTransaction() {
      final title = titleController.text.trim();
      final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
      if (title.isNotEmpty && amount > 0) {
        final dbInstance = ref.read(databaseProvider);
        dbInstance.insertTransaction(
          db.TransactionsCompanion.insert(
            title: drift.Value(title),
            amount: amount,
            category: selectedCategory,
            date: DateTime.now(),
            type: selectedType == TransactionType.income ? 'income' : 'expense',
          ),
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!')),
        );
      }
    }

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
          
            void stopListeningAndProcess({bool cancel = false, bool autoSave = false}) async {
              recordTimer?.cancel();
              if (_speechToText.isListening) {
                await _speechToText.stop();
              }
              setModalState(() => isListening = false);
              
              if (cancel) {
                titleController.text = "";
                return;
              }
              
              String text = titleController.text.trim();
              if (text.isEmpty) return;

              // Extract amount
              final RegExp numRegex = RegExp(r'\d+(\.\d+)?');
              final match = numRegex.firstMatch(text);
              if (match != null) {
                amountController.text = match.group(0)!;
              }
              
              // Extract category using NLP
              String category = _nlpService.classifyTransaction(text);
              
              // Determine Income or Expense
              if (category == 'salary') {
                selectedType = TransactionType.income;
                selectedCategory = 'Salary'; 
              } else {
                selectedType = TransactionType.expense;
                selectedCategory = category[0].toUpperCase() + category.substring(1).toLowerCase();
              }
              
              setModalState(() {});
              
              if (autoSave) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  saveTransaction();
                });
              }
            }

            void startListening() async {
              if (!_speechEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Speech recognition is not available on this device.')),
                );
                return;
              }
              
              titleController.text = "";
              setModalState(() => isListening = true);
              
              await _speechToText.listen(
                onResult: (result) {
                  titleController.text = result.recognizedWords;
                },
              );
              
              recordTimer = Timer(const Duration(seconds: 10), () {
                if (isListening) {
                  stopListeningAndProcess(autoSave: true);
                }
              });
            }

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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (isListening) {
                              stopListeningAndProcess(cancel: true);
                            } else {
                              startListening();
                            }
                          },
                          icon: Icon(isListening ? Icons.mic_off_rounded : Icons.mic_rounded, size: 20),
                          label: Text(isListening ? 'Cancel' : 'Voice'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isListening ? AppColors.primaryPurple : Colors.transparent,
                            foregroundColor: isListening ? Colors.white : AppColors.primaryPurple,
                            side: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement image scanning
                          },
                          icon: const Icon(Icons.document_scanner_rounded, size: 20),
                          label: const Text('Scan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryPurple,
                            side: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (\$)',
                      prefixText: '\$ ',
                    ),
                  ),

                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                      DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                      DropdownMenuItem(value: 'Movie', child: Text('Movie')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
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
                        if (isListening) {
                          stopListeningAndProcess(autoSave: true);
                        } else {
                          saveTransaction();
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
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);
    final userAsyncValue = ref.watch(userStreamProvider);
    
    final transactions = transactionsAsyncValue.maybeWhen(
      data: (driftTxList) => driftTxList.map((tx) => TransactionModel.fromDrift(tx)).toList().reversed.toList(),
      orElse: () => <TransactionModel>[],
    );
    
    final user = userAsyncValue.valueOrNull;
    final totalBalance = user?.currentWalletAmount ?? 0.0;

    final screens = [
      HomeScreen(
        transactions: transactions,
        user: user,
        onNavigateToTransactions: () => setState(() => _currentIndex = 1),
        onNavigateToReports: () => setState(() => _currentIndex = 2),
      ),
      TransactionsScreen(
        transactions: transactions,
        onAddTransaction: () => _showAddTransactionBottomSheet(context),
      ),
      ReportsScreen(transactions: transactions),
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
