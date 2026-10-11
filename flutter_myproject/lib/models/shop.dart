// ============================================================
// shop.dart — model ฝั่งร้านรับซื้อ (ใช้กับ ShopService ใน services/shop_service.dart)
//
// ShopInfo (ข้อมูลร้าน), ShopPriceRate (ราคาตามเกรด), ShopPurchase (การรับซื้อ 1 ครั้ง),
// FarmerResult / PendingHarvest (ค้นหาเกษตรกรและล็อตรอขาย), IncomingLot (ล็อตที่เกษตรกรส่งมาให้ร้าน),
// ShopReport / ShopReportRow (รายงานรายปี), ShopDashboardData (หน้าแรกของร้าน)
// ============================================================

/// ข้อมูลร้าน 1 ร้าน
class ShopInfo {
  final String shopId;
  final String name;
  final String location;
  final String phone;
  final bool isOpen;
  final String openSchedule;

  ShopInfo({
    required this.shopId,
    required this.name,
    required this.location,
    required this.phone,
    required this.isOpen,
    required this.openSchedule,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> j) => ShopInfo(
    shopId: j['shop_id'].toString(),
    name: j['shop_name']?.toString() ?? 'ร้านรับซื้อ',
    location: j['location']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
    isOpen: j['status']?.toString().toUpperCase() == 'ACTIVE',
    openSchedule: j['open_schedule']?.toString() ?? '',
  );
}

/// ราคารับซื้อ 1 เกรด
class ShopPriceRate {
  final String? id; // price_rate_id (มีเฉพาะข้อมูลจากประวัติราคา)
  final String grade;
  final double pricePerKg;
  final String? effectiveDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd หรือ null = ไม่มีวันหมดอายุ
  final bool isCurrent; // false = หมดอายุแล้ว (หรือยังไม่ถึงวันเริ่มใช้)

  ShopPriceRate({
    this.id,
    required this.grade,
    required this.pricePerKg,
    this.effectiveDate,
    this.endDate,
    required this.isCurrent,
  });

  /// สถานะเทียบกับวันนี้: 'current' ใช้อยู่ / 'expired' หมดอายุ / 'upcoming' ยังไม่ถึงวันเริ่ม
  String get status {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    final start = DateTime.tryParse(effectiveDate ?? '');
    final end = DateTime.tryParse(endDate ?? '');
    if (start != null && start.isAfter(d)) return 'upcoming';
    if (end != null && end.isBefore(d)) return 'expired';
    return 'current';
  }

  factory ShopPriceRate.fromJson(Map<String, dynamic> j) {
    final rate = ShopPriceRate(
      id: j['price_rate_id']?.toString(),
      grade: j['quality_grade']?.toString() ?? '-',
      pricePerKg: double.tryParse(j['price_per_kg']?.toString() ?? '') ?? 0,
      effectiveDate: j['effective_date']?.toString(),
      endDate: j['end_date']?.toString(),
      isCurrent: j['is_current'] == true,
    );
    // ประวัติราคาไม่มี is_current มาด้วย -> คำนวณจากวันที่เอง
    if (j.containsKey('is_current')) return rate;
    return ShopPriceRate(
      id: rate.id,
      grade: rate.grade,
      pricePerKg: rate.pricePerKg,
      effectiveDate: rate.effectiveDate,
      endDate: rate.endDate,
      isCurrent: rate.status == 'current',
    );
  }
}

/// การรับซื้อ 1 รายการ
class ShopPurchase {
  final String purchaseId;
  final String farmerName;
  final String farmerPhone;
  final String gardenName;
  final String grade; // เกรดที่ร้านเลือกตอนรับซื้อ ('' = ไม่ระบุ/กรอกราคาเอง)
  final double quantity;
  final double pricePerKg;
  final double totalPrice;
  final DateTime date;

