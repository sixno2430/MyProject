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
import 'package:flutter_myproject/config/app_config.dart';
import 'add_harvest_screen.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'package:flutter_myproject/utils/error_message.dart';

// ==========================================
// 1. MODELS
// ==========================================

/// ข้อมูลการเก็บเกี่ยว 1 รายการ
class HarvestData {
  final String id;
  final String gardenId;

  /// รหัสร้านในแอป ('' = ไม่มี) รอขาย = ร้านที่จะขายให้, ขายแล้ว = ร้านที่รับซื้อ
  final String shopId;

  /// ชื่อร้านนอกระบบที่พิมพ์เอง ('' = ไม่ระบุ)
  final String buyerName;

  /// วันที่ขาย yyyy-MM-dd ('' = ยังไม่ขาย)
  final String soldDate;

  /// true = ร้านในแอปบันทึกรับซื้อแล้ว แก้/ลบเองไม่ได้
  final bool purchasedByShop;

  /// หมายเหตุที่เกษตรกรพิมพ์เอง ('' = ไม่มี)
  final String note;

  /// เกรดที่ร้านในแอปให้ตอนรับซื้อ ('' = ไม่มี)
  final String grade;

  /// ร้านล่าสุดที่ไม่รับล็อตนี้ + เหตุผล ('' = ไม่มี / เลือกร้านใหม่แล้ว)
  final String rejectedBy;
  final String rejectReason;
  final String code;
  final String plotName;
  final String buyer;
  final double quantityKg;
  final double pricePerKg;
  final double totalPrice;
  final String date;
  final String status;

  HarvestData({
    required this.id,
    this.gardenId = '',
    this.shopId = '',
    this.buyerName = '',
    this.soldDate = '',
    this.purchasedByShop = false,
    this.note = '',
    this.grade = '',
    this.rejectedBy = '',
    this.rejectReason = '',
    required this.code,
    required this.plotName,
    required this.buyer,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalPrice,
    required this.date,
    required this.status,
  });

