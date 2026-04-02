import 'package:flutter/material.dart';

const Color _kPrimaryColor = Color(0xFF0A1F33);
const Color _kSheetColor = Color(0xFFF8F5BE);
const Color _kSundayColor = Color(0xFFD3D3D3);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Attendance',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: _kPrimaryColor).copyWith(
          primary: _kPrimaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AttendanceDashboard(),
    );
  }
}

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  late int _year;
  DateTime? _selectedDate;
  final Map<DateTime, AttendanceStatus> _attendanceMarks =
      <DateTime, AttendanceStatus>{};

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final CalendarPalette palette = CalendarPalette();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Daily Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Container(
                      color: _kSheetColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              _year--;
                              _selectedDate = null;
                            }),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '$_year',
                            style: const TextStyle(
                              color: _kPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _year++;
                              _selectedDate = null;
                            }),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: _kSheetColor,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(6, 4, 2, 0),
                        itemCount: 12,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.82,
                            ),
                        itemBuilder: (BuildContext context, int index) {
                          return _MiniMonth(
                            monthDate: DateTime(_year, index + 1),
                            palette: palette,
                            selectedDate: _selectedDate,
                            attendanceMarks: _attendanceMarks,
                            onDayTap: (DateTime day) {
                              setState(() {
                                _selectedDate = day;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: _kSheetColor,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Column(
                      children: [
                        if (_selectedDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Selected: ${_formatDate(_selectedDate!)}',
                              style: const TextStyle(
                                color: _kPrimaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _selectedDate == null
                                ? null
                                : () => _openMarkAttendance(),
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimaryColor,
                              disabledBackgroundColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Mark Attendance'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _StatusStrip(palette: palette),
          ],
        ),
      ),
    );
  }

  Future<void> _openMarkAttendance() async {
    final DateTime selectedDate = _selectedDate!;
    AttendanceStatus? selectedStatus = _attendanceMarks[_normalizeDate(selectedDate)];

    final AttendanceStatus? submittedStatus = await showDialog<AttendanceStatus>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Mark ${_formatDate(selectedDate)}'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AttendanceStatus.values
                      .map(
                        (AttendanceStatus status) => InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedStatus = status;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  selectedStatus == status
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: status.color,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(status.label)),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedStatus == null
                      ? null
                      : () => Navigator.of(context).pop(selectedStatus),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || submittedStatus == null) {
      return;
    }

    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Attendance'),
              content: Text(
                'Mark ${submittedStatus.label} for ${_formatDate(selectedDate)}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      _attendanceMarks[_normalizeDate(selectedDate)] = submittedStatus;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${submittedStatus.label} marked for ${_formatDate(selectedDate)}',
        ),
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.monthDate,
    required this.palette,
    required this.selectedDate,
    required this.attendanceMarks,
    required this.onDayTap,
  });

  final DateTime monthDate;
  final CalendarPalette palette;
  final DateTime? selectedDate;
  final Map<DateTime, AttendanceStatus> attendanceMarks;
  final ValueChanged<DateTime> onDayTap;

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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _monthName(monthDate.month),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFC74D46),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: _weekdays
              .map(
                (String day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF5A4637),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayCells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 0.7,
              crossAxisSpacing: 0.7,
              childAspectRatio: 1,
            ),
            itemBuilder: (BuildContext context, int index) {
              final DateTime? day = dayCells[index];
              if (day == null) {
                return const SizedBox.shrink();
              }

              final DateTime normalizedDay = DateTime(day.year, day.month, day.day);

              return _MiniDayCell(
                day: day,
                isSunday: day.weekday == DateTime.sunday,
                isSelected: _isSameDay(selectedDate, day),
                mark: attendanceMarks[normalizedDay],
                onTap: () => onDayTap(normalizedDay),
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

  bool _isSameDay(DateTime? first, DateTime second) {
    return first != null &&
        first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class _MiniDayCell extends StatelessWidget {
  const _MiniDayCell({
    required this.day,
    required this.isSunday,
    required this.isSelected,
    required this.mark,
    required this.onTap,
  });

  final DateTime day;
  final bool isSunday;
  final bool isSelected;
  final AttendanceStatus? mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          painter: _AttendanceDayPainter(
            baseColor: isSunday ? _kSundayColor : _kSheetColor,
            borderColor: const Color(0xFF808080),
            markColor: mark?.color,
            highlightColor: isSelected ? _kPrimaryColor : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF4E4E4E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceDayPainter extends CustomPainter {
  _AttendanceDayPainter({
    required this.baseColor,
    required this.borderColor,
    required this.markColor,
    required this.highlightColor,
  });

  final Color baseColor;
  final Color borderColor;
  final Color? markColor;
  final Color? highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint basePaint = Paint()..color = baseColor;
    canvas.drawRect(rect, basePaint);

    if (markColor != null) {
      final Path filledHalf = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, 0)
        ..close();
      final Paint markPaint = Paint()..color = markColor!;
      canvas.drawPath(filledHalf, markPaint);

      final Paint diagonalPaint = Paint()
        ..color = borderColor
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        diagonalPaint,
      );
    }

    final Paint borderPaint = Paint()
      ..color = highlightColor ?? borderColor
      ..strokeWidth = highlightColor == null ? 0.5 : 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect.deflate(borderPaint.strokeWidth / 2), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _AttendanceDayPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.markColor != markColor ||
        oldDelegate.highlightColor != highlightColor;
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.palette});

  final CalendarPalette palette;

  @override
  Widget build(BuildContext context) {
    final List<_StripItemData> items = <_StripItemData>[
      _StripItemData('Present', palette.presentColor),
      _StripItemData('Absent', palette.absentColor),
      _StripItemData('Half Day', palette.halfDayColor),
      _StripItemData('Overtime', palette.overtimeColor),
      _StripItemData('Shift', palette.shiftColor),
      _StripItemData('Holiday', palette.holidayColor),
    ];

    return SizedBox(
      width: 28,
      child: Column(
        children: items
            .map(
              (_StripItemData item) => Expanded(
                child: Container(
                  width: double.infinity,
                  color: item.color,
                  alignment: Alignment.center,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: item.color.computeLuminance() > 0.6
                            ? Colors.black87
                            : Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StripItemData {
  const _StripItemData(this.label, this.color);

  final String label;
  final Color color;
}

class CalendarPalette {
  final Color presentColor = const Color(0xFF222222);
  final Color absentColor = const Color(0xFF2D5BFF);
  final Color halfDayColor = const Color(0xFFFF9800);
  final Color overtimeColor = const Color(0xFFD6D63B);
  final Color shiftColor = const Color(0xFF09D624);
  final Color holidayColor = const Color(0xFFC41717);
}

enum AttendanceStatus {
  present('Present', Color(0xFF222222)),
  absent('Absent', Color(0xFF2D5BFF)),
  halfDay('Half Day', Color(0xFFFF9800)),
  overtime('Overtime', Color(0xFFD6D63B)),
  shift('Shift', Color(0xFF09D624)),
  holiday('Holiday', Color(0xFFC41717));

  const AttendanceStatus(this.label, this.color);

  final String label;
  final Color color;
}
