import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'add_transaction_screen.dart';

// Notice we use ConsumerWidget instead of StatelessWidget to use Riverpod
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grab the database instance from the provider
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      // StreamBuilder listens to the Drift stream
      body: StreamBuilder<List<Transaction>>(
      stream: db.watchAllTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions yet. Add one!'));
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            // Display each transaction as a list item
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: transaction.type == 'income' ? Colors.green : Colors.red,
                child: Icon(
                  transaction.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                ),
              ),
              title: Text(transaction.category),
              subtitle: Text(transaction.date.toString().split(' ')[0]),
              trailing: Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onLongPress: () {
                // Delete on long press
                db.deleteTransaction(transaction.id);
              },
            );
          },
        );
      },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}