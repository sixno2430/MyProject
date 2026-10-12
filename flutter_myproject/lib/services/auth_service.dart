// ============================================================
// auth_service.dart — การล็อกอินและข้อมูลการล็อกอินที่เก็บในเครื่อง
//
// เก็บ/อ่าน/ลบ user_id และ access token ผ่าน SharedPreferences
// ทุกหน้าที่ต้องรู้ว่าใครล็อกอินอยู่ จะเรียก AuthService.getUserId()
// เรียก API: POST /api/authen_request (ล็อกอิน), POST /api/access_request (แลก token),
//            POST /api/register (สมัคร), PUT /api/user/:id/password (เปลี่ยนรหัสผ่าน)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_myproject/services/api.dart';

/// รวมฟังก์ชันจัดการสถานะการล็อกอิน (เรียกแบบ static ไม่ต้องสร้าง object)
class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'access_token';

  /// เก็บ user_id ตอน login
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// ดึง user_id คนที่ล็อคอินอยู่
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// เก็บ token
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// ดึง token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// เช็กว่ายังล็อกอินอยู่ไหม: ต้องมี user_id และ token ที่ยังไม่หมดอายุ
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    final token = await getToken();
    if (userId == null || userId.isEmpty || token == null || token.isEmpty) {
      return false;
    }
    return !_isTokenExpired(token);
  }

  /// อ่านเวลาหมดอายุ (exp) จากส่วน payload ของ JWT
  /// JWT = header.payload.signature โดย payload เป็น JSON ที่เข้ารหัส base64url
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      if (exp is! int) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  static const _requestTimeout = Duration(seconds: 10);
  static const _jsonUtf8 = {'Content-Type': 'application/json; charset=UTF-8'};

  /// ขั้นที่ 1 ของการล็อกอิน: ตรวจ username/password และบทบาทที่เลือก
  /// คืน (isError, authenToken, userId, roleId, errorMessage) — server ไม่ตอบใน 10 วินาที = TimeoutException
  static Future<(bool, String, String, String, String)> authenRequest(
    String username,
    String password,
    String roleId,
  ) async {
    final response = await http
        .post(
          Uri.parse('${Api.base}/authen_request'),
          headers: _jsonUtf8,
          body: jsonEncode({'username': username, 'password': password, 'role_id': roleId}),
        )
        .timeout(_requestTimeout);
    final json = jsonDecode(response.body);
    return (
      json['isError'] as bool,
      json['data'] as String? ?? '',
      json['user_id'] as String? ?? '',
      json['role_id'] as String? ?? '',
      json['errorMessage'] as String? ?? '',
    );
  }

  /// ขั้นที่ 2 ของการล็อกอิน: แลก token จากขั้นที่ 1 เป็น access token
  static Future<({bool isError, String errorMessage, String data})> accessRequest(String token) async {
    final response = await http
        .post(Uri.parse('${Api.base}/access_request'), headers: _jsonUtf8, body: jsonEncode({'token': token}))
        .timeout(_requestTimeout);
    final json = jsonDecode(response.body);
    return (
      isError: json['isError'] as bool,
      errorMessage: json['errorMessage'] as String? ?? '',
      data: json['data'] as String? ?? '',
    );
  }

  /// สมัครสมาชิก — ไม่สำเร็จโยน Exception พร้อมข้อความจาก server (เช่น ชื่อผู้ใช้ซ้ำ)
  static Future<void> register(Map<String, dynamic> fields) async {
    final response = await http.post(
      Uri.parse('${Api.base}/register'),
      headers: {..._jsonUtf8, 'Accept': 'application/json'},
      body: jsonEncode(fields),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('เซิร์ฟเวอร์ตอบกลับผิดพลาด (Status: ${response.statusCode})');
    }
    Api.decode(response, 'สมัครไม่สำเร็จ');
  }

  /// เปลี่ยนรหัสผ่าน (server ตรวจรหัสเดิมอีกครั้ง)
  static Future<void> changePassword(String userId, String oldPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('${Api.base}/user/$userId/password'),
      headers: Api.jsonHeaders,
      body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
    );
    Api.decode(response, 'เปลี่ยนรหัสผ่านไม่สำเร็จ');
  }

  /// ล้างข้อมูลตอน logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenKey);
  }
}
