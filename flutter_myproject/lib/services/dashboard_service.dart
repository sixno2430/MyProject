// ============================================================
// dashboard_service.dart — ข้อมูลหน้า Dashboard และกิจกรรม
//
// - ActivityItem: กิจกรรม 1 รายการ (เก็บเกี่ยว / ดูแลสวน / รายรับ / รายจ่าย)
// - DashboardData: ข้อมูลสรุปทั้งหมดของหน้า Dashboard
// - DashboardService: เรียก API /dashboard และ /activities
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';

/// ข้อมูลกิจกรรม 1 รายการ (เก็บเกี่ยว / ดูแลสวน / รายรับ / รายจ่าย)
class ActivityItem {
  final String type; // 'harvest' | 'care' | 'income' | 'expense'
  final String id; // รหัสรายการจริง เช่น H004, C123, FN005 (ใช้ตอนแก้ไข/ลบ)
  final String gardenId;
  final String gardenName;
  final String? description;
  final double? quantity;
  final double? amount;
  final DateTime recordDate;

  /// ข้อมูลดิบทั้งหมดจาก API ไว้ส่งต่อให้ฟอร์มแก้ไข
  final Map<String, dynamic> raw;

  /// ชื่อกิจกรรมดูแลสวนเป็นภาษาไทย (ใส่ปุ๋ย / ตัดแต่ง / ให้น้ำ ...)
  String get careLabel {
    if (raw['fertilizer_id'] != null) return 'ใส่ปุ๋ย';
    switch (raw['action_type']) {
      case 'fertilizer':
        return 'ใส่ปุ๋ย';
      case 'pruning':
        return 'ตัดแต่ง';
      case 'weeding':
        return 'กำจัดวัชพืช';
      case 'watering':
        return 'ให้น้ำ';
      case 'spraying':
        return 'พ่นยา';
      default:
        return 'ดูแลสวน';
    }
  }

  /// หน่วยของจำนวน: ดูแลสวนใช้หน่วยที่บันทึกไว้ (ต้น / ครั้ง / กก.) ส่วนเก็บเกี่ยวเป็น กก.
  String get quantityUnit =>
      type == 'care' ? (raw['quantity_type']?.toString() ?? 'กก.') : 'กก.';

  ActivityItem({
    required this.type,
    this.id = '',
    this.gardenId = '',
    this.raw = const {},
    required this.gardenName,
    this.description,
    this.quantity,
    this.amount,
    required this.recordDate,
  });

  /// แปลง JSON จาก API เป็น ActivityItem
  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['type'] as String,
      id: json['id']?.toString() ?? '',
      gardenId: json['garden_id']?.toString() ?? '',
      raw: json,
      gardenName: json['garden_name'] ?? '',
      description: json['description'],
      quantity: json['quantity'] != null
          ? double.tryParse(json['quantity'].toString())
          : null,
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      // DB ส่งวันที่มาเป็นเวลา UTC ต้องแปลงเป็นเวลาไทยก่อน ไม่งั้นวันที่จะเลื่อนไป 1 วัน
      recordDate: DateTime.parse(json['record_date'].toString()).toLocal(),
    );
  }
}

/// ข้อมูลสรุปทั้งหมดของหน้า Dashboard
class DashboardData {
  final int gardenCount;
  final double totalArea; // ไร่
  final int totalPlants;
  final double monthlyProduction;
  final double monthlyIncome;
  final int pendingHarvestCount; // ผลผลิตที่ยังรอขาย
  final double pendingHarvestKg;
  final List<ActivityItem> activities;

  DashboardData({
    required this.gardenCount,
    this.totalArea = 0,
    this.totalPlants = 0,
    required this.monthlyProduction,
    required this.monthlyIncome,
    this.pendingHarvestCount = 0,
    this.pendingHarvestKg = 0,
    required this.activities,
  });

  /// แปลง JSON จาก API เป็น DashboardData
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      gardenCount: int.tryParse(json['garden_count'].toString()) ?? 0,
      totalArea: double.tryParse(json['total_area']?.toString() ?? '') ?? 0,
      totalPlants: int.tryParse(json['total_plants']?.toString() ?? '') ?? 0,
      pendingHarvestCount: int.tryParse(json['pending_harvest_count']?.toString() ?? '') ?? 0,
      pendingHarvestKg: double.tryParse(json['pending_harvest_kg']?.toString() ?? '') ?? 0,
      monthlyProduction:
          double.tryParse(json['monthly_production'].toString()) ?? 0,
      monthlyIncome: double.tryParse(json['monthly_income'].toString()) ?? 0,
      activities: (json['activities'] as List<dynamic>? ?? [])
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// เรียก API ที่เกี่ยวกับหน้า Dashboard
class DashboardService {
  static String get baseUrl => AppConfig.apiBaseUri;

  /// ดึงข้อมูลสรุปของ Dashboard ของ user คนนี้ (GET /dashboard/:userId)
  Future<DashboardData> fetchDashboard(String userId) async {
    final uri = Uri.parse('$baseUrl/dashboard/$userId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('เชื่อมต่อ server ไม่สำเร็จ (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['isError'] == true) {
      throw Exception(body['errorMessage'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
    }

    return DashboardData.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// ประวัติกิจกรรมทั้งหมดของ user
  Future<List<ActivityItem>> fetchActivities(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/activities/$userId'));
    if (response.statusCode != 200) {
      throw Exception('เชื่อมต่อ server ไม่สำเร็จ (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['isError'] == true) {
      throw Exception(body['errorMessage'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
    }
    return (body['data'] as List<dynamic>)
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}