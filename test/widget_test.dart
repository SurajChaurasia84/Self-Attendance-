import 'package:daily_attendance/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows attendance dashboard with current year and statuses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final String currentYear = DateTime.now().year.toString();

    expect(find.textContaining(currentYear), findsOneWidget);
    expect(find.text('Attendance Status'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.text('Half Day'), findsOneWidget);
    expect(find.text('Over Time'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
  });
}
