import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/palmplot/palmplot_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/gardencare_screen.dart';
import 'package:flutter_myproject/screens/garden/havest/harvest_screen.dart';
import 'package:flutter_myproject/screens/main/report/report_screen.dart';
import 'package:flutter_myproject/screens/garden/plamvarieties/palmvarieties_screen.dart';
import 'package:flutter_myproject/screens/finance/finance_screen.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_item.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              // MenuItem(
              //   emoji: '💊',
              //   label: 'ใส่ปุ๋ย',
              //   bgColor: const Color(0xFFFFEBEE),
              //   labelColor: Colors.red,
              //   onTap: () {},
              // ),
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                onTap: () {},
              ),
              MenuItem(
                emoji: '🌱',
                label: 'พันธุ์ปาล์ม',
                bgColor: const Color(0xFFE8F5E9),
                labelColor: const Color(0xFF2D6A4F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PalmVarietiesScreen()),
                ),
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
            ],
          ),
        ],
      ),
    );
  }
}
