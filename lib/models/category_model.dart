import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final double amountSpent;
  final double budgetLimit;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color progressBarColor;

  CategoryModel({
    required this.id,
    required this.name,
    required this.amountSpent,
    required this.budgetLimit,
    required this.icon,
    required this.iconBackgroundColor,
    required this.progressBarColor,
  });

  double get percentage => (amountSpent / budgetLimit).clamp(0.0, 1.0);
  int get percentageInt => (percentage * 100).round();

  static List<CategoryModel> get dummyCategories => [
        CategoryModel(
          id: 'c1',
          name: 'Food',
          amountSpent: 0.00,
          budgetLimit: 2000.00,
          icon: Icons.fastfood_rounded,
          iconBackgroundColor: const Color(0xFFF0ECF6),
          progressBarColor: const Color(0xFF6C5294),
        ),
        CategoryModel(
          id: 'c2',
          name: 'Transport',
          amountSpent: 0.00,
          budgetLimit: 1500.00,
          icon: Icons.directions_bus_rounded,
          iconBackgroundColor: const Color(0xFFFFF3E0),
          progressBarColor: const Color(0xFFFF9800),
        ),
        CategoryModel(
          id: 'c3',
          name: 'Salary',
          amountSpent: 0.00,
          budgetLimit: 5000.00,
          icon: Icons.attach_money_rounded,
          iconBackgroundColor: const Color(0xFFE8F5E9),
          progressBarColor: const Color(0xFF4CAF50),
        ),
        CategoryModel(
          id: 'c4',
          name: 'Utilities',
          amountSpent: 0.00,
          budgetLimit: 3000.00,
          icon: Icons.electrical_services_rounded,
          iconBackgroundColor: const Color(0xFFE3F2FD),
          progressBarColor: const Color(0xFF1E88E5),
        ),
        CategoryModel(
          id: 'c5',
          name: 'Movie',
          amountSpent: 0.00,
          budgetLimit: 500.00,
          icon: Icons.movie_rounded,
          iconBackgroundColor: const Color(0xFFFFEBEE),
          progressBarColor: const Color(0xFFE53935),
        ),
        CategoryModel(
          id: 'c6',
          name: 'Other',
          amountSpent: 0.00,
          budgetLimit: 1000.00,
          icon: Icons.category_rounded,
          iconBackgroundColor: const Color(0xFFEFEFEF),
          progressBarColor: const Color(0xFF9E9E9E),
        ),
      ];
}
