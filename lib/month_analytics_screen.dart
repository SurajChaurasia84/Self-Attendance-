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
  late DateTime _visibleMonth;
  bool _isSaving = false;
  bool _isExpanded = false;

  final Map<DateTime, ShiftType?> _shiftSubtypes = {};

  static const List<String> _weekdays = <String>[
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.monthDate.year, widget.monthDate.month);
  }

  Future<void> _openMarkAttendance(DateTime selectedDate) async {
    AttendanceStatus? selectedStatus =
        widget.attendanceMarks[DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        )];

    // Extra variable to track shift subtype if needed (optional)
    // If shift attendance needs subtype, you can add an enum or string for it.

    final AttendanceStatus?
    submittedStatus = await showDialog<AttendanceStatus>(
      context: context,
      builder: (context) {
        AttendanceStatus? tempSelectedStatus = selectedStatus;
        bool shiftExpanded = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildStatusOption(AttendanceStatus status, Widget icon) {
              return InkWell(
                onTap: () {
                  setDialogState(() {
                    tempSelectedStatus = status;
                    shiftExpanded =
                        false; // collapse shift submenu on selection
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Text(status.label),
                    ],
                  ),
                ),
              );
            }

            Widget buildShiftSubmenu() {
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        tempSelectedStatus = AttendanceStatus.shift;
                        // You can store shift subtype info here if needed
                        shiftExpanded = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 24), // indent to align with icons
                          Text('General'),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        // Shift subtype: Morning
                        tempSelectedStatus =
                            AttendanceStatus.shift; // same enum
                        shiftExpanded = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [SizedBox(width: 24), Text('Morning')],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        // Shift subtype: Afternoon
                        tempSelectedStatus = AttendanceStatus.shift;
                        shiftExpanded = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [SizedBox(width: 24), Text('Afternoon')],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        // Shift subtype: Night
                        tempSelectedStatus = AttendanceStatus.shift;
                        shiftExpanded = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [SizedBox(width: 24), Text('Night')],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        // Clear shift (means clear attendance)
                        tempSelectedStatus = null;
                        shiftExpanded = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [SizedBox(width: 24), Text('Clear Shift')],
                      ),
                    ),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Text(
                'Mark ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildStatusOption(
                      AttendanceStatus.present,
                      Icon(Icons.check, color: AttendanceStatus.present.color),
                    ),
                    buildStatusOption(
                      AttendanceStatus.absent,
                      Icon(Icons.close, color: AttendanceStatus.absent.color),
                    ),
                    buildStatusOption(
                      AttendanceStatus.halfDay,
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AttendanceStatus.halfDay.color,
                      ),
                    ),
                    buildStatusOption(
                      AttendanceStatus.overtime,
                      Icon(
                        Icons.timer_3_outlined,
                        color: AttendanceStatus.overtime.color,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          shiftExpanded = !shiftExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              shiftExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 10),
                            const Text('Shift'),
                          ],
                        ),
                      ),
                    ),
                    if (shiftExpanded) buildShiftSubmenu(),
                    buildStatusOption(
                      AttendanceStatus.holiday,
                      const Icon(
                        Icons.more_horiz,
                        color: Colors.grey,
                      ), // changed to "Holiday" icon if you want something else change here
                    ),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          tempSelectedStatus = null; // Clear attendance
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            const Text('Clear'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, tempSelectedStatus),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submittedStatus == null) {
      // Clear attendance if clear selected or no option selected
      setState(() {
        widget.attendanceMarks.remove(
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
        );
      });
      return;
    }

    setState(() {
      widget.attendanceMarks[DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          )] =
          submittedStatus;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${submittedStatus.label} marked for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _MonthSummary summary = _buildSummary(_visibleMonth);
    final List<DateTime?> dayCells = _buildDayCells(_visibleMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(monthName(_visibleMonth.month))),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isSaving,
            onSelected: (String value) {
              if (value == 'download_pdf') {
                _downloadPdfReport(summary);
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
        refreshToken: _visibleMonth.microsecondsSinceEpoch,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MonthActionButton(
                      label: 'PREV',
                      icon: Icons.chevron_left,
                      onTap: () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month - 1,
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        '${monthName(_visibleMonth.month).toUpperCase()} ${_visibleMonth.year}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _MonthActionButton(
                      label: 'NEXT',
                      icon: Icons.chevron_right,
                      isTrailingIcon: true,
                      onTap: () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month + 1,
                        );
                      }),
                    ),
                  ),
                ],
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
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.05,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayCells.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final DateTime? day = dayCells[index];
                    if (day == null) {
                      return const _AnalyticsEmptyCell();
                    }

                    final AttendanceStatus? mark =
                        widget.attendanceMarks[DateTime(
                          day.year,
                          day.month,
                          day.day,
                        )];
                    return _AnalyticsDayCell(
                      day: day,
                      mark: mark,
                      shiftType: _shiftSubtypes[day],
                      onTap: (selectedDay) {
                        _openMarkAttendance(selectedDay);
                      },
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD2D2D2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Attendance for this month',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF505050),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _AnalyticsLegendItem(
                            color: AttendanceStatus.present.color,
                            label: 'Present : ${summary.presentCount}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnalyticsLegendItem(
                            color: AttendanceStatus.absent.color,
                            label: 'Absent : ${summary.absentCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AnalyticsLegendItem(
                            color: AttendanceStatus.halfDay.color,
                            label: 'Half Days : ${summary.halfDayCount}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnalyticsLegendItem(
                            color: AttendanceStatus.overtime.color,
                            label: 'OT : ${summary.overtimeCount} days',
                            textColor: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isExpanded) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _AnalyticsLegendItem(
                              color: AttendanceStatus.shift.color,
                              label:
                                  'Shift : ${summary.counts[AttendanceStatus.shift] ?? 0}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AnalyticsLegendItem(
                              color: AttendanceStatus.holiday.color,
                              label:
                                  'Holiday : ${summary.counts[AttendanceStatus.holiday] ?? 0}',
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Percentage : ${summary.attendancePercentage}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 20,
                        //     vertical: 10,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(8),
                        //     gradient: const LinearGradient(
                        //       colors: [Color(0xFF5B5B5B), Color(0xFF252525)],
                        //     ),
                        //   ),
                        //   child: const Row(
                        //     mainAxisSize: MainAxisSize.min,
                        //     children: [
                        //       Icon(
                        //         Icons.info_outline,
                        //         color: Color(0xFF44D36F),
                        //         size: 16,
                        //       ),
                        //       SizedBox(width: 6),
                        //       Text(
                        //         'More Info',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontWeight: FontWeight.w700,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdfReport(_MonthSummary summary) async {
  setState(() {
    _isSaving = true;
  });

  try {
    final file = await PdfReportService().generateReportFromMarks(
      months: [_visibleMonth],
      attendanceMarks: widget.attendanceMarks,
    );

    await PdfReportService().saveToDownloads(file);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF saved to Downloads')),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

  _MonthSummary _buildSummary(DateTime month) {
    final Map<AttendanceStatus, int> counts = <AttendanceStatus, int>{
      for (final AttendanceStatus status in AttendanceStatus.values) status: 0,
    };

    for (final MapEntry<DateTime, AttendanceStatus> entry
        in widget.attendanceMarks.entries) {
      if (entry.key.year == month.year && entry.key.month == month.month) {
        counts[entry.value] = (counts[entry.value] ?? 0) + 1;
      }
    }

    final int presentCount = counts[AttendanceStatus.present] ?? 0;
    final int absentCount = counts[AttendanceStatus.absent] ?? 0;
    final int halfDayCount = counts[AttendanceStatus.halfDay] ?? 0;
    final int overtimeCount = counts[AttendanceStatus.overtime] ?? 0;
    final int shiftCount = counts[AttendanceStatus.shift] ?? 0;
    final int holidayCount = counts[AttendanceStatus.holiday] ?? 0;
    final int totalMarked =
        presentCount +
        absentCount +
        halfDayCount +
        overtimeCount +
        shiftCount +
        holidayCount;

    final int attendanceBase = presentCount + absentCount + halfDayCount;
    final double percentage = attendanceBase == 0
        ? 0
        : ((presentCount + (halfDayCount * 0.5)) / attendanceBase) * 100;

    return _MonthSummary(
      counts: counts,
      totalMarked: totalMarked,
      presentCount: presentCount,
      absentCount: absentCount,
      halfDayCount: halfDayCount,
      overtimeCount: overtimeCount,
      attendancePercentage: percentage.toStringAsFixed(2),
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

class _MonthSummary {
  const _MonthSummary({
    required this.counts,
    required this.totalMarked,
    required this.presentCount,
    required this.absentCount,
    required this.halfDayCount,
    required this.overtimeCount,
    required this.attendancePercentage,
  });

  final Map<AttendanceStatus, int> counts;
  final int totalMarked;
  final int presentCount;
  final int absentCount;
  final int halfDayCount;
  final int overtimeCount;
  final String attendancePercentage;
}

class _MonthActionButton extends StatelessWidget {
  const _MonthActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isTrailingIcon = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isTrailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            colors: [Color(0xFF727272), Color(0xFF232323)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isTrailingIcon
              ? [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(icon, color: const Color(0xFF1FDC67)),
                ]
              : [
                  Icon(icon, color: const Color(0xFF1FDC67)),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

class _AnalyticsEmptyCell extends StatelessWidget {
  const _AnalyticsEmptyCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
      ),
    );
  }
}

class _AnalyticsDayCell extends StatelessWidget {
  const _AnalyticsDayCell({
    required this.day,
    required this.mark,
    required this.onTap,
    this.shiftType,
  });

  final DateTime day;
  final AttendanceStatus? mark;
  final Function(DateTime) onTap;
  final ShiftType? shiftType;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = mark?.color ?? Colors.white;
    final Color textColor = backgroundColor.computeLuminance() < 0.45
        ? Colors.white
        : Colors.black;

    String? shiftText;
    if (shiftType != null) {
      switch (shiftType) {
        case ShiftType.morning:
          shiftText = 'M';
          break;
        case ShiftType.afternoon:
          shiftText = 'A';
          break;
        case ShiftType.night:
          shiftText = 'N';
          break;
        case ShiftType.general:
          shiftText = 'G';
          break;
          default:
            shiftText = null;
      }
    }

    return InkWell(
      onTap: () => onTap(day),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: mark == AttendanceStatus.shift
                ? Colors.blue.shade700
                : Colors.black,
            width: mark == AttendanceStatus.shift ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (shiftText != null)
              Text(
                shiftText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsLegendItem extends StatelessWidget {
  const _AnalyticsLegendItem({
    required this.color,
    required this.label,
    this.textColor = Colors.black,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 18, height: 18, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        ),
      ],
    );
  }
}

enum ShiftType { morning, afternoon, night, general }
