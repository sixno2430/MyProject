// ============================================================
// garden.dart — model แปลงสวน
//
// - Garden       : แปลงสวน 1 แปลง (พื้นที่, จำนวนต้น, ปีที่ปลูก, ที่อยู่, พันธุ์ที่ปลูก)
// - GardenVariety: พันธุ์ที่ปลูกในแปลง + จำนวนต้น (ต่างจาก PalmVariety ในหน้าพันธุ์ปาล์มที่เป็นรายชื่อพันธุ์ของผู้ใช้)
// ============================================================

/// พันธุ์ปาล์มที่ปลูกในแปลง (พร้อมจำนวนต้น)
class GardenVariety {
  final String varietyId;
  final String varietyName;
  final int plantCount;

  GardenVariety({required this.varietyId, required this.varietyName, required this.plantCount});

  factory GardenVariety.fromJson(Map<String, dynamic> json) {
    return GardenVariety(
      varietyId: json['variety_id']?.toString() ?? '',
      varietyName: json['variety_name']?.toString() ?? 'ไม่ระบุพันธุ์',
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// ข้อมูลแปลงสวน 1 แปลง
class Garden {
  final String gardenId;
  final String userId;
  final String gardenName;
  final double areaSize;
  final int plantCount;
  final int? plantYear;
  final int? plantAge;
  final String? address; // ← เพิ่ม
  final List<GardenVariety>? varieties;

  Garden({
    required this.gardenId,
    required this.userId,
    required this.gardenName,
    required this.areaSize,
    required this.plantCount,
    this.plantYear,
    this.plantAge,
    this.address, // ← เพิ่ม
    this.varieties,
  });

  /// แปลง JSON จาก API เป็น Garden
  factory Garden.fromJson(Map<String, dynamic> json) {
    List<GardenVariety>? varietyList;
    if (json['varieties'] != null && json['varieties'] is List) {
      varietyList = (json['varieties'] as List).map((v) => GardenVariety.fromJson(v)).toList();
    }
    return Garden(
      gardenId: json['garden_id'] ?? '',
      userId: json['user_id'] ?? '',
      gardenName: json['garden_name'] ?? 'ไม่ระบุชื่อแปลง',
      areaSize: double.tryParse(json['area_size']?.toString() ?? '0') ?? 0.0,
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
      plantYear: json['plant_year'] != null ? int.tryParse(json['plant_year'].toString()) : null,
      plantAge: json['plant_age'] != null ? int.tryParse(json['plant_age'].toString()) : null,
      address: json['address']?.toString(), // ← เพิ่ม
      varieties: varietyList,
    );
  }

  // ← เพิ่ม: สร้างข้อความ "เหนื่อย่า · 5 ปี · 12 ไร่ · 330 ต้น"
  String get detailText {
    final parts = <String>[];
    if (plantAge != null) parts.add('$plantAge ปี');
    if (areaSize > 0) {
      parts.add('${areaSize.toStringAsFixed(areaSize.truncateToDouble() == areaSize ? 0 : 2)} ไร่');
    }
    if (plantCount > 0) parts.add('$plantCount ต้น');
    return parts.join(' · ');
  }
}
