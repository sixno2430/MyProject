// ============================================================
// store_screen.dart — หน้า "ร้านรับซื้อปาล์ม"
//
// รายชื่อร้าน/ลานเทรับซื้อ พร้อมราคาล่าสุดแต่ละเกรด, เวลาเปิด-ปิด, เบอร์โทร
// และประวัติที่เราเคยขายให้ร้านนั้น เรียงร้านที่เปิดและให้ราคาสูงสุดขึ้นก่อน
// API: GET /api/shops?user_id=...
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';

// ==========================================
// 1. MODEL
// ==========================================

/// ราคารับซื้อ 1 เกรด พร้อมช่วงวันที่ใช้ได้
class PriceRate {
  final String grade;
  final double pricePerKg;
  final String effectiveDate;
  final String? endDate;
  final bool isCurrent;

  PriceRate({
    required this.grade,
    required this.pricePerKg,
    required this.effectiveDate,
    this.endDate,
    required this.isCurrent,
  });

  factory PriceRate.fromJson(Map<String, dynamic> json) => PriceRate(
        grade: json['quality_grade']?.toString() ?? '-',
        pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? 0,
        effectiveDate: json['effective_date']?.toString() ?? '',
        endDate: json['end_date']?.toString(),
        isCurrent: json['is_current'] == true,
      );
}

/// ข้อมูลร้านรับซื้อ 1 ร้าน
class BuyingShop {
  final String id;
  final String name;
  final String location;
  final String phone;
  final bool isActive;
  final String openSchedule;
  final int soldCount;
  final double soldKg;
  final double soldTotal;
  final List<PriceRate> rates;

  BuyingShop({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.isActive,
    required this.openSchedule,
    required this.soldCount,
    required this.soldKg,
    required this.soldTotal,
    required this.rates,
  });

  /// ราคาสูงสุดที่ยังไม่หมดอายุ (ใช้เรียงร้าน) — ไม่มีราคาปัจจุบัน = 0
  double get bestCurrentPrice => rates
      .where((r) => r.isCurrent)
      .fold<double>(0, (best, r) => r.pricePerKg > best ? r.pricePerKg : best);

  factory BuyingShop.fromJson(Map<String, dynamic> json) => BuyingShop(
        id: json['shop_id']?.toString() ?? '',
        name: json['shop_name']?.toString() ?? 'ไม่ระบุชื่อร้าน',
        location: json['location']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        isActive: json['status']?.toString().toUpperCase() == 'ACTIVE',
        openSchedule: json['open_schedule']?.toString() ?? '',
        soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
        soldKg: (json['sold_kg'] as num?)?.toDouble() ?? 0,
        soldTotal: (json['sold_total'] as num?)?.toDouble() ?? 0,
        rates: (json['rates'] as List? ?? []).map((e) => PriceRate.fromJson(e)).toList(),
      );
}

// ==========================================
// 2. UI
// ==========================================

