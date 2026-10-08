// ============================================================
// shop_home_screen.dart — หน้าหลักฝั่งร้านรับซื้อ (โครงของแอปฝั่งร้าน)
//
// แถบเมนูด้านล่าง 5 แท็บ โทนส้ม: หน้าหลัก / รับซื้อ / ร้านของฉัน / รายงาน / โปรไฟล์
// โหลดข้อมูลร้านของบัญชีที่ล็อกอินครั้งเดียว แล้วส่งต่อให้ทุกแท็บ
// เปิดจาก: หน้าล็อกอิน เมื่อบัญชีเป็น R003 (ร้านรับซื้อ)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/main/profile/profile_screen.dart';
import 'package:flutter_myproject/screens/shop/my_shop_screen.dart';
import 'package:flutter_myproject/screens/shop/shop_dashboard_screen.dart';
import 'package:flutter_myproject/screens/shop/shop_purchase_screen.dart';
import 'package:flutter_myproject/screens/shop/shop_report_screen.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';
import 'package:flutter_myproject/widgets/button_nav.dart';
import 'package:flutter_myproject/utils/error_message.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  static const theme = RoleTheme.shop;

  /// เมนูของฝั่งร้าน
  static const _navItems = [
    ('🏠', 'หน้าหลัก'),
    ('🤝', 'รับซื้อ'),
    ('🏪', 'ร้านของฉัน'),
    ('📈', 'รายงาน'),
    ('👤', 'โปรไฟล์'),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  ShopInfo? _shop; // null = บัญชีนี้ยังไม่มีร้าน
  int _purchaseVersion = 0; // เพิ่มทุกครั้งที่รับซื้อ/ยกเลิก ให้แท็บรายงานโหลดใหม่
  int _incomingCount = 0; // ล็อตที่เกษตรกรส่งมา รอร้านยืนยัน -> ตัวเลขบนแท็บ "รับซื้อ"

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  /// โหลดข้อมูลร้านของบัญชีที่ล็อกอินอยู่
  /// silent = true: โหลดเงียบๆ หลังแก้ข้อมูลร้าน ไม่ขึ้นหน้าโหลดทับ (แท็บที่เปิดอยู่ไม่หาย)
  Future<void> _loadShop({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      final shop = await ShopService.fetchMyShop(userId);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _isLoading = false;
      });
      _refreshIncoming();
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = friendlyError(e);
        _isLoading = false;
      });
    }
  }

  /// นับล็อตที่ส่งมารอร้านยืนยัน (โหลดไม่ได้ก็แค่ไม่แสดงตัวเลข)
  Future<void> _refreshIncoming() async {
    final shop = _shop;
    if (shop == null) return;
    try {
      final lots = await ShopService.fetchIncoming(await AuthService.getUserId() ?? '', shop.shopId);
      if (mounted) setState(() => _incomingCount = lots.length);
    } catch (_) {}
  }

  /// เปลี่ยนแท็บ + เช็กล็อตใหม่ทุกครั้ง (เกษตรกรอาจส่งล็อตมาระหว่างที่เปิดแอปค้างไว้)
  void _goTab(int index) {
    setState(() => _currentIndex = index);
    _refreshIncoming();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)));
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadShop, child: const Text('ลองใหม่')),
            ],
          ),
        ),
      );
    } else {
      body = IndexedStack(
        index: _currentIndex,
        children: [
          ShopDashboardScreen(shop: _shop, onGoTab: _goTab),
          ShopPurchaseScreen(
            shop: _shop,
            onChanged: () {
              setState(() => _purchaseVersion++);
              _loadShop(silent: true); // แดชบอร์ดโหลดยอดใหม่ตาม
            },
            onGoMyShop: () => _goTab(2),
          ),
          MyShopScreen(shop: _shop, onChanged: () => _loadShop(silent: true)),
          ShopReportScreen(shop: _shop, dataVersion: _purchaseVersion),
          const ProfileScreen(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      body: body,
      bottomNavigationBar: ButtonNav(
        currentIndex: _currentIndex,
        onTap: _goTab,
        badges: {1: _incomingCount}, // แท็บ "รับซื้อ"
        items: _navItems,
        color: theme.primary,
      ),
    );
  }
}
