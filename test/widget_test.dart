import 'package:daily_attendance/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('marks attendance after selecting a day and status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final String currentYear = DateTime.now().year.toString();

    expect(find.text(currentYear), findsOneWidget);
    expect(find.text('Mark Attendance'), findsOneWidget);

    await tester.tap(find.text('1').first);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Selected:'), findsOneWidget);

    await tester.tap(find.text('Mark Attendance'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);

    await tester.tap(find.text('Present'));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Confirm Attendance'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('marked for'), findsOneWidget);
  });
}
