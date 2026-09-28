import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/splash_screen.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);

  runApp(const MyApp());
}

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
