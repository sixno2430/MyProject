// ============================================================
// api.dart — ของกลางที่ service ใช้ร่วมกัน
//
// - Api.base       : ที่อยู่ server (มาจาก config/app_config.dart)
// - Api.jsonHeaders: header สำหรับส่ง body เป็น JSON
// - Api.decode     : อ่านคำตอบรูปแบบ { isError, data, errorMessage }
//                    isError = true -> โยน Exception พร้อมข้อความภาษาไทยจาก server
// - Api.listOf     : ดึงรายการจากคำตอบ (รองรับ API ที่ส่ง array มาตรงๆ เช่น /care-logs)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';

class Api {
  static String get base => AppConfig.apiBaseUri;

  static const jsonHeaders = {'Content-Type': 'application/json'};

  /// แปลงคำตอบเป็น Map ถ้า server ตอบ isError ให้โยน Exception ข้อความจาก server (ไม่มีข้อความ = fallback)
  static Map<String, dynamic> decode(http.Response res, [String fallback = 'ทำรายการไม่สำเร็จ']) {
    final body = jsonDecode(res.body);
    if (body is! Map) throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    if (body['isError'] == true) throw Exception(body['errorMessage'] ?? fallback);
    return Map<String, dynamic>.from(body);
  }

  /// รายการในคำตอบ: { data: [...] } หรือ [...] ตรงๆ (รูปแบบอื่น = รายการว่าง)
  static List<Map<String, dynamic>> listOf(String responseBody) {
    final body = jsonDecode(responseBody);
    final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
