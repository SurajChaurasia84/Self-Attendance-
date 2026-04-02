import 'package:flutter/material.dart';

const Color _kPrimaryColor = Color(0xFF0A1F33);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: _kPrimaryColor)
        .copyWith(
          primary: _kPrimaryColor,
          surface: const Color(0xFFF4F7FB),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Attendance',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFEAF0F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: _kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AttendanceDashboard(),
    );
  }
}

class AttendanceDashboard extends StatelessWidget {
  const AttendanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int year = now.year;
    final List<AttendanceStatus> statuses = AttendanceStatus.values;
    final AttendanceDataSource dataSource = AttendanceDataSource(year);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            final Widget calendarCard = _CalendarCard(
              year: year,
              dataSource: dataSource,
            );
            final Widget legendCard = _LegendCard(statuses: statuses);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: calendarCard),
                        const SizedBox(width: 16),
                        Expanded(child: legendCard),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        calendarCard,
                        const SizedBox(height: 16),
                        legendCard,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.year,
    required this.dataSource,
  });

  final int year;
  final AttendanceDataSource dataSource;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: _kPrimaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$year Attendance Overview',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Current year shown at the top as requested.',
                          style: TextStyle(
                            color: Color(0xFFD8E2ED),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (BuildContext context, int index) {
                return _MonthCard(
                  monthDate: DateTime(year, index + 1),
                  dataSource: dataSource,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.monthDate,
    required this.dataSource,
  });

  final DateTime monthDate;
  final AttendanceDataSource dataSource;

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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E3EE)),
      ),
      child: Column(
        children: [
          Text(
            _monthName(monthDate.month),
            style: const TextStyle(
              color: _kPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _weekdays
                .map(
                  (String day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: Color(0xFF65758B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: dayCells.length,
              itemBuilder: (BuildContext context, int index) {
                final DateTime? day = dayCells[index];
                if (day == null) {
                  return const SizedBox.shrink();
                }

                final AttendanceStatus? status = dataSource.statusFor(day);
                final bool isToday = _isSameDay(day, DateTime.now());
                return _DayCell(
                  dayNumber: day.day,
                  status: status,
                  isToday: isToday,
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
    final List<DateTime?> cells = List<DateTime?>.filled(startOffset, null);

    for (int day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.status,
    required this.isToday,
  });

  final int dayNumber;
  final AttendanceStatus? status;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = status?.color.withValues(alpha: 0.22) ??
        const Color(0xFFFFFFFF);
    final Color borderColor = isToday
        ? _kPrimaryColor
        : status?.color.withValues(alpha: 0.65) ?? const Color(0xFFD7E0EA);
    final Color textColor = status?.color.computeLuminance() != null &&
            (status?.color.computeLuminance() ?? 1) < 0.45
        ? const Color(0xFF122033)
        : _kPrimaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: isToday ? 1.6 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '$dayNumber',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard({required this.statuses});

  final List<AttendanceStatus> statuses;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Status',
              style: TextStyle(
                color: _kPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Removed the old extra labels and kept only the client-requested set.',
              style: TextStyle(
                color: Color(0xFF5F6F82),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            for (int index = 0; index < statuses.length; index++) ...<Widget>[
              _LegendTile(
                number: index + 1,
                status: statuses[index],
              ),
              if (index != statuses.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({
    required this.number,
    required this.status,
  });

  final int number;
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E1EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.label,
              style: const TextStyle(
                color: _kPrimaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AttendanceStatus {
  present('Present', Color(0xFF2EAD4B)),
  absent('Absent', Color(0xFFE33D3D)),
  halfDay('Half Day', Color(0xFFF2A531)),
  overTime('Over Time', Color(0xFF7A5AF8)),
  shift('Shift', Color(0xFF1480D8)),
  holiday('Holiday', Color(0xFF8E44AD));

  const AttendanceStatus(this.label, this.color);

  final String label;
  final Color color;
}

class AttendanceDataSource {
  AttendanceDataSource(this.year);

  final int year;

  AttendanceStatus? statusFor(DateTime date) {
    if (date.year != year) {
      return null;
    }
    if (date.weekday == DateTime.sunday) {
      return AttendanceStatus.holiday;
    }
    if (date.day == 1 || date.day == 15) {
      return AttendanceStatus.shift;
    }
    if (date.day == 5 || date.day == 19) {
      return AttendanceStatus.absent;
    }
    if (date.day == 8 || date.day == 22) {
      return AttendanceStatus.halfDay;
    }
    if (date.day == 11 || date.day == 26) {
      return AttendanceStatus.overTime;
    }
    if (date.day % 2 == 0) {
      return AttendanceStatus.present;
    }
    return null;
  }
}
