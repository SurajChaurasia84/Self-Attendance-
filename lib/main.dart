import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'attendance_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('FLUTTER_TEST')) {
    await MobileAds.instance.initialize();
  }
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'Daily Attendance';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A1F33),
        ).copyWith(primary: const Color(0xFF0A1F33)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1F33),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AttendanceHomeScreen(),
    );
  }
}
