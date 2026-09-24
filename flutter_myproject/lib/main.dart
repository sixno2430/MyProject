import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/HOME/home_screen.dart';
import 'services/auth_server.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);

  // เช็กว่าเคยล็อกอินค้างไว้หรือไม่ ถ้าใช่ข้ามหน้า Login ไปหน้าหลักเลย
  final loggedIn = await AuthService.isLoggedIn();

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, this.loggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palm Oil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      ),
      home: loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
