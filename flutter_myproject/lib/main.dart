// ============================================================
// main.dart — จุดเริ่มต้นของแอป PalmTrack
//
// เตรียมรูปแบบวันที่ภาษาไทย แล้วเปิดแอปที่หน้า Splash (อนิเมชันเปิดแอป)
// ซึ่งจะพาไปหน้า Login ต่อ
// ทั้งแอปครอบด้วย AuthHttpClient: ทุก http.get/post แนบ token ให้อัตโนมัติ (services/api_client.dart)
// ============================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/splash_screen.dart';
import 'services/api_client.dart';

/// เริ่มแอป: โหลดข้อมูลวันที่ภาษาไทย (th_TH) ก่อน แล้วจึงแสดงหน้าจอ
void main() {
  // สร้าง client ตัวจริงนอก runWithClient (ข้างในจะได้ AuthHttpClient วนกลับมาเอง)
  final inner = http.Client();
  // ต้องทำทุกอย่าง (รวม ensureInitialized) ในโซนเดียวกัน ปุ่ม/หน้าจอทั้งหมดจะได้ใช้ client นี้
  http.runWithClient(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('th_TH', null);
    runApp(const MyApp());
  }, () => AuthHttpClient(inner));
}
/// Widget รากของแอป กำหนดธีมสีและหน้าแรก (SplashScreen)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ให้ AuthHttpClient พากลับหน้าล็อกอินได้ตอน token หมดอายุ
      title: 'Palm Oil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      ),
      // เปิดแอป -> อนิเมชัน Splash ~2 วินาที -> หน้า Login ทุกครั้ง
      home: const SplashScreen(),
    );
  }
}
