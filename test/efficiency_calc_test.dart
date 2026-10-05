import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_goals/core/utils/efficiency_calculator.dart';

void main() {
  group('EfficiencyCalculator', () {
    group('overallEfficiency', () {
      test('0 tasks returns 0', () {
        expect(EfficiencyCalculator.overallEfficiency(0, 0), 0.0);
      });

      test('all completed returns 100', () {
        expect(EfficiencyCalculator.overallEfficiency(10, 10), 100.0);
      });

      test('half completed returns 50', () {
        expect(EfficiencyCalculator.overallEfficiency(10, 5), 50.0);
      });

      test('clamped to 100 max', () {
        expect(EfficiencyCalculator.overallEfficiency(5, 10), 100.0);
      });
    });

    group('onTimeRate', () {
      test('0 completed returns 0', () {
        expect(EfficiencyCalculator.onTimeRate(0, 0), 0.0);
      });

      test('all on time returns 100', () {
        expect(EfficiencyCalculator.onTimeRate(8, 8), 100.0);
      });

      test('half on time returns 50', () {
        expect(EfficiencyCalculator.onTimeRate(10, 5), 50.0);
      });
    });

    group('grade', () {
      test('90+ is Excellent', () {
        expect(EfficiencyCalculator.grade(95), contains('Excellent'));
      });

      test('70–89 is Great', () {
        expect(EfficiencyCalculator.grade(80), contains('Great'));
      });

      test('50–69 is Good Effort', () {
        expect(EfficiencyCalculator.grade(60), contains('Good'));
      });

      test('<50 is Keep Going', () {
        expect(EfficiencyCalculator.grade(40), contains('Keep Going'));
      });
    });

    group('monthOverMonthChange', () {
      test('0 previous returns 100 if current > 0', () {
        expect(EfficiencyCalculator.monthOverMonthChange(50, 0), 100.0);
      });

      test('increase calculated correctly', () {
        expect(
            EfficiencyCalculator.monthOverMonthChange(75, 50), closeTo(50.0, 0.01));
      });

      test('decrease calculated correctly', () {
        expect(
            EfficiencyCalculator.monthOverMonthChange(40, 80), closeTo(-50.0, 0.01));
      });
    });
  });
}