  /// แปลง JSON จาก API เป็น HarvestData
  factory HarvestData.fromJson(Map<String, dynamic> json) {
    return HarvestData(
      id: json['id']?.toString() ?? '',
      gardenId: json['gardenId']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      soldDate: json['soldDate']?.toString() ?? '',
      // MariaDB ส่งค่า boolean มาเป็น 0/1
      purchasedByShop: json['purchasedByShop'] == true || json['purchasedByShop'] == 1,
      note: json['note']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      rejectedBy: json['rejectedBy']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString() ?? '',
      code: json['code'] ?? '',
      plotName: json['plotName'] ?? json['plot_name'] ?? '',
      buyer: json['buyer'] ?? '',
      quantityKg: (json['quantityKg'] ?? json['quantity_kg'] ?? 0).toDouble(),
      pricePerKg: (json['pricePerKg'] ?? json['price_per_kg'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? json['total_price'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      status: json['status'] ?? 'sold',
    );
  }
}

/// ข้อมูลสรุป: ผลผลิตรวม, รายได้ (เฉพาะที่ขายแล้ว), ราคาเฉลี่ย, ผลผลิตรายเดือน
class HarvestSummary {
  final double totalQuantityKg;
  final double totalRevenue;
  final double averagePrice;
  final Map<String, double> last12MonthsProduction;

  HarvestSummary({
    required this.totalQuantityKg,
    required this.totalRevenue,
    required this.averagePrice,
    required this.last12MonthsProduction,
  });

  /// แปลง JSON จาก API เป็น HarvestSummary
  factory HarvestSummary.fromJson(Map<String, dynamic> json) {
    return HarvestSummary(
      totalQuantityKg: (json['totalQuantityKg'] ?? json['total_quantity_kg'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? json['total_revenue'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? json['average_price'] ?? 0).toDouble(),
      last12MonthsProduction: Map<String, double>.from(
        (json['last12MonthsProduction'] ?? json['last6MonthsProduction'] ?? json['monthly_production'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SERVICE
// ==========================================

/// เรียก API การเก็บเกี่ยว (ส่ง user_id ของคนที่ล็อกอินไปทุกครั้ง)
class HarvestService {
  static String get baseUrl => AppConfig.apiBaseUri;

  // สร้าง query ที่มี user_id ของคนที่ล็อกอินอยู่เสมอ (+ garden_id ถ้ามี)
  /// รายชื่อร้านรับซื้อในแอป [{id, name, open}] สำหรับ dropdown (โหลดไม่ได้ = รายการว่าง)
  static Future<List<Map<String, String>>> fetchShops() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shops'));
      final body = jsonDecode(response.body);
      if (body is! Map || body['isError'] == true) return [];
      return (body['data'] as List)
          .map((s) => {
                'id': s['shop_id'].toString(),
                'name': s['shop_name'].toString(),
                'open': (s['status']?.toString().toUpperCase() == 'ACTIVE').toString(),
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, String>> _buildQuery(String? gardenId, int? year) async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }
    return {
      'user_id': userId,
      'garden_id': ?gardenId,
      if (year != null) 'year': '$year',
    };
  }

  /// ดึงรายการเก็บเกี่ยวของปีที่กำหนด (ไม่ส่ง year = ปีนี้)
  Future<List<HarvestData>> fetchHarvestRecords({String? gardenId, int? year}) async {
    final uri = Uri.parse('$baseUrl/harvests').replace(
      queryParameters: await _buildQuery(gardenId, year),
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);

      if (resMap is Map) {
        if (resMap['isError'] == false && resMap['data'] != null) {
          final data = resMap['data'];

          if (data is List) {
            return data.map((item) => HarvestData.fromJson(item)).toList();
          }

          if (data is Map) {
            final listData = data['items'] ?? data['harvests'] ?? data['records'] ?? data['rows'];
            if (listData is List) {
              return listData.map((item) => HarvestData.fromJson(item)).toList();
            }
          }

          return [];
        } else {
          throw Exception(resMap['errorMessage'] ?? 'ไม่สามารถดึงข้อมูลได้');
        }
      } else if (resMap is List) {
        return resMap.map((item) => HarvestData.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    }
  }

  /// ดึงข้อมูลสรุปและผลผลิตรายเดือนของปีนี้
  Future<HarvestSummary> fetchHarvestSummary({String? gardenId, int? year}) async {
    final uri = Uri.parse('$baseUrl/harvests/summary').replace(
      queryParameters: await _buildQuery(gardenId, year),
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      if (resMap is Map) {
        if (resMap['isError'] == false && resMap['data'] != null) {
          return HarvestSummary.fromJson(resMap['data']);
        } else if (resMap['totalQuantityKg'] != null || resMap['total_quantity_kg'] != null) {
          return HarvestSummary.fromJson(resMap as Map<String, dynamic>);
        } else {
          throw Exception(resMap['errorMessage'] ?? 'ไม่สามารถดึงข้อมูลสรุปได้');
        }
      }
      throw Exception('ข้อมูลสรุปรูปแบบไม่ถูกต้อง');
    } else {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    }
  }
}

// ==========================================
// 3. UI SCREEN
// ==========================================

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item.buyer} บันทึกการรับซื้อรายการนี้แล้ว แก้ไขหรือลบไม่ได้ หากผิดพลาดให้ติดต่อร้าน'),
      ));
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
      final response = await http.delete(
        Uri.parse('${HarvestService.baseUrl}/harvests/${item.id}?user_id=$userId'),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))),
      );
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHarvestScreen(),
      ),
    );

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
            Text(
              'บันทึกผลผลิต · ราคา · ร้านรับซื้อ',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
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
          )
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
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
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

                  final String cardTitle = _selectedMonth != null
                      ? 'ผลผลิตเดือน $_selectedMonth'
                      : 'ผลผลิตทั้งปี';

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard(cardTitle, displayKg.toStringAsFixed(0), 'กก.')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('รายได้รวม', summary.totalRevenue.toStringAsFixed(0), 'บาท')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('ราคาเฉลี่ย', summary.averagePrice.toStringAsFixed(2), '฿/กก.')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InteractiveChartCard(
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
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
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
      builder: (_) => _SellSheet(item: item),
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
        SnackBar(
          content: Text('บันทึกการขาย ${item.code} แล้ว'),
          backgroundColor: const Color(0xFF1E5631),
        ),
      );
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))),
      );
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSold ? green : Colors.grey,
                    ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E5631))),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ==========================================
// 4. INTERACTIVE CHART COMPONENT
// ==========================================

/// กราฟแท่งผลผลิต 12 เดือน แตะแท่งเพื่อดูตัวเลขของเดือนนั้น
class _InteractiveChartCard extends StatefulWidget {
  final Map<String, double> monthlyData;
  final ValueChanged<String?>? onHoverMonth;

  const _InteractiveChartCard({
    required this.monthlyData,
    this.onHoverMonth,
  });

  @override
  State<_InteractiveChartCard> createState() => _InteractiveChartCardState();
}

class _InteractiveChartCardState extends State<_InteractiveChartCard> {
  String? _hoveredMonth;

  /// จำเดือนที่ถูกแตะ แล้วแจ้งหน้าแม่ให้เปลี่ยนตัวเลขสรุป
  void _updateHover(String? month) {
    setState(() {
      _hoveredMonth = month;
    });
    widget.onHoverMonth?.call(month);
  }

