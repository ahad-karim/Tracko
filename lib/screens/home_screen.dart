import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'add_transaction_screen.dart';
import '../services/nlp_service.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<List<Transaction>>? _transactionsFuture;
  Future<User>? _userFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final db = ref.read(databaseProvider);
    setState(() {
      _transactionsFuture = db.getAllTransactions();
      _userFuture = db.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [

          IconButton(
            icon: const Icon(Icons.android),
            tooltip: 'Test AI Model',
            onPressed: () async {
              final nlp = NLPService();

              await nlp.initializeModel();
              final result = nlp.classifyTransaction("I spent 500 taka on a massive burger at Unique Flavours");

              print("====================================");
              print("AI PREDICTION RESULT: $result");
              print("====================================");
            },
          ),
        ],
      ),

      body: Column(
        children: [
          FutureBuilder<User>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final user = snapshot.data!;
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Hello, ${user.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Wallet'),
                            Text('\$${user.currentWalletAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Income', style: TextStyle(color: Colors.green)),
                            Text('\$${user.totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Expense', style: TextStyle(color: Colors.red)),
                            Text('\$${user.totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions yet!!!! Add one!'));
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];

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
                      onLongPress: () async {
                        await db.deleteTransaction(transaction.id);
                        _refreshData();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}