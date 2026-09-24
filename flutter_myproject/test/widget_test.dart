import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_myproject/main.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// สร้าง JWT ปลอมสำหรับเทสต์ (ไม่ต้องมี signature จริง เพราะแอปอ่านแค่ exp)
String fakeJwt(DateTime expiry) {
  String enc(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = expiry.millisecondsSinceEpoch ~/ 1000;
  return '${enc({'alg': 'HS256'})}.${enc({'user_id': 'U001', 'exp': exp})}.sig';
}

void main() {
  group('formatNumber', () {
    test('ใส่ comma ทุก 3 หลัก', () {
      expect(formatNumber(1234567), '1,234,567');
      expect(formatNumber(999), '999');
      expect(formatNumber(0), '0');
    });

    test('ตัวเลขติดลบ', () {
      expect(formatNumber(-1500), '-1,500');
    });
  });

  group('formatThaiDate', () {
    test('แสดงวัน เดือน และปี พ.ศ.', () {
      // 24 ก.ย. 2026 เป็นวันพฤหัสบดี
      expect(formatThaiDate(DateTime(2026, 9, 24)), 'พฤหัสบดี, 24 กันยายน 2569');
    });
  });

  group('AuthService.isLoggedIn', () {
    test('ไม่มีข้อมูล = ยังไม่ล็อกอิน', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AuthService.isLoggedIn(), isFalse);
    });

    test('มี user_id และ token ที่ยังไม่หมดอายุ = ล็อกอินอยู่', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 'U001',
        'access_token': fakeJwt(DateTime.now().add(const Duration(hours: 1))),
      });
      expect(await AuthService.isLoggedIn(), isTrue);
    });

    test('token หมดอายุแล้ว = ต้องล็อกอินใหม่', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 'U001',
        'access_token': fakeJwt(DateTime.now().subtract(const Duration(minutes: 1))),
      });
      expect(await AuthService.isLoggedIn(), isFalse);
    });

    test('token รูปแบบผิด = ต้องล็อกอินใหม่', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 'U001',
        'access_token': 'not-a-jwt',
      });
      expect(await AuthService.isLoggedIn(), isFalse);
    });

    test('clear แล้วต้องออกจากระบบ', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 'U001',
        'access_token': fakeJwt(DateTime.now().add(const Duration(hours: 1))),
      });
      await AuthService.clear();
      expect(await AuthService.isLoggedIn(), isFalse);
    });
  });

  testWidgets('ยังไม่ล็อกอิน เปิดแอปแล้วเจอหน้า Login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp(loggedIn: false));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
