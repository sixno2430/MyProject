// ============================================================
// app_config.dart — ตั้งค่ากลางของแอป
//
// เก็บที่อยู่ (URL) ของเซิร์ฟเวอร์ API ไว้ที่เดียว ทุกหน้าเรียกผ่าน AppConfig.apiBaseUri
// ถ้าย้ายเซิร์ฟเวอร์หรือทดสอบบนมือถือจริง แก้ที่ไฟล์นี้ไฟล์เดียว
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';

/// ค่าตั้งค่ากลางของแอป
class AppConfig {
  /// URL ของ API ตามแพลตฟอร์มที่รัน
  /// - Web / iOS Simulator / macOS: localhost
  /// - Android Emulator: 10.0.2.2 (คือ localhost ของเครื่องที่รัน emulator)
  static String get apiBaseUri {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }
}

