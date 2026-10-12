// ============================================================
// store_service.dart — เรียก API หน้า "ร้านรับซื้อ" ของเกษตรกร
//
// GET /api/shops?user_id=  รายชื่อร้าน + ราคาแต่ละเกรด + ยอดที่ผู้ใช้คนนี้เคยขายให้แต่ละร้าน
// model อยู่ใน models/store.dart
// ============================================================

import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/api.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/models/store.dart';

class StoreService {
  static Future<List<BuyingShop>> fetchShops() async {
    final userId = await AuthService.getUserId();
    final res = await http.get(Uri.parse('${Api.base}/shops?user_id=${userId ?? ''}'));
    return (Api.decode(res)['data'] as List).map((e) => BuyingShop.fromJson(e)).toList();
  }
}
