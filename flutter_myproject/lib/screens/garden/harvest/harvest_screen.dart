// ============================================================
// harvest_screen.dart — หน้า "บันทึกการเก็บเกี่ยว"
//
// แสดงสรุปผลผลิตปีนี้, กราฟรายเดือน และรายการเก็บเกี่ยว
// กรองตามสถานะ (ทั้งหมด / รอขาย / ขายแล้ว)
// รอขายที่เลือกร้านในแอปไว้ = รอร้านยืนยันรับซื้อ, ยังไม่เลือกร้าน = บันทึก "ขายนอกระบบ" เองได้
// API: GET /api/harvests, GET /api/harvests/summary, PUT /api/harvests/:id/sell, DELETE /api/harvests/:id
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_harvest_screen.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/models/harvest.dart';
import 'package:flutter_myproject/services/harvest_service.dart';
import 'package:flutter_myproject/screens/garden/harvest/widgets/harvest_monthly_chart.dart';
import 'package:flutter_myproject/screens/garden/harvest/widgets/sell_sheet.dart';

// model: models/harvest.dart · เรียก API: services/harvest_service.dart
// widget ย่อย: widgets/harvest_monthly_chart.dart (กราฟ), widgets/sell_sheet.dart (ขายนอกระบบ)

/// หน้าบันทึกการเก็บเกี่ยว
class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final HarvestService _service = HarvestService();
  late Future<HarvestSummary> _summaryFuture;
  late Future<List<HarvestData>> _harvestsFuture;

  String? _selectedMonth;

  /// ปีที่กำลังดู (ค.ศ.) เลื่อนดูปีก่อนๆ ได้
  int _year = DateTime.now().year;

  /// แท็บกรองรายการ: 'all' | 'pending' | 'sold'
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  /// โหลดสรุปและรายการใหม่ทั้งคู่
  void _refreshData() {
    setState(() {
      _summaryFuture = _service.fetchHarvestSummary(year: _year);
      _harvestsFuture = _service.fetchHarvestRecords(year: _year);
    });
  }

  // กดค้างที่รายการ -> เลือกแก้ไข / ลบ
  /// กดค้างที่การ์ด: เลือกแก้ไข (เปิดฟอร์ม) หรือลบ
  Future<void> _onHarvestLongPress(HarvestData item) async {
    // ร้านในแอปบันทึกรับซื้อแล้ว แก้/ลบเองไม่ได้ (กันข้อมูลร้านกับเกษตรกรไม่ตรงกัน)
    if (item.purchasedByShop) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.buyer} บันทึกการรับซื้อรายการนี้แล้ว แก้ไขหรือลบไม่ได้ หากผิดพลาดให้ติดต่อร้าน'),
        ),
      );
      return;
    }
    final action = await showItemActionsSheet(context);
    if (action == null || !mounted) return;

    if (action == ItemAction.edit) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddHarvestScreen(existing: item)),
      );
      if (result == true) _refreshData();
      return;
    }

    if (!await confirmDelete(context, '${item.code} · ${item.plotName}')) return;
    final userId = await AuthService.getUserId();
    try {
      final response = await http.delete(Uri.parse('${HarvestService.baseUrl}/harvests/${item.id}?user_id=$userId'));
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  /// เปิดฟอร์มบันทึกการเก็บเกี่ยวใหม่ กลับมาแล้วโหลดใหม่
  /// แถบเลือกปี (ลูกศรซ้าย/ขวา) ไม่ให้เลือกปีอนาคต
  Widget _buildYearSelector() {
    const green = Color(0xFF1E5631);
    final isCurrentYear = _year >= DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: green),
          onPressed: () {
            _year--;
            _selectedMonth = null;
            _refreshData();
          },
        ),
        Flexible(
          child: Text(
            'ปี พ.ศ. ${_year + 543}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: green),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: isCurrentYear ? Colors.grey[300] : green),
          onPressed: isCurrentYear
              ? null
              : () {
                  _year++;
                  _selectedMonth = null;
                  _refreshData();
                },
        ),
      ],
    );
  }

  Future<void> _navigateToAddHarvest() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddHarvestScreen()));

    if (result == true || result != null) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E5631),
        elevation: 0,
        title: const Column(
          children: [
            Text(
              'บันทึกการเก็บเกี่ยว',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 2),
            Text('บันทึกผลผลิต · ราคา · ร้านรับซื้อ', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: _navigateToAddHarvest,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 0. เลือกปี ---
              _buildYearSelector(),
              const SizedBox(height: 8),

              // --- 1. สรุปภาพรวม (Summary) ---
              FutureBuilder<HarvestSummary>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(friendlyError(snapshot.error), style: const TextStyle(color: Colors.red)),
                    );
                  }
                  final summary = snapshot.data;
                  if (summary == null) return const SizedBox.shrink();

                  final double displayKg = _selectedMonth != null
                      ? (summary.last12MonthsProduction[_selectedMonth] ?? 0)
                      : summary.totalQuantityKg;

                  final String cardTitle = _selectedMonth != null ? 'ผลผลิตเดือน $_selectedMonth' : 'ผลผลิตทั้งปี';

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard(cardTitle, formatNumber(displayKg), 'กก.')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('รายได้รวม', formatNumber(summary.totalRevenue), 'บาท')),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard('ราคาเฉลี่ย', summary.averagePrice.toStringAsFixed(2), '฿/กก.'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      HarvestMonthlyChart(
                        monthlyData: summary.last12MonthsProduction,
                        onHoverMonth: (month) {
                          setState(() {
                            _selectedMonth = month;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- 2. รายการเก็บเกี่ยว (List) ---
              const Text('รายการเก็บเกี่ยว', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              FutureBuilder<List<HarvestData>>(
                future: _harvestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(friendlyError(snapshot.error), style: const TextStyle(color: Colors.red)),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('ยังไม่มีข้อมูลการเก็บเกี่ยว', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  // นับจำนวนแต่ละสถานะไว้แสดงบนแท็บ
                  final pendingCount = items.where((i) => i.status != 'sold').length;
                  final soldCount = items.length - pendingCount;
                  final shown = switch (_statusFilter) {
                    'pending' => items.where((i) => i.status != 'sold').toList(),
                    'sold' => items.where((i) => i.status == 'sold').toList(),
                    _ => items,
                  };

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // เลื่อนซ้าย-ขวาได้ จอแคบชิปจะได้ไม่ล้น
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'ทั้งหมด', items.length),
                            const SizedBox(width: 8),
                            _buildFilterChip('pending', 'รอขาย', pendingCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('sold', 'ขายแล้ว', soldCount),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (shown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('ไม่มีรายการในหมวดนี้', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ...shown.map(_buildHarvestCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5631),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: _navigateToAddHarvest,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'บันทึกการเก็บเกี่ยว',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ── บันทึก "ขายนอกระบบ" ให้รายการรอขายที่ไม่ได้เลือกร้านในแอป: ถามราคา ชื่อร้าน วันที่ขาย ──
  //    ขายให้ร้านในแอป ร้านเป็นคนยืนยันรับซื้อ (เกษตรกรเลือกร้านไว้ในฟอร์มแก้ไข)
  Future<void> _markAsSold(HarvestData item) async {
    final sale = await showModalBottomSheet<({double price, String buyerName, String soldDate, String grade})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellSheet(item: item),
    );
    if (sale == null || !mounted) return;

    final userId = await AuthService.getUserId();
    try {
      final response = await http.put(
        Uri.parse('${HarvestService.baseUrl}/harvests/${item.id}/sell'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'price_per_kg': sale.price,
          'buyer_name': sale.buyerName,
          'sold_date': sale.soldDate,
          'quality_grade': sale.grade,
        }),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกการขาย ${item.code} แล้ว'), backgroundColor: const Color(0xFF1E5631)),
      );
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  /// ปุ่มกรองสถานะ พร้อมจำนวนรายการ
  Widget _buildFilterChip(String value, String label, int count) {
    final selected = _statusFilter == value;
    const green = Color(0xFF1E5631);
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? green : Colors.grey.shade300),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// การ์ดเก็บเกี่ยว 1 รายการ (รายการรอขายมีปุ่ม "ขายแล้ว" ด้านล่าง)
  Widget _buildHarvestCard(HarvestData item) {
    final bool isSold = item.status == 'sold';
    const green = Color(0xFF1E5631);
    const orange = Color(0xFFE65100);

    return GestureDetector(
      onLongPress: () => _onHarvestLongPress(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // รอขาย = มีขอบส้มบางๆ ให้เห็นชัดว่ายังต้องจัดการ
          border: isSold ? null : Border.all(color: orange.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${item.code} · ${item.plotName}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSold ? const Color(0xFFE8F5E9) : const Color(0xFFFFE0B2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isSold ? 'ขายแล้ว' : 'รอขาย',
                                style: TextStyle(
                                  color: isSold ? const Color(0xFF2E7D32) : orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            // จอแคบ: วันที่กับชื่อร้านหดตัดเป็น ... ได้ทั้งคู่ ไม่ล้นขวา
                            Flexible(
                              child: Text(
                                item.date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.storefront_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.buyer,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSold || item.pricePerKg > 0
                              ? '${item.grade.isEmpty ? '' : '${item.grade} · '}'
                                    '${item.quantityKg.toStringAsFixed(0)} กก. × ${item.pricePerKg.toStringAsFixed(2)} บาท'
                              : '${item.quantityKg.toStringAsFixed(0)} กก. · ยังไม่ได้ขาย',
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                        // หมายเหตุ (ถ้ามี) บรรทัดเดียว ยาวเกินตัดเป็น ...
                        if (item.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📝 ${item.note}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0)} ฿',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isSold ? green : Colors.grey),
                  ),
                ],
              ),
            ),

            // ── ปุ่มขาย เฉพาะรายการที่ยังรอขาย ──
            // ── รอขาย: เลือกร้านในแอปไว้ = รอร้านยืนยัน (ไม่มีปุ่ม), ยังไม่เลือก = ปุ่มบันทึกขายนอกระบบ ──
            if (!isSold && item.shopId.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  border: Border(top: BorderSide(color: orange.withValues(alpha: 0.2))),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, size: 16, color: orange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'รอร้านยืนยันรับซื้อ · กดค้างเพื่อเปลี่ยนร้าน',
                        style: TextStyle(color: orange, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              )
            else if (!isSold) ...[
              // ร้านที่เลือกไว้ไม่รับ -> บอกเหตุผล (หายเองเมื่อเลือกร้านใหม่)
              if (item.rejectedBy.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border(top: BorderSide(color: Colors.red.withValues(alpha: 0.15))),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.block, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.rejectedBy} ไม่รับ: ${item.rejectReason}\nกดค้างที่รายการเพื่อเลือกร้านใหม่',
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: () => _markAsSold(item),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.06),
                    border: Border(top: BorderSide(color: orange.withValues(alpha: 0.2))),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sell_outlined, size: 18, color: orange),
                      SizedBox(width: 6),
                      Text(
                        'บันทึกขายนอกระบบ',
                        style: TextStyle(color: orange, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// การ์ดสรุป 1 ช่อง (ผลผลิต / รายได้ / ราคาเฉลี่ย)
  Widget _buildSummaryCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
          ),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
