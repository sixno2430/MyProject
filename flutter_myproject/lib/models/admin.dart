// ============================================================
// admin.dart — model ฝั่งผู้ดูแลระบบ (ใช้กับ AdminService ใน services/admin_service.dart)
//
// AdminOverview (ภาพรวมระบบ), AdminUser (บัญชีผู้ใช้), AdminLog + logActionLabels/logCategories
// (ประวัติการใช้งาน), AdminReport + MonthValue (รายงานระบบ), RecentActivity (กิจกรรมล่าสุด)
// ============================================================

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
  // การเข้าสู่ระบบ / บัญชี
  'LOGIN': 'เข้าสู่ระบบ',
  'REGISTER': 'ลงทะเบียนบัญชีใหม่',
  'EDIT_PROFILE': 'แก้ไขข้อมูลส่วนตัว',
  'CHANGE_PASSWORD': 'เปลี่ยนรหัสผ่าน',
  // เกษตรกร
  'ADD_GARDEN': 'เพิ่มแปลงสวน',
  'EDIT_GARDEN': 'แก้ไขแปลงสวน',
  'DELETE_GARDEN': 'ลบแปลงสวน',
  'ADD_VARIETY': 'เพิ่มพันธุ์ปาล์ม',
  'EDIT_VARIETY': 'แก้ไขพันธุ์ปาล์ม',
  'DELETE_VARIETY': 'ลบพันธุ์ปาล์ม',
  'ADD_CARE': 'บันทึกการดูแลสวน',
  'EDIT_CARE': 'แก้ไขการดูแลสวน',
  'DELETE_CARE': 'ลบการดูแลสวน',
  'ADD_HARVEST': 'บันทึกการเก็บเกี่ยว',
  'EDIT_HARVEST': 'แก้ไขการเก็บเกี่ยว',
  'DELETE_HARVEST': 'ลบการเก็บเกี่ยว',
  'SELL_HARVEST': 'บันทึกการขายนอกระบบ',
  'ADD_FINANCE': 'บันทึกรายรับ-รายจ่าย',
  'EDIT_FINANCE': 'แก้ไขรายรับ-รายจ่าย',
  'DELETE_FINANCE': 'ลบรายรับ-รายจ่าย',
  // ร้านรับซื้อ
  'ADD_SHOP': 'ลงทะเบียนข้อมูลร้าน',
  'EDIT_SHOP': 'แก้ไขข้อมูลร้าน',
  'UPDATE_PRICE': 'ปรับราคารับซื้อ',
  'DELETE_PRICE': 'ลบราคารับซื้อ',
  'ADD_PURCHASE': 'บันทึกการรับซื้อผลผลิต',
  'EDIT_PURCHASE': 'แก้ไขการรับซื้อ',
  'CANCEL_PURCHASE': 'ยกเลิกการรับซื้อ',
  'REJECT_HARVEST': 'ไม่รับซื้อล็อตผลผลิต',
  // ผู้ดูแลระบบ
  'ADD_USER': 'เพิ่มบัญชีผู้ใช้',
  'EDIT_USER': 'แก้ไขข้อมูลบัญชีผู้ใช้',
  'SUSPEND_USER': 'ระงับการใช้งานบัญชี',
  'ACTIVATE_USER': 'เปิดใช้งานบัญชี',
};

/// action ในหมวดที่ระบุ (ใช้ชื่อขึ้นต้น เช่น ADD_ = เพิ่มข้อมูล) คั่นด้วย comma สำหรับส่งไปกรองที่เซิร์ฟเวอร์
String _actionsWhere(bool Function(String action) test) => logActionLabels.keys.where(test).join(',');

const _accountActions = {
  'REGISTER',
  'EDIT_PROFILE',
  'CHANGE_PASSWORD',
  'ADD_USER',
  'EDIT_USER',
  'SUSPEND_USER',
  'ACTIVATE_USER',
};

/// หมวดของประวัติการใช้งาน ใช้เป็นตัวกรองในหน้าประวัติ (ค่า = action ในหมวด คั่นด้วย comma, null = ทั้งหมด)
final List<(String, String?)> logCategories = [
  ('ทั้งหมด', null),
  ('การเข้าสู่ระบบ', 'LOGIN'),
  ('เพิ่มข้อมูล', _actionsWhere((a) => !_accountActions.contains(a) && a != 'LOGIN' && !_isChange(a))),
  ('แก้ไข/ลบข้อมูล', _actionsWhere((a) => !_accountActions.contains(a) && _isChange(a))),
  ('การจัดการบัญชี', _accountActions.join(',')),
];

/// แก้ไข / ลบ / ยกเลิก / ไม่รับซื้อ = การเปลี่ยนแปลงข้อมูลเดิม
bool _isChange(String a) =>
    a.startsWith('EDIT_') || a.startsWith('DELETE_') || a == 'CANCEL_PURCHASE' || a == 'REJECT_HARVEST';

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