  ShopPurchase({
    required this.purchaseId,
    required this.farmerName,
    this.farmerPhone = '',
    this.gardenName = '',
    this.grade = '',
    required this.quantity,
    required this.pricePerKg,
    required this.totalPrice,
    required this.date,
  });

  factory ShopPurchase.fromJson(Map<String, dynamic> j) => ShopPurchase(
    purchaseId: j['purchase_id'].toString(),
    farmerName: j['farmer_name']?.toString() ?? 'ไม่ระบุชื่อ',
    farmerPhone: j['farmer_phone']?.toString() ?? '',
    gardenName: j['garden_name']?.toString() ?? '',
    grade: j['quality_grade']?.toString() ?? '',
    quantity: double.tryParse(j['quantity']?.toString() ?? '') ?? 0,
    pricePerKg: double.tryParse(j['price_per_kg']?.toString() ?? '') ?? 0,
    totalPrice: double.tryParse(j['total_price']?.toString() ?? '') ?? 0,
    // DB ส่งวันที่เป็น UTC ต้องแปลงเป็นเวลาไทย ไม่งั้นวันที่เลื่อนไป 1 วัน
    date: DateTime.tryParse(j['purchase_date']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
  );
}

/// เกษตรกรจากผลการค้นหา
class FarmerResult {
  final String userId;
  final String name;
  final String phone;
  final int pendingCount; // จำนวนผลผลิตที่รอขาย

  FarmerResult({required this.userId, required this.name, required this.phone, required this.pendingCount});

  factory FarmerResult.fromJson(Map<String, dynamic> j) => FarmerResult(
    userId: j['user_id'].toString(),
    name: j['full_name']?.toString() ?? '-',
    phone: j['phone']?.toString() ?? '',
    pendingCount: (j['pending_count'] as num?)?.toInt() ?? 0,
  );
}

/// ผลผลิตที่รอขายของเกษตรกร (ให้ร้านเลือกรับซื้อ)
class PendingHarvest {
  final String harvestId;
  final String code;
  final String gardenName;
  final double quantity;
  final DateTime date;
  final bool reserved; // true = เกษตรกรเลือกขายให้ร้านนี้ไว้แล้ว

  PendingHarvest({
    required this.harvestId,
    required this.code,
    required this.gardenName,
    required this.quantity,
    required this.date,
    this.reserved = false,
  });

  factory PendingHarvest.fromJson(Map<String, dynamic> j) => PendingHarvest(
    harvestId: j['harvest_id'].toString(),
    code: j['code']?.toString() ?? '',
    gardenName: j['garden_name']?.toString() ?? 'แปลงปาล์ม',
    quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(j['harvest_date']?.toString() ?? '') ?? DateTime.now(),
    reserved: j['reserved'] == true,
  );
}

/// ล็อตที่เกษตรกรส่งมาขายร้านนี้ (ผลผลิตรอขาย + เกษตรกรเจ้าของ)
class IncomingLot {
  final PendingHarvest harvest;
  final FarmerResult farmer;

  IncomingLot({required this.harvest, required this.farmer});

  factory IncomingLot.fromJson(Map<String, dynamic> j) => IncomingLot(
    harvest: PendingHarvest.fromJson({...j, 'reserved': true}),
    farmer: FarmerResult(
      userId: j['farmer_id'].toString(),
      name: j['farmer_name']?.toString() ?? '-',
      phone: j['farmer_phone']?.toString() ?? '',
      pendingCount: 1,
    ),
  );
}

/// ยอดรับซื้อ 1 เดือน (หรือของเกษตรกร 1 คนในรายงาน)
class ShopReportRow {
  final String label; // เดือน (1-12) หรือชื่อเกษตรกร
  final double kg;
  final double amount;
  final int count;

  ShopReportRow({required this.label, required this.kg, required this.amount, required this.count});

  double get avgPrice => kg > 0 ? amount / kg : 0;