  @override
  Widget build(BuildContext context) {
    double maxKg = widget.monthlyData.values.isNotEmpty
        ? widget.monthlyData.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    if (maxKg == 0) maxKg = 1.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ผลผลิตรายเดือน ม.ค.–ธ.ค. (กก.)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.monthlyData.entries.map((entry) {
                double heightFactor = (entry.value / maxKg).clamp(0.08, 1.0);
                bool hasData = entry.value > 0;
                bool isHovered = _hoveredMonth == entry.key;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => _updateHover(entry.key),
                  onExit: (_) => _updateHover(null),
                  child: GestureDetector(
                    onTap: () => _updateHover(entry.key),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: (isHovered || (hasData && _hoveredMonth == null)) ? 1.0 : 0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: isHovered
                                ? BoxDecoration(
                                    color: const Color(0xFF1E5631),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              entry.value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: isHovered ? 10 : 9,
                                color: isHovered ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isHovered ? 20 : 16,
                          height: 85 * heightFactor,
                          decoration: BoxDecoration(
                            color: isHovered
                                ? const Color(0xFF143B21)
                                : (hasData ? const Color(0xFF1E5631) : const Color(0xFFC8E6C9)),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isHovered
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1E5631).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                            color: isHovered ? const Color(0xFF1E5631) : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. BOTTOM SHEET: บันทึกขายนอกระบบ
// ==========================================

/// ขายให้ร้านที่ไม่อยู่ในแอป: ถามราคาต่อกิโลกรัม ชื่อร้าน (ไม่บังคับ) และวันที่ขาย
/// คำนวณรายได้ให้ดูทันที แล้วคืนค่าที่กรอก
class _SellSheet extends StatefulWidget {
  final HarvestData item;
  const _SellSheet({required this.item});

  @override
  State<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<_SellSheet> {
  static const green = Color(0xFF1E5631);
  late final TextEditingController _priceCtrl;
  final _buyerCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  DateTime _soldDate = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.item.pricePerKg;
    _priceCtrl = TextEditingController(
      text: p > 0 ? (p % 1 == 0 ? p.toInt().toString() : p.toString()) : '',
    );
    _priceCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _buyerCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  /// ราคาที่กรอก (null ถ้าไม่ใช่ตัวเลข)
  double? get _price => double.tryParse(_priceCtrl.text.trim());

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    // ขายได้ตั้งแต่วันเก็บเกี่ยวถึงวันนี้ (วันเก็บเกี่ยวอยู่ในอนาคต = เริ่มที่วันนี้ กัน firstDate > lastDate)
    final today = DateUtils.dateOnly(DateTime.now());
    final harvested = DateTime.tryParse(widget.item.date);
    final first = harvested == null || harvested.isAfter(today) ? today : harvested;
    final picked = await showDatePicker(
      context: context,
      initialDate: _soldDate.isBefore(first) ? first : _soldDate,
      firstDate: first,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _soldDate = picked);
  }

  /// ตรวจว่าราคามากกว่า 0 แล้วปิด sheet พร้อมส่งค่ากลับ
  void _confirm() {
    final price = _price;
    if (price == null || price <= 0) {
      setState(() => _error = 'กรุณาใส่ราคาที่มากกว่า 0');
      return;
    }
    Navigator.pop(context, (
      price: price,
      buyerName: _buyerCtrl.text.trim(),
      soldDate: _ymd(_soldDate),
      grade: _gradeCtrl.text.trim(),
    ));
  }

  InputDecoration _decoration(String label, IconData icon, {String? suffix, String? hint, String? error}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      errorText: error,
      prefixIcon: Icon(icon, color: green),
      floatingLabelStyle: const TextStyle(color: green),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = (_price ?? 0) * item.quantityKg;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ขายนอกระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${item.code} · ${item.plotName} · ${item.quantityKg.toStringAsFixed(0)} กก.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                // บอกทางที่ถูกถ้าร้านอยู่ในแอป: ให้ร้านเป็นคนยืนยัน ยอดสองฝั่งจะได้ตรงกัน
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFFC2410C)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ขายให้ร้านที่อยู่ในแอป? กดค้างที่รายการ > แก้ไข แล้วเลือกร้าน '
                          'ร้านจะเป็นคนยืนยันรับซื้อ',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF7C2D12), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: green,
                  decoration: _decoration('ราคาขายต่อกิโลกรัม', Icons.payments_outlined,
                      suffix: 'บาท/กก.', error: _error),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buyerCtrl,
                  cursorColor: green,
                  maxLength: 100,
                  decoration: _decoration('ชื่อร้านที่ขายให้ (ไม่บังคับ)', Icons.storefront_outlined,
                          hint: 'เช่น ลานเทสมชาย')
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                GradePicker(controller: _gradeCtrl),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration('วันที่ขาย', Icons.calendar_today_outlined),
                    child: Text('${_soldDate.day}/${_soldDate.month}/${_soldDate.year + 543}'),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('รายได้จากการขาย', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${total.toStringAsFixed(2)} ฿',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันขายแล้ว', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. เลือกร้านในแอปที่จะขายให้ (ใช้ในฟอร์มเก็บเกี่ยว ตอนสถานะรอขาย)
// ==========================================

/// Dropdown เลือกร้านรับซื้อในแอป ตัวเลือกแรกคือ "ยังไม่เลือกร้าน" (value = null)
/// ร้านที่ปิดรับซื้อชั่วคราวแสดงไว้แต่เลือกไม่ได้
class ShopDropdown extends StatelessWidget {
  final List<Map<String, String>> shops;
  final String? value;
  final ValueChanged<String?> onChanged;

  const ShopDropdown({
    super.key,
    required this.shops,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ค่าที่เลือกต้องมีอยู่ในรายการ ไม่งั้น Dropdown จะ error (เช่น ตอนรายชื่อร้านยังโหลดไม่เสร็จ)
    final safeValue = shops.any((s) => s['id'] == value) ? value : null;
    return DropdownButtonFormField<String?>(
      // initialValue ถูกอ่านแค่ตอนสร้าง -> เปลี่ยน key เมื่อรายชื่อร้าน/ค่าที่เลือกเปลี่ยน ให้สร้างใหม่แสดงค่าที่ถูกต้อง
      key: ValueKey('${shops.length}-$safeValue'),
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'ร้านในแอปที่จะขายให้',
        prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFF1E5631)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('ยังไม่เลือกร้าน')),
        ...shops.map((s) {
          final open = s['open'] != 'false';
          return DropdownMenuItem<String?>(
            value: s['id'],
            enabled: open || s['id'] == value,
            child: Text(
              open ? s['name']! : '${s['name']} (ปิดรับซื้อชั่วคราว)',
              overflow: TextOverflow.ellipsis,
              style: open ? null : const TextStyle(color: Colors.grey),
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

/// ข้อความใต้ช่องเลือกร้าน บอกว่าการเลือกนี้มีผลยังไง
class ShopSaleHint extends StatelessWidget {
  final String? shopName; // null = ยังไม่เลือกร้าน
  const ShopSaleHint({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    final chosen = shopName != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(chosen ? Icons.sync_alt : Icons.info_outline, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            chosen
                ? '$shopName จะเห็นล็อตนี้ และเป็นคนกดยืนยันรับซื้อ รายการจะเปลี่ยนเป็น "ขายแล้ว" เอง'
                : 'ร้านในแอปค้นหาแล้วรับซื้อได้ หรือคุณบันทึก "ขายนอกระบบ" เองภายหลัง',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 6. เลือกเกรดที่ขาย (ใช้ในหน้าต่างขายนอกระบบ และฟอร์มเก็บเกี่ยว)
// ==========================================

/// ปุ่มลัดเกรดที่ใช้บ่อย + ช่องพิมพ์เอง (ไม่บังคับ) ค่าอยู่ใน controller
class GradePicker extends StatefulWidget {
  final TextEditingController controller;
  const GradePicker({super.key, required this.controller});

  static const quickGrades = ['เกรด A', 'เกรด B', 'เกรด C', 'ลูกร่วง', 'ทะลายสด'];

  @override
  State<GradePicker> createState() => _GradePickerState();
}

class _GradePickerState extends State<GradePicker> {
  static const green = Color(0xFF1E5631);

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GradePicker.quickGrades.map((g) {
            final selected = current == g;
            return ChoiceChip(
              label: Text(g),
              selected: selected,
              showCheckmark: false,
              selectedColor: green,
              backgroundColor: const Color(0xFFF1F8F3),
              side: BorderSide(color: selected ? green : const Color(0xFFD5E8DB)),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey[800], fontSize: 13),
              // แตะซ้ำที่เกรดที่เลือกอยู่ = ยกเลิก (ไม่ระบุเกรด)
              onSelected: (_) => setState(() => widget.controller.text = selected ? '' : g),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.controller,
          maxLength: 100,
          cursorColor: green,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'เกรดที่ขาย (ไม่บังคับ)',
            hintText: 'เลือกด้านบน หรือพิมพ์เอง',
            counterText: '',
            prefixIcon: const Icon(Icons.grade_outlined, color: green),
            floatingLabelStyle: const TextStyle(color: green),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
