import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String title;
  final String categoryName;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final IconData icon;
  final Color iconBackgroundColor;
  final String accountName;

  TransactionModel({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.amount,
    required this.date,
    required this.type,
    required this.icon,
    required this.iconBackgroundColor,
    this.accountName = 'Main Bank Account',
  });

  bool get isIncome => type == TransactionType.income;

  static List<TransactionModel> get dummyTransactions => [];
}
