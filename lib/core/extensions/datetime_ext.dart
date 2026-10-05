import 'package:intl/intl.dart';

/// Extension methods on DateTime for MonthlyGoals.
extension DateTimeExt on DateTime {
  /// Returns 'YYYY-MM' string used as the month key in DB.
  String get monthKey => DateFormat('yyyy-MM').format(this);

  /// Returns 'January 2026' style label.
  String get monthLabel => DateFormat('MMMM yyyy').format(this);

  /// Returns 'Mon, 6 Oct' style label.
  String get shortLabel => DateFormat('EEE, d MMM').format(this);

  /// Returns 'Oct 6' compact label.
  String get compactLabel => DateFormat('MMM d').format(this);

  /// Returns 'Oct 6, 2026' full date.
  String get fullDate => DateFormat('MMM d, yyyy').format(this);

  /// Returns '2:30 PM' time.
  String get timeLabel => DateFormat('h:mm a').format(this);

  /// Returns 'Oct 6, 2026 · 2:30 PM'.
  String get fullDateTime => '$fullDate · $timeLabel';

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isOverdue => isBefore(DateTime.now());

  bool get isDueSoon {
    final diff = difference(DateTime.now()).inHours;
    return diff >= 0 && diff <= 48;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  DateTime get firstDayOfMonth => DateTime(year, month, 1);
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);

  String countdownLabel() {
    final now = DateTime.now();
    final diff = difference(now);
    if (diff.isNegative) {
      final absDiff = now.difference(this);
      if (absDiff.inDays >= 1) return '${absDiff.inDays}d overdue';
      if (absDiff.inHours >= 1) return '${absDiff.inHours}h overdue';
      return 'Just overdue';
    }
    if (diff.inDays >= 1) return 'in ${diff.inDays}d';
    if (diff.inHours >= 1) return 'in ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'in ${diff.inMinutes}m';
    return 'now';
  }
}

extension NullableDateTimeExt on DateTime? {
  bool get isOverdueOrNull => this == null ? false : this!.isOverdue;
}
