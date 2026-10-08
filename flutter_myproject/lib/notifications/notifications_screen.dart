// ============================================================
// notifications_screen.dart — หน้าการแจ้งเตือน
//
// สร้างการแจ้งเตือนจากข้อมูลจริงของ user (ไม่มีตารางแจ้งเตือนในฐานข้อมูล):
//   0) ร้านในแอปรับซื้อแล้ว ภายใน 7 วัน -> แตะแล้วไปหน้าเก็บเกี่ยว
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
import 'package:flutter_myproject/utils/error_message.dart';

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

  /// แจ้งเตือน "ขายให้ร้านแล้ว" ย้อนหลังกี่วัน
  static const int soldNoticeDays = 7;

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 0) ขายให้ร้านในแอปแล้ว (มีวันที่รับซื้อ) ภายใน 7 วัน ใหม่สุดก่อน
    //    ให้เกษตรกรรู้ว่าร้านบันทึกรับซื้อแล้ว ผลผลิตเปลี่ยนเป็น "ขายแล้ว" และรายได้เข้าหน้าการเงิน
    final recentSales = harvests.where((h) {
      // เฉพาะที่ร้านในแอปรับซื้อ (ขายนอกระบบเกษตรกรบันทึกเอง ไม่ต้องแจ้ง) MariaDB ส่ง boolean มาเป็น 0/1
      if (h['purchasedByShop'] != true && h['purchasedByShop'] != 1) return false;
      final d = DateTime.tryParse(h['soldDate']?.toString() ?? '');
      return d != null && today.difference(d).inDays <= soldNoticeDays;
    }).toList()
      ..sort((a, b) => b['soldDate'].toString().compareTo(a['soldDate'].toString()));
    for (final h in recentSales) {
      final kg = (h['quantityKg'] as num?)?.toDouble() ?? 0;
      final total = (h['totalPrice'] as num?)?.toDouble() ?? 0;
      final d = DateTime.parse(h['soldDate'].toString());
      final days = today.difference(d).inDays;
      list.add(AppNotification(
        icon: '🤝',
        title: 'ขาย ${h['code'] ?? h['id']} ให้ ${h['buyer']} แล้ว',
        desc: '${kg.toStringAsFixed(0)} กก. · ${total.toStringAsFixed(0)} บาท · '
            '${days == 0 ? 'วันนี้' : days == 1 ? 'เมื่อวาน' : '$days วันก่อน'}',
        color: const Color(0xFF2E7D32),
        destination: () => const HarvestScreen(),
      ));
    }

    // 0.1) ร้านที่เลือกไว้ไม่รับล็อต ภายใน 7 วัน (เกษตรกรต้องเลือกร้านใหม่)
    for (final h in harvests) {
      final by = h['rejectedBy']?.toString() ?? '';
      final d = DateTime.tryParse(h['rejectedAt']?.toString() ?? '');
      if (by.isEmpty || d == null || today.difference(d).inDays > soldNoticeDays) continue;
      list.add(AppNotification(
        icon: '🚫',
        title: '$by ไม่รับ ${h['code'] ?? h['id']}',
        desc: 'เหตุผล: ${h['rejectReason'] ?? '-'} · แตะเพื่อเลือกร้านใหม่',
        color: const Color(0xFFDC2626),
        destination: () => const HarvestScreen(),
      ));
    }

    // 1) ผลผลิตรอขาย
    for (final h in harvests.where((h) => h['status'] != 'sold')) {
      final kg = (h['quantityKg'] as num?)?.toDouble() ?? 0;
      list.add(AppNotification(
        icon: '🏷️',
        title: 'ผลผลิตรอขาย ${h['code'] ?? h['id']}',
        // เลือกร้านไว้แล้ว = รอร้านยืนยัน (บันทึกขายเองไม่ได้), ยังไม่เลือก = เลือกร้านหรือขายนอกระบบได้
        desc: (h['shopId']?.toString() ?? '').isNotEmpty
            ? '${h['plotName']} · ${kg.toStringAsFixed(0)} กก. · ${h['buyer']}'
            : '${h['plotName']} · ${kg.toStringAsFixed(0)} กก. · ยังไม่เลือกร้าน แตะเพื่อเลือกร้านหรือบันทึกขาย',
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
                'โหลดการแจ้งเตือนไม่สำเร็จ\n${friendlyError(snapshot.error)}',
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
