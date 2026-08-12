import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_card.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_empty_state.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_filter_bar.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'all';
  late Future<List<ActivityItem>> _activitiesFuture;

  //@override
  // void initState() {
  //   super.initState();
  //   _loadActivities();
  // }

  // void _loadActivities() {
  //   // TODO: เปลี่ยนเป็น service จริงที่ดึงจาก API/DB
  //   _activitiesFuture = DashboardService().fetchActivities();
  // }

  // Future<void> _onRefresh() async {
  //   setState(_loadActivities);
  //   await _activitiesFuture;
  // }

  List<ActivityItem> _filterList(List<ActivityItem> list) {
    if (_selectedFilter == 'all') return list;
    return list.where((a) => a.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<List<ActivityItem>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('โหลดข้อมูลไม่สำเร็จ', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  // TextButton.icon(
                  //   onPressed: _onRefresh,
                  //   icon: const Icon(Icons.refresh),
                  //   label: const Text('ลองใหม่'),
                  // ),
                ],
              ),
            );
          }

          final allActivities = snapshot.data ?? [];
          final filtered = _filterList(allActivities);

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: const Color(0xFF2D6A4F),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: const Text(
                    'ประวัติกิจกรรม',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ActivityFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (val) => setState(() => _selectedFilter = val),
                  ),
                ),
              ),

              // Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'พบ ${filtered.length} รายการ',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (_selectedFilter != 'all')
                        GestureDetector(
                          onTap: () => setState(() => _selectedFilter = 'all'),
                          child: Text(
                            'รีเซ็ต',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF2D6A4F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: ActivityEmptyState(filter: _selectedFilter),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ActivityCard(activity: filtered[index]),
                      childCount: filtered.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: ไปหน้าเพิ่มกิจกรรม
        },
        backgroundColor: const Color(0xFF2D6A4F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('เพิ่มกิจกรรม', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
