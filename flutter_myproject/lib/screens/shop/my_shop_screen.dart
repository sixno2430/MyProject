// ============================================================
// my_shop_screen.dart — แท็บ "ร้านของฉัน" ของร้านรับซื้อ (ภาพ 4.3.2 + 4.3.3)
//
// - ยังไม่มีร้าน: ฟอร์มสร้างร้าน
// - มีร้านแล้ว: ข้อมูลร้าน + สวิตช์เปิด/ปิดรับซื้อ + แก้ไขข้อมูล
//               ราคารับซื้อ: เพิ่ม / แก้ไข / ลบ และดูประวัติราคา
// แก้ข้อมูลแล้วเรียก onChanged ให้หน้าแม่โหลดข้อมูลร้านใหม่ (หัวแดชบอร์ดจะอัปเดตตาม)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/models/shop.dart';
import 'package:flutter_myproject/screens/shop/widgets/shop_form_sheet.dart';
import 'package:flutter_myproject/screens/shop/widgets/price_form_sheet.dart';

class MyShopScreen extends StatefulWidget {
  final ShopInfo? shop;
  final VoidCallback onChanged;

  const MyShopScreen({super.key, required this.shop, required this.onChanged});

  @override
  State<MyShopScreen> createState() => _MyShopScreenState();
}

class _MyShopScreenState extends State<MyShopScreen> {
  static const theme = RoleTheme.shop;
  final NumberFormat _price = NumberFormat('#,##0.00');

  Future<List<ShopPriceRate>>? _pricesFuture;
  bool _savingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  void didUpdateWidget(MyShopScreen old) {
    super.didUpdateWidget(old);
    // เพิ่งสร้างร้าน / เปลี่ยนร้าน -> โหลดราคาของร้านใหม่
    if (old.shop?.shopId != widget.shop?.shopId) _loadPrices();
  }

  void _loadPrices() {
    final shop = widget.shop;
    if (shop == null) return;
    setState(() {
      _pricesFuture = ShopService.fetchPrices(shop.shopId);
    });
  }

  Future<String> _userId() async {
    final id = await AuthService.getUserId();
    if (id == null || id.isEmpty) throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    return id;
  }

