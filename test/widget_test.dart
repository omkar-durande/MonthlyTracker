import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_goals/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MonthlyGoalsApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MonthlyGoalsApp), findsOneWidget);
    // Drain pending timers from page transitions
    await tester.pumpAndSettle();
  });
}
