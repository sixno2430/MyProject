// ============================================================
// main.dart — จุดเริ่มต้นของแอป PalmTrack
//
// เตรียมรูปแบบวันที่ภาษาไทย แล้วเปิดแอปที่หน้า Splash (อนิเมชันเปิดแอป)
// ซึ่งจะพาไปหน้า Login ต่อ
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/splash_screen.dart';

/// เริ่มแอป: โหลดข้อมูลวันที่ภาษาไทย (th_TH) ก่อน แล้วจึงแสดงหน้าจอ
void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);

  runApp(const MyApp());
}

/// Widget รากของแอป กำหนดธีมสีและหน้าแรก (SplashScreen)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palm Oil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      ),
      // เปิดแอป -> อนิเมชัน Splash ~2 วินาที -> หน้า Login ทุกครั้ง
      home: const SplashScreen(),
    );
  }
}
