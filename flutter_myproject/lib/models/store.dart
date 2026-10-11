// ============================================================
// store.dart — model หน้า "ร้านรับซื้อ" ของเกษตรกร
//
// - BuyingShop: ร้านรับซื้อ 1 ร้าน (ที่อยู่, เวลาเปิด, สถานะ, ยอดที่เคยขายให้ร้านนี้)
// - PriceRate : ราคารับซื้อตามเกรดของร้าน
// ============================================================

/// ราคารับซื้อ 1 เกรด พร้อมช่วงวันที่ใช้ได้
class PriceRate {
  final String grade;
  final double pricePerKg;
  final String effectiveDate;
  final String? endDate;
  final bool isCurrent;

  PriceRate({
    required this.grade,
    required this.pricePerKg,
    required this.effectiveDate,
    this.endDate,
    required this.isCurrent,
  });

  factory PriceRate.fromJson(Map<String, dynamic> json) => PriceRate(
    grade: json['quality_grade']?.toString() ?? '-',
    pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? 0,
    effectiveDate: json['effective_date']?.toString() ?? '',
    endDate: json['end_date']?.toString(),
    isCurrent: json['is_current'] == true,
  );
}

/// ข้อมูลร้านรับซื้อ 1 ร้าน
class BuyingShop {
  final String id;
  final String name;
  final String location;
  final String phone;
  final bool isActive;
  final String openSchedule;
  final int soldCount;
  final double soldKg;
  final double soldTotal;
  final List<PriceRate> rates;

  BuyingShop({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.isActive,
    required this.openSchedule,
    required this.soldCount,
    required this.soldKg,
    required this.soldTotal,
    required this.rates,
  });

  /// ราคาสูงสุดที่ยังไม่หมดอายุ (ใช้เรียงร้าน) — ไม่มีราคาปัจจุบัน = 0
  double get bestCurrentPrice =>
      rates.where((r) => r.isCurrent).fold<double>(0, (best, r) => r.pricePerKg > best ? r.pricePerKg : best);

  factory BuyingShop.fromJson(Map<String, dynamic> json) => BuyingShop(
    id: json['shop_id']?.toString() ?? '',
    name: json['shop_name']?.toString() ?? 'ไม่ระบุชื่อร้าน',
    location: json['location']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    isActive: json['status']?.toString().toUpperCase() == 'ACTIVE',
    openSchedule: json['open_schedule']?.toString() ?? '',
    soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
    soldKg: (json['sold_kg'] as num?)?.toDouble() ?? 0,
    soldTotal: (json['sold_total'] as num?)?.toDouble() ?? 0,
    rates: (json['rates'] as List? ?? []).map((e) => PriceRate.fromJson(e)).toList(),
  );
}
