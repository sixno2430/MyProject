import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../screens/garden/plamvarieties/palm_variety.dart';

class PalmVarietyService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<PalmVariety>> getVarieties(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/varieties'),
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

        // กรณีที่ 1: ส่งมาแบบ { isError: false, data: [...] }
        if (decoded is Map<String, dynamic>) {
          if (decoded['isError'] == true) {
            throw Exception(decoded['errorMessage'] ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์');
          }
          if (decoded['data'] is List) {
            list = decoded['data'] as List;
          }
        } 
        // กรณีที่ 2: ส่งมาเป็น List ตรงๆ [ {...}, {...} ]
        else if (decoded is List) {
          list = decoded;
        }

        return list.map((e) => PalmVariety.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching varieties: $e');
      rethrow;
    }
  }
}