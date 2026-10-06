// ============================================================
// role_theme.dart — ชุดสีตามบทบาทผู้ใช้
//
//   RoleTheme.farmer = โทนเขียว (ชาวสวน)
//   RoleTheme.shop   = โทนส้ม (ร้านรับซื้อ)
//
// หน้าที่ใช้ร่วมกันทั้งสองฝั่งให้รับ RoleTheme แทนการเขียนสีตายตัว
// วันหลังมีบทบาทเพิ่ม (เช่น Admin) แค่เพิ่มชุดสีใหม่ที่ไฟล์นี้
//
// หมายเหตุ: สีที่มีความหมายในตัว (รายรับ = เขียว, รายจ่าย = แดง) ไม่ได้อยู่ในนี้
// เพราะต้องเหมือนกันทุกบทบาท ไม่งั้นผู้ใช้จะสับสน
// ============================================================

import 'package:flutter/material.dart';

class RoleTheme {
  /// สีหลัก: AppBar, ปุ่ม, ไอคอน, ขอบช่องกรอกตอนพิมพ์
  final Color primary;

  /// สีเข้ม: ต้นสีไล่ของส่วนหัว
  final Color primaryDark;

  /// สีสว่าง: ปลายสีไล่ของปุ่ม
  final Color primaryLight;

  /// สีพื้นอ่อน: ชิป, ป้าย, ปุ่มที่ยังไม่ได้เลือก
  final Color soft;

  /// สีขอบอ่อน
  final Color border;

  /// สีตัวอักษรรองบนพื้นสีเข้ม (คำโปรยใต้ชื่อแอป)
  final Color onDarkAccent;

  /// สีพื้นหลังของหน้า
  final Color background;

  const RoleTheme({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.soft,
    required this.border,
    required this.onDarkAccent,
    required this.background,
  });

  /// สีไล่ของส่วนหัว (บนลงล่าง / ซ้ายไปขวา)
  List<Color> get headerGradient => [primaryDark, primary];

  /// สีไล่ของปุ่มหลัก
  List<Color> get buttonGradient => [primary, primaryLight];

  /// ชาวสวน: โทนเขียว
  static const farmer = RoleTheme(
    primary: Color(0xFF15803D),
    primaryDark: Color(0xFF064E3B),
    primaryLight: Color(0xFF22C55E),
    soft: Color(0xFFF0FDF4),
    border: Color(0xFFBBF7D0),
    onDarkAccent: Color(0xFF86EFAC),
    background: Color(0xFFF4F6F5),
  );

  /// ร้านรับซื้อ: โทนส้มกลาง (ไม่เข้มจนออกน้ำตาล แต่ตัวหนังสือสีขาวยังอ่านชัด)
  static const shop = RoleTheme(
    primary: Color(0xFFEA580C),
    primaryDark: Color(0xFFC2410C),
    primaryLight: Color(0xFFFB923C),
    soft: Color(0xFFFFF7ED),
    border: Color(0xFFFED7AA),
    onDarkAccent: Color(0xFFFFEDD5),
    background: Color(0xFFFFFBF7),
  );

  /// ชุดสีตาม role_id ในฐานข้อมูล (R003 = ร้านรับซื้อ, อื่นๆ = ชาวสวน)
  static RoleTheme ofRole(String? roleId) => roleId == 'R003' ? shop : farmer;

  /// ผสมสีระหว่าง 2 ชุด (t = 0 ได้ a, t = 1 ได้ b) ใช้ทำอนิเมชันเปลี่ยนสีแบบค่อยๆ ไล่
  static RoleTheme lerp(RoleTheme a, RoleTheme b, double t) => RoleTheme(
        primary: Color.lerp(a.primary, b.primary, t)!,
        primaryDark: Color.lerp(a.primaryDark, b.primaryDark, t)!,
        primaryLight: Color.lerp(a.primaryLight, b.primaryLight, t)!,
        soft: Color.lerp(a.soft, b.soft, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        onDarkAccent: Color.lerp(a.onDarkAccent, b.onDarkAccent, t)!,
        background: Color.lerp(a.background, b.background, t)!,
      );
}
