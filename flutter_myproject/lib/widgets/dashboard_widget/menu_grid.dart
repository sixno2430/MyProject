// ============================================================
// menu_grid.dart — ตารางเมนูหลักบนหน้า Dashboard (4 คอลัมน์)
//
// แต่ละปุ่มเปิดหน้าของฟังก์ชันนั้น: แปลงสวน, ดูแลรักษา, เก็บเกี่ยว, พันธุ์ปาล์ม,
// รายรับ-จ่าย, ร้านรับซื้อ, รายงาน
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/palmplot/palmplot_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/gardencare_screen.dart';
import 'package:flutter_myproject/screens/garden/harvest/harvest_screen.dart';
import 'package:flutter_myproject/screens/main/report/report_screen.dart';
import 'package:flutter_myproject/screens/garden/plamvarieties/palmvarieties_screen.dart';
import 'package:flutter_myproject/screens/finance/finance_screen.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_item.dart';
import 'package:flutter_myproject/screens/store/store_screen.dart';

/// ตารางเมนูหลัก (ต้องส่ง token ไปให้หน้าพันธุ์ปาล์ม)
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),

          // ตาราง 4 คอลัมน์ ทุกช่องกว้างเท่ากัน (แทน Row + SizedBox ดันช่องว่าง)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              childAspectRatio: 0.82,
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StoreScreen()),
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
          ),
        ],
      ),
    );
  }
}