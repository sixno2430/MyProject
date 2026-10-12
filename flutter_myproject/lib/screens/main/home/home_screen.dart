// ============================================================
// home_screen.dart — หน้าหลักหลังล็อกอิน (โครงของแอป)
//
// มีแถบเมนูด้านล่าง 5 แท็บ และสลับหน้าด้วย IndexedStack
// (ทุกแท็บถูกสร้างพร้อมกันตั้งแต่เข้าหน้า จึงจำสถานะของแต่ละแท็บไว้ได้)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/button_nav.dart';

// หน้าทั้ง 5 หน้าในแถบล่าง
import 'package:flutter_myproject/screens/main/home/dashboard_screen.dart';   // หน้าแรก: หน้าหลัก
import 'package:flutter_myproject/screens/garden/palmplot/palmplot_screen.dart';     // หน้าสวน
import 'package:flutter_myproject/screens/finance/finance_screen.dart';     // หน้าการเงิน
import 'package:flutter_myproject/screens/main/report/report_screen.dart';      // หน้ารายงาน
import 'package:flutter_myproject/screens/main/profile/profile_screen.dart';     // หน้าโปรไฟล์

/// หน้าหลักที่มีแถบเมนูด้านล่าง
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // กดแท็บ "การเงิน" แล้วเพิ่มค่านี้ -> หน้าการเงินโหลดข้อมูลใหม่ (แปลง/รายการที่เพิ่มจากหน้าอื่นขึ้นทันที)
  final ValueNotifier<int> _financeRefresh = ValueNotifier(0);

  // เรียงตามลำดับปุ่มในแถบล่าง
  late final List<Widget> _pages = [
    const DashboardScreen(),   // index 0: 🏠 หน้าหลัก
    const PalmplotScreen(),    // index 1: 🌴 สวน
    FinanceScreen(refreshTrigger: _financeRefresh), // index 2: 💵 การเงิน
    const ReportScreen(),      // index 3: 📈 รายงาน
    const ProfileScreen(),     // index 4: 👤 โปรไฟล์
  ];

  @override
  void dispose() {
    _financeRefresh.dispose();
    super.dispose();
  }

  /// เปลี่ยนแท็บเมื่อกดปุ่มในแถบด้านล่าง
  void _onNavTapped(int index) {
    if (index == 2) _financeRefresh.value++;
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