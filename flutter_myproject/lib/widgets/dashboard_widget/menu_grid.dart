import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/palmplot/palmplot_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/gardencare_screen.dart';
import 'package:flutter_myproject/screens/garden/harvest/harvest_screen.dart';
import 'package:flutter_myproject/screens/main/report/report_screen.dart';
import 'package:flutter_myproject/screens/garden/plamvarieties/palmvarieties_screen.dart';
import 'package:flutter_myproject/screens/finance/finance_screen.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_item.dart';

class MenuGrid extends StatelessWidget {
  final String token;
  const MenuGrid({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เมนูหลัก',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // แถวที่ 1 (4 เมนู)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MenuItem(
                emoji: '🗺️',
                label: 'แปลงสวน',
                bgColor: const Color(0xFFE8F5E9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PalmplotScreen()),
                ),
              ),
              MenuItem(
                emoji: '🌿',
                label: 'ดูแลรักษา',
                bgColor: const Color(0xFFFFF8E1),
                labelColor: const Color(0xFF8D6E63),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GardenCareScreen()),
                ),
              ),
              MenuItem(
                emoji: '🧺',
                label: 'เก็บเกี่ยว',
                bgColor: const Color(0xFFFCE4EC),
                labelColor: const Color(0xFFC2185B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HarvestScreen()),
                ),
              ),
              MenuItem(
                emoji: '🌱',
                label: 'พันธุ์ปาล์ม',
                bgColor: const Color(0xFFE8F5E9),
                labelColor: const Color(0xFF2D6A4F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PalmVarietiesScreen(token: token),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // แถวที่ 2 (3 หรือ 4 เมนู)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MenuItem(
                emoji: '💵',
                label: 'รายรับ-จ่าย',
                bgColor: const Color(0xFFE0F2F1),
                labelColor: const Color(0xFF00695C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FinanceScreen()),
                ),
              ),
              MenuItem(
                emoji: '🏪',
                label: 'ร้านรับซื้อ',
                bgColor: const Color(0xFFFFF3E0),
                labelColor: const Color(0xFFE65100),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กำลังพัฒนาฟังก์ชันร้านรับซื้อ')),
                  );
                },
              ),
              MenuItem(
                emoji: '📈',
                label: 'รายงาน',
                bgColor: const Color(0xFFE3F2FD),
                labelColor: const Color(0xFF1565C0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                ),
              ),
              // ใช้ SizedBox กว้างเท่าปุ่ม เพื่อรักษาการจัดช่องว่างให้ตรงแนวกับแถวบน
              const SizedBox(width: 64), 
            ],
          ),
        ],
      ),
    );
  }
}