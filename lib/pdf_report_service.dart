import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'attendance_models.dart';

class PdfReportService {
  Future<File> saveMonthReport({
    required DateTime monthDate,
    required Map<AttendanceStatus, int> counts,
    required int totalMarked,
  }) async {
    final pw.Document document = pw.Document();
    final String monthLabel = monthName(monthDate.month);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$monthLabel ${monthDate.year} Attendance Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Month: $monthLabel ${monthDate.year}'),
              pw.Text('Total marked days: $totalMarked'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _cell('Attendance Type', isHeader: true),
                      _cell('Count', isHeader: true),
                    ],
                  ),
                  for (final AttendanceStatus status in AttendanceStatus.values)
                    pw.TableRow(
                      children: [
                        _cell(status.label),
                        _cell('${counts[status] ?? 0}'),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final Directory downloadsDirectory = await _resolveDownloadsDirectory();

    final String fileName =
        '${monthLabel.toLowerCase()}_${monthDate.year}.pdf';
    final File file = File('${downloadsDirectory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<Directory> _resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      const String androidDownloadsPath = '/storage/emulated/0/Download';
      final Directory androidDownloads = Directory(androidDownloadsPath);
      if (await androidDownloads.exists()) {
        return androidDownloads;
      }
    }

    final Directory? downloadsDirectory = await getDownloadsDirectory();
    if (downloadsDirectory != null) {
      return downloadsDirectory;
    }

    final Directory fallbackDirectory = await getApplicationDocumentsDirectory();
    return fallbackDirectory;
  }

  pw.Padding _cell(String text, {bool isHeader = false}) {
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
}
