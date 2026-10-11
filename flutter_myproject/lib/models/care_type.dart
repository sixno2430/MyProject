// ============================================================
// care_type.dart — ประเภทกิจกรรมการดูแลสวน (ใช้ร่วมกันทั้งหน้ารายการ ฟอร์ม การ์ดกิจกรรม และหน้าการเงิน)
//
// type ตรงกับค่า action_type ในตาราง palm_care
// แต่ละประเภทกำหนดว่าฟอร์มต้องถามอะไร (ฟอร์มจึงหน้าตาไม่เหมือนกันทุกประเภท):
//   - ใส่ปุ๋ย     : รายการปุ๋ยหลายชนิด (ชื่อ + ปริมาณ + หน่วย) กด + เพิ่มได้ — ดู screens/garden/gardencare/add_gardencare_screen.dart
//   - อื่นๆ ทุกประเภท: ช่องรายละเอียด (detail) + ปริมาณพร้อมหน่วยที่เลือกได้
// ============================================================

import 'package:flutter/material.dart';

/// ประเภทกิจกรรม 1 แบบ
class CareType {
  final String type; // ค่าที่เก็บในฐานข้อมูล
  final String label; // ชื่อภาษาไทย
  final String emoji;
  final Color color;
  final String unit; // หน่วยเริ่มต้นของ "ปริมาณ"

  /// หน่วยที่เลือกได้ (ตัวแรก = ค่าเริ่มต้น) ว่าง = ไม่มีช่องปริมาณ
  final List<String> units;

  /// ชื่อช่องปริมาณ เช่น "จำนวนต้นที่ตัดแต่ง"
  final String quantityLabel;

  /// ช่องรายละเอียดเฉพาะประเภท (null = ไม่มี) เช่น "วิธีให้น้ำ"
  final String? detailLabel;

  /// ตัวเลือกสำเร็จรูปของรายละเอียด (null = พิมพ์เอง)
  final List<String>? detailOptions;
  final String? detailHint;
  final bool detailRequired;

  const CareType(
    this.type,
    this.label,
    this.emoji,
    this.color,
    this.unit, {
    this.units = const [],
    this.quantityLabel = 'ปริมาณ',
    this.detailLabel,
    this.detailOptions,
    this.detailHint,
    this.detailRequired = false,
  });

  /// สีพื้นอ่อนๆ ของประเภทนี้
  Color get bgColor => color.withValues(alpha: 0.12);

  bool get hasQuantity => units.isNotEmpty;
}

const List<CareType> careTypes = [
  CareType('fertilizer', 'ใส่ปุ๋ย', '💊', Color(0xFF43A047), 'กก.'),
  CareType(
    'pruning',
    'ตัดแต่ง',
    '✂️',
    Color(0xFFFB8C00),
    'ต้น',
    units: ['ต้น'],
    quantityLabel: 'จำนวนต้นที่ตัดแต่ง',
    detailLabel: 'ลักษณะงาน',
    detailOptions: ['ตัดแต่งทางใบ', 'ตัดทางใบแห้ง/เป็นโรค', 'ตัดช่อดอก/ทะลายเสีย'],
  ),
  CareType(
    'weeding',
    'กำจัดวัชพืช',
    '🌿',
    Color(0xFF8E24AA),
    'ไร่',
    units: ['ไร่', 'แปลง'],
    quantityLabel: 'พื้นที่ที่ดำเนินการ',
    detailLabel: 'วิธีกำจัด',
    detailOptions: ['ตัดหญ้า', 'ฉีดยาฆ่าหญ้า', 'ถอนด้วยมือ'],
  ),
  CareType(
    'watering',
    'ให้น้ำ',
    '💧',
    Color(0xFF1E88E5),
    'ครั้ง',
    units: ['ครั้ง', 'ชั่วโมง', 'ลิตร'],
    quantityLabel: 'ปริมาณการให้น้ำ',
    detailLabel: 'วิธีให้น้ำ',
    detailOptions: ['สปริงเกอร์', 'ระบบน้ำหยด', 'สายยาง', 'รถบรรทุกน้ำ'],
  ),
  CareType(
    'spraying',
    'พ่นยา',
    '🧴',
    Color(0xFFE53935),
    'ลิตร',
    units: ['ลิตร', 'ซีซี', 'ถัง'],
    quantityLabel: 'ปริมาณสารที่ใช้',
    detailLabel: 'ชื่อสาร/ยาที่ใช้',
    detailHint: 'เช่น คลอร์ไพริฟอส (กำจัดด้วงแรด)',
    detailRequired: true,
  ),
  CareType(
    'other',
    'อื่นๆ',
    '🛠️',
    Color(0xFF607D8B),
    'รายการ',
    detailLabel: 'กิจกรรมที่ทำ',
    detailHint: 'เช่น ซ่อมทางเข้าสวน, ปลูกซ่อมต้นที่ตาย',
    detailRequired: true,
  ),
];

/// หน่วยที่เลือกได้สำหรับปุ๋ยแต่ละชนิด
const List<String> fertilizerUnits = ['กก.', 'กระสอบ', 'ลิตร'];

/// หาประเภทจากค่าในฐานข้อมูล (ไม่รู้จัก/ว่าง = "อื่นๆ")
CareType careTypeOf(String? type) => careTypes.firstWhere((t) => t.type == type, orElse: () => careTypes.last);
