// ============================================================
// error_message.dart — แปลง error เป็นข้อความภาษาไทยที่ผู้ใช้อ่านเข้าใจ
//
// เดิมหลายหน้าแสดง error ดิบ เช่น "ClientException: HTTP request failed..." หรือ "FormatException"
// ใช้ friendlyError(e) ทุกที่ที่เอา error ไปแสดงบนจอ (SnackBar / Dialog / ข้อความในหน้า)
// ข้อความภาษาไทยที่เซิร์ฟเวอร์ส่งมา (throw Exception('...')) ยังแสดงตามเดิม แค่ตัดคำว่า Exception ออก
// ============================================================

import 'dart:async';
import 'package:http/http.dart' as http;

const _connectionMessage = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง';

/// ข้อความ error สำหรับแสดงให้ผู้ใช้
String friendlyError(Object? error) {
  if (error == null) return 'เกิดข้อผิดพลาด กรุณาลองใหม่';

  // ต่อเซิร์ฟเวอร์ไม่ได้ (ปิดเซิร์ฟเวอร์อยู่ / ไม่มีเน็ต / ที่อยู่ผิด) -> http แปลงเป็น ClientException
  if (error is http.ClientException) return _connectionMessage;
  if (error is TimeoutException) return 'เซิร์ฟเวอร์ตอบช้าเกินไป กรุณาลองใหม่อีกครั้ง';
  // เซิร์ฟเวอร์ตอบกลับมาไม่ใช่ JSON (เช่นหน้า error HTML ของ Express)
  if (error is FormatException) return 'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  // บางที่ห่อ error ไว้ใน Exception('...$e') อีกชั้น -> ดูจากข้อความแทน
  const connectionHints = ['ClientException', 'SocketException', 'Connection refused', 'Failed host lookup'];
  if (connectionHints.any(text.contains)) return _connectionMessage;
  if (text.contains('TimeoutException')) return 'เซิร์ฟเวอร์ตอบช้าเกินไป กรุณาลองใหม่อีกครั้ง';
  if (text.contains('FormatException')) return 'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';
  return text.isEmpty ? 'เกิดข้อผิดพลาด กรุณาลองใหม่' : text;
}
