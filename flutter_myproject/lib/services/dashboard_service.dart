import 'dart:convert';
import 'package:http/http.dart' as http;

/// ข้อมูลกิจกรรมล่าสุด 1 รายการ (เก็บเกี่ยว / ใส่ปุ๋ย / รับเงิน)
class ActivityItem {
  final String type; // 'harvest' | 'care' | 'income'
  final String gardenName;
  final String? description;
  final double? quantity;
  final double? amount;
  final DateTime recordDate;

  ActivityItem({
    required this.type,
    required this.gardenName,
    this.description,
    this.quantity,
    this.amount,
    required this.recordDate,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['type'] as String,
      gardenName: json['garden_name'] ?? '',
      description: json['description'],
      quantity: json['quantity'] != null
          ? double.tryParse(json['quantity'].toString())
          : null,
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      recordDate: DateTime.parse(json['record_date'].toString()),
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
  // TODO: เปลี่ยนตามที่รันจริง
  // - รันบน Chrome/Web หรือ iOS Simulator: ใช้ localhost ได้เลย
  // - รันบน Android Emulator: ต้องใช้ 10.0.2.2 แทน localhost
  // - รันบนมือถือจริง: ต้องใช้ IP เครื่อง server เช่น 192.168.x.x
  static const String baseUrl = 'http://localhost:3000';

  Future<DashboardData> fetchDashboard(String userId) async {
    final uri = Uri.parse('$baseUrl/api/dashboard/$userId');
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
}