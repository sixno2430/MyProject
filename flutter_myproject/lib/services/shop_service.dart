// ============================================================
// shop_service.dart — เรียก API ฝั่งร้านรับซื้อ
//
// GET  /api/shop/profile/:userId   ข้อมูลร้านของบัญชีที่ล็อกอินอยู่
// POST /api/shop/profile           สร้างร้าน / PUT /api/shop/profile/:shopId แก้ไขร้าน
// GET  /api/shop/:shopId/dashboard ตัวเลขสรุป + ราคาปัจจุบัน + การรับซื้อล่าสุด
// GET  /api/shop/:shopId/prices    ประวัติราคา / POST /api/shop/prices บันทึก / DELETE ลบ
// GET  /api/shop/:shopId/purchases ประวัติรับซื้อ / POST /api/shop/purchases บันทึก / DELETE ยกเลิก
// GET  /api/shop/farmers/search    ค้นหาเกษตรกร / GET /api/shop/farmers/:id/harvests ผลผลิตรอขาย
// GET  /api/shop/:shopId/reports?year= รายงานรายปี
// ทุกคำสั่งที่แก้ข้อมูลส่ง user_id ไปให้เซิร์ฟเวอร์ตรวจว่าเป็นเจ้าของร้านจริง
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';

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
  final double quantity;
  final double pricePerKg;
  final double totalPrice;
  final DateTime date;

  ShopPurchase({
    required this.purchaseId,
    required this.farmerName,
    this.farmerPhone = '',
    this.gardenName = '',
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

  PendingHarvest({
    required this.harvestId,
    required this.code,
    required this.gardenName,
    required this.quantity,
    required this.date,
  });

  factory PendingHarvest.fromJson(Map<String, dynamic> j) => PendingHarvest(
        harvestId: j['harvest_id'].toString(),
        code: j['code']?.toString() ?? '',
        gardenName: j['garden_name']?.toString() ?? 'แปลงปาล์ม',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(j['harvest_date']?.toString() ?? '') ?? DateTime.now(),
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
      rates: (j['currentRates'] as List? ?? []).map((e) => ShopPriceRate.fromJson(e)).toList(),
      recent: (j['recentPurchases'] as List? ?? []).map((e) => ShopPurchase.fromJson(e)).toList(),
    );
  }
}

class ShopService {
  static String get _base => AppConfig.apiBaseUri;

  /// ร้านของบัญชีนี้ — คืน null ถ้ายังไม่มีร้าน (ห้ามเดาเป็นร้านอื่น)
  static Future<ShopInfo?> fetchMyShop(String userId) async {
    final res = await http.get(Uri.parse('$_base/shop/profile/$userId'));
    final body = jsonDecode(res.body);
    if (body is! Map || body['isError'] == true || body['data'] == null) return null;
    return ShopInfo.fromJson(Map<String, dynamic>.from(body['data']));
  }

  static Future<ShopDashboardData> fetchDashboard(String shopId) async {
    final res = await http.get(Uri.parse('$_base/shop/$shopId/dashboard'));
    final body = jsonDecode(res.body);
    if (body is! Map || body['isError'] == true) {
      throw Exception(body is Map ? body['errorMessage'] ?? 'โหลดข้อมูลไม่สำเร็จ' : 'โหลดข้อมูลไม่สำเร็จ');
    }
    return ShopDashboardData.fromJson(Map<String, dynamic>.from(body['data']));
  }

