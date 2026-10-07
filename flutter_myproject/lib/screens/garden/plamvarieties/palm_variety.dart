// ============================================================
// palm_variety.dart (plamvarieties/) — โมเดลพันธุ์ปาล์มที่ใช้กับ PalmVarietyService
// ============================================================

/// พันธุ์ปาล์ม 1 พันธุ์ (ของผู้ใช้คนนี้)
class PalmVariety {
  final String varietyId;
  final String varietyName;
  final String? scientificName;

  /// จำนวนต้น / จำนวนแปลงที่ปลูกพันธุ์นี้ (ปลูกอยู่ = ลบไม่ได้)
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
        varietyId: (json['variety_id'] ?? '').toString(),
        varietyName: (json['variety_name'] ?? '').toString(),
        scientificName: json['scientific_name']?.toString(),
        plantCount: int.tryParse(json['plant_count']?.toString() ?? '') ?? 0,
        gardenCount: int.tryParse(json['garden_count']?.toString() ?? '') ?? 0,
      );
}
