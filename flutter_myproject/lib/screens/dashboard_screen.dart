import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/main/palmplot_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare_screen.dart';
import 'package:flutter_myproject/screens/garden/harvest_screen.dart';
import 'package:flutter_myproject/screens/main/report_screen.dart';
import 'package:flutter_myproject/screens/garden/palmvarieties_screen.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final Color lightGreen = const Color(0xFF40916C);

  // TODO: แทนที่ด้วย user_id จริงจากระบบ login/session ของคุณ
  // (เช่น ดึงจาก SharedPreferences หลัง login สำเร็จ)
  final String _currentUserId = 'U002';

  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _dashboardFuture = DashboardService().fetchDashboard(_currentUserId);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _loadDashboard();
    });
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'โหลดข้อมูลไม่สำเร็จ\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(_loadDashboard),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                // ====== ส่วนหัวสีเขียว ======
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                                        child: Text('👨‍🌾', style: TextStyle(fontSize: 24)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // TODO: เปลี่ยนเป็นชื่อ/บทบาทจริงจาก session ผู้ใช้
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'สมชาย มีทรัพย์',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'เกษตรกร · สวนปาล์มน้ำมัน',
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
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
                                      child: const Text('🔔', style: TextStyle(fontSize: 18)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
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
                                  _formatThaiDate(DateTime.now()),
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ====== การ์ดสถิติซ้อนทับ (ข้อมูลจริงจาก API) ======
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
                              _buildStatItem('${data.gardenCount}', 'แปลงสวน\nจำนวน'),
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              _buildStatItem(
                                  _formatNumber(data.monthlyProduction), 'กก.\nผลผลิต/เดือน'),
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              _buildStatItem(
                                  _formatNumber(data.monthlyIncome), 'บาท\nรายรับเดือนนี้'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 56)),

                // ====== เมนูลัด (เหมือนเดิม ไม่ต้องดึงจาก API) ======
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('เมนูหลัก',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMenuItem(context,
                                emoji: '🗺️',
                                label: 'แปลงสวน',
                                bgColor: const Color(0xFFE8F5E9),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const PalmplotScreen()))),
                            _buildMenuItem(context,
                                emoji: '🌿',
                                label: 'ดูแลรักษา',
                                bgColor: const Color(0xFFFFF8E1),
                                labelColor: const Color(0xFF8D6E63),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const GardenCareScreen()))),
                            _buildMenuItem(context,
                                emoji: '💊',
                                label: 'ใส่ปุ๋ย',
                                bgColor: const Color(0xFFFFEBEE),
                                labelColor: Colors.red,
                                onTap: () {}),
                            _buildMenuItem(context,
                                emoji: '🧺',
                                label: 'เก็บเกี่ยว',
                                bgColor: const Color(0xFFFCE4EC),
                                labelColor: const Color(0xFFC2185B),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const HarvestScreen()))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMenuItem(context,
                                emoji: '💵',
                                label: 'รายรับ-จ่าย',
                                bgColor: const Color(0xFFE0F2F1),
                                labelColor: const Color(0xFF00695C),
                                onTap: () {}),
                            _buildMenuItem(context,
                                emoji: '🏪',
                                label: 'ร้านรับซื้อ',
                                bgColor: const Color(0xFFFFF3E0),
                                labelColor: const Color(0xFFE65100),
                                onTap: () {}),
                            _buildMenuItem(context,
                                emoji: '🌱',
                                label: 'พันธุ์ปาล์ม',
                                bgColor: const Color(0xFFE8F5E9),
                                labelColor: primaryGreen,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const PalmVarietiesScreen()))),
                            _buildMenuItem(context,
                                emoji: '📈',
                                label: 'รายงาน',
                                bgColor: const Color(0xFFE3F2FD),
                                labelColor: const Color(0xFF1565C0),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const ReportScreen()))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ====== กิจกรรมล่าสุด (ข้อมูลจริงจาก API) ======
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('กิจกรรมล่าสุด',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Text('ดูทั้งหมด',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: primaryGreen,
                                          fontWeight: FontWeight.w600)),
                                  Icon(Icons.arrow_forward_ios, size: 12, color: primaryGreen),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (data.activities.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('ยังไม่มีกิจกรรม',
                                  style: TextStyle(color: Colors.grey[500])),
                            ),
                          )
                        else
                          ...data.activities.map((activity) => _buildActivityFromApi(activity)),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ====== Widget ย่อย ======

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3)),
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
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // แปลง ActivityItem จาก API → การ์ดกิจกรรม (เลือก emoji/สี/ข้อความตาม type)
  Widget _buildActivityFromApi(ActivityItem activity) {
    late String emoji;
    late Color bgColor;
    late String title;
    late String subtitle;

    switch (activity.type) {
      case 'harvest':
        emoji = '🧺';
        bgColor = const Color(0xFFFCE4EC);
        title = 'เก็บเกี่ยว ${activity.gardenName}';
        subtitle = '${_formatNumber(activity.quantity ?? 0)} กก.';
        break;
      case 'care':
        emoji = '💊';
        bgColor = const Color(0xFFFFEBEE);
        title = 'ใส่ปุ๋ย ${activity.gardenName}';
        subtitle = activity.description != null
            ? '${activity.description} · ${_formatNumber(activity.quantity ?? 0)} กก.'
            : '${_formatNumber(activity.quantity ?? 0)} กก.';
        break;
      case 'income':
      default:
        emoji = '💵';
        bgColor = const Color(0xFFE0F2F1);
        title = activity.description ?? 'รับเงิน ${activity.gardenName}';
        subtitle = '+${_formatNumber(activity.amount ?? 0)} บาท';
        break;
    }

    return _buildActivityCard(
      emoji: emoji,
      bgColor: bgColor,
      title: title,
      subtitle: subtitle,
      time: _formatRelativeDate(activity.recordDate),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ====== Helper functions ======

  String _formatNumber(num value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0 && str[i - 1] != '-') buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';

    const thaiMonths = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${thaiMonths[date.month]}';
  }

  String _formatThaiDate(DateTime date) {
    const thaiMonths = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    const thaiWeekdays = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
    final buddhistYear = date.year + 543;
    final weekday = thaiWeekdays[date.weekday - 1];
    return '$weekday, ${date.day} ${thaiMonths[date.month]} $buddhistYear';
  }
}