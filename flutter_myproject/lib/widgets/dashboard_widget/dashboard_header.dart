// ============================================================
// dashboard_header.dart — ส่วนหัวสีเขียวของหน้า Dashboard
//
// แสดงคำทักทายตามเวลา, ชื่อผู้ใช้ (โหลดจากโปรไฟล์), วันที่
// และการ์ดสถิติ 3 ช่อง (แปลงสวน / ผลผลิตเดือนนี้ / รายรับเดือนนี้)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/services/profile_service.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/utils/formatters.dart';

/// ส่วนหัว Dashboard รับข้อมูลสถิติจาก DashboardData
class DashboardHeader extends StatefulWidget {
  final DashboardData data;
  const DashboardHeader({super.key, required this.data});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  String _displayName = 'กำลังโหลด...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// โหลดชื่อผู้ใช้จาก API โปรไฟล์ (รองรับ JSON หลายรูปแบบ)
  Future<void> _loadUserProfile() async {
    try {
      final userId = await AuthService.getUserId();
      debugPrint('🔎 [DEBUG] User ID ที่อ่านได้: $userId');

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _displayName = 'ไม่ได้เข้าสู่ระบบ';
          });
        }
        return;
      }

      final profileRes = await ProfileService.getProfile(userId);
      debugPrint('🔎 [DEBUG] Response จาก API: $profileRes');

      // 1. ตรวจสอบว่าห่ออยู่ใน 'data' หรือไม่
      dynamic rawData = profileRes;
      if (profileRes.containsKey('data') && profileRes['data'] != null) {
        rawData = profileRes['data'];
      }

      // 2. กรณีที่ API ส่งกลับมาเป็น List (Array) เช่น [{"full_name": "..."}]
      if (rawData is List && rawData.isNotEmpty) {
        rawData = rawData[0];
      }

      // 3. กรณีที่ซ้อนอยู่ในคีย์ย่อย เช่น data['user'] หรือ data['profile']
      if (rawData is Map<String, dynamic>) {
        if (rawData['user'] is Map<String, dynamic>) {
          rawData = rawData['user'];
        } else if (rawData['profile'] is Map<String, dynamic>) {
          rawData = rawData['profile'];
        }
      }

      // 4. ดึงชื่อจากฟิลด์ full_name (ตามคอลัมน์ใน Database)
      String? foundName;
      if (rawData is Map<String, dynamic>) {
        foundName = rawData['full_name'] ??
            rawData['name'] ??
            rawData['fullname'] ??
            rawData['username'] ??
            rawData['user_name'];
      }

      if (mounted) {
        setState(() {
          _displayName = foundName?.toString() ?? 'ไม่พบชื่อ ($userId)';
        });
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] โหลดโปรไฟล์ผิดพลาด: $e');
      if (mounted) {
        setState(() {
          _displayName = 'เกิดข้อผิดพลาด';
        });
      }
    }
  }

  // ทักทายตามช่วงเวลาของวัน
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'อรุณสวัสดิ์ ☀️';
    if (h < 17) return 'สวัสดีตอนบ่าย 🌤️';
    return 'สวัสดีตอนเย็น 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildGreenHeader(),
        Positioned(
          bottom: -52,
          left: 16,
          right: 16,
          child: _buildStatsCard(),
        ),
      ],
    );
  }

  /// พื้นหลังไล่สีเขียว + รูป/ชื่อผู้ใช้ + วันที่
  Widget _buildGreenHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // วงกลมตกแต่งจางๆ มุมขวาบน
          Positioned(
            top: -40,
            right: -30,
            child: _decorCircle(160, 0.06),
          ),
          Positioned(
            top: 60,
            right: 50,
            child: _decorCircle(70, 0.05),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 76),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _displayName, // แสดงชื่อจริงตามฐานข้อมูล
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationBell(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formatThaiDate(DateTime.now()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// วงกลมโปร่งแสงสำหรับตกแต่งพื้นหลัง
  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  /// รูปโปรไฟล์ (ไอคอนเกษตรกร)
  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
      ),
      child: const Center(
        child: Text('👨‍🌾', style: TextStyle(fontSize: 26)),
      ),
    );
  }

  /// ปุ่มกระดิ่งแจ้งเตือน (ยังไม่มีการทำงาน)
  Widget _buildNotificationBell() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
    );
  }

  /// การ์ดสีขาวลอยทับส่วนหัว แสดงสถิติ 3 ช่อง
  Widget _buildStatsCard() {
    final d = widget.data;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.landscape_rounded,
            color: const Color(0xFF2D6A4F),
            value: '${d.gardenCount}',
            unit: 'แปลง',
            caption: d.totalArea > 0 ? '${formatNumber(d.totalArea)} ไร่' : 'แปลงสวน',
          ),
          _divider(),
          _StatTile(
            icon: Icons.agriculture_rounded,
            color: const Color(0xFFE76F51),
            value: formatNumber(d.monthlyProduction),
            unit: 'กก.',
            caption: 'ผลผลิตเดือนนี้',
          ),
          _divider(),
          _StatTile(
            icon: Icons.payments_rounded,
            color: const Color(0xFF1565C0),
            value: formatNumber(d.monthlyIncome),
            unit: '฿',
            caption: 'รายรับเดือนนี้',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 56, color: Colors.grey[200]);
}

/// ช่องสถิติ 1 ช่อง: ไอคอนในวงกลมสี + ตัวเลข + คำอธิบาย
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String caption;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(caption, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
