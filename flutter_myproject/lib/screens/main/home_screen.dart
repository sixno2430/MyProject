import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/button_nav.dart';

// หน้าทั้ง 5 หน้าในแถบล่าง
import 'package:flutter_myproject/screens/dashboard_screen.dart';   // หน้าแรก: หน้าหลัก (ต้องสร้างเพิ่ม)
import 'package:flutter_myproject/screens/main/palmplot_screen.dart';     // หน้าสวน
import 'package:flutter_myproject/screens/main/finance_screen.dart';     // หน้าการเงิน
import 'package:flutter_myproject/screens/main/report_screen.dart';      // หน้ารายงาน
import 'package:flutter_myproject/screens/main/profile_screen.dart';     // หน้าโปรไฟล์

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  

  // เรียงตามลำดับปุ่มในแถบล่าง
  final List<Widget> _pages = const [
    DashboardScreen(),   // index 0: 🏠 หน้าหลัก
    PalmplotScreen(),     // index 1: 🌴 สวน
    FinanceScreen(),     // index 2: 💵 การเงิน
    ReportScreen(),      // index 3: 📈 รายงาน
    ProfileScreen(),     // index 4: 👤 โปรไฟล์
  ];

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ButtonNav(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}