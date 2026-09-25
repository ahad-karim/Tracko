import 'package:flutter/material.dart';
import '../database/database.dart' as db;

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

  factory TransactionModel.fromDrift(db.Transaction driftTx) {
    IconData icon = Icons.receipt_rounded;
    Color color = const Color(0xFFF0ECF6);

    if (driftTx.type == 'income') {
      icon = Icons.attach_money_rounded;
      color = const Color(0xFFE8F5E9);
    } else {
      final catName = driftTx.category.toLowerCase();
      if (catName.contains('transport')) {
        icon = Icons.directions_bus_rounded;
        color = const Color(0xFFFFF3E0);
      } else if (catName.contains('food')) {
        icon = Icons.fastfood_rounded;
        color = const Color(0xFFF0ECF6);
      } else if (catName.contains('utilit')) {
        icon = Icons.electrical_services_rounded;
        color = const Color(0xFFE3F2FD);
      } else if (catName.contains('movie')) {
        icon = Icons.movie_rounded;
        color = const Color(0xFFFFEBEE);
      } else {
        icon = Icons.category_rounded;
        color = const Color(0xFFEFEFEF);
      }
    }

    return TransactionModel(
      id: driftTx.id.toString(),
      title: driftTx.title,
      categoryName: driftTx.category,
      amount: driftTx.amount,
      date: driftTx.date,
      type: driftTx.type == 'income' ? TransactionType.income : TransactionType.expense,
      icon: icon,
      iconBackgroundColor: color,
    );
  }
}
