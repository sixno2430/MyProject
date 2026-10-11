// ============================================================
// care_log.dart — model รายการดูแลสวน 1 รายการ (แปลงจาก JSON ของ GET /api/care-logs)
//
// ใส่ปุ๋ย: fertilizerName = ชื่อปุ๋ยทุกชนิดในรอบนั้น, กิจกรรมอื่น: detail = วิธีให้น้ำ / ชื่อสารที่พ่น ฯลฯ
// ============================================================

import 'package:flutter_myproject/models/care_type.dart';

/// รายการดูแลสวน 1 รายการ (แปลงจาก JSON ของ API แล้ว)
class CareLog {
  final String careId;
  final CareType type;
  final String gardenName;
  final String? fertilizerName;
  final String note;
  final String detail; // รายละเอียดตามประเภท เช่น วิธีให้น้ำ, ชื่อสารที่พ่น
  final double quantity;
  final String unit;
  final double cost;
  final DateTime date;
  final Map<String, dynamic> raw; // ข้อมูลดิบไว้ส่งให้หน้าแก้ไข

  CareLog({
    required this.careId,
    required this.type,
    required this.gardenName,
    required this.fertilizerName,
    required this.note,
    required this.detail,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.date,
    required this.raw,
  });

  factory CareLog.fromJson(Map<String, dynamic> j) {
    // ใส่ปุ๋ย: action_type = fertilizer หรือรายการเก่าที่มี fertilizer_id
    // fertilizer_name จากเซิร์ฟเวอร์ = ชื่อปุ๋ยทุกชนิดในรอบนั้น คั่นด้วย comma
    final hasFertilizer =
        j['action_type'] == 'fertilizer' || (j['fertilizer_id'] != null && j['fertilizer_id'].toString().isNotEmpty);
    // รายการเก่าที่ไม่มี action_type -> "อื่นๆ"
    final type = hasFertilizer ? careTypeOf('fertilizer') : careTypeOf(j['action_type']?.toString());
    return CareLog(
      careId: j['care_id'].toString(),
      type: type,
      gardenName: j['garden_name']?.toString() ?? 'ไม่ระบุแปลง',
      fertilizerName: hasFertilizer ? j['fertilizer_name']?.toString() : null,
      note: j['note']?.toString().trim() ?? '',
      detail: j['detail']?.toString().trim() ?? '',
      quantity: double.tryParse(j['quantity']?.toString() ?? '') ?? 0,
      unit: j['quantity_type']?.toString() ?? type.unit,
      cost: double.tryParse(j['cost']?.toString() ?? '') ?? 0,
      // DB ส่งวันที่มาเป็น UTC ต้องแปลงเป็นเวลาไทย ไม่งั้นวันที่จะเลื่อนไป 1 วัน
      date: DateTime.tryParse(j['record_date']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      raw: j,
    );
  }
}
