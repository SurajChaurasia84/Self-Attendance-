import 'dart:io';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'attendance_models.dart';

class PdfReportService {
  Future<File> generateReportFromMarks({
    required List<DateTime> months,
    required Map<DateTime, AttendanceStatus> attendanceMarks,
    required Map<DateTime, ShiftType> shiftSubtypes,
    required Map<DateTime, double> overtimeHours,
  }) async {
    final pw.Document document = pw.Document();

    months.sort((DateTime a, DateTime b) => b.compareTo(a));

    for (final DateTime month in months) {
      final Map<String, dynamic> summary = _calculateSummary(
        month,
        attendanceMarks,
        overtimeHours,
      );
      document.addPage(
        _buildPage(
          month,
          summary,
          attendanceMarks,
          shiftSubtypes,
          overtimeHours,
        ),
      );
    }

    final List<int> bytes = await document.save();
    return _saveTemp(bytes);
  }

  Map<String, dynamic> _calculateSummary(
    DateTime month,
    Map<DateTime, AttendanceStatus> marks,
    Map<DateTime, double> overtimeHours,
  ) {
    final Map<AttendanceStatus, int> counts = <AttendanceStatus, int>{
      for (final AttendanceStatus status in AttendanceStatus.values) status: 0,
    };
    double totalOvertimeHours = 0;

    for (final MapEntry<DateTime, AttendanceStatus> entry in marks.entries) {
      if (entry.key.year == month.year && entry.key.month == month.month) {
        counts[entry.value] = (counts[entry.value] ?? 0) + 1;
      }
    }

    for (final MapEntry<DateTime, double> entry in overtimeHours.entries) {
      if (entry.key.year == month.year && entry.key.month == month.month) {
        totalOvertimeHours += entry.value;
      }
    }

    return <String, dynamic>{
      'counts': counts,
      'total': counts.values.fold(0, (int sum, int count) => sum + count),
      'totalOvertimeHours': totalOvertimeHours,
    };
  }

