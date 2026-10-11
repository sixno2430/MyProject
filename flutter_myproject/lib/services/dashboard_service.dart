// ============================================================
// dashboard_service.dart — ข้อมูลหน้า Dashboard และกิจกรรม
//
// DashboardService: เรียก API /dashboard และ /activities
// model (ActivityItem, DashboardData) อยู่ใน models/activity.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/models/activity.dart';

/// เรียก API ที่เกี่ยวกับหน้า Dashboard
class DashboardService {
  static String get baseUrl => AppConfig.apiBaseUri;

  /// ดึงข้อมูลสรุปของ Dashboard ของ user คนนี้ (GET /dashboard/:userId)
  Future<DashboardData> fetchDashboard(String userId) async {
    final uri = Uri.parse('$baseUrl/dashboard/$userId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('เชื่อมต่อ server ไม่สำเร็จ (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['isError'] == true) {
      throw Exception(body['errorMessage'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
    }

    return DashboardData.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// ประวัติกิจกรรมทั้งหมดของ user
  Future<List<ActivityItem>> fetchActivities(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/activities/$userId'));
    if (response.statusCode != 200) {
      throw Exception('เชื่อมต่อ server ไม่สำเร็จ (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['isError'] == true) {
      throw Exception(body['errorMessage'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
    }
    return (body['data'] as List<dynamic>).map((e) => ActivityItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
