// ============================================================
// admin_service.dart — เรียก API ฝั่งผู้ดูแลระบบ (role R001)
//
// ทุกคำสั่งส่ง admin_id = user_id ของคนที่ล็อกอิน ให้เซิร์ฟเวอร์ตรวจว่าเป็นแอดมินจริง
//   GET /api/admin/overview       ตัวเลขภาพรวมระบบ
//   GET/POST/PUT /api/admin/users รายชื่อ / เพิ่ม / แก้ไขผู้ใช้, PUT /users/:id/status ระงับหรือเปิดใช้
//   GET /api/admin/logs           ประวัติการใช้งาน (ตาราง user_log)
//   GET /api/admin/report         รายงานระบบ
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';

/// ตัวเลขภาพรวมระบบ
class AdminOverview {
  final int userCount;
  final int farmerCount;
  final int shopCount;
  final int adminCount;
  final int active7d; // เข้าสู่ระบบภายใน 7 วัน
  final int gardenCount;
  final double gardenArea; // ไร่
  final int harvestCount;
  final int harvestPending;
  final int harvestSold;
  final int purchaseCount;
  final double purchaseQty; // กก.
  final double purchaseAmount; // บาท
  final double monthPurchaseQty; // รับซื้อเดือนนี้ (กก.)
  final double monthPurchaseAmount;
  final List<MonthValue> harvestMonthly; // ผลผลิตทั้งชุมชน 6 เดือน
  final List<RecentActivity> recent;

  AdminOverview.fromJson(Map<String, dynamic> j)
      : userCount = _int(j['user_count']),
        farmerCount = _int(j['farmer_count']),
        shopCount = _int(j['shop_count']),
        adminCount = _int(j['admin_count']),
        active7d = _int(j['active_7d']),
        gardenCount = _int(j['garden_count']),
        gardenArea = _double(j['garden_area']),
        harvestCount = _int(j['harvest_count']),
        harvestPending = _int(j['harvest_pending']),
        harvestSold = _int(j['harvest_sold']),
        purchaseCount = _int(j['purchase_count']),
        purchaseQty = _double(j['purchase_qty']),
        purchaseAmount = _double(j['purchase_amount']),
        monthPurchaseQty = _double(j['month_purchase_qty']),
        monthPurchaseAmount = _double(j['month_purchase_amount']),
        harvestMonthly = MonthValue.listFrom(j['harvest_monthly'], 'qty'),
        recent = _list(j['recent']).map(RecentActivity.fromJson).toList();
}

/// ค่าของเดือนหนึ่ง สำหรับกราฟแท่ง (month = 'YYYY-MM')
class MonthValue {
  final String month;
  final double value;
  const MonthValue(this.month, this.value);

  static List<MonthValue> listFrom(dynamic raw, String field) =>
      _list(raw).map((e) => MonthValue(e['month'].toString(), _double(e[field]))).toList();
}

/// กิจกรรมล่าสุดในระบบ: harvest / purchase / register
class RecentActivity {
  final String type;
  final DateTime? at;
  final String who;
  final String detail;

  RecentActivity.fromJson(Map<String, dynamic> j)
      : type = (j['type'] ?? '').toString(),
        at = DateTime.tryParse(j['at']?.toString() ?? '')?.toLocal(),
        who = (j['who'] ?? '').toString(),
        detail = (j['detail'] ?? '').toString();
}

/// ผู้ใช้ 1 คนในหน้าจัดการผู้ใช้
class AdminUser {
  final String userId;
  final String roleId; // R001 แอดมิน / R002 เกษตรกร / R003 ร้านรับซื้อ
  final String fullName;
  final String phone;
  final String username;
  final String citizenId;
  final String status; // active / suspended
  final String? createdAt; // yyyy-MM-dd
  final String? lastLogin; // yyyy-MM-dd HH:mm (null = ยังไม่เคยเข้าตั้งแต่เริ่มเก็บประวัติ)
  final int gardenCount;
  final String? shopName;

  AdminUser.fromJson(Map<String, dynamic> j)
      : userId = (j['user_id'] ?? '').toString(),
        roleId = (j['role_id'] ?? '').toString(),
        fullName = (j['full_name'] ?? '').toString(),
        phone = (j['phone'] ?? '').toString(),
        username = (j['username'] ?? '').toString(),
        citizenId = (j['citizen_id'] ?? '').toString(),
        status = (j['status'] ?? 'active').toString(),
        createdAt = j['created_at']?.toString(),
        lastLogin = j['last_login']?.toString(),
        gardenCount = _int(j['garden_count']),
        shopName = j['shop_name']?.toString();

  bool get isSuspended => status == 'suspended';

  String get roleLabel => roleLabelOf(roleId);
}

/// ชื่อบทบาทภาษาไทย
String roleLabelOf(String roleId) => switch (roleId) {
        'R001' => 'ผู้ดูแลระบบ',
        'R002' => 'เกษตรกร',
        'R003' => 'ร้านรับซื้อ',
        _ => 'ไม่ทราบ',
      };

/// ประวัติการใช้งาน 1 รายการ (ตาราง user_log)
class AdminLog {
  final String logId;
  final String userId;
  final String action;
  final String? ipAddress;
  final String logDate; // yyyy-MM-dd HH:mm:ss
  final String username;
  final String fullName;

  AdminLog.fromJson(Map<String, dynamic> j)
      : logId = (j['log_id'] ?? '').toString(),
        userId = (j['user_id'] ?? '').toString(),
        action = (j['action'] ?? '').toString(),
        ipAddress = j['ip_address']?.toString(),
        logDate = (j['log_date'] ?? '').toString(),
        username = (j['username'] ?? '-').toString(),
        fullName = (j['full_name'] ?? '(ผู้ใช้ถูกลบ)').toString();
}

