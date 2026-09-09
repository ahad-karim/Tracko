import '../models/transaction_model.dart';

enum ReportTimeframe { weekly, monthly, yearly }

/// One bucket on the x-axis of a report chart (a day, a month, or a year).
class ReportBucket {
  final String label;
  final double income;
  final double expense;

  /// Cumulative net worth as of the END of this bucket, including everything
  /// that happened before the visible window started.
  final double cumulativeNetWorth;

  const ReportBucket({
    required this.label,
    required this.income,
    required this.expense,
    required this.cumulativeNetWorth,
  });

  double get net => income - expense;
}

class ReportData {
  final List<ReportBucket> buckets;
  final double growthPercent;

  const ReportData({
    required this.buckets,
    required this.growthPercent,
  });
}

const List<String> _monthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _weekdayLabels = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// Builds chart-ready buckets for [transactions], grouped according to
/// [timeframe], anchored on [now] (defaults to DateTime.now()).
ReportData buildReportData(
  List<TransactionModel> transactions,
  ReportTimeframe timeframe, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));

  late DateTime windowStart;
  late List<DateTime> bucketStarts; // start instant of each bucket
  late String Function(DateTime) labelFor;
  late bool Function(DateTime, DateTime bucketStart) belongsToBucket;

  switch (timeframe) {
    case ReportTimeframe.weekly:
      // Last 7 days, one bucket per day.
      final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
      windowStart = today.subtract(const Duration(days: 6));
      bucketStarts = List.generate(7, (i) => windowStart.add(Duration(days: i)));
      labelFor = (d) => _weekdayLabels[d.weekday - 1];
      belongsToBucket = (txDate, bucketStart) {
        final txDay = DateTime(txDate.year, txDate.month, txDate.day);
        return txDay == bucketStart;
      };
      break;

    case ReportTimeframe.monthly:
      // Last 12 months, one bucket per month.
      final thisMonth = DateTime(currentTime.year, currentTime.month, 1);
      windowStart = DateTime(thisMonth.year, thisMonth.month - 11, 1);
      bucketStarts = List.generate(
        12,
        (i) => DateTime(windowStart.year, windowStart.month + i, 1),
      );
      labelFor = (d) => _monthLabels[d.month - 1];
      belongsToBucket = (txDate, bucketStart) {
        return txDate.year == bucketStart.year && txDate.month == bucketStart.month;
      };
      break;

    case ReportTimeframe.yearly:
      // Last 5 years, one bucket per year.
      windowStart = DateTime(currentTime.year - 4, 1, 1);
      bucketStarts = List.generate(5, (i) => DateTime(windowStart.year + i, 1, 1));
      labelFor = (d) => d.year.toString();
      belongsToBucket = (txDate, bucketStart) => txDate.year == bucketStart.year;
      break;
  }

  // Net worth accumulated from all transactions strictly before the window,
  // so the line chart starts from the correct baseline instead of zero.
  double runningTotal = 0;
  for (final tx in sorted) {
    if (tx.date.isBefore(windowStart)) {
      runningTotal += tx.isIncome ? tx.amount : -tx.amount;
    }
  }
  final double startingWealth = runningTotal;

  final buckets = <ReportBucket>[];
  for (final bucketStart in bucketStarts) {
    double income = 0;
    double expense = 0;
    for (final tx in sorted) {
      if (belongsToBucket(tx.date, bucketStart)) {
        if (tx.isIncome) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }
    runningTotal += income - expense;
    buckets.add(
      ReportBucket(
        label: labelFor(bucketStart),
        income: income,
        expense: expense,
        cumulativeNetWorth: runningTotal,
      ),
    );
  }

  final double endingWealth = buckets.isNotEmpty ? buckets.last.cumulativeNetWorth : startingWealth;
  double growthPercent;
  if (startingWealth == 0) {
    growthPercent = endingWealth == 0 ? 0.0 : 100.0;
  } else {
    growthPercent = ((endingWealth - startingWealth) / startingWealth.abs()) * 100;
  }

  return ReportData(buckets: buckets, growthPercent: growthPercent);
}
