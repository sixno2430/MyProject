import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/main/palmplot_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare_screen.dart';
import 'package:flutter_myproject/screens/garden/harvest_screen.dart';
import 'package:flutter_myproject/screens/main/report_screen.dart';
import 'package:flutter_myproject/screens/garden/palmvarieties_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);
  final Color lightGreen = const Color(0xFF40916C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ====== ส่วนหัวสีเขียว ======
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // พื้นหลังเขียว
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // แถวบน: โปรไฟล์ + แจ้งเตือน
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '👨‍🌾',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'สมชาย มีทรัพย์',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'เกษตรกร · สวนปาล์มน้ำมัน',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '🔔',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // สวัสดี
                          const Text(
                            'สวัสดี ยินดีต้อนรับ 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'พุธ, 11 มิถุนายน 2568',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ====== การ์ดสถิติซ้อนทับ ======
                Positioned(
                  bottom: -40,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatItem('4', 'แปลงสวน\nจำนวน'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                        ),
                        _buildStatItem('5,850', 'กก.\nผลผลิต/เดือน'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                        ),
                        _buildStatItem('39,538', 'บาท\nรายรับรวม'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====== เว้นที่ให้การ์ดสถิติ ======
          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          // ====== เมนูลัด ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เมนูหลัก',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // แถวที่ 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMenuItem(
                        context,
                        emoji: '🗺️',
                        label: 'แปลงสวน',
                        bgColor: const Color(0xFFE8F5E9),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PalmplotScreen(),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        emoji: '🌿',
                        label: 'ดูแลรักษา',
                        bgColor: const Color(0xFFFFF8E1),
                        labelColor: const Color(0xFF8D6E63),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GardenCareScreen(),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        emoji: '💊',
                        label: 'ใส่ปุ๋ย',
                        bgColor: const Color(0xFFFFEBEE),
                        labelColor: Colors.red,
                        onTap: () {}, // TODO: ไปหน้าใส่ปุ๋ย
                      ),
                      _buildMenuItem(
                        context,
                        emoji: '🧺',
                        label: 'เก็บเกี่ยว',
                        bgColor: const Color(0xFFFCE4EC),
                        labelColor: const Color(0xFFC2185B),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HarvestScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // แถวที่ 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMenuItem(
                        context,
                        emoji: '💵',
                        label: 'รายรับ-จ่าย',
                        bgColor: const Color(0xFFE0F2F1),
                        labelColor: const Color(0xFF00695C),
                        onTap: () {}, // TODO: ไปหน้าการเงิน
                      ),
                      _buildMenuItem(
                        context,
                        emoji: '🏪',
                        label: 'ร้านรับซื้อ',
                        bgColor: const Color(0xFFFFF3E0),
                        labelColor: const Color(0xFFE65100),
                        onTap: () {}, // TODO: ไปหน้าร้านค้า
                      ),
                      _buildMenuItem(
                        context,
                        emoji: '🌱',
                        label: 'พันธุ์ปาล์ม',
                        bgColor: const Color(0xFFE8F5E9),
                        labelColor: primaryGreen,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PalmVarietiesScreen(),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        emoji: '📈',
                        label: 'รายงาน',
                        bgColor: const Color(0xFFE3F2FD),
                        labelColor: const Color(0xFF1565C0),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ====== กิจกรรมล่าสุด ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'กิจกรรมล่าสุด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(
                              'ดูทั้งหมด',
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    emoji: '🧺',
                    bgColor: const Color(0xFFFCE4EC),
                    title: 'เก็บเกี่ยว แปลง A',
                    subtitle: '1,800 กก. · 9,900 บาท',
                    time: 'วันนี้',
                  ),
                  _buildActivityCard(
                    emoji: '💊',
                    bgColor: const Color(0xFFFFEBEE),
                    title: 'ใส่ปุ๋ย แปลง B',
                    subtitle: 'ปุ๋ย 15-15-15 · 40 กก.',
                    time: 'เมื่อวาน',
                  ),
                  _buildActivityCard(
                    emoji: '💵',
                    bgColor: const Color(0xFFE0F2F1),
                    title: 'รับเงินจากสหกรณ์',
                    subtitle: '+9,900 บาท',
                    time: '10 มิ.ย.',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ====== Widget ย่อย ======

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String emoji,
    required String label,
    required Color bgColor,
    Color labelColor = const Color(0xFF2D6A4F),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String emoji,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
