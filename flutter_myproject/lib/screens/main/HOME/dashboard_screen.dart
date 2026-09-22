import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/activity_list.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/dashboard_header.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/error_view.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_grid.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/services/auth_server.dart'; // เรียกใช้ AuthService

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _dashboardFuture;

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

  Future<DashboardData> _fetchDashboardWithAuth() async {
    // 1. ดึง user_id ของคนที่ล็อกอินอยู่จริงจาก AuthService
    final userId = await AuthService.getUserId();
    
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง');
    }

    // 2. ส่ง userId จริงไปดึงข้อมูลแดชบอร์ด
    return await DashboardService().fetchDashboard(userId);
  }

  Future<void> _onRefresh() async {
    _loadDashboard();
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _dashboardFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<DashboardData>(
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

                final data = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: DashboardHeader(data: data)),
                      const SliverToBoxAdapter(child: SizedBox(height: 56)),
                      const SliverToBoxAdapter(child: MenuGrid()),
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