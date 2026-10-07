// ============================================================
// palm_variety_service.dart — เรียก API รายชื่อพันธุ์ปาล์ม
//
// ใช้กับหน้าพันธุ์ปาล์มในโฟลเดอร์ plamvarieties/ (ส่ง token ไปใน header ด้วย)
// พันธุ์แยกตามผู้ใช้: ทุกคำสั่งส่ง user_id ให้เซิร์ฟเวอร์จัดการเฉพาะพันธุ์ของตัวเอง
//   GET /api/varieties  POST /api/varieties  PUT /api/varieties/:id  DELETE /api/varieties/:id
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import '../screens/garden/plamvarieties/palm_variety.dart';

/// เรียก API พันธุ์ปาล์ม
class PalmVarietyService {
  // ใช้ที่อยู่เซิร์ฟเวอร์จาก AppConfig (เดิมใส่ localhost ตายตัว ทำให้ใช้บน Android Emulator ไม่ได้)
  static String get baseUrl => AppConfig.apiBaseUri;

  /// ดึงรายชื่อพันธุ์ปาล์มทั้งหมด (GET /api/varieties)
  /// รองรับทั้งแบบ { data: [...] } และแบบส่ง List มาตรงๆ
  static Future<List<PalmVariety>> getVarieties(String token) async {
    try {
      // พันธุ์แยกตามผู้ใช้ -> ส่ง user_id ไปให้เซิร์ฟเวอร์กรองเฉพาะพันธุ์ของตัวเอง
      final userId = await AuthService.getUserId() ?? '';
      final res = await http.get(
        Uri.parse('$baseUrl/varieties?user_id=$userId'),
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

  /// เพิ่ม (id = null) หรือแก้ไขพันธุ์ปาล์ม — เซิร์ฟเวอร์ตอบ error เป็นภาษาไทย (เช่น ชื่อซ้ำ) จะโยน Exception
  static Future<void> saveVariety({String? id, required String name, String? scientificName}) async {
    final userId = await AuthService.getUserId() ?? '';
    final body = jsonEncode({
      'user_id': userId,
      'variety_name': name,
      'scientific_name': scientificName ?? '',
    });
    const headers = {'Content-Type': 'application/json'};
    final res = id == null
        ? await http.post(Uri.parse('$baseUrl/varieties'), headers: headers, body: body)
        : await http.put(Uri.parse('$baseUrl/varieties/$id'), headers: headers, body: body);
    _check(res);
  }

  /// ลบพันธุ์ปาล์ม (พันธุ์ที่มีแปลงปลูกอยู่ เซิร์ฟเวอร์จะไม่ให้ลบ)
  static Future<void> deleteVariety(String id) async {
    final userId = await AuthService.getUserId() ?? '';
    final res = await http.delete(Uri.parse('$baseUrl/varieties/$id?user_id=$userId'));
    _check(res);
  }

  /// เซิร์ฟเวอร์ตอบ isError -> โยน Exception พร้อมข้อความของเซิร์ฟเวอร์
  static void _check(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is! Map || body['isError'] == true) {
      throw Exception(body is Map ? body['errorMessage'] ?? 'ทำรายการไม่สำเร็จ' : 'ทำรายการไม่สำเร็จ');
    }
  }
}
