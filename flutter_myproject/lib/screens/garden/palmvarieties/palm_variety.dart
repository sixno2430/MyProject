// ============================================================
// palm_variety.dart — โมเดลพันธุ์ปาล์ม (ใช้กับหน้าใน palmvarieties/ และ PalmVarietyDropdown)
// ============================================================

/// พันธุ์ปาล์ม 1 พันธุ์
class PalmVariety {
  final String varietyId;
  final String varietyName;
  final String? scientificName;

  /// จำนวนต้นและจำนวนแปลงที่ user ที่ล็อกอินอยู่ปลูกพันธุ์นี้
  /// (ได้มาเมื่อเรียก /api/varieties?user_id=...)
  final int plantCount;
  final int gardenCount;

  PalmVariety({
    required this.varietyId,
    required this.varietyName,
    this.scientificName,
    this.plantCount = 0,
    this.gardenCount = 0,
  });

  /// แปลง JSON จาก API เป็น PalmVariety
  factory PalmVariety.fromJson(Map<String, dynamic> json) => PalmVariety(
        varietyId: json['variety_id'] as String,
        varietyName: json['variety_name'] as String,
        scientificName: json['scientific_name'] as String?,
        // SUM() ใน MySQL ส่งมาเป็น string จึงต้อง parse ผ่าน toString
        plantCount: int.tryParse(json['plant_count']?.toString().split('.').first ?? '') ?? 0,
        gardenCount: int.tryParse(json['garden_count']?.toString() ?? '') ?? 0,
      );
}
