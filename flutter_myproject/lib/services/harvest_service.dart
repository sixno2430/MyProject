import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. MODELS (วางไว้ส่วนบนของไฟล์)
// ==========================================

class HarvestData {
  final String id;
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
      code: json['code'] ?? '',
      plotName: json['plotName'] ?? '',
      buyer: json['buyer'] ?? '',
      quantityKg: (json['quantityKg'] ?? 0).toDouble(),
      pricePerKg: (json['pricePerKg'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
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
      totalQuantityKg: (json['totalQuantityKg'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      last12MonthsProduction: Map<String, double>.from(
        (json['last12MonthsProduction'] ?? json['last6MonthsProduction'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SERVICE (คลาสเชื่อมต่อ API)
// ==========================================

class HarvestService {
  static const String baseUrl = 'http://localhost:3000/api'; 

  Future<List<HarvestData>> fetchHarvestRecords({String? gardenId}) async {
    final uri = Uri.parse('$baseUrl/harvests').replace(
      queryParameters: gardenId != null ? {'garden_id': gardenId} : null,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      if (resMap['isError'] == false) {
        List<dynamic> listData = resMap['data'];
        return listData.map((item) => HarvestData.fromJson(item)).toList();
      } else {
        throw Exception(resMap['errorMessage'] ?? 'ไม่สามารถดึงข้อมูลได้');
      }
    } else {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    }
  }

  Future<HarvestSummary> fetchHarvestSummary({String? gardenId}) async {
    final uri = Uri.parse('$baseUrl/harvests/summary').replace(
      queryParameters: gardenId != null ? {'garden_id': gardenId} : null,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      if (resMap['isError'] == false) {
        return HarvestSummary.fromJson(resMap['data']);
      } else {
        throw Exception(resMap['errorMessage'] ?? 'ไม่สามารถดึงข้อมูลสรุปได้');
      }
    } else {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    }
  }
}

// ==========================================
// 3. UI SCREEN (คลาสแสดงหน้าจอหลัก)
// ==========================================

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({Key? key}) : super(key: key);

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final HarvestService _service = HarvestService();
  late Future<HarvestSummary> _summaryFuture;
  late Future<List<HarvestData>> _harvestsFuture;

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
            onPressed: () {
              // TODO: ไปหน้า add_harvest_screen.dart
            },
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

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard('ผลผลิตรวม 1 ปี', summary.totalQuantityKg.toStringAsFixed(0), 'กก.')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('รายได้รวม', summary.totalRevenue.toStringAsFixed(0), 'บาท')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('ราคาเฉลี่ย', summary.averagePrice.toStringAsFixed(2), '฿/กก.')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildChartCard(summary.last12MonthsProduction),
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
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.status == 'sold' ? 'ขายแล้ว' : 'รอดำเนินการ',
                                        style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
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
            onPressed: () {
              // TODO: Action กดปุ่มบันทึกการเก็บเกี่ยว
            },
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
            color: Colors.black.withOpacity(0.03),
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

  Widget _buildChartCard(Map<String, double> monthlyData) {
    double maxKg = monthlyData.values.isNotEmpty
        ? monthlyData.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    if (maxKg == 0) maxKg = 1.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData.entries.map((entry) {
                  double heightFactor = (entry.value / maxKg).clamp(0.08, 1.0);
                  bool hasData = entry.value > 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasData)
                          Text(
                            entry.value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 22,
                          height: 90 * heightFactor,
                          decoration: BoxDecoration(
                            color: hasData ? const Color(0xFF1E5631) : const Color(0xFFC8E6C9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}