// ============================================================
// shop_purchase_screen.dart — แท็บ "รับซื้อ" ของร้านรับซื้อ (ภาพ 4.3.4)
//
// - ปุ่ม "บันทึกการรับซื้อ" -> RecordPurchaseScreen
// - ประวัติการรับซื้อ กรองช่วงเวลา (วันนี้ / 7 วัน / เดือนนี้ / ทั้งหมด) จัดกลุ่มตามวัน
// - กด ⋮ ที่รายการ = ยกเลิกการรับซื้อ (ผลผลิตของเกษตรกรกลับเป็น "รอขาย")
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/screens/shop/record_purchase_screen.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';

class ShopPurchaseScreen extends StatefulWidget {
  final ShopInfo? shop;

  /// บันทึก/ยกเลิกแล้ว ให้หน้าแม่รีเฟรชแดชบอร์ด
  final VoidCallback onChanged;

  /// ไปแท็บร้านของฉัน (กรณียังไม่มีร้าน)
  final VoidCallback onGoMyShop;

  const ShopPurchaseScreen({super.key, required this.shop, required this.onChanged, required this.onGoMyShop});

  @override
  State<ShopPurchaseScreen> createState() => _ShopPurchaseScreenState();
}

class _ShopPurchaseScreenState extends State<ShopPurchaseScreen> {
  static const theme = RoleTheme.shop;
  static const _ranges = ['วันนี้', '7 วัน', 'เดือนนี้', 'ทั้งหมด'];
  final NumberFormat _money = NumberFormat('#,##0');
  final NumberFormat _kg = NumberFormat('#,##0.##');

  Future<List<ShopPurchase>>? _future;
  int _range = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ShopPurchaseScreen old) {
    super.didUpdateWidget(old);
    if (old.shop?.shopId != widget.shop?.shopId) _load();
  }

  void _load() {
    final shop = widget.shop;
    if (shop == null) return;
    setState(() {
      _future = ShopService.fetchPurchases(shop.shopId);
    });
  }

  /// กรองตามช่วงเวลาที่เลือก
  List<ShopPurchase> _filter(List<ShopPurchase> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((p) {
      final d = DateTime(p.date.year, p.date.month, p.date.day);
      return switch (_range) {
        0 => d == today,
        1 => !d.isBefore(today.subtract(const Duration(days: 6))),
        2 => d.year == today.year && d.month == today.month,
        _ => true,
      };
    }).toList();
  }

  Future<void> _openRecord() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RecordPurchaseScreen(shop: widget.shop!)),
    );
    if (saved == true) {
      _load();
      widget.onChanged();
    }
  }

  Future<void> _cancel(ShopPurchase p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยกเลิกการรับซื้อ?'),
        content: Text(
          '${p.farmerName} · ${_kg.format(p.quantity)} กก. · ฿${_money.format(p.totalPrice)}\n\n'
          'ผลผลิตของเกษตรกรจะกลับเป็น "รอขาย" และรายรับฝั่งเกษตรกรจะหายไป',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ไม่ใช่')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ยกเลิกการรับซื้อ'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ShopService.cancelPurchase(await AuthService.getUserId() ?? '', p.purchaseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยกเลิกการรับซื้อแล้ว')));
      _load();
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: shop == null
              ? _buildNoShop()
              : RefreshIndicator(
                  color: theme.primary,
                  onRefresh: () async {
                    _load();
                    try {
                      await _future;
                    } catch (_) {}
                  },
                  child: FutureBuilder<List<ShopPurchase>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.primary));
                      }
                      if (snap.hasError) {
                        return ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                snap.error.toString().replaceFirst('Exception: ', ''),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      }
                      return _buildList(_filter(snap.data ?? []));
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: theme.headerGradient),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🤝', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'รับซื้อผลผลิต',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.shop == null ? null : _openRecord,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('บันทึกการรับซื้อ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primaryDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoShop() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏪', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text('ยังไม่มีร้าน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('สร้างร้านก่อนจึงจะบันทึกการรับซื้อได้', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: widget.onGoMyShop,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary),
              ),
              child: const Text('ไปที่ร้านของฉัน'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ShopPurchase> items) {
    final totalKg = items.fold<double>(0, (s, p) => s + p.quantity);
    final totalAmount = items.fold<double>(0, (s, p) => s + p.totalPrice);

    // จัดกลุ่มตามวัน (รายการเรียงใหม่สุดก่อนจากเซิร์ฟเวอร์แล้ว)
    final groups = <DateTime, List<ShopPurchase>>{};
    for (final p in items) {
      groups.putIfAbsent(DateTime(p.date.year, p.date.month, p.date.day), () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_ranges.length, (i) {
              final selected = _range == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_ranges[i]),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: theme.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: selected ? theme.primary : theme.border),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey[800]),
                  onSelected: (_) => setState(() => _range = i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.soft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              _summaryCell('รายการ', '${items.length}'),
              _summaryCell('น้ำหนักรวม', '${_kg.format(totalKg)} กก.'),
              _summaryCell('ยอดซื้อ', '฿${_money.format(totalAmount)}'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Text('📭', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text('ยังไม่มีการรับซื้อในช่วงนี้', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text(
              _dayLabel(entry.key),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ),
          ...entry.value.map(_purchaseTile),
        ],
      ],
    );
  }

  Widget _summaryCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'วันนี้';
    if (d == today.subtract(const Duration(days: 1))) return 'เมื่อวาน';
    return '${DateFormat('EEEE d MMMM', 'th_TH').format(d)} ${d.year + 543}';
  }

  Widget _purchaseTile(ShopPurchase p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.soft,
            child: Text(
              p.farmerName.isEmpty ? '?' : p.farmerName.characters.first,
              style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.farmerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_kg.format(p.quantity)} กก. × ${p.pricePerKg.toStringAsFixed(2)} ฿'
                  '${p.gardenName.isEmpty ? '' : ' · ${p.gardenName}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '฿${_money.format(p.totalPrice)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.primaryDark),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            onSelected: (_) => _cancel(p),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.undo, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('ยกเลิกการรับซื้อ', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
