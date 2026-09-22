import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/services/profile_service.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/stat_item.dart';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildGreenHeader(),
        Positioned(
          bottom: -40,
          left: 16,
          right: 16,
          child: _buildStatsCard(),
        ),
      ],
    );
  }

  Widget _buildGreenHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2D6A4F),
        borderRadius: BorderRadius.only(
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
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName, // แสดงชื่อจริงตามฐานข้อมูล
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'เกษตรกร · สวนปาล์มน้ำมัน',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationBell(),
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
                formatThaiDate(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
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
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Text('🔔', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildStatsCard() {
    return Container(
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
          StatItem(value: '${widget.data.gardenCount}', label: 'แปลงสวน\nจำนวน'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          StatItem(
            value: formatNumber(widget.data.monthlyProduction),
            label: 'กก.\nผลผลิต/เดือน',
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          StatItem(
            value: formatNumber(widget.data.monthlyIncome),
            label: 'บาท\nรายรับเดือนนี้',
          ),
        ],
      ),
    );
  }
}