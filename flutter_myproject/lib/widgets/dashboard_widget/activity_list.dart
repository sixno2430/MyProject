// ============================================================
// activity_list.dart — ส่วน "กิจกรรมล่าสุด" บนหน้า Dashboard
//
// แสดงกิจกรรมล่าสุด 5 รายการ และปุ่ม "ดูทั้งหมด" ไปหน้าประวัติกิจกรรม
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/recent_activity_card.dart';
import 'package:flutter_myproject/screens/main/HOME/activity_screen.dart';

/// รายการกิจกรรมล่าสุด เรียก onChanged เมื่อมีการแก้ไข/ลบ ให้ Dashboard โหลดใหม่
class ActivityList extends StatelessWidget {
  final List<ActivityItem> activities;

  /// ให้ Dashboard โหลดข้อมูลใหม่ เมื่อมีการแก้ไข/ลบกิจกรรม
  final VoidCallback? onChanged;

  const ActivityList({super.key, required this.activities, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'กิจกรรมล่าสุด',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityScreen()),
                  );
                  // กลับมาแล้วโหลดใหม่ เผื่อมีการแก้ไข/ลบในหน้านั้น
                  onChanged?.call();
                },
                child: const Row(
                  children: [
                    Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2D6A4F)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'ยังไม่มีกิจกรรม',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ...activities.map((a) => RecentActivityCard(activity: a, onChanged: onChanged)),
        ],
      ),
    );
  }
}
