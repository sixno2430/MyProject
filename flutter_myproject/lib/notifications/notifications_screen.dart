// ============================================================
// notifications_screen.dart — หน้าการแจ้งเตือน
//
// สร้างการแจ้งเตือนจากข้อมูลจริงของ user (ไม่มีตารางแจ้งเตือนในฐานข้อมูล):
//   1) ผลผลิตที่ยังรอขาย            -> แตะแล้วไปหน้าเก็บเกี่ยว
//   2) แปลงที่ไม่มีบันทึกการดูแลเกิน 30 วัน -> แตะแล้วไปหน้าดูแลสวน
// เปิดจาก: กระดิ่งบน Dashboard และเมนู "การแจ้งเตือน" ในหน้าโปรไฟล์
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/screens/garden/harvest/harvest_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/gardencare_screen.dart';

/// การแจ้งเตือน 1 รายการ
class AppNotification {
  final String icon;
  final String title;
  final String desc;
  final Color color;

  /// หน้าที่จะเปิดเมื่อแตะ
  final Widget Function() destination;

  AppNotification({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.destination,
  });
}

/// หน้ารายการแจ้งเตือน
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryGreen = Color(0xFF2D6A4F);

  /// ไม่มีบันทึกการดูแลนานกว่านี้ (วัน) จะแจ้งเตือน
  static const int careReminderDays = 30;

  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildNotifications();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _buildNotifications();
    });
    try {
      await _future;
    } catch (_) {}
  }

  /// ดึงข้อมูลเก็บเกี่ยว / แปลง / การดูแล แล้วแปลงเป็นรายการแจ้งเตือน
  Future<List<AppNotification>> _buildNotifications() async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }
    final base = AppConfig.apiBaseUri;
    final results = await Future.wait([
      http.get(Uri.parse('$base/harvests?user_id=$userId')),
      http.get(Uri.parse('$base/gardens/$userId')),
      http.get(Uri.parse('$base/care-logs?user_id=$userId')),
    ]);

    List<dynamic> dataOf(http.Response r) {
      final body = jsonDecode(r.body);
      if (body is List) return body; // care-logs ส่ง array มาตรงๆ
      if (body is Map && body['data'] is List) return body['data'];
      return [];
    }

    final harvests = dataOf(results[0]);
    final gardens = dataOf(results[1]);
    final careLogs = dataOf(results[2]);
    final list = <AppNotification>[];

    // 1) ผลผลิตรอขาย
    for (final h in harvests.where((h) => h['status'] != 'sold')) {
      final kg = (h['quantityKg'] as num?)?.toDouble() ?? 0;
      list.add(AppNotification(
        icon: '🏷️',
        title: 'ผลผลิตรอขาย ${h['code'] ?? h['id']}',
        desc: '${h['plotName']} · ${kg.toStringAsFixed(0)} กก. · แตะเพื่อบันทึกการขาย',
        color: const Color(0xFFE65100),
        destination: () => const HarvestScreen(),
      ));
    }

    // 2) แปลงที่ไม่ได้ดูแลนาน: หาวันที่ดูแลล่าสุดของแต่ละแปลง
    final lastCare = <String, DateTime>{};
    for (final c in careLogs) {
      final id = c['garden_id']?.toString();
      final d = DateTime.tryParse(c['record_date']?.toString() ?? '')?.toLocal();
      if (id == null || d == null) continue;
      if (lastCare[id] == null || d.isAfter(lastCare[id]!)) lastCare[id] = d;
    }
    final now = DateTime.now();
    for (final g in gardens) {
      final id = g['garden_id']?.toString();
      final name = g['garden_name']?.toString() ?? 'แปลงสวน';
      final last = lastCare[id];
      if (last == null) {
        list.add(AppNotification(
          icon: '🌱',
          title: 'ยังไม่มีบันทึกการดูแล $name',
          desc: 'เริ่มบันทึกการใส่ปุ๋ย / ตัดแต่ง เพื่อติดตามการดูแลแปลง',
          color: primaryGreen,
          destination: () => const GardenCareScreen(),
        ));
      } else if (now.difference(last).inDays > careReminderDays) {
        list.add(AppNotification(
          icon: '🌴',
          title: 'ถึงเวลาดูแล $name',
          desc: 'ไม่มีบันทึกการดูแลมา ${now.difference(last).inDays} วันแล้ว',
          color: primaryGreen,
          destination: () => const GardenCareScreen(),
        ));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('การแจ้งเตือน', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildMessage(
                'โหลดการแจ้งเตือนไม่สำเร็จ\n${snapshot.error.toString().replaceFirst('Exception: ', '')}',
              );
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return _buildMessage('🎉 ไม่มีการแจ้งเตือน\nทุกอย่างเรียบร้อยดี');
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: items.map(_buildNotificationItem).toList(),
            );
          },
        ),
      ),
    );
  }

  /// ข้อความกลางจอ (ยังเลื่อนลงเพื่อโหลดใหม่ได้)
  Widget _buildMessage(String text) {
    return ListView(
      children: [
        const SizedBox(height: 160),
        Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.6),
          ),
        ),
      ],
    );
  }

  /// การ์ดแจ้งเตือน 1 รายการ แตะแล้วเปิดหน้าที่เกี่ยวข้อง กลับมาแล้วโหลดใหม่
  Widget _buildNotificationItem(AppNotification n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => n.destination()));
            _reload();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(n.icon, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: n.color),
                      ),
                      const SizedBox(height: 2),
                      Text(n.desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
