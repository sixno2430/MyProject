// ============================================================
// harvest_service.dart — เรียก API การเก็บเกี่ยว
//
// GET /api/harvests, GET /api/harvests/summary, GET /api/shops (รายชื่อร้านสำหรับเลือกขาย)
// ทุกคำขอแนบ user_id ของคนที่ล็อกอินอยู่ (+ garden_id / year ถ้ามี)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/models/harvest.dart';

/// เรียก API การเก็บเกี่ยว (ส่ง user_id ของคนที่ล็อกอินไปทุกครั้ง)
class HarvestService {
  static String get baseUrl => AppConfig.apiBaseUri;

  // สร้าง query ที่มี user_id ของคนที่ล็อกอินอยู่เสมอ (+ garden_id ถ้ามี)
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
