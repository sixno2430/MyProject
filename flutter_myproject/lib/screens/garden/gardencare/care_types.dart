// ============================================================
// care_types.dart — ประเภทกิจกรรมการดูแลสวน (ใช้ร่วมกันทั้งหน้ารายการและฟอร์ม)
//
// type ตรงกับค่า action_type ในตาราง palm_care
// ============================================================

import 'package:flutter/material.dart';

/// ประเภทกิจกรรม 1 แบบ
class CareType {
  final String type; // ค่าที่เก็บในฐานข้อมูล
  final String label; // ชื่อภาษาไทย
  final String emoji;
  final Color color;
  final String unit; // หน่วยของ "ปริมาณ"

  const CareType(this.type, this.label, this.emoji, this.color, this.unit);

  /// สีพื้นอ่อนๆ ของประเภทนี้
  Color get bgColor => color.withValues(alpha: 0.12);
}

const List<CareType> careTypes = [
  CareType('fertilizer', 'ใส่ปุ๋ย', '💊', Color(0xFF43A047), 'กก.'),
  CareType('pruning', 'ตัดแต่ง', '✂️', Color(0xFFFB8C00), 'ต้น'),
  CareType('weeding', 'กำจัดวัชพืช', '🌿', Color(0xFF8E24AA), 'แปลง'),
  CareType('watering', 'ให้น้ำ', '💧', Color(0xFF1E88E5), 'ครั้ง'),
  CareType('spraying', 'พ่นยา', '🧴', Color(0xFFE53935), 'ครั้ง'),
  CareType('other', 'อื่นๆ', '🛠️', Color(0xFF607D8B), 'รายการ'),
];

/// หาประเภทจากค่าในฐานข้อมูล (ไม่รู้จัก/ว่าง = "อื่นๆ")
CareType careTypeOf(String? type) =>
    careTypes.firstWhere((t) => t.type == type, orElse: () => careTypes.last);
