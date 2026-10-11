// ============================================================
// shop_service.dart — เรียก API ฝั่งร้านรับซื้อ
//
// GET  /api/shop/profile/:userId   ข้อมูลร้านของบัญชีที่ล็อกอินอยู่
// POST /api/shop/profile           สร้างร้าน / PUT /api/shop/profile/:shopId แก้ไขร้าน
// GET  /api/shop/:shopId/dashboard ตัวเลขสรุป + ราคาปัจจุบัน + การรับซื้อล่าสุด
// GET  /api/shop/:shopId/prices    ประวัติราคา / POST /api/shop/prices บันทึก / DELETE ลบ
// GET  /api/shop/:shopId/purchases ประวัติรับซื้อ / POST /api/shop/purchases บันทึก / DELETE ยกเลิก
// GET  /api/shop/farmers/search    ค้นหาเกษตรกร / GET /api/shop/farmers/:id/harvests ผลผลิตรอขาย
// GET  /api/shop/:shopId/incoming  ล็อตที่เกษตรกรเลือกขายให้ร้านนี้ (รอร้านยืนยันรับซื้อ)
// GET  /api/shop/:shopId/reports?year= รายงานรายปี
// ทุกคำสั่งที่แก้ข้อมูลส่ง user_id ไปให้เซิร์ฟเวอร์ตรวจว่าเป็นเจ้าของร้านจริง
// model อยู่ใน models/shop.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/models/shop.dart';

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
    return (body['data'] as List? ?? []).map((e) => ShopPriceRate.fromJson(Map<String, dynamic>.from(e))).toList();
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

  /// ล็อตที่เกษตรกรเลือกขายให้ร้านนี้ และยังรอร้านยืนยันรับซื้อ (เก่าสุดก่อน)
  static Future<List<IncomingLot>> fetchIncoming(String userId, String shopId) async {
    final res = await http.get(Uri.parse('$_base/shop/$shopId/incoming?user_id=$userId'));
    return (_decode(res)['data'] as List? ?? [])
        .map((e) => IncomingLot.fromJson(Map<String, dynamic>.from(e)))
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
    String? grade, // เกรดที่เลือก (null = กรอกราคาเอง ไม่ระบุเกรด)
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
        'quality_grade': grade,
      }),
    );
    _decode(res);
  }

  /// ยกเลิกการรับซื้อ (ผลผลิตของเกษตรกรกลับเป็น "รอขาย")
  /// ร้านไม่รับล็อตที่เกษตรกรเลือกขายให้ (เหตุผลบังคับ) ล็อตกลับไปให้เกษตรกรเลือกร้านใหม่
  static Future<void> rejectHarvest({
    required String userId,
    required String shopId,
    required String harvestId,
    required String reason,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/shop/harvests/$harvestId/reject'),
      headers: _json,
      body: jsonEncode({'user_id': userId, 'shop_id': shopId, 'reason': reason}),
    );
    _decode(res);
  }

  static Future<void> cancelPurchase(String userId, String purchaseId) async {
    final res = await http.delete(Uri.parse('$_base/shop/purchases/$purchaseId?user_id=$userId'));
    _decode(res);
  }

  /// แก้ไขการรับซื้อ (เซิร์ฟเวอร์อัปเดตผลผลิตฝั่งเกษตรกรให้ตรงกันเอง)
  static Future<void> updatePurchase({
    required String userId,
    required String purchaseId,
    required double quantity,
    required double pricePerKg,
    required String purchaseDate,
  }) async {
    final res = await http.put(
      Uri.parse('$_base/shop/purchases/$purchaseId'),
      headers: _json,
      body: jsonEncode({
        'user_id': userId,
        'quantity': quantity,
        'price_per_kg': pricePerKg,
        'purchase_date': purchaseDate,
      }),
    );
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
