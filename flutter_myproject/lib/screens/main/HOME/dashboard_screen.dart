import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/activity_list.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/dashboard_header.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/error_view.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_grid.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/services/auth_server.dart';

// โมเดลชั่วคราวเพื่อห่อหุ้ม Data + Token เข้าด้วยกันอย่างปลอดภัย
class _DashboardScreenData {
  final DashboardData dashboard;
  final String token;

  _DashboardScreenData({required this.dashboard, required this.token});
}

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

  void _loadDashboard() {
    setState(() {
      _dashboardFuture = _fetchDashboardWithAuth();
    });
  }

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

  Future<void> _onRefresh() async {
    _loadDashboard();
    try {
      await _dashboardFuture;
    } catch (_) {
      // ป้องกัน exception หลุดออกมาตอนดึงรีเฟรชหน้าจอ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                    error: snapshot.error.toString(),
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
                      const SliverToBoxAdapter(child: SizedBox(height: 56)),
                      // ส่ง token ที่โหลดมาพร้อมกับข้อมูลอย่างแน่นอน
                      SliverToBoxAdapter(child: MenuGrid(token: token)),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: ActivityList(activities: data.activities),
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