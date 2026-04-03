import 'package:flutter/material.dart';

import 'attendance_models.dart';
import 'banner_ad_bar.dart';
import 'pdf_report_service.dart';

class MonthAnalyticsScreen extends StatefulWidget {
  const MonthAnalyticsScreen({
    super.key,
    required this.monthDate,
    required this.counts,
    required this.totalMarked,
    required this.attendanceMarks,
  });

  final DateTime monthDate;
  final Map<AttendanceStatus, int> counts;
  final int totalMarked;
  final Map<DateTime, AttendanceStatus> attendanceMarks;

  @override
  State<MonthAnalyticsScreen> createState() => _MonthAnalyticsScreenState();
}

class _MonthAnalyticsScreenState extends State<MonthAnalyticsScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${monthName(widget.monthDate.month)} ${widget.monthDate.year}'),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isSaving,
            onSelected: (String value) {
              if (value == 'download_pdf') {
                _downloadPdfReport();
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem<String>(
                value: 'download_pdf',
                child: Text('Download Report PDF'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BannerAdBar(
        refreshToken: widget.monthDate.microsecondsSinceEpoch,
      ),
      body: Container(
        color: kSheetColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSheetColor,
                  border: Border.all(color: const Color(0xFFDDD6A7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Month: ${monthName(widget.monthDate.month)} ${widget.monthDate.year}',
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total marked days: ${widget.totalMarked}',
                      style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 420,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSheetColor,
                  border: Border.all(color: const Color(0xFFDDD6A7)),
                ),
                child: _AnalyticsMonthCalendar(
                  monthDate: widget.monthDate,
                  attendanceMarks: widget.attendanceMarks,
                ),
              ),
              const SizedBox(height: 12),
              for (final AttendanceStatus status in AttendanceStatus.values) ...[
                _AnalyticsRow(
                  label: status.label,
                  color: status.color,
                  count: widget.counts[status] ?? 0,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdfReport() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final file = await PdfReportService().saveMonthReport(
        monthDate: widget.monthDate,
        counts: widget.counts,
        totalMarked: widget.totalMarked,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to ${file.path}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _AnalyticsMonthCalendar extends StatelessWidget {
  const _AnalyticsMonthCalendar({
    required this.monthDate,
    required this.attendanceMarks,
  });

  final DateTime monthDate;
  final Map<DateTime, AttendanceStatus> attendanceMarks;

  static const List<String> _weekdays = <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    final List<DateTime?> dayCells = _buildDayCells(monthDate);

    return Column(
      children: [
        Text(
          monthName(monthDate.month),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFC74D46),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _weekdays
              .map(
                (String day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5A4637),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayCells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 1.2,
              crossAxisSpacing: 1.2,
              childAspectRatio: 1,
            ),
            itemBuilder: (BuildContext context, int index) {
              final DateTime? day = dayCells[index];
              if (day == null) {
                return const SizedBox.shrink();
              }

              final DateTime normalizedDay = DateTime(day.year, day.month, day.day);
              return _AnalyticsDayCell(
                day: day,
                isSunday: day.weekday == DateTime.sunday,
                mark: attendanceMarks[normalizedDay],
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime?> _buildDayCells(DateTime month) {
    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int startOffset = firstDay.weekday % 7;
    final List<DateTime?> cells = List<DateTime?>.filled(
      startOffset,
      null,
      growable: true,
    );

    for (int day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }

    while (cells.length < 42) {
      cells.add(null);
    }

    return cells;
  }
}

class _AnalyticsDayCell extends StatelessWidget {
  const _AnalyticsDayCell({
    required this.day,
    required this.isSunday,
    required this.mark,
  });

  final DateTime day;
  final bool isSunday;
  final AttendanceStatus? mark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnalyticsDayPainter(
        baseColor: isSunday ? kSundayColor : kSheetColor,
        borderColor: const Color(0xFF808080),
        markColor: mark?.color,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF4E4E4E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsDayPainter extends CustomPainter {
  _AnalyticsDayPainter({
    required this.baseColor,
    required this.borderColor,
    required this.markColor,
  });

  final Color baseColor;
  final Color borderColor;
  final Color? markColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = baseColor);

    if (markColor != null) {
      final Path filledHalf = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, 0)
        ..close();
      canvas.drawPath(filledHalf, Paint()..color = markColor!);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        Paint()
          ..color = borderColor
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawRect(
      rect.deflate(0.25),
      Paint()
        ..color = borderColor
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalyticsDayPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.markColor != markColor;
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kSheetColor,
        border: Border.all(color: const Color(0xFFDDD6A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: kPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
