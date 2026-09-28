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
  final double monthlyProduction;
  final double monthlyIncome;
  final List<ActivityItem> activities;

  DashboardData({
    required this.gardenCount,
    required this.monthlyProduction,
    required this.monthlyIncome,
    required this.activities,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      gardenCount: int.tryParse(json['garden_count'].toString()) ?? 0,
      monthlyProduction:
          double.tryParse(json['monthly_production'].toString()) ?? 0,
      monthlyIncome: double.tryParse(json['monthly_income'].toString()) ?? 0,
      activities: (json['activities'] as List<dynamic>? ?? [])
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardService {
  static String get baseUrl => AppConfig.apiBaseUri;

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