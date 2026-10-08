// ============================================================
// dashboard_screen.dart — แท็บ "หน้าหลัก" (Dashboard)
//
// แสดงส่วนหัว + สถิติ, การ์ดเตือนผลผลิตรอขาย, เมนูหลัก และกิจกรรมล่าสุด
// ข้อมูลทั้งหมดมาจาก GET /api/dashboard/:userId ครั้งเดียว ดึงหน้าจอลงเพื่อโหลดใหม่ได้
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/activity_list.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/dashboard_header.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/error_view.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_grid.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/screens/garden/harvest/harvest_screen.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/utils/error_message.dart';

// โมเดลชั่วคราวเพื่อห่อหุ้ม Data + Token เข้าด้วยกันอย่างปลอดภัย
/// ห่อข้อมูล Dashboard กับ token ไว้ด้วยกัน (token ต้องส่งต่อให้หน้าพันธุ์ปาล์ม)
class _DashboardScreenData {
  final DashboardData dashboard;
  final String token;

  _DashboardScreenData({required this.dashboard, required this.token});
}

/// แท็บหน้าหลัก
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<_DashboardScreenData>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  /// สั่งโหลดข้อมูลใหม่ (FutureBuilder จะแสดงผลเมื่อโหลดเสร็จ)
  void _loadDashboard() {
    setState(() {
      _dashboardFuture = _fetchDashboardWithAuth();
    });
  }

  /// อ่าน user_id/token จากเครื่อง แล้วดึงข้อมูล Dashboard
  Future<_DashboardScreenData> _fetchDashboardWithAuth() async {
    // 1. ดึง user_id และ token พร้อมกัน
    final userId = await AuthService.getUserId();

    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง');
    }

    final token = await AuthService.getToken() ?? '';

    // 2. ดึงข้อมูลแดชบอร์ด
    final dashboardData = await DashboardService().fetchDashboard(userId);

    // 3. ส่งข้อมูลกลับไปพร้อม token เสมอ
    return _DashboardScreenData(
      dashboard: dashboardData,
      token: token,
    );
  }

  /// ดึงหน้าจอลงเพื่อโหลดใหม่
  Future<void> _onRefresh() async {
    _loadDashboard();
    try {
      await _dashboardFuture;
    } catch (_) {
      // ป้องกัน exception หลุดออกมาตอนดึงรีเฟรชหน้าจอ
    }
  }

  /// การ์ดสีส้ม "มีผลผลิตรอขาย" แตะแล้วไปหน้าเก็บเกี่ยว (แสดงเฉพาะเมื่อมีรายการรอขาย)
  /// บรรทัดรองของการ์ดรอขาย: แยกล็อตที่รอร้านยืนยัน กับที่ยังไม่เลือกร้าน
  /// (ล็อตที่เลือกร้านไว้ เกษตรกรบันทึกขายเองไม่ได้ ต้องรอร้านกดรับซื้อ)
  String _pendingDetail(DashboardData data) {
    final waiting = data.pendingWaitingShopCount;
    final open = data.pendingHarvestCount - waiting;
    final parts = <String>[
      if (waiting > 0) 'รอร้านยืนยัน $waiting',
      if (open > 0) 'ยังไม่เลือกร้าน $open',
    ];
    final action = open > 0 ? 'แตะเพื่อเลือกร้านหรือบันทึกขาย' : 'แตะเพื่อดูรายการ';
    return '${parts.join(' · ')} · รวม ${formatNumber(data.pendingHarvestKg)} กก.\n$action';
  }

  Widget _buildPendingHarvestCard(DashboardData data) {
    const orange = Color(0xFFE65100);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Material(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HarvestScreen()),
            );
            _loadDashboard(); // กลับมาแล้วโหลดใหม่ เผื่อขายไปแล้ว
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sell_outlined, color: orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'มีผลผลิตรอขาย ${data.pendingHarvestCount} รายการ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: orange),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pendingDetail(data),
                        style: TextStyle(fontSize: 12, color: Colors.brown[400]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: orange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: _dashboardFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<_DashboardScreenData>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ErrorView(
                    error: friendlyError(snapshot.error),
                    onRetry: _loadDashboard,
                  );
                }

                final screenData = snapshot.data!;
                final data = screenData.dashboard;
                final token = screenData.token;

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // ให้ดึง Refresh ได้แม้เนื้อหาไม่ล้นจอ
                    slivers: [
                      SliverToBoxAdapter(child: DashboardHeader(data: data)),
                      const SliverToBoxAdapter(child: SizedBox(height: 72)),
                      // การ์ดเตือนผลผลิตรอขาย (แสดงเฉพาะเมื่อมี)
                      if (data.pendingHarvestCount > 0)
                        SliverToBoxAdapter(child: _buildPendingHarvestCard(data)),
                      // ส่ง token ที่โหลดมาพร้อมกับข้อมูลอย่างแน่นอน
                      SliverToBoxAdapter(child: MenuGrid(token: token)),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: ActivityList(
                          activities: data.activities,
                          onChanged: _loadDashboard,
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
}