import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 0,
        title: const Text('การแจ้งเตือน', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('อ่านทั้งหมด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationItem(
            icon: '🌴',
            title: 'ถึงเวลาให้ปุ๋ยแปลง D',
            desc: 'แปลง D ห้วยป่าซาง ต้องการให้ปุ๋ยด่วน',
            time: '10 นาทีที่แล้ว',
            isRead: false,
          ),
          _buildNotificationItem(
            icon: '💰',
            title: 'รายได้เข้า +9,900 บาท',
            desc: 'ขายผลปาล์มน้ำมัน แปลง A',
            time: '2 ชั่วโมงที่แล้ว',
            isRead: false,
          ),
          _buildNotificationItem(
            icon: '📊',
            title: 'รายงานประจำเดือนพร้อม',
            desc: 'รายงานสรุปผลการผลิตเดือนมิถุนายน 2568',
            time: '1 วันที่แล้ว',
            isRead: true,
          ),
          _buildNotificationItem(
            icon: '✅',
            title: 'บันทึกการเก็บเกี่ยวสำเร็จ',
            desc: 'H003 — แปลง C บันทึกเรียบร้อย',
            time: '2 วันที่แล้ว',
            isRead: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String icon,
    required String title,
    required String desc,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: isRead ? null : Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}