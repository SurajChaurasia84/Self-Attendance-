import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'attendance_models.dart';

class PdfReportService {
  /// 🔥 MAIN FUNCTION (REAL DATA ONLY)
  Future<File> generateReportFromMarks({
    required List<DateTime> months,
    required Map<DateTime, AttendanceStatus> attendanceMarks,
  }) async {
    final document = pw.Document();

    // Latest month first
    months.sort((a, b) => b.compareTo(a));

    for (final month in months) {
      final summary = _calculateSummary(month, attendanceMarks);
      document.addPage(_buildPage(month, summary, attendanceMarks));
    }

    final bytes = await document.save();
    return await _saveTemp(bytes);
  }

  /// 🔹 Summary Calculation (Same as UI)
  Map<String, dynamic> _calculateSummary(
    DateTime month,
    Map<DateTime, AttendanceStatus> marks,
  ) {
    final counts = {for (var status in AttendanceStatus.values) status: 0};

    for (final entry in marks.entries) {
      if (entry.key.year == month.year && entry.key.month == month.month) {
        counts[entry.value] = (counts[entry.value] ?? 0) + 1;
      }
    }

    final present = counts[AttendanceStatus.present] ?? 0;
    final absent = counts[AttendanceStatus.absent] ?? 0;
    final halfDay = counts[AttendanceStatus.halfDay] ?? 0;
    final overtime = counts[AttendanceStatus.overtime] ?? 0;
    final shift = counts[AttendanceStatus.shift] ?? 0;
    final holiday = counts[AttendanceStatus.holiday] ?? 0;

    final total = present + absent + halfDay + overtime + shift + holiday;

    return {"counts": counts, "total": total};
  }

  /// 🔹 PDF Page
  pw.Page _buildPage(
    DateTime month,
    Map<String, dynamic> summary,
    Map<DateTime, AttendanceStatus> attendanceMarks,
  ) {
    final counts = summary['counts'] as Map<AttendanceStatus, int>;
    final total = summary['total'];

    final monthLabel = monthName(month.month);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$monthLabel ${month.year} Attendance Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 10),
            pw.Text('Total marked days: $total'),

            pw.SizedBox(height: 20),
            _buildCalendar(month, attendanceMarks),

            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    _cell('Type', isHeader: true),
                    _cell('Count', isHeader: true),
                  ],
                ),

                for (final status in AttendanceStatus.values)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: _statusWithColor(status), 
                      ),
                      _cell('${counts[status] ?? 0}'),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Cell
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
  ) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;

    final List<pw.Widget> cells = [];

    // Empty cells
    for (int i = 0; i < startOffset; i++) {
      cells.add(pw.Container());
    }

    // Days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final status = marks[date];

      PdfColor bgColor = PdfColors.white;

      if (status != null) {
        bgColor = PdfColor.fromInt(status.color.toARGB32());
      }

      cells.add(
        pw.Container(
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: bgColor,
            border: pw.Border.all(width: 0.3),
          ),
          child: pw.Text(
            '$day',
            style: pw.TextStyle(
              fontSize: 17,
              color: bgColor == PdfColors.white
                  ? PdfColors.black
                  : PdfColors.white,
            ),
          ),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (e) => pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(e, style: pw.TextStyle(fontSize: 17)),
                  ),
                ),
              )
              .toList(),
        ),
        pw.GridView(crossAxisCount: 7, childAspectRatio: 1, children: cells),
      ],
    );
  }

  pw.Widget _statusWithColor(AttendanceStatus status) {
    final color = PdfColor.fromInt(status.color.toARGB32());

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

  /// 🔹 Temp Save
  Future<File> _saveTemp(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 🔥 Save to Downloads
  Future<void> saveToDownloads(File file) async {
    await MediaStore().saveFile(
      tempFilePath: file.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );
  }
}