/// คำอธิบายการกระทำใน user_log เป็นภาษาไทย
const Map<String, String> logActionLabels = {
  'LOGIN': 'เข้าสู่ระบบ',
  'REGISTER': 'ลงทะเบียนบัญชีใหม่',
  'ADD_HARVEST': 'บันทึกการเก็บเกี่ยว',
  'ADD_CARE': 'บันทึกการดูแลสวน',
  'ADD_PURCHASE': 'บันทึกการรับซื้อผลผลิต',
  'UPDATE_PRICE': 'ปรับราคารับซื้อ',
  'ADD_USER': 'เพิ่มบัญชีผู้ใช้',
  'EDIT_USER': 'แก้ไขข้อมูลบัญชีผู้ใช้',
  'SUSPEND_USER': 'ระงับการใช้งานบัญชี',
  'ACTIVATE_USER': 'เปิดใช้งานบัญชี',
};

/// หมวดของประวัติการใช้งาน ใช้เป็นตัวกรองในหน้าประวัติ (ค่า = action ในหมวด คั่นด้วย comma)
const List<(String, String?)> logCategories = [
  ('ทั้งหมด', null),
  ('การเข้าสู่ระบบ', 'LOGIN'),
  ('การบันทึกข้อมูล', 'ADD_HARVEST,ADD_CARE,ADD_PURCHASE,UPDATE_PRICE'),
  ('การจัดการบัญชี', 'REGISTER,ADD_USER,EDIT_USER,SUSPEND_USER,ACTIVATE_USER'),
];

/// ข้อมูลหน้ารายงานระบบ
class AdminReport {
  final List<MonthValue> harvestMonthly;
  final List<MonthValue> purchaseMonthlyQty;
  final List<MonthValue> purchaseMonthlyAmount;
  final List<Map<String, dynamic>> usageMonthly; // month, logins, actions, users
  final List<Map<String, dynamic>> topFarmers; // full_name, lots, qty
  final List<Map<String, dynamic>> shops; // shop_name, status, latest_price, purchase_count, purchase_qty

  AdminReport.fromJson(Map<String, dynamic> j)
      : harvestMonthly = MonthValue.listFrom(j['harvest_monthly'], 'qty'),
        purchaseMonthlyQty = MonthValue.listFrom(j['purchase_monthly'], 'qty'),
        purchaseMonthlyAmount = MonthValue.listFrom(j['purchase_monthly'], 'amount'),
        usageMonthly = _list(j['usage_monthly']),
        topFarmers = _list(j['top_farmers']),
        shops = _list(j['shops']);
}

List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];

int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
double _double(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

/// เรียก API ของแอดมิน
class AdminService {
  static String get _base => '${AppConfig.apiBaseUri}/admin';

  static Future<String> _adminId() async => await AuthService.getUserId() ?? '';

  static Future<AdminOverview> getOverview() async {
    final res = await http.get(Uri.parse('$_base/overview?admin_id=${await _adminId()}'));
    return AdminOverview.fromJson(_data(res) as Map<String, dynamic>);
  }

  static Future<List<AdminUser>> getUsers() async {
    final res = await http.get(Uri.parse('$_base/users?admin_id=${await _adminId()}'));
    return (_data(res) as List).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// เพิ่มผู้ใช้ (id = null) หรือแก้ไข — แก้ไขแล้วเว้นรหัสผ่านว่าง = คงรหัสเดิม
  static Future<void> saveUser({
    String? id,
    required String roleId,
    required String fullName,
    required String username,
    required String citizenId,
    required String phone,
    required String password,
  }) async {
    final body = jsonEncode({
      'admin_id': await _adminId(),
      'role_id': roleId,
      'full_name': fullName,
      'username': username,
      'citizen_id': citizenId,
      'phone': phone,
      'password': password,
    });
    const headers = {'Content-Type': 'application/json'};
    final res = id == null
        ? await http.post(Uri.parse('$_base/users'), headers: headers, body: body)
        : await http.put(Uri.parse('$_base/users/$id'), headers: headers, body: body);
    _data(res);
  }

  /// ระงับ (suspended = true) หรือเปิดใช้บัญชี
  static Future<void> setSuspended(String userId, bool suspended) async {
    final res = await http.put(
      Uri.parse('$_base/users/$userId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admin_id': await _adminId(), 'status': suspended ? 'suspended' : 'active'}),
    );
    _data(res);
  }

  /// ประวัติการใช้งาน กรองตามการกระทำ / ผู้ใช้ได้
  static Future<List<AdminLog>> getLogs({String? action, String? userId}) async {
    final query = {
      'admin_id': await _adminId(),
      'action': ?action, // ? = ใส่เฉพาะตอนไม่เป็น null
      'user_id': ?userId,
    };
    final res = await http.get(Uri.parse('$_base/logs').replace(queryParameters: query));
    return (_data(res) as List).map((e) => AdminLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<AdminReport> getReport() async {
    final res = await http.get(Uri.parse('$_base/report?admin_id=${await _adminId()}'));
    return AdminReport.fromJson(_data(res) as Map<String, dynamic>);
  }

  /// เซิร์ฟเวอร์ตอบ isError -> โยน Exception พร้อมข้อความของเซิร์ฟเวอร์, ไม่งั้นคืน data
  static dynamic _data(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is! Map || body['isError'] == true) {
      throw Exception(body is Map ? body['errorMessage'] ?? 'ทำรายการไม่สำเร็จ' : 'ทำรายการไม่สำเร็จ');
    }
    return body['data'];
  }
}
