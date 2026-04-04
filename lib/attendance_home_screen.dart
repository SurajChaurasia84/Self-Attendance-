import 'dart:convert';

import 'package:daily_attendance/select_months_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'attendance_models.dart';
import 'banner_ad_bar.dart';
import 'month_analytics_screen.dart';

class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  static const String _kStoredYearKey = 'attendance_selected_year';
  static const String _kStoredDateKey = 'attendance_selected_date';
  static const String _kStoredMarksKey = 'attendance_marks';

  late int _year;
  DateTime? _selectedDate;
  final Map<DateTime, AttendanceStatus> _attendanceMarks =
      <DateTime, AttendanceStatus>{};
  bool _isLoaded = false;
  int _adRefreshToken = 0;

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse(
      'https://www.termsfeed.com/live/a525088b-da0d-4df8-be00-fb6640222334',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'epson5732@gmail.com',
      query: 'subject=App Feedback',
    );

    await launchUrl(emailUri);
  }

  @override
  void initState() {
    super.initState();
    final DateTime today = DateTime.now();
    _year = today.year;
    _selectedDate = DateTime(today.year, today.month, today.day);
    _loadSavedAttendance();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Daily Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 📥 Import Reports
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Reports'),
            onTap: () {
              Navigator.pop(context); // 👈 drawer close (recommended)

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectMonthsScreen(
                    attendanceMarks: _attendanceMarks, // ✅ FIX HERE
                  ),
                ),
              );
            },
          ),

          // 🔒 Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              _openPrivacyPolicy();
            },
          ),

          // 📩 Send Feedback
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            onTap: () {
              Navigator.pop(context);
              _sendFeedback();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CalendarPalette palette = CalendarPalette();

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Daily Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: BannerAdBar(refreshToken: _adRefreshToken),
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
                      color: kSheetColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _changeYear(-1),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '$_year',
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _changeYear(1),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: kSheetColor,
                      child: Stack(
                        children: [
                          GridView.builder(
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
                                selectedDate: _selectedDate,
                                attendanceMarks: _attendanceMarks,
                                onMonthTap: (DateTime month) =>
                                    _openMonthAnalyticsScreen(month),
                                onDayTap: (DateTime day) async {
                                  setState(() {
                                    _selectedDate = day;
                                  });
                                  await _persistAttendance();
                                  _openMonthAnalyticsScreen(
                                    DateTime(day.year, day.month),
                                  );
                                },
                              );
                            },
                          ),
                          if (!_isLoaded)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x66F8F5BE),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: kSheetColor,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _StatusStrip(palette: palette),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMonthAnalyticsScreen(DateTime monthDate) async {
    final Map<AttendanceStatus, int> counts = <AttendanceStatus, int>{
      for (final AttendanceStatus status in AttendanceStatus.values) status: 0,
    };

    int totalMarked = 0;
    for (final MapEntry<DateTime, AttendanceStatus> entry
        in _attendanceMarks.entries) {
      final DateTime date = entry.key;
      if (date.year == monthDate.year && date.month == monthDate.month) {
        counts[entry.value] = (counts[entry.value] ?? 0) + 1;
        totalMarked++;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MonthAnalyticsScreen(
          monthDate: monthDate,
          counts: counts,
          totalMarked: totalMarked,
          attendanceMarks: _attendanceMarks,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _adRefreshToken++;
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      _selectedDate = null;
    });
    _persistAttendance();
  }

  Future<void> _loadSavedAttendance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime today = DateTime.now();
    final int savedYear = prefs.getInt(_kStoredYearKey) ?? today.year;
    final String? savedDate = prefs.getString(_kStoredDateKey);
    final String? savedMarks = prefs.getString(_kStoredMarksKey);
    final Map<DateTime, AttendanceStatus> parsedMarks =
        <DateTime, AttendanceStatus>{};

    if (savedMarks != null && savedMarks.isNotEmpty) {
      final Map<String, dynamic> rawMap =
          jsonDecode(savedMarks) as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> entry in rawMap.entries) {
        final DateTime? date = DateTime.tryParse(entry.key);
        AttendanceStatus? matchedStatus;
        for (final AttendanceStatus status in AttendanceStatus.values) {
          if (status.name == entry.value) {
            matchedStatus = status;
            break;
          }
        }
        if (date != null && matchedStatus != null) {
          parsedMarks[_normalizeDate(date)] = matchedStatus;
        }
      }
    }

    DateTime? restoredDate;
    if (savedDate != null && savedDate.isNotEmpty) {
      restoredDate = DateTime.tryParse(savedDate);
    } else {
      restoredDate = DateTime(today.year, today.month, today.day);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _year = savedYear;
      _selectedDate = restoredDate == null
          ? null
          : _normalizeDate(restoredDate);
      _attendanceMarks
        ..clear()
        ..addAll(parsedMarks);
      _isLoaded = true;
    });
  }

  Future<void> _persistAttendance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, String> encodedMarks = <String, String>{};

    for (final MapEntry<DateTime, AttendanceStatus> entry
        in _attendanceMarks.entries) {
      encodedMarks[entry.key.toIso8601String()] = entry.value.name;
    }

    await prefs.setInt(_kStoredYearKey, _year);
    await prefs.setString(
      _kStoredDateKey,
      _selectedDate == null
          ? ''
          : _normalizeDate(_selectedDate!).toIso8601String(),
    );
    await prefs.setString(_kStoredMarksKey, jsonEncode(encodedMarks));
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.monthDate,
    required this.selectedDate,
    required this.attendanceMarks,
    required this.onMonthTap,
    required this.onDayTap,
  });

  final DateTime monthDate;
  final DateTime? selectedDate;
  final Map<DateTime, AttendanceStatus> attendanceMarks;
  final ValueChanged<DateTime> onMonthTap;
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

    return InkWell(
      onTap: () => onMonthTap(monthDate),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            monthName(monthDate.month),
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

                final DateTime normalizedDay = DateTime(
                  day.year,
                  day.month,
                  day.day,
                );

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
      ),
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
            baseColor: isSunday ? kSundayColor : kSheetColor,
            borderColor: const Color(0xFF808080),
            markColor: mark?.color,
            highlightColor: isSelected ? kPrimaryColor : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: (mark?.color.computeLuminance() ?? 1) < 0.5
                    ? Colors.white
                    : const Color(0xFF4E4E4E),
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
      final Paint markPaint = Paint()..color = markColor!;
      canvas.drawRect(rect, markPaint);
    }

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 0.5
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
