// ============================================================
// palm_variety.dart (plamvarieties/) — โมเดลพันธุ์ปาล์มที่ใช้กับ PalmVarietyService
// ============================================================

/// พันธุ์ปาล์ม 1 พันธุ์
class PalmVariety {
  final String varietyId;
  final String varietyName;
  final String? scientificName;

  PalmVariety({
    required this.varietyId,
    required this.varietyName,
    this.scientificName,
  });

  /// แปลง JSON จาก API เป็น PalmVariety
  factory PalmVariety.fromJson(Map<String, dynamic> json) => PalmVariety(
        varietyId: (json['variety_id'] ?? '').toString(),
        varietyName: (json['variety_name'] ?? '').toString(),
        scientificName: json['scientific_name']?.toString(),
      );
}