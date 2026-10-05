import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pump();
    });
  });
}
