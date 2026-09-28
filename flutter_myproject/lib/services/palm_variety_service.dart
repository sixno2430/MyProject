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