/// หน้า "ร้านรับซื้อ": รายชื่อลานเท/ร้านรับซื้อปาล์ม พร้อมราคารับซื้อล่าสุด
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFD97706);

  final NumberFormat _number = NumberFormat('#,##0');
  final NumberFormat _price = NumberFormat('#,##0.00');

  late Future<List<BuyingShop>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _fetchShops();
  }

  /// ดึงรายชื่อร้าน แล้วเรียง: ร้านที่เปิดก่อน ตามด้วยราคาปัจจุบันสูงสุด
  Future<List<BuyingShop>> _fetchShops() async {
    final userId = await AuthService.getUserId();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUri}/shops?user_id=${userId ?? ''}'),
    );
    final body = jsonDecode(response.body);
    if (body['isError'] == true) throw Exception(body['errorMessage']);
    final shops = (body['data'] as List).map((e) => BuyingShop.fromJson(e)).toList();

    // ร้านที่เปิดอยู่ขึ้นก่อน แล้วเรียงตามราคาปัจจุบันสูงสุด
    shops.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.bestCurrentPrice.compareTo(a.bestCurrentPrice);
    });
    return shops;
  }

  /// ดึงหน้าจอลงเพื่อโหลดใหม่
  Future<void> _refresh() async {
    setState(() {
      _future = _fetchShops();
    });
    try {
      await _future;
    } catch (_) {}
  }

  /// แปลงวันที่เป็นแบบไทยสั้น เช่น "31 ก.ค. 69"
  String _thaiDate(String ymd) {
    final d = DateTime.tryParse(ymd);
    if (d == null) return ymd;
    const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${d.day} ${months[d.month - 1]} ${(d.year + 543) % 100}';
  }

  /// คัดลอกเบอร์โทรร้านไปยังคลิปบอร์ด
  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('คัดลอกเบอร์ $phone แล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('ร้านรับซื้อปาล์ม', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BuyingShop>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(child: ElevatedButton(onPressed: _refresh, child: const Text('ลองใหม่'))),
                ],
              );
            }

            final all = snapshot.data!;
            final q = _query.toLowerCase();
            final shops = q.isEmpty
                ? all
                : all
                    .where((s) => s.name.toLowerCase().contains(q) || s.location.toLowerCase().contains(q))
                    .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchBox(),
                const SizedBox(height: 12),
                Text(
                  'พบ ${shops.length} ร้าน · เรียงตามราคารับซื้อสูงสุด',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                if (shops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        all.isEmpty ? 'ยังไม่มีข้อมูลร้านรับซื้อ' : 'ไม่พบร้านที่ค้นหา',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  )
                else
                  ...shops.map(_buildShopCard),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ช่องค้นหาชื่อร้าน/จังหวัด
  Widget _buildSearchBox() {
    return TextField(
      onChanged: (v) => setState(() => _query = v.trim()),
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อร้าน หรือจังหวัด...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// การ์ดร้าน 1 ร้าน (ข้อมูลติดต่อ + ราคา + ประวัติการขาย)
  Widget _buildShopCard(BuyingShop shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ชื่อร้าน + สถานะ ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🏪', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shop.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: shop.isActive ? const Color(0xFFE8F5E9) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shop.isActive ? 'เปิดรับซื้อ' : 'ปิดชั่วคราว',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: shop.isActive ? const Color(0xFF2E7D32) : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ข้อมูลติดต่อ ──
            if (shop.location.isNotEmpty) _buildInfoRow(Icons.location_on_outlined, shop.location),
            if (shop.openSchedule.isNotEmpty) _buildInfoRow(Icons.access_time, shop.openSchedule),
            if (shop.phone.isNotEmpty)
              InkWell(
                onTap: () => _copyPhone(shop.phone),
                child: _buildInfoRow(Icons.phone_outlined, '${shop.phone}  (แตะเพื่อคัดลอก)'),
              ),
            const SizedBox(height: 10),

            // ── ราคารับซื้อ ──
            const Text('ราคารับซื้อล่าสุด', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (shop.rates.isEmpty)
              Text('ร้านยังไม่ได้ประกาศราคา', style: TextStyle(fontSize: 13, color: Colors.grey[500]))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shop.rates.map(_buildRateChip).toList(),
              ),

            // ── ประวัติที่เราเคยขายให้ร้านนี้ ──
            if (shop.soldCount > 0) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.history, size: 16, color: primaryGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'คุณขายให้ร้านนี้ ${shop.soldCount} ครั้ง · '
                      '${_number.format(shop.soldKg)} กก. · ${_number.format(shop.soldTotal)} บาท',
                      style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// แถวข้อมูลติดต่อ (ไอคอน + ข้อความ)
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  /// ป้ายราคา 1 เกรด (สีเทาถ้าหมดอายุแล้ว)
  Widget _buildRateChip(PriceRate rate) {
    final color = rate.isCurrent ? accent : Colors.grey;
    final until = rate.endDate == null ? '' : ' ถึง ${_thaiDate(rate.endDate!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${rate.grade}  ${_price.format(rate.pricePerKg)} ฿/กก.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            rate.isCurrent ? 'ใช้ได้$until' : 'หมดอายุแล้ว$until',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
