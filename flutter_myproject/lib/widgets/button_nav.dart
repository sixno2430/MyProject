// ============================================================
// button_nav.dart — แถบเมนูด้านล่าง (ใช้ทั้งฝั่งชาวสวนและร้านรับซื้อ)
//
// ค่าเริ่มต้น: เมนูชาวสวน หน้าหลัก / สวน / การเงิน / รายงาน / โปรไฟล์ สีเขียว
// ฝั่งร้านส่ง items และ color (สีส้ม) ของตัวเองมา
// ============================================================

import 'package:flutter/material.dart';

/// แถบเมนูด้านล่าง แจ้งแท็บที่ถูกกดผ่าน onTap
class ButtonNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// รายการเมนู (emoji, ชื่อ) ไม่ส่งมา = เมนูชาวสวน
  final List<(String, String)> items;

  /// สีของแท็บที่เลือกอยู่
  final Color color;

  /// ตัวเลขแจ้งเตือนบนไอคอน {ลำดับแท็บ: จำนวน} เช่น {1: 3} = แท็บที่ 2 มี 3 รายการ (0 = ไม่แสดง)
  final Map<int, int> badges;

  /// เมนูของฝั่งชาวสวน
  static const farmerItems = [
    ('🏠', 'หน้าหลัก'),
    ('🌴', 'สวน'),
    ('💵', 'การเงิน'),
    ('📈', 'รายงาน'),
    ('👤', 'โปรไฟล์'),
  ];

  const ButtonNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = farmerItems,
    this.color = const Color(0xFF2D6A4F),
    this.badges = const {},
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
              for (var i = 0; i < items.length; i++) Expanded(child: _buildItem(items[i].$1, items[i].$2, i)),
            ],
          ),
        ),
      ),
    );
  }

  /// ปุ่ม 1 แท็บ (ไอคอน + ชื่อ) ไฮไลต์ถ้าเป็นแท็บที่เลือกอยู่
  Widget _buildItem(String icon, String label, int index) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // แตะตรงไหนในช่องของแท็บก็ได้
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            isLabelVisible: (badges[index] ?? 0) > 0,
            label: Text('${(badges[index] ?? 0) > 99 ? '99+' : badges[index]}'),
            backgroundColor: const Color(0xFFDC2626),
            offset: const Offset(8, -4),
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 22,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}