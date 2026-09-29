// ============================================================
// profile_service.dart — เรียก API ข้อมูลโปรไฟล์ผู้ใช้
//
// ดึงและแก้ไขข้อมูลส่วนตัว (ชื่อ, เบอร์โทร ฯลฯ) ผ่าน /api/profile/:userId
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';

/// รวมฟังก์ชันเรียก API โปรไฟล์ (เรียกแบบ static)
class ProfileService {
  /// ใช้ apiBaseUri จาก AppConfig โดยตรง
  /// AppConfig.apiBaseUri = "http://localhost:3000/api"
  static String get _baseUri => AppConfig.apiBaseUri;

  /// ดึงข้อมูลโปรไฟล์
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final url = '$_baseUri/profile/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'ไม่สามารถดึงข้อมูลได้ (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e',
      };
    }
  }

  /// อัปเดตข้อมูลโปรไฟล์ (เช่น full_name, phone)
  static Future<Map<String, dynamic>> updateProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      final url = '$_baseUri/profile/$userId';

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'บันทึกข้อมูลไม่สำเร็จ (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e',
      };
    }
  }
}