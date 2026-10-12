// ============================================================
// care_service.dart — เรียก API การดูแลสวน
//
// GET /api/care-logs?user_id=        รายการดูแลสวนทั้งหมด (server ส่ง array มาตรงๆ)
// GET /api/care-logs/:id             รายการเดียวพร้อมปุ๋ยทุกชนิด (ใช้ตอนเปิดฟอร์มแก้ไข)
// POST /api/care-logs, PUT/DELETE /api/care-logs/:id
// GET /api/fertilizers/used          ชื่อปุ๋ยที่ผู้ใช้เคยบันทึก (รายการแนะนำในฟอร์มใส่ปุ๋ย)
// ทุกคำสั่งแนบ user_id ให้ server ตรวจว่าเป็นแปลงของผู้ใช้คนนี้จริง
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/api.dart';
import 'package:flutter_myproject/services/auth_service.dart';

class CareService {
  /// รายการดูแลสวนทั้งหมดของ userId เป็น JSON ทีละรายการ (หน้าจอใช้ CareLog.fromJson ต่อ)
  static Future<List<Map<String, dynamic>>> fetchCareLogs(String userId) async {
    final res = await http.get(Uri.parse('${Api.base}/care-logs?user_id=$userId'));
    if (res.statusCode != 200) throw Exception('เซิร์ฟเวอร์ตอบกลับด้วยสถานะ ${res.statusCode}');
    return Api.listOf(res.body);
  }

  /// รายการเดียวแบบเต็ม (รวม fertilizer_items และ detail)
  static Future<Map<String, dynamic>> fetchCareLog(String careId) async {
    final userId = await AuthService.getUserId() ?? '';
    final res = await http.get(Uri.parse('${Api.base}/care-logs/$careId?user_id=$userId'));
    return Map<String, dynamic>.from(Api.decode(res, 'โหลดข้อมูลไม่สำเร็จ')['data']);
  }

  /// เพิ่ม (careId = null) หรือแก้ไขรายการ
  static Future<void> saveCareLog(String? careId, Map<String, dynamic> fields) async {
    final body = jsonEncode(fields);
    final res = careId == null
        ? await http.post(Uri.parse('${Api.base}/care-logs'), headers: Api.jsonHeaders, body: body)
        : await http.put(Uri.parse('${Api.base}/care-logs/$careId'), headers: Api.jsonHeaders, body: body);
    Api.decode(res, 'บันทึกไม่สำเร็จ');
  }

  static Future<void> deleteCareLog(String careId) async {
    final userId = await AuthService.getUserId();
    final res = await http.delete(Uri.parse('${Api.base}/care-logs/$careId?user_id=$userId'));
    Api.decode(res);
  }

  /// ชื่อปุ๋ยที่ผู้ใช้คนนี้เคยบันทึก เรียงจากที่ใช้ล่าสุด (โหลดไม่ได้ = รายการว่าง ยังพิมพ์ชื่อเองได้)
  static Future<List<String>> fetchUsedFertilizers() async {
    try {
      final userId = await AuthService.getUserId() ?? '';
      final res = await http.get(Uri.parse('${Api.base}/fertilizers/used?user_id=$userId'));
      return (Api.decode(res)['data'] as List).map((n) => n.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