  /// ประวัติราคาทั้งหมดของร้าน (ใหม่สุดก่อน)
  static Future<List<ShopPriceRate>> fetchPrices(String shopId) async {
    final res = await http.get(Uri.parse('$_base/shop/$shopId/prices'));
    final body = _decode(res);
    return (body['data'] as List? ?? [])
        .map((e) => ShopPriceRate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// สร้างร้านใหม่ คืน shop_id
  static Future<String> createShop(String userId, Map<String, String> fields) async {
    final res = await http.post(
      Uri.parse('$_base/shop/profile'),
      headers: _json,
      body: jsonEncode({...fields, 'user_id': userId}),
    );
    return _decode(res)['data']['shop_id'].toString();
  }

  /// แก้ไขข้อมูลร้าน (ชื่อ ที่ตั้ง เบอร์ เวลาเปิด-ปิด สถานะ)
  static Future<void> updateShop(String userId, String shopId, Map<String, String> fields) async {
    final res = await http.put(
      Uri.parse('$_base/shop/profile/$shopId'),
      headers: _json,
      body: jsonEncode({...fields, 'user_id': userId}),
    );
    _decode(res);
  }

  /// เพิ่ม (id = null) หรือแก้ไขราคา 1 เกรด
  static Future<void> savePrice({
    required String userId,
    required String shopId,
    String? id,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
    String? endDate,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/shop/prices'),
      headers: _json,
      body: jsonEncode({
        'user_id': userId,
        'shop_id': shopId,
        'price_rate_id': id,
        'quality_grade': grade,
        'price_per_kg': pricePerKg,
        'effective_date': effectiveDate,
        'end_date': endDate,
      }),
    );
    _decode(res);
  }

  static Future<void> deletePrice(String userId, String priceRateId) async {
    final res = await http.delete(Uri.parse('$_base/shop/prices/$priceRateId?user_id=$userId'));
    _decode(res);
  }

  /// ประวัติการรับซื้อทั้งหมดของร้าน (ใหม่สุดก่อน)
  static Future<List<ShopPurchase>> fetchPurchases(String shopId) async {
    final res = await http.get(Uri.parse('$_base/shop/$shopId/purchases'));
    return (_decode(res)['data'] as List? ?? [])
        .map((e) => ShopPurchase.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// ค้นหาเกษตรกรจากชื่อ เบอร์โทร หรือเลขบัตรประชาชน
  static Future<List<FarmerResult>> searchFarmers(String userId, String keyword) async {
    final uri = Uri.parse('$_base/shop/farmers/search').replace(queryParameters: {'user_id': userId, 'q': keyword});
    return (_decode(await http.get(uri))['data'] as List? ?? [])
        .map((e) => FarmerResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// ผลผลิตที่รอขายของเกษตรกร
  static Future<List<PendingHarvest>> fetchPendingHarvests(String userId, String farmerId) async {
    final res = await http.get(Uri.parse('$_base/shop/farmers/$farmerId/harvests?user_id=$userId'));
    return (_decode(res)['data'] as List? ?? [])
        .map((e) => PendingHarvest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// บันทึกการรับซื้อ (เซิร์ฟเวอร์เปลี่ยนผลผลิตของเกษตรกรเป็น "ขายแล้ว" ให้เอง)
  static Future<void> createPurchase({
    required String userId,
    required String shopId,
    required String harvestId,
    required double quantity,
    required double pricePerKg,
    required String purchaseDate,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/shop/purchases'),
      headers: _json,
      body: jsonEncode({
        'user_id': userId,
        'shop_id': shopId,
        'harvest_id': harvestId,
        'quantity': quantity,
        'price_per_kg': pricePerKg,
        'purchase_date': purchaseDate,
      }),
    );
    _decode(res);
  }

  /// ยกเลิกการรับซื้อ (ผลผลิตของเกษตรกรกลับเป็น "รอขาย")
  static Future<void> cancelPurchase(String userId, String purchaseId) async {
    final res = await http.delete(Uri.parse('$_base/shop/purchases/$purchaseId?user_id=$userId'));
    _decode(res);
  }

  /// รายงานการรับซื้อของปีที่เลือก
  static Future<ShopReport> fetchReport(String shopId, int year) async {
    final res = await http.get(Uri.parse('$_base/shop/$shopId/reports?year=$year'));
    return ShopReport.fromJson(Map<String, dynamic>.from(_decode(res)['data']));
  }

  static const _json = {'Content-Type': 'application/json'};

  /// แปลงผลลัพธ์ ถ้าเซิร์ฟเวอร์ตอบ isError ให้โยน Exception พร้อมข้อความภาษาไทยจากเซิร์ฟเวอร์
  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is! Map) throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    if (body['isError'] == true) throw Exception(body['errorMessage'] ?? 'ทำรายการไม่สำเร็จ');
    return Map<String, dynamic>.from(body);
  }
}
