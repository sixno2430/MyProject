import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp is! int) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  /// ล้างข้อมูลตอน logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenKey);
  }
}