import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';

class ProfileService {
  /// ใช้ apiBaseUri จาก AppConfig โดยตรง
  /// AppConfig.apiBaseUri = "http://localhost:3000/api"
  /// ดังนั้น endpoint จะเป็น: http://localhost:3000/api/profile/U001
  static String get _baseUri => AppConfig.apiBaseUri;

  /// ดึงข้อมูลโปรไฟล์
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final url = '$_baseUri/profile/$userId';

      // 🔍 Debug: แสดง URL ที่เรียก
      if (kDebugMode) {
        print('🔵 [ProfileService] GET $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      // 🔍 Debug: แสดง Response
      if (kDebugMode) {
        print('🟢 [ProfileService] Status: ${response.statusCode}');
        print('🟢 [ProfileService] Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'ไม่สามารถดึงข้อมูลได้ (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [ProfileService] Error: $e');
      }
      return {
        'success': false,
        'message': 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e',
      };
    }
  }
}