// ============================================================
// garden_service.dart — เรียก API แปลงสวน
//
// GET /api/gardens/:userId   แปลงทั้งหมดของผู้ใช้ (ใช้ทั้งหน้าแปลงสวน และ dropdown เลือกแปลงในฟอร์มอื่น)
// POST /api/gardens          เพิ่มแปลง
// PUT/DELETE /api/gardens/:id แก้ไข / ลบแปลง (server ตรวจว่าเป็นแปลงของผู้ใช้คนนี้จริง)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/api.dart';
import 'package:flutter_myproject/services/auth_service.dart';

class GardenService {
  /// แปลงทั้งหมดของ userId เป็น JSON ทีละแปลง (garden_id, garden_name, area_size, varieties ...)
  /// หน้าที่ต้องการ object ใช้ Garden.fromJson ต่อเอง
  static Future<List<Map<String, dynamic>>> fetchGardens(String userId) async {
    final res = await http.get(Uri.parse('${Api.base}/gardens/$userId'));
    if (res.statusCode != 200) throw Exception('Server Error (${res.statusCode})');
    Api.decode(res, 'เกิดข้อผิดพลาดในการโหลดข้อมูล');
    return Api.listOf(res.body);
  }

  /// แปลงของผู้ใช้สำหรับ dropdown: [{id, name}] (โหลดไม่ได้ = รายการว่าง)
  static Future<List<Map<String, String>>> fetchGardenOptions(String userId) async {
    try {
      final gardens = await fetchGardens(userId);
      return gardens.map((g) => {'id': g['garden_id'].toString(), 'name': g['garden_name'].toString()}).toList();
    } catch (_) {
      return [];
    }
  }

  /// เพิ่มแปลงใหม่ของผู้ใช้ที่ล็อกอินอยู่
  static Future<void> createGarden(Map<String, dynamic> fields) async {
    final userId = await AuthService.getUserId();
    final res = await http.post(
      Uri.parse('${Api.base}/gardens'),
      headers: Api.jsonHeaders,
      body: jsonEncode({'user_id': userId, ...fields}),
    );
    Api.decode(res, 'บันทึกไม่สำเร็จ');
  }

  /// แก้ไขแปลง
  static Future<void> updateGarden(String gardenId, Map<String, dynamic> fields) async {
    final userId = await AuthService.getUserId();
    final res = await http.put(
      Uri.parse('${Api.base}/gardens/$gardenId'),
      headers: Api.jsonHeaders,
      body: jsonEncode({...fields, 'user_id': userId}),
    );
    Api.decode(res);
  }

  /// ลบแปลง (แปลงที่ร้านรับซื้อผลผลิตไปแล้ว server ไม่ให้ลบ)
  static Future<void> deleteGarden(String gardenId) async {
    final userId = await AuthService.getUserId();
    final res = await http.delete(Uri.parse('${Api.base}/gardens/$gardenId?user_id=$userId'));
    Api.decode(res);
  }
}
