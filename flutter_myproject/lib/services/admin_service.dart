// ============================================================
// admin_service.dart — เรียก API ฝั่งผู้ดูแลระบบ (role R001)
//
// ทุกคำสั่งส่ง admin_id = user_id ของคนที่ล็อกอิน ให้เซิร์ฟเวอร์ตรวจว่าเป็นแอดมินจริง
//   GET /api/admin/overview       ตัวเลขภาพรวมระบบ
//   GET/POST/PUT /api/admin/users รายชื่อ / เพิ่ม / แก้ไขผู้ใช้, PUT /users/:id/status ระงับหรือเปิดใช้
//   GET /api/admin/logs           ประวัติการใช้งาน (ตาราง user_log)
//   GET /api/admin/report         รายงานระบบ (?months=12 = ย้อนหลัง 1 ปี, ไม่ส่ง = 6 เดือน)
// model อยู่ใน models/admin.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/models/admin.dart';

/// เรียก API ของแอดมิน
class AdminService {
  static String get _base => '${AppConfig.apiBaseUri}/admin';

  static Future<String> _adminId() async => await AuthService.getUserId() ?? '';

  static Future<AdminOverview> getOverview() async {
    final res = await http.get(Uri.parse('$_base/overview?admin_id=${await _adminId()}'));
    return AdminOverview.fromJson(_data(res) as Map<String, dynamic>);
  }

  static Future<List<AdminUser>> getUsers() async {
    final res = await http.get(Uri.parse('$_base/users?admin_id=${await _adminId()}'));
    return (_data(res) as List).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// เพิ่มผู้ใช้ (id = null) หรือแก้ไข — แก้ไขแล้วเว้นรหัสผ่านว่าง = คงรหัสเดิม
  static Future<void> saveUser({
    String? id,
    required String roleId,
    required String fullName,
    required String username,
    required String citizenId,
    required String phone,
    required String password,
  }) async {
    final body = jsonEncode({
      'admin_id': await _adminId(),
      'role_id': roleId,
      'full_name': fullName,
      'username': username,
      'citizen_id': citizenId,
      'phone': phone,
      'password': password,
    });
    const headers = {'Content-Type': 'application/json'};
    final res = id == null
        ? await http.post(Uri.parse('$_base/users'), headers: headers, body: body)
        : await http.put(Uri.parse('$_base/users/$id'), headers: headers, body: body);
    _data(res);
  }

  /// ระงับ (suspended = true) หรือเปิดใช้บัญชี
  static Future<void> setSuspended(String userId, bool suspended) async {
    final res = await http.put(
      Uri.parse('$_base/users/$userId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admin_id': await _adminId(), 'status': suspended ? 'suspended' : 'active'}),
    );
    _data(res);
  }

  /// ประวัติการใช้งาน กรองตามการกระทำ / ผู้ใช้ได้
  static Future<List<AdminLog>> getLogs({String? action, String? userId}) async {
    final query = {
      'admin_id': await _adminId(),
      'action': ?action, // ? = ใส่เฉพาะตอนไม่เป็น null
      'user_id': ?userId,
    };
    final res = await http.get(Uri.parse('$_base/logs').replace(queryParameters: query));
    return (_data(res) as List).map((e) => AdminLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// months: 6 หรือ 12 เดือนย้อนหลัง
  static Future<AdminReport> getReport({int months = 6}) async {
    final res = await http.get(Uri.parse('$_base/report?admin_id=${await _adminId()}&months=$months'));
    return AdminReport.fromJson(_data(res) as Map<String, dynamic>);
  }

  /// เซิร์ฟเวอร์ตอบ isError -> โยน Exception พร้อมข้อความของเซิร์ฟเวอร์, ไม่งั้นคืน data
  static dynamic _data(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is! Map || body['isError'] == true) {
      throw Exception(body is Map ? body['errorMessage'] ?? 'ทำรายการไม่สำเร็จ' : 'ทำรายการไม่สำเร็จ');
    }
    return body['data'];
  }
}
