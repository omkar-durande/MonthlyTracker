/// Efficiency calculator — pure functions, unit-testable.
class EfficiencyCalculator {
  const EfficiencyCalculator._();

  /// Overall efficiency = completed / total * 100
  static double overallEfficiency(int total, int completed) {
    if (total == 0) return 0;
    return (completed / total * 100).clamp(0, 100);
  }

  /// On-time rate = tasks completed before deadline / total completed * 100
  static double onTimeRate(int completed, int onTime) {
    if (completed == 0) return 0;
    return (onTime / completed * 100).clamp(0, 100);
  }

  /// Grade based on efficiency %
  static String grade(double efficiency) {
    if (efficiency >= 90) return 'Excellent 🏆';
    if (efficiency >= 70) return 'Great Job 🌟';
    if (efficiency >= 50) return 'Good Effort 💪';
    return 'Keep Going 🔥';
  }

  /// Short auto-generated insight
  static String insight({
    required double efficiency,
    required double onTime,
    required int streakDays,
    required String bestCategory,
  }) {
    final buffer = StringBuffer();

    if (efficiency >= 90) {
      buffer.write('Outstanding month! You crushed your goals. ');
    } else if (efficiency >= 70) {
      buffer.write('Great progress! You\'re building solid habits. ');
    } else if (efficiency >= 50) {
      buffer.write('Decent effort — keep the momentum going. ');
    } else {
      buffer.write('Every step counts. Let\'s push harder next month. ');
    }

    if (onTime >= 80) {
      buffer.write('You\'re excellent at beating deadlines. ');
    } else if (onTime < 50) {
      buffer.write('Focus on tackling tasks well before their deadlines. ');
    }

    if (streakDays >= 7) {
      buffer.write('Your $streakDays-day habit streak is inspiring! ');
    }

    if (bestCategory.isNotEmpty) {
      buffer.write('You were most productive in "$bestCategory".');
    }

    return buffer.toString().trim();
  }

  /// Percentage change between two months
  static double monthOverMonthChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous * 100);
  }
}
