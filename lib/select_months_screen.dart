import 'package:flutter/material.dart';
import 'pdf_report_service.dart';
import 'attendance_models.dart';
import 'pdf_preview_screen.dart';

class SelectMonthsScreen extends StatefulWidget {
  final Map<DateTime, AttendanceStatus> attendanceMarks;

  const SelectMonthsScreen({super.key, required this.attendanceMarks});

  @override
  State<SelectMonthsScreen> createState() => _SelectMonthsScreenState();
}

class _SelectMonthsScreenState extends State<SelectMonthsScreen> {
  final List<DateTime> selectedMonths = [];

  List<DateTime> getMonths() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      return DateTime(now.year, now.month - i);
    });
  }

  /// ✅ Month compare fix
  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final months = getMonths();

    return Scaffold(
      appBar: AppBar(title: const Text("Select Months")),

      body: ListView(
        children: months.map((month) {
          final label = "${monthName(month.month)} ${month.year}";

          final isSelected = selectedMonths.any((m) => isSameMonth(m, month));

          return CheckboxListTile(
            title: Text(label),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedMonths.add(month);
                } else {
                  selectedMonths.removeWhere((m) => isSameMonth(m, month));
                }
              });
            },
          );
        }).toList(),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor, // 👈 AppBar color
            foregroundColor: Colors.white, // 👈 Text white
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: selectedMonths.isEmpty
              ? null
              : () async {
                  final file = await PdfReportService().generateReportFromMarks(
                    months: selectedMonths,
                    attendanceMarks: widget.attendanceMarks,
                  );

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewScreen(file: file),
                    ),
                  );
                },
          child: const Text("Preview Report"),
        ),
      ),
    );
  }
}
