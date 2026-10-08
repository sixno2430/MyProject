// ทดสอบ friendlyError: error ดิบต้องกลายเป็นข้อความภาษาไทยที่ผู้ใช้อ่านเข้าใจ
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/utils/error_message.dart';

void main() {
  test('ต่อเซิร์ฟเวอร์ไม่ได้ (ClientException) -> ข้อความเชื่อมต่อ', () {
    final msg = friendlyError(http.ClientException('Connection refused', Uri.parse('http://localhost:3000/api/x')));
    expect(msg, contains('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'));
    expect(msg, isNot(contains('ClientException')));
  });

  test('error ที่ห่อไว้ใน Exception อีกชั้นก็ยังจับได้', () {
    expect(friendlyError(Exception('SocketException: Failed host lookup')), contains('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'));
  });

  test('หมดเวลา / ข้อมูลไม่ใช่ JSON', () {
    expect(friendlyError(TimeoutException('x')), contains('ตอบช้าเกินไป'));
    expect(friendlyError(const FormatException('Unexpected character <')), contains('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
  });

  test('ข้อความภาษาไทยจากเซิร์ฟเวอร์แสดงตามเดิม แค่ตัด Exception: ออก', () {
    expect(friendlyError(Exception('ผลผลิตนี้ขายไปแล้ว')), 'ผลผลิตนี้ขายไปแล้ว');
  });

  test('null / ว่าง -> ข้อความทั่วไป', () {
    expect(friendlyError(null), contains('ลองใหม่'));
    expect(friendlyError(Exception('')), contains('ลองใหม่'));
  });
}