  void _toast(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red : theme.primary));
  }

  String _err(Object e) => friendlyError(e);

  // ---------- ข้อมูลร้าน ----------

  /// เปิดฟอร์มข้อมูลร้าน (shop = null คือสร้างใหม่)
  Future<void> _openShopForm({ShopInfo? shop}) async {
    final fields = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopFormSheet(shop: shop),
    );
    if (fields == null) return;
    try {
      final userId = await _userId();
      if (shop == null) {
        await ShopService.createShop(userId, fields);
        _toast('สร้างร้านเรียบร้อยแล้ว');
      } else {
        await ShopService.updateShop(userId, shop.shopId, {...fields, 'status': shop.isOpen ? 'ACTIVE' : 'INACTIVE'});
        _toast('บันทึกข้อมูลร้านแล้ว');
      }
      widget.onChanged();
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  /// สวิตช์เปิด/ปิดรับซื้อ
  Future<void> _toggleOpen(ShopInfo shop, bool open) async {
    setState(() => _savingStatus = true);
    try {
      await ShopService.updateShop(await _userId(), shop.shopId, {
        'shop_name': shop.name,
        'location': shop.location,
        'phone': shop.phone,
        'open_schedule': shop.openSchedule,
        'status': open ? 'ACTIVE' : 'INACTIVE',
      });
      _toast(open ? 'เปิดรับซื้อแล้ว' : 'ปิดรับซื้อชั่วคราวแล้ว');
      widget.onChanged();
    } catch (e) {
      _toast(_err(e), error: true);
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  // ---------- ราคา ----------

  Future<void> _openPriceForm({ShopPriceRate? rate}) async {
    final shop = widget.shop!;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PriceFormSheet(shopId: shop.shopId, rate: rate),
    );
    if (saved == true) {
      _toast(rate == null ? 'เพิ่มราคาแล้ว' : 'แก้ไขราคาแล้ว');
      _loadPrices();
      widget.onChanged();
    }
  }

  Future<void> _priceActions(ShopPriceRate rate) async {
    final action = await showItemActionsSheet(context);
    if (action == null || !mounted) return;
    if (action == ItemAction.edit) {
      _openPriceForm(rate: rate);
      return;
    }
    if (!await confirmDelete(context, '${rate.grade} ${_price.format(rate.pricePerKg)} ฿/กก.')) return;
    try {
      await ShopService.deletePrice(await _userId(), rate.id!);
      _toast('ลบราคาแล้ว');
      _loadPrices();
      widget.onChanged();
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return RefreshIndicator(
      color: theme.primary,
      onRefresh: () async {
        widget.onChanged();
        _loadPrices();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHeader(shop),
          if (shop == null) _buildCreateShop() else ...[_buildShopInfoCard(shop), _buildPricesSection()],
        ],
      ),
    );
  }

  Widget _buildHeader(ShopInfo? shop) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: theme.headerGradient),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Row(
            children: [
              const Text('🏪', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ร้านของฉัน',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      shop == null ? 'ตั้งค่าร้านเพื่อเริ่มรับซื้อ' : 'ข้อมูลร้านและราคารับซื้อ',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }

  Widget _buildCreateShop() {
    return _card(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: theme.soft, shape: BoxShape.circle),
            child: const Center(child: Text('🏪', style: TextStyle(fontSize: 38))),
          ),
          const SizedBox(height: 14),
          const Text('สร้างร้านของคุณ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'ใส่ชื่อร้าน ที่ตั้ง และเบอร์โทร\nเกษตรกรจะเห็นร้านของคุณในหน้า "ร้านรับซื้อ"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openShopForm(),
              icon: const Icon(Icons.add_business),
              label: const Text('สร้างร้าน', style: TextStyle(fontWeight: FontWeight.w600)),
              style: _primaryButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard(ShopInfo shop) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openShopForm(shop: shop),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('แก้ไข'),
                style: TextButton.styleFrom(foregroundColor: theme.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on_outlined, shop.location.isEmpty ? 'ยังไม่ระบุที่ตั้ง' : shop.location),
          _infoRow(Icons.phone_outlined, shop.phone.isEmpty ? 'ยังไม่ระบุเบอร์โทร' : shop.phone),
          _infoRow(Icons.access_time, shop.openSchedule.isEmpty ? 'ยังไม่ระบุเวลาเปิด-ปิด' : shop.openSchedule),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.storefront, color: shop.isOpen ? const Color(0xFF2E7D32) : Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.isOpen ? 'เปิดรับซื้อ' : 'ปิดรับซื้อชั่วคราว',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      shop.isOpen ? 'เกษตรกรเห็นร้านเป็น "เปิดรับซื้อ"' : 'เกษตรกรจะเห็นว่าร้านปิดชั่วคราว',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _savingStatus
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Switch(value: shop.isOpen, activeThumbColor: theme.primary, onChanged: (v) => _toggleOpen(shop, v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏷️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('ราคารับซื้อ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () => _openPriceForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มราคา'),
                style: _primaryButton(compact: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ShopPriceRate>>(
            future: _pricesFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))),
                );
              }
              if (snap.hasError) {
                return Text(_err(snap.error!), style: const TextStyle(color: Colors.red));
              }
              final rates = snap.data ?? [];
              if (rates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'ยังไม่มีราคา กด "เพิ่มราคา" เพื่อตั้งราคารับซื้อ',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              // ใช้อยู่ก่อน แล้วตามด้วยเริ่มในอนาคต และหมดอายุ
              const order = {'current': 0, 'upcoming': 1, 'expired': 2};
              final sorted = [...rates]..sort((a, b) => order[a.status]!.compareTo(order[b.status]!));
              return Column(children: sorted.map(_priceTile).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _priceTile(ShopPriceRate r) {
    final (label, color) = switch (r.status) {
      'current' => ('ใช้อยู่', const Color(0xFF2E7D32)),
      'upcoming' => ('เริ่มใช้เร็วๆ นี้', const Color(0xFF1565C0)),
      _ => ('หมดอายุ', Colors.grey),
    };
    final dimmed = r.status == 'expired';
    String d(String? ymd) {
      final dt = DateTime.tryParse(ymd ?? '');
      return dt == null ? '-' : '${DateFormat('d MMM', 'th_TH').format(dt)} ${(dt.year + 543) % 100}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: dimmed ? const Color(0xFFF7F7F7) : theme.soft,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 14, right: 4),
          onTap: () => _priceActions(r),
          title: Text(
            r.grade,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, color: dimmed ? Colors.grey : null),
          ),
          subtitle: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                r.endDate == null ? 'ตั้งแต่ ${d(r.effectiveDate)}' : '${d(r.effectiveDate)} – ${d(r.endDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_price.format(r.pricePerKg)} ฿',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dimmed ? Colors.grey : theme.primary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                onPressed: () => _priceActions(r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButton({bool compact = false}) => ElevatedButton.styleFrom(
    backgroundColor: theme.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 8 : 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ==========================================
// ฟอร์มข้อมูลร้าน (bottom sheet) คืนค่า Map ของช่องที่กรอก
// ==========================================

// ==========================================
// ฟอร์มราคา (bottom sheet) บันทึกเองแล้วคืนค่า true
// ==========================================

// ==========================================
// ส่วนที่ใช้ร่วมกันของฟอร์มทั้งสอง
// ==========================================
