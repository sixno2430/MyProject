// ============================================================
// finance_service.dart — เรียก API รายรับ-รายจ่าย
//
// GET /api/finance/transactions?month=&type=&user_id=  รายการเงินของเดือน (รวมขายผลผลิต + ค่าดูแลสวน + ที่บันทึกเอง)
// POST /api/finance/add, PUT/DELETE /api/finance/:id    รายการที่บันทึกเอง (FN...) เท่านั้น
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/api.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/models/finance.dart';

class FinanceService {
  /// รายการของเดือน (yyyy-MM) และประเภท ('income' / 'expense') — โหลดไม่ได้ = รายการว่าง
  static Future<List<TransactionItem>> fetchTransactions(String month, String type, String userId) async {
    try {
      final res = await http.get(Uri.parse('${Api.base}/finance/transactions?month=$month&type=$type&user_id=$userId'));
      if (res.statusCode != 200) return [];
      final data = Api.decode(res)['data'];
      if (data is List) return data.map((i) => TransactionItem.fromJson(i)).toList();
      if (data is Map<String, dynamic>) return [TransactionItem.fromJson(data)];
    } catch (_) {}
    return [];
  }

  /// เพิ่ม (id = null) หรือแก้ไขรายการที่บันทึกเอง
  static Future<void> saveTransaction(String? id, Map<String, dynamic> fields) async {
    final body = jsonEncode(fields);
    final res = id == null
        ? await http.post(Uri.parse('${Api.base}/finance/add'), headers: Api.jsonHeaders, body: body)
        : await http.put(Uri.parse('${Api.base}/finance/$id'), headers: Api.jsonHeaders, body: body);
    Api.decode(res, 'ไม่สามารถบันทึกได้');
  }

  static Future<void> deleteTransaction(String id) async {
    final userId = await AuthService.getUserId();
    final res = await http.delete(Uri.parse('${Api.base}/finance/$id?user_id=$userId'));
    Api.decode(res);
  }
}
