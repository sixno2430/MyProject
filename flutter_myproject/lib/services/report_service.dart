// ============================================================
// report_service.dart — เรียก API รายงานสรุปของเกษตรกร
//
// GET /api/report/:userId?year=2026 (&month=10 = รายเดือน)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/models/report.dart';

/// เรียก API รายงาน
class ReportService {
  /// ดึงรายงานของปีที่กำหนด (ส่ง month = รายงานของเดือนนั้น) สำหรับ user ที่ล็อกอินอยู่
  static Future<YearlyReport> fetchYearly(int year, {int? month}) async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUri}/report/$userId?year=$year${month == null ? '' : '&month=$month'}'),
    );
    if (response.statusCode != 200) {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    if (body['isError'] == true) {
      throw Exception(body['errorMessage'] ?? 'โหลดรายงานไม่สำเร็จ');
    }
    return YearlyReport.fromJson(body['data']);
  }
}
