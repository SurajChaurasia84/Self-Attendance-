import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF0A1F33);
const Color kSheetColor = Color(0xFFF8F5BE);
const Color kSundayColor = Color(0xFFD3D3D3);

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

String monthName(int month) {
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
