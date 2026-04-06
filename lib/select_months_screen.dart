import 'package:flutter/material.dart';

import 'attendance_models.dart';
import 'pdf_preview_screen.dart';
import 'pdf_report_service.dart';

class SelectMonthsScreen extends StatefulWidget {
  final Map<DateTime, AttendanceStatus> attendanceMarks;
  final Map<DateTime, ShiftType> shiftSubtypes;
  final Map<DateTime, double> overtimeHours;

  const SelectMonthsScreen({
    super.key,
    required this.attendanceMarks,
    this.shiftSubtypes = const <DateTime, ShiftType>{},
    this.overtimeHours = const <DateTime, double>{},
  });

  @override
  State<SelectMonthsScreen> createState() => _SelectMonthsScreenState();
}

class _SelectMonthsScreenState extends State<SelectMonthsScreen> {
  final List<DateTime> selectedMonths = <DateTime>[];

  List<DateTime> getMonths() {
    final DateTime now = DateTime.now();
    return List<DateTime>.generate(12, (int i) {
      return DateTime(now.year, now.month - i);
    });
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> months = getMonths();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Months')),
      body: ListView(
        children: months.map((DateTime month) {
          final String label = '${monthName(month.month)} ${month.year}';
          final bool isSelected =
              selectedMonths.any((DateTime m) => isSameMonth(m, month));

          return CheckboxListTile(
            title: Text(label),
            value: isSelected,
            onChanged: (bool? val) {
              setState(() {
                if (val == true) {
                  selectedMonths.add(month);
                } else {
                  selectedMonths.removeWhere(
                    (DateTime m) => isSameMonth(m, month),
                  );
                }
              });
            },
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: selectedMonths.isEmpty
                ? null
                : () async {
                    final NavigatorState navigator = Navigator.of(context);
                    final dynamic file =
                        await PdfReportService().generateReportFromMarks(
                      months: selectedMonths,
                      attendanceMarks: widget.attendanceMarks,
                      shiftSubtypes: widget.shiftSubtypes,
                      overtimeHours: widget.overtimeHours,
                    );

                    if (!mounted) {
                      return;
                    }

                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => PdfPreviewScreen(file: file),
                      ),
                    );
                  },
            child: const Text('Preview Report'),
          ),
        ),
      ),
    );
  }
}
