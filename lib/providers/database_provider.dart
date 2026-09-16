import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

// This creates a single instance of AppDatabase to be shared across the app
final databaseProvider = Provider((ref) {
  return AppDatabase();
});

// A stream provider that watches all transactions from the database
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTransactions();
});