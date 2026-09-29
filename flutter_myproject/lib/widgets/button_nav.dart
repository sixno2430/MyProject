// ============================================================
// button_nav.dart — แถบเมนูด้านล่างของหน้าหลัก (5 แท็บ)
//
// หน้าหลัก / สวน / การเงิน / รายงาน / โปรไฟล์ ใช้ใน HomeScreen
// ============================================================

import 'package:flutter/material.dart';

/// แถบเมนูด้านล่าง แจ้งแท็บที่ถูกกดผ่าน onTap
class ButtonNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ButtonNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem('🏠', 'หน้าหลัก', 0),
              _buildItem('🌴', 'สวน', 1),
              _buildItem('💵', 'การเงิน', 2),
              _buildItem('📈', 'รายงาน', 3),
              _buildItem('👤', 'โปรไฟล์', 4),
            ],
          ),
        ),
      ),
    );
  }

  /// ปุ่ม 1 แท็บ (ไอคอน + ชื่อ) ไฮไลต์ถ้าเป็นแท็บที่เลือกอยู่
  Widget _buildItem(String icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    final Color primaryGreen = const Color(0xFF2D6A4F);

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 22,
              color: isSelected ? primaryGreen : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? primaryGreen : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}