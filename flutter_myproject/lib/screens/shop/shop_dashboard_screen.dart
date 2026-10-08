// ============================================================
// shop_dashboard_screen.dart — แท็บ "หน้าหลัก" ของร้านรับซื้อ (ภาพ 4.3.1)
//
// ส่วนหัวโทนส้ม + การ์ดสถิติ (รับซื้อวันนี้ / ยอดซื้อเดือนนี้), ราคารับซื้อวันนี้,
// ปุ่มลัด และรายการรับซื้อล่าสุด
// ข้อมูล: GET /api/shop/:shopId/dashboard
// ใช้ใน ShopHomeScreen (ไม่มี Scaffold/AppBar ของตัวเอง แถบเมนูอยู่ที่หน้าแม่)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/utils/error_message.dart';

class ShopDashboardScreen extends StatefulWidget {
  /// ร้านของบัญชีนี้ (null = ยังไม่มีร้าน)
  final ShopInfo? shop;

  /// สั่งให้หน้าแม่เปลี่ยนแท็บ (1 = รับซื้อ, 2 = ร้านของฉัน)
  final ValueChanged<int> onGoTab;

  const ShopDashboardScreen({super.key, required this.shop, required this.onGoTab});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  static const theme = RoleTheme.shop;
  final NumberFormat _money = NumberFormat('#,##0');
  final NumberFormat _price = NumberFormat('#,##0.00');

  Future<ShopDashboardData>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ShopDashboardScreen old) {
    super.didUpdateWidget(old);
    // หน้าแม่โหลดข้อมูลร้านใหม่ (แก้ร้าน/ราคาในแท็บร้านของฉัน) -> โหลดแดชบอร์ดใหม่ตาม
    if (old.shop != widget.shop) _load();
  }

  void _load() {
    final shop = widget.shop;
    if (shop == null) return;
    setState(() {
      _future = ShopService.fetchDashboard(shop.shopId);
    });
  }

  Future<void> _refresh() async {
    _load();
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return RefreshIndicator(
      color: theme.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(shop),
          if (shop == null)
            _buildNoShopCard()
          else
            FutureBuilder<ShopDashboardData>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          friendlyError(snap.error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
                      ],
                    ),
                  );
                }
                return _buildContent(snap.data!);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------- ส่วนหัวโทนส้ม ----------

  Widget _buildHeader(ShopInfo? shop) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.headerGradient,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                    ),
                    child: const Center(child: Text('🏪', style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ร้านรับซื้อ · PalmTrack',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shop?.name ?? 'ยังไม่มีร้าน',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (shop != null) _statusPill(shop.isOpen),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        formatThaiDate(DateTime.now()),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
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

  Widget _statusPill(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? '● เปิดรับซื้อ' : '● ปิดชั่วคราว',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isOpen ? const Color(0xFF2E7D32) : Colors.white,
        ),
      ),
    );
  }

  // ---------- เนื้อหา ----------

  Widget _buildContent(ShopDashboardData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _statCard('รับซื้อวันนี้', formatNumber(d.todayKg), 'กก.', Icons.scale_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('ยอดซื้อเดือนนี้', _money.format(d.monthAmount), '฿', Icons.payments_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceCard(d.rates),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _actionButton('🤝', 'บันทึกการรับซื้อ', () => widget.onGoTab(1))),
              const SizedBox(width: 12),
              Expanded(child: _actionButton('🏷️', 'ตั้งราคารับซื้อ', () => widget.onGoTab(2))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('การรับซื้อล่าสุด', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: Text(
                  'ทั้งหมด ${formatNumber(d.totalKg)} กก. · ${d.totalFarmers} ราย',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (d.recent.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text('ยังไม่มีการรับซื้อ',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
            )
          else
            ...d.recent.map(_purchaseCard),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: theme.soft, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: theme.primary),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดราคารับซื้อวันนี้ (เตือนถ้ายังไม่ได้ตั้งราคา หรือราคาหมดอายุแล้ว)
  Widget _buildPriceCard(List<ShopPriceRate> rates) {
    final current = rates.where((r) => r.isCurrent).toList();
    final hasCurrent = current.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasCurrent ? theme.soft : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hasCurrent ? theme.border : const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏷️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('ราคารับซื้อวันนี้', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => widget.onGoTab(2),
                style: TextButton.styleFrom(foregroundColor: theme.primary, visualDensity: VisualDensity.compact),
                child: Text(hasCurrent ? 'แก้ไขราคา' : 'ตั้งราคา'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasCurrent)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: current
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.grade, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text(
                              '${_price.format(r.pricePerKg)} ฿/กก.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primary),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            )
          else
            Text(
              rates.isEmpty
                  ? 'ยังไม่ได้ตั้งราคารับซื้อ เกษตรกรจะยังไม่เห็นราคาของร้าน'
                  : 'ราคาล่าสุดหมดอายุแล้ว (${rates.first.grade} ${_price.format(rates.first.pricePerKg)} ฿/กก.) '
                      'กรุณาตั้งราคาใหม่',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8D6E00), height: 1.4),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(String emoji, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _purchaseCard(ShopPurchase p) {
    final initial = p.farmerName.isNotEmpty ? p.farmerName.characters.first : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.soft,
            child: Text(initial, style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.farmerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${formatNumber(p.quantity)} กก. × ${_price.format(p.pricePerKg)} ฿ · ${formatRelativeDate(p.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_money.format(p.totalPrice)} ฿',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// บัญชีร้านที่ยังไม่มีร้าน (เดิมจะเห็นข้อมูลร้าน S001 แทน)
  Widget _buildNoShopCard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: theme.soft, shape: BoxShape.circle),
            child: const Center(child: Text('🏪', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 20),
          const Text('บัญชีนี้ยังไม่มีข้อมูลร้าน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'ตั้งค่าชื่อร้าน ที่ตั้ง และราคารับซื้อ\nเพื่อให้เกษตรกรเห็นร้านของคุณ',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => widget.onGoTab(2),
            icon: const Icon(Icons.storefront),
            label: const Text('ตั้งค่าร้าน'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
