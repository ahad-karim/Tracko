import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  RealColumn get totalIncome => real().withDefault(const Constant(0.0))();
  RealColumn get totalExpense => real().withDefault(const Constant(0.0))();
  RealColumn get currentWalletAmount => real().withDefault(const Constant(0.0))();
}

@DriftDatabase(tables: [Transactions, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await into(users).insert(
          UsersCompanion.insert(name: 'Default User', email: 'user@example.com'),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(users);
          await into(users).insert(
            UsersCompanion.insert(name: 'Default User', email: 'user@example.com'),
          );
        }
      },
    );
  }

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  
  Future<User> getUser() => (select(users)..where((tbl) => tbl.id.equals(1))).getSingle();

  Future<void> _updateUserBalances() async {
    final allTx = await getAllTransactions();
    double income = 0;
    double expense = 0;
    for (var t in allTx) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    double wallet = income - expense;

    await (update(users)..where((tbl) => tbl.id.equals(1))).write(
      UsersCompanion(
        totalIncome: Value(income),
        totalExpense: Value(expense),
        currentWalletAmount: Value(wallet),
      ),
    );
  }

  Future<int> insertTransaction(TransactionsCompanion entry) {
    return transaction(() async {
      final id = await into(transactions).insert(entry);
      await _updateUserBalances();
      return id;
    });
  }

  Future<int> deleteTransaction(int id) {
    return transaction(() async {
      final rowsDeleted = await (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
      await _updateUserBalances();
      return rowsDeleted;
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}