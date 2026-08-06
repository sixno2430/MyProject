import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF), // สีน้ำเงิน
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ผู้ดูแลระบบ Admin', style: TextStyle(fontSize: 16)),
            Text('PalmTrack Community OS', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // สรุปภาพรวมระบบ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ภาพรวมระบบ 📊', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAdminStat('8', 'ผู้ใช้งาน', Icons.people),
                      _buildAdminStat('12', 'แปลงสวน', Icons.forest),
                      _buildAdminStat('15,240', 'รายได้', Icons.trending_up),
                      _buildAdminStat('82,458', 'ยอดขาย', Icons.shopping_bag),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // รายชื่อผู้ใช้ล่าสุด
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ผู้ใช้งานล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('ดูทั้งหมด')),
              ],
            ),
            const SizedBox(height: 12),
            _buildUserItem('สมชาย มีทรัพย์', 'เกษตรกร', 'ใช้งาน', Colors.green),
            _buildUserItem('รวย พาณิชย์', 'เกษตรกร', 'ใช้งาน', Colors.green),
            _buildUserItem('สมหญิง สวยงาม', 'แอดมิน', 'ใช้งาน', Colors.blue),
            _buildUserItem('กลมกล่อม จ่ายดี', 'ร้านค้า', 'ใช้งาน', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildUserItem(String name, String role, String status, Color roleColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.2),
            child: Text(name[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(role, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: const TextStyle(fontSize: 12, color: Colors.green)),
          ),
        ],
      ),
    );
  }
}