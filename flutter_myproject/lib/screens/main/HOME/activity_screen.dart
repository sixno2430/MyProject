// ============================================================
// activity_screen.dart — หน้า "ประวัติกิจกรรม" ทั้งหมด
//
// เปิดจากปุ่ม "ดูทั้งหมด" บน Dashboard ดึงจาก GET /api/activities/:userId
// กรองตามประเภทได้ และมีปุ่มเพิ่มกิจกรรม
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_card.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_empty_state.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_filter_bar.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/screens/garden/harvest/add_harvest_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/add_gardencare_screen.dart';
import 'package:flutter_myproject/screens/finance/add_transaction_screen.dart';

/// หน้าประวัติกิจกรรม
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'all';
  late Future<List<ActivityItem>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _fetch();
  }

  /// ดึงกิจกรรมทั้งหมดของ user ที่ล็อกอินอยู่
  Future<List<ActivityItem>> _fetch() async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }
    return DashboardService().fetchActivities(userId);
  }

  /// โหลดรายการใหม่ (เช่น หลังเพิ่ม/แก้ไข/ลบ)
  void _reload() {
    setState(() {
      _activitiesFuture = _fetch();
    });
  }

  /// ดึงหน้าจอลงเพื่อโหลดใหม่
  Future<void> _onRefresh() async {
    _reload();
    try {
      await _activitiesFuture;
    } catch (_) {}
  }

  // ปุ่ม "เพิ่มกิจกรรม": เลือกประเภทก่อน แล้วเปิดฟอร์มของประเภทนั้น
  Future<void> _addActivity() async {
    final page = await showModalBottomSheet<Widget>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'เพิ่มกิจกรรม',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Text('🧺', style: TextStyle(fontSize: 24)),
              title: const Text('บันทึกการเก็บเกี่ยว'),
              onTap: () => Navigator.pop(context, const AddHarvestScreen()),
            ),
            ListTile(
              leading: const Text('💊', style: TextStyle(fontSize: 24)),
              title: const Text('บันทึกการดูแลสวน / ใส่ปุ๋ย'),
              onTap: () => Navigator.pop(context, const AddGardenCareScreen()),
            ),
            ListTile(
              leading: const Text('💵', style: TextStyle(fontSize: 24)),
              title: const Text('บันทึกรายรับ-รายจ่าย'),
              onTap: () => Navigator.pop(context, const AddTransactionScreen()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (page == null || !mounted) return;
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (saved == true) _reload();
  }

  /// กรองรายการตามแท็บที่เลือก (ทั้งหมด / เก็บเกี่ยว / ดูแล / รายรับ / รายจ่าย)
  List<ActivityItem> _filterList(List<ActivityItem> list) {
    if (_selectedFilter == 'all') return list;
    return list.where((a) => a.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      // 1. AppBar แบบปกติ ไม่ชนปุ่มย้อนกลับ และไม่บั๊กตอนเลื่อน
      appBar: AppBar(
        title: const Text(
          'ประวัติกิจกรรม',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<ActivityItem>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'โหลดข้อมูลไม่สำเร็จ',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final allActivities = snapshot.data ?? [];
          final filtered = _filterList(allActivities);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF2D6A4F),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Filter Chips
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ActivityFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (val) =>
                        setState(() => _selectedFilter = val),
                  ),
                ),

                // สรุปจำนวน
                Padding(
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
                          child: const Text(
                            'รีเซ็ต',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2D6A4F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // List รายการ
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ActivityEmptyState(filter: _selectedFilter),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => ActivityCard(
                      activity: filtered[index],
                      onChanged: _reload,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      // 2. เปลี่ยนปุ่มเพิ่มกิจกรรมเป็นเครื่องหมาย + กลมๆ
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}