// ============================================================
// api_client.dart — แนบ token ให้ทุก request อัตโนมัติ
//
// main.dart ครอบแอปด้วย http.runWithClient(..., AuthHttpClient)
// ทุกที่ที่เรียก http.get / http.post / ... จึงผ่านตัวนี้เอง ไม่ต้องแก้ทีละหน้า
//   - แนบ header  Authorization: Bearer <access token>  (เซิร์ฟเวอร์ใช้ตรวจว่าเป็นใคร)
//   - เซิร์ฟเวอร์ตอบ 401 (token หมดอายุ/ไม่ถูกต้อง) -> ล้างการล็อกอิน แล้วพากลับหน้าล็อกอิน
// ============================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:flutter_myproject/services/auth_server.dart';

/// ใช้พาไปหน้าล็อกอินจากนอก widget (ตอนเจอ 401) ผูกกับ MaterialApp ใน main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthHttpClient extends http.BaseClient {
  /// client ตัวจริงที่ส่ง request ต้องสร้างนอก runWithClient
  /// (ถ้าสร้างข้างใน http.Client() จะได้ AuthHttpClient ตัวเองกลับมา วนไม่จบ)
  final http.Client _inner;

  AuthHttpClient(this._inner);

  /// กันพากลับหน้าล็อกอินซ้ำ เมื่อหลาย request ได้ 401 พร้อมกัน
  static bool _redirecting = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await _inner.send(request);
    if (response.statusCode == 401) await _onUnauthorized();
    return response;
  }

  Future<void> _onUnauthorized() async {
    if (_redirecting) return;
    _redirecting = true;
    try {
      await AuthService.clear();
      // อ่าน context หลัง await แล้วเช็ก mounted (หน้าอาจถูกปิดไประหว่างรอ)
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        const SnackBar(content: Text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่')),
      );
      Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } finally {
      _redirecting = false;
    }
  }

  @override
  void close() => _inner.close();
}