  factory ShopReportRow.fromJson(Map<String, dynamic> j, String labelKey) => ShopReportRow(
    label: j[labelKey]?.toString() ?? '-',
    kg: (j['total_kg'] as num?)?.toDouble() ?? 0,
    amount: (j['total_amount'] as num?)?.toDouble() ?? 0,
    count: (j['purchase_count'] as num?)?.toInt() ?? 0,
  );
}

/// รายงานการรับซื้อรายปีของร้าน
class ShopReport {
  final int year;
  final List<int> years; // ปีที่เลือกดูได้
  final double totalKg, totalAmount, avgPrice;
  final int purchaseCount, farmerCount;
  final List<ShopReportRow> months; // ครบ 12 เดือน (เดือนที่ไม่มีข้อมูล = 0)
  final List<ShopReportRow> topFarmers;

  ShopReport({
    required this.year,
    required this.years,
    required this.totalKg,
    required this.totalAmount,
    required this.avgPrice,
    required this.purchaseCount,
    required this.farmerCount,
    required this.months,
    required this.topFarmers,
  });

  factory ShopReport.fromJson(Map<String, dynamic> j) {
    final s = Map<String, dynamic>.from(j['summary'] as Map? ?? {});
    final byMonth = {
      for (final m in (j['monthly'] as List? ?? []))
        (m['month'] as num).toInt(): ShopReportRow.fromJson(Map<String, dynamic>.from(m), 'month'),
    };
    return ShopReport(
      year: (j['year'] as num?)?.toInt() ?? DateTime.now().year,
      years: (j['years'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
      totalKg: (s['total_kg'] as num?)?.toDouble() ?? 0,
      totalAmount: (s['total_amount'] as num?)?.toDouble() ?? 0,
      avgPrice: (s['avg_price'] as num?)?.toDouble() ?? 0,
      purchaseCount: (s['purchase_count'] as num?)?.toInt() ?? 0,
      farmerCount: (s['farmer_count'] as num?)?.toInt() ?? 0,
      months: List.generate(12, (i) => byMonth[i + 1] ?? ShopReportRow(label: '${i + 1}', kg: 0, amount: 0, count: 0)),
      topFarmers: (j['topFarmers'] as List? ?? [])
          .map((e) => ShopReportRow.fromJson(Map<String, dynamic>.from(e), 'farmer_name'))
          .toList(),
    );
  }
}

/// ข้อมูลแดชบอร์ดของร้าน
class ShopDashboardData {
  final double todayKg, todayAmount, monthKg, monthAmount, totalKg, totalAmount;
  final int totalFarmers;
  final int incomingCount; // ล็อตที่เกษตรกรส่งมา รอร้านยืนยันรับซื้อ
  final List<ShopPriceRate> rates;
  final List<ShopPurchase> recent;

  ShopDashboardData({
    required this.todayKg,
    required this.todayAmount,
    required this.monthKg,
    required this.monthAmount,
    required this.totalKg,
    required this.totalAmount,
    required this.totalFarmers,
    this.incomingCount = 0,
    required this.rates,
    required this.recent,
  });

  factory ShopDashboardData.fromJson(Map<String, dynamic> j) {
    final s = (j['summary'] as Map?) ?? {};
    double n(String k) => (s[k] as num?)?.toDouble() ?? 0;
    return ShopDashboardData(
      todayKg: n('today_kg'),
      todayAmount: n('today_amount'),
      monthKg: n('month_kg'),
      monthAmount: n('month_amount'),
      totalKg: n('total_kg'),
      totalAmount: n('total_amount'),
      totalFarmers: (s['total_farmers'] as num?)?.toInt() ?? 0,
      incomingCount: (s['incoming_count'] as num?)?.toInt() ?? 0,
      rates: (j['currentRates'] as List? ?? []).map((e) => ShopPriceRate.fromJson(e)).toList(),
      recent: (j['recentPurchases'] as List? ?? []).map((e) => ShopPurchase.fromJson(e)).toList(),
    );
  }
}
