import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/activity_list.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/dashboard_header.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/error_view.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/menu_grid.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    setState(_loadDashboard);
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
            return ErrorView(
              error: snapshot.error.toString(),
              onRetry: () => setState(_loadDashboard),
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
