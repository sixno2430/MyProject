import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/havest/add_harvest_screen.dart';
class HarvestRecordScreen extends StatefulWidget {
  const HarvestRecordScreen({super.key});

  @override
  State<HarvestRecordScreen> createState() => _HarvestRecordScreenState();
}

class _HarvestRecordScreenState extends State<HarvestRecordScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  String _selectedPlot = 'ทั้งหมด';

  final List<String> _plots = [
    'ทั้งหมด',
    'แปลง A',
    'แปลง B',
    'แปลง C',
    'แปลง D',
  ];

  final List<Map<String, dynamic>> _harvests = [
    {
      'code': 'H001',
      'plot': 'แปลง A',
      'buyer': 'สหกรณ์ปาล์มน้ำมันภาคใต้',
      'amount': 1800,
      'price': 5.50,
      'total': 9900,
      'status': 'sold', // ขายแล้ว
      'date': '10 มิ.ย.',
    },
    {
      'code': 'H002',
      'plot': 'แปลง B',
      'buyer': 'สหกรณ์ปาล์มน้ำมันภาคใต้',
      'amount': 1200,
      'price': 5.30,
      'total': 6360,
      'status': 'sold',
      'date': '8 มิ.ย.',
    },
    {
      'code': 'H003',
      'plot': 'แปลง C',
      'buyer': 'ยังไม่ได้เลือกร้าน',
      'amount': 840,
      'price': 5.20,
      'total': 4368,
      'status': 'pending', // รอขาย
      'date': '5 มิ.ย.',
    },
  ];

  List<Map<String, dynamic>> get _filteredHarvests {
    if (_selectedPlot == 'ทั้งหมด') return _harvests;
    return _harvests.where((h) => h['plot'] == _selectedPlot).toList();
  }

  Map<String, dynamic> get _stats {
    final list = _filteredHarvests;
    final totalAmount = list.fold<int>(
      0,
      (sum, h) => sum + (h['amount'] as int),
    );
    final totalIncome = list.fold<int>(
      0,
      (sum, h) => sum + (h['total'] as int),
    );
    final avgPrice = list.isEmpty
        ? 0.0
        : list.fold<double>(0, (sum, h) => sum + (h['price'] as double)) /
              list.length;
    return {'amount': totalAmount, 'income': totalIncome, 'avg': avgPrice};
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final filtered = _filteredHarvests;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ====== Header ======
          Container(
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Column(
                            children: [
                              Text(
                                'บันทึกการเก็บเกี่ยว',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'บันทึกผลผลิต · ราคา · ร้านรับซื้อ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: ไปหน้าเพิ่มบันทึกการเก็บเกี่ยว
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====== เนื้อหา ======
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown เลือกแปลง
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPlot,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: primaryGreen,
                        ),
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _plots.map((String plot) {
                          return DropdownMenuItem<String>(
                            value: plot,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.forest_outlined,
                                  color: primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(plot),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPlot = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // สถิติ 3 ช่อง
                  Row(
                    children: [
                      _buildStatBox(
                        'ผลผลิตรวม',
                        '${stats['amount']}',
                        'กก.',
                        primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        'รายได้รวม',
                        '${stats['income']}',
                        'บาท',
                        primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        'ราคาเฉลี่ย',
                        (stats['avg'] as double).toStringAsFixed(2),
                        '฿/กก.',
                        primaryGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // กราฟแท่ง
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ผลผลิต 6 เดือนล่าสุด (กก.)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar('ม.ค.', 0.4),
                              _buildBar('ก.พ.', 0.7),
                              _buildBar('มี.ค.', 0.5),
                              _buildBar('เม.ย.', 0.85),
                              _buildBar('พ.ค.', 0.6),
                              _buildBar('มิ.ย.', 0.95),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // หัวข้อรายการ
                  const Text(
                    'รายการเก็บเกี่ยว',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // รายการ
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'ไม่มีรายการ${_selectedPlot != 'ทั้งหมด' ? 'ใน$_selectedPlot' : ''}',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((item) => _buildHarvestCard(item)),
                ],
              ),
            ),
          ),

          // ปุ่มล่าง
          Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ElevatedButton.icon(
              onPressed: () {
                // จากหน้า Dashboard (เมนูลัด เก็บเกี่ยว)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddHarvestScreen(),
                  ),
                );

                // หรือจากหน้า Finance
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'บันทึกการเก็บเกี่ยว',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40916C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String month, double heightPercent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 80 * heightPercent,
          decoration: BoxDecoration(
            color: heightPercent > 0.8
                ? primaryGreen
                : primaryGreen.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(month, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHarvestCard(Map<String, dynamic> item) {
    final isSold = item['status'] == 'sold';
    final statusColor = isSold
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA000);
    final statusBg = isSold ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final statusText = isSold ? 'ขายแล้ว' : 'รอขาย';
    final leftColor = isSold
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA000);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // แถบสีซ้าย
          Container(
            width: 4,
            height: 110,
            decoration: BoxDecoration(
              color: leftColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['code']} · ${item['plot']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('🏪 ', style: TextStyle(fontSize: 12)),
                      Text(
                        item['buyer'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['amount']} กก. × ${item['price']} บาท',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        '${item['total']} ฿',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