  pw.Page _buildPage(
    DateTime month,
    Map<String, dynamic> summary,
    Map<DateTime, AttendanceStatus> attendanceMarks,
    Map<DateTime, ShiftType> shiftSubtypes,
    Map<DateTime, double> overtimeHours,
  ) {
    final Map<AttendanceStatus, int> counts =
        summary['counts'] as Map<AttendanceStatus, int>;
    final int total = summary['total'] as int;
    final double totalOvertimeHours =
        summary['totalOvertimeHours'] as double? ?? 0;
    final String monthLabel = monthName(month.month);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$monthLabel ${month.year} Attendance Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total marked days: $total'),
            pw.SizedBox(height: 20),
            _buildCalendar(month, attendanceMarks, shiftSubtypes, overtimeHours),
            pw.SizedBox(height: 20),
            _buildSummarySection(
              counts,
              totalOvertimeHours,
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Shift / Overtime Details',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildDetailsTable(month, attendanceMarks, shiftSubtypes, overtimeHours),
          ],
        );
      },
    );
  }

  pw.Widget _buildSummarySection(
    Map<AttendanceStatus, int> counts,
    double totalOvertimeHours,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: _summaryCell(
                AttendanceStatus.present.label,
                _formatDayCount(counts[AttendanceStatus.present] ?? 0),
                AttendanceStatus.present,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _summaryCell(
                AttendanceStatus.absent.label,
                _formatDayCount(counts[AttendanceStatus.absent] ?? 0),
                AttendanceStatus.absent,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _summaryCell(
                AttendanceStatus.halfDay.label,
                _formatDayCount(counts[AttendanceStatus.halfDay] ?? 0),
                AttendanceStatus.halfDay,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: _summaryCell(
                AttendanceStatus.overtime.label,
                _formatHourCount(totalOvertimeHours),
                AttendanceStatus.overtime,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _summaryCell(
                AttendanceStatus.shift.label,
                _formatDayCount(counts[AttendanceStatus.shift] ?? 0),
                AttendanceStatus.shift,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _summaryCell(
                AttendanceStatus.holiday.label,
                _formatDayCount(counts[AttendanceStatus.holiday] ?? 0),
                AttendanceStatus.holiday,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryCell(
    String label,
    String value,
    AttendanceStatus status,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _statusWithColor(status),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayCount(int count) {
    return '$count ${count == 1 ? 'day' : 'days'}';
  }

  String _formatHourCount(double hours) {
    final String value = hours % 1 == 0
        ? hours.toStringAsFixed(0)
        : hours.toStringAsFixed(1);
    return '$value hrs';
  }

  pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildCalendar(
    DateTime month,
    Map<DateTime, AttendanceStatus> marks,
    Map<DateTime, ShiftType> shiftSubtypes,
    Map<DateTime, double> overtimeHours,
  ) {
    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int startOffset = firstDay.weekday % 7;
    final List<pw.Widget> cells = <pw.Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(pw.Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(month.year, month.month, day);
      final AttendanceStatus? status = marks[date];
      final ShiftType? shiftType = shiftSubtypes[date];
      final double? overtimeHour = overtimeHours[date];

      PdfColor bgColor = PdfColors.white;
      String? subtitle;

      if (status != null) {
        bgColor = PdfColor.fromInt(status.color.toARGB32());
        if (status == AttendanceStatus.shift && shiftType != null) {
          subtitle = _shiftShortLabel(shiftType);
        } else if (status == AttendanceStatus.overtime && overtimeHour != null) {
          subtitle = 'OT ${overtimeHour.toStringAsFixed(1)}';
        }
      }

      cells.add(
        pw.Container(
          decoration: pw.BoxDecoration(
            color: bgColor,
            border: pw.Border.all(width: 0.3),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                '$day',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: bgColor == PdfColors.white
                      ? PdfColors.black
                      : PdfColors.white,
                ),
              ),
              if (subtitle != null)
                pw.SizedBox(height: 4),
              if (subtitle != null)
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: bgColor == PdfColors.white
                        ? PdfColors.black
                        : PdfColors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (String e) => pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(e, style: const pw.TextStyle(fontSize: 12)),
                  ),
                ),
              )
              .toList(),
        ),
        pw.SizedBox(height: 4),
        pw.GridView(
          crossAxisCount: 7,
          childAspectRatio: 1,
          children: cells,
        ),
      ],
    );
  }

  pw.Widget _buildDetailsTable(
    DateTime month,
    Map<DateTime, AttendanceStatus> marks,
    Map<DateTime, ShiftType> shiftSubtypes,
    Map<DateTime, double> overtimeHours,
  ) {
    final List<DateTime> detailDates = marks.keys
        .where(
          (DateTime date) =>
              date.year == month.year &&
              date.month == month.month &&
              (marks[date] == AttendanceStatus.shift ||
                  marks[date] == AttendanceStatus.overtime),
        )
        .toList()
      ..sort();

    if (detailDates.isEmpty) {
      return pw.Text('No shift or overtime details for this month.');
    }

    final List<pw.TableRow> rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _cell('Date', isHeader: true),
          _cell('Type', isHeader: true),
          _cell('Details', isHeader: true),
        ],
      ),
    ];

    for (final DateTime date in detailDates) {
      final AttendanceStatus status = marks[date]!;
      String details = '-';
      if (status == AttendanceStatus.shift && shiftSubtypes[date] != null) {
        details = _shiftLongLabel(shiftSubtypes[date]!);
      } else if (status == AttendanceStatus.overtime && overtimeHours[date] != null) {
        details = '${overtimeHours[date]!.toStringAsFixed(1)} hrs';
      }

      rows.add(
        pw.TableRow(
          children: [
            _cell('${date.day}/${date.month}/${date.year}'),
            _cell(status.label),
            _cell(details),
          ],
        ),
      );
    }

    return pw.Table(border: pw.TableBorder.all(), children: rows);
  }

  pw.Widget _statusWithColor(AttendanceStatus status) {
    final PdfColor color = PdfColor.fromInt(status.color.toARGB32());

    return pw.Row(
      children: [
        pw.Container(
          width: 10,
          height: 10,
          margin: const pw.EdgeInsets.only(right: 6),
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(width: 0.3),
          ),
        ),
        pw.Text(status.label, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<File> _saveTemp(List<int> bytes) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> saveToDownloads(File file) async {
    await MediaStore().saveFile(
      tempFilePath: file.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );
  }

  String _shiftShortLabel(ShiftType type) {
    switch (type) {
      case ShiftType.morning:
        return 'M';
      case ShiftType.afternoon:
        return 'A';
      case ShiftType.night:
        return 'N';
      case ShiftType.general:
        return 'G';
    }
  }

  String _shiftLongLabel(ShiftType type) {
    switch (type) {
      case ShiftType.morning:
        return 'Morning';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.general:
        return 'General';
    }
  }
}
