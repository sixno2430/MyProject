// ============================================================
// palm_variety_service.dart — เรียก API รายชื่อพันธุ์ปาล์ม
//
// ใช้กับหน้าพันธุ์ปาล์มในโฟลเดอร์ plamvarieties/ (ส่ง token ไปใน header ด้วย)
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import '../screens/garden/plamvarieties/palm_variety.dart';

/// เรียก API พันธุ์ปาล์ม
class PalmVarietyService {
  // ใช้ที่อยู่เซิร์ฟเวอร์จาก AppConfig (เดิมใส่ localhost ตายตัว ทำให้ใช้บน Android Emulator ไม่ได้)
  static String get baseUrl => AppConfig.apiBaseUri;

  /// ดึงรายชื่อพันธุ์ปาล์มทั้งหมด (GET /api/varieties)
  /// รองรับทั้งแบบ { data: [...] } และแบบส่ง List มาตรงๆ
  static Future<List<PalmVariety>> getVarieties(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/varieties'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        List<dynamic> list = [];

        if (decoded is Map<String, dynamic>) {
          if (decoded['isError'] == true) {
            throw Exception(decoded['errorMessage'] ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์');
          }
          final raw = decoded['data'];
          if (raw is List) {
            list = raw;
          } else if (raw is Map<String, dynamic>) {
            list = [raw];
          }
        } else if (decoded is List) {
          list = decoded;
        }

        return list.map((e) => PalmVariety.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getVarieties: $e');
      rethrow;
    }
  }
}