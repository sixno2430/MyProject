// ============================================================
// harvest_service.dart — เรียก API การเก็บเกี่ยว
//
// GET /api/harvests, GET /api/harvests/summary, GET /api/shops (รายชื่อร้านสำหรับเลือกขาย)
// POST /api/harvests, PUT/DELETE /api/harvests/:id, PUT /api/harvests/:id/sell (ขายนอกระบบ)
// ทุกคำขอแนบ user_id ของคนที่ล็อกอินอยู่ (+ garden_id / year ถ้ามี)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/api.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/models/harvest.dart';

/// เรียก API การเก็บเกี่ยว (ส่ง user_id ของคนที่ล็อกอินไปทุกครั้ง)
class HarvestService {
  static String get baseUrl => AppConfig.apiBaseUri;

  /// รายชื่อร้านรับซื้อในแอป [{id, name, open}] สำหรับ dropdown (โหลดไม่ได้ = รายการว่าง)
  static Future<List<Map<String, String>>> fetchShops() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shops'));
      final body = jsonDecode(response.body);
      if (body is! Map || body['isError'] == true) return [];
      return (body['data'] as List)
          .map(
            (s) => {
              'id': s['shop_id'].toString(),
              'name': s['shop_name'].toString(),
              'open': (s['status']?.toString().toUpperCase() == 'ACTIVE').toString(),
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// เพิ่ม (id = null) หรือแก้ไขการเก็บเกี่ยว — server ตอบ error เป็นภาษาไทย (เช่น วันที่ขายไม่ถูกต้อง) จะโยน Exception
  static Future<void> saveHarvest(String? id, Map<String, dynamic> fields) async {
    final body = jsonEncode(fields);
    final res = id == null
        ? await http.post(Uri.parse('$baseUrl/harvests'), headers: Api.jsonHeaders, body: body)
        : await http.put(Uri.parse('$baseUrl/harvests/$id'), headers: Api.jsonHeaders, body: body);
    Api.decode(res, 'บันทึกไม่สำเร็จ');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('เกิดข้อผิดพลาดจาก Server');
  }

  /// ลบการเก็บเกี่ยว (ล็อตที่ร้านรับซื้อแล้ว server ไม่ให้ลบ)
  static Future<void> deleteHarvest(String id) async {
    final userId = await AuthService.getUserId();
    final res = await http.delete(Uri.parse('$baseUrl/harvests/$id?user_id=$userId'));
    Api.decode(res);
  }

  /// บันทึกขายนอกระบบให้ล็อตที่รอขาย
  static Future<void> sellOutside(
    String id, {
    required double pricePerKg,
    required String buyerName,
    required String soldDate,
    required String grade,
  }) async {
    final userId = await AuthService.getUserId();
    final res = await http.put(
      Uri.parse('$baseUrl/harvests/$id/sell'),
      headers: Api.jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'price_per_kg': pricePerKg,
        'buyer_name': buyerName,
        'sold_date': soldDate,
        'quality_grade': grade,
      }),
    );
    Api.decode(res);
  }

  /// การเก็บเกี่ยวของผู้ใช้เป็น JSON ดิบ (หน้าการแจ้งเตือนใช้ฟิลด์ที่ HarvestData ไม่มี เช่น rejectedAt)
  static Future<List<Map<String, dynamic>>> fetchHarvestJson(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/harvests?user_id=$userId'));
    return Api.listOf(res.body);
  }

  // สร้าง query ที่มี user_id ของคนที่ล็อกอินอยู่เสมอ (+ garden_id / year ถ้ามี)
  Future<Map<String, String>> _buildQuery(String? gardenId, int? year) async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }
    return {'user_id': userId, 'garden_id': ?gardenId, if (year != null) 'year': '$year'};
  }

  /// ดึงรายการเก็บเกี่ยวของปีที่กำหนด (ไม่ส่ง year = ปีนี้)
  Future<List<HarvestData>> fetchHarvestRecords({String? gardenId, int? year}) async {
    final uri = Uri.parse('$baseUrl/harvests').replace(queryParameters: await _buildQuery(gardenId, year));

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);

      if (resMap is Map) {
        if (resMap['isError'] == false && resMap['data'] != null) {
          final data = resMap['data'];

          if (data is List) {
            return data.map((item) => HarvestData.fromJson(item)).toList();
          }

          if (data is Map) {
            final listData = data['items'] ?? data['harvests'] ?? data['records'] ?? data['rows'];
            if (listData is List) {
              return listData.map((item) => HarvestData.fromJson(item)).toList();
            }
          }

          return [];
        } else {
          throw Exception(resMap['errorMessage'] ?? 'ไม่สามารถดึงข้อมูลได้');
        }
      } else if (resMap is List) {
        return resMap.map((item) => HarvestData.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    }
  }

  /// ดึงข้อมูลสรุปและผลผลิตรายเดือนของปีนี้
  Future<HarvestSummary> fetchHarvestSummary({String? gardenId, int? year}) async {
    final uri = Uri.parse('$baseUrl/harvests/summary').replace(queryParameters: await _buildQuery(gardenId, year));

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      if (resMap is Map) {
        if (resMap['isError'] == false && resMap['data'] != null) {
          return HarvestSummary.fromJson(resMap['data']);
        } else if (resMap['totalQuantityKg'] != null || resMap['total_quantity_kg'] != null) {
          return HarvestSummary.fromJson(resMap as Map<String, dynamic>);
        } else {
          throw Exception(resMap['errorMessage'] ?? 'ไม่สามารถดึงข้อมูลสรุปได้');
        }
      }
      throw Exception('ข้อมูลสรุปรูปแบบไม่ถูกต้อง');
    } else {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    }
  }
}
