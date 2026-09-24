import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'add_harvest_screen.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';

// ==========================================
// 1. MODELS
// ==========================================

class HarvestData {
  final String id;
  final String gardenId;
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
    required this.code,
    required this.plotName,
    required this.buyer,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalPrice,
    required this.date,
    required this.status,
  });

  factory HarvestData.fromJson(Map<String, dynamic> json) {
    return HarvestData(
      id: json['id']?.toString() ?? '',
      gardenId: json['gardenId']?.toString() ?? '',
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

class HarvestService {
  static String get baseUrl => AppConfig.apiBaseUri;

  // สร้าง query ที่มี user_id ของคนที่ล็อกอินอยู่เสมอ (+ garden_id ถ้ามี)
  Future<Map<String, String>> _buildQuery(String? gardenId) async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }
    return {
      'user_id': userId,
      'garden_id': ?gardenId,
    };
  }

  Future<List<HarvestData>> fetchHarvestRecords({String? gardenId}) async {
    final uri = Uri.parse('$baseUrl/harvests').replace(
      queryParameters: await _buildQuery(gardenId),
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

  Future<HarvestSummary> fetchHarvestSummary({String? gardenId}) async {
    final uri = Uri.parse('$baseUrl/harvests/summary').replace(
      queryParameters: await _buildQuery(gardenId),
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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _summaryFuture = _service.fetchHarvestSummary();
      _harvestsFuture = _service.fetchHarvestRecords();
    });
  }

  // กดค้างที่รายการ -> เลือกแก้ไข / ลบ
  Future<void> _onHarvestLongPress(HarvestData item) async {
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
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
                      child: Text('ข้อผิดพลาด: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    );
                  }
                  final summary = snapshot.data;
                  if (summary == null) return const SizedBox.shrink();

                  final double displayKg = _selectedMonth != null
                      ? (summary.last12MonthsProduction[_selectedMonth] ?? 0)
                      : summary.totalQuantityKg;

                  final String cardTitle = _selectedMonth != null
                      ? 'ผลผลิตเดือน $_selectedMonth'
                      : 'ผลผลิตปีนี้';

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
                      child: Text('ข้อผิดพลาด: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
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

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final bool isSold = item.status == 'sold';

                      return GestureDetector(
                        onLongPress: () => _onHarvestLongPress(item),
                        child: Container(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${item.code} · ${item.plotName}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    // 🟠 Badge ปรับสีส้มและข้อความ "รอขาย" ชัดเจน
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSold ? const Color(0xFFE8F5E9) : const Color(0xFFFFE0B2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isSold ? 'ขายแล้ว' : 'รอขาย',
                                        style: TextStyle(
                                          color: isSold ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.storefront_outlined, size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(item.buyer, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantityKg.toStringAsFixed(0)} กก. × ${item.pricePerKg.toStringAsFixed(1)} บาท',
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              '${item.totalPrice.toStringAsFixed(0)} ฿',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
                            ),
                          ],
                        ),
                      ),
                      );
                    },
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
            'ผลผลิต 12 เดือนล่าสุด (กก.)',
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