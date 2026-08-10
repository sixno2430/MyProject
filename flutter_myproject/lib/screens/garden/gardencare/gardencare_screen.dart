import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/gardencare/add_gardencare_screen.dart';

class GardenCareScreen extends StatefulWidget {
  const GardenCareScreen({super.key});

  @override
  State<GardenCareScreen> createState() => _GardenCareScreenState();
}

class _GardenCareScreenState extends State<GardenCareScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  String _selectedPlot = 'ทั้งหมด';
  String _selectedTab = 'ทั้งหมด';

  final List<String> _plots = [
    'ทั้งหมด',
    'แปลง A',
    'แปลง B',
    'แปลง C',
    'แปลง D',
  ];

  final List<Map<String, dynamic>> _activities = [
    {
      'title': 'ใส่ปุ๋ย · แปลง A',
      'detail': 'ปุ๋ย 15-15-15 · 40 กก.',
      'cost': 'ค่าใช้จ่าย 1,200 บาท',
      'date': '10 มิ.ย.',
      'type': 'fertilizer',
      'plot': 'แปลง A',
    },
    {
      'title': 'ตัดแต่งทางใบ · แปลง A',
      'detail': 'ตัดครบ 480 ต้น',
      'cost': 'ค่าแรง 1,500 บาท',
      'date': '8 มิ.ย.',
      'type': 'pruning',
      'plot': 'แปลง A',
    },
    {
      'title': 'ใส่ปุ๋ย · แปลง B',
      'detail': 'ปุ๋ยเร่งโต 46-0-0 · 30 กก.',
      'cost': 'ค่าใช้จ่าย 900 บาท',
      'date': '7 มิ.ย.',
      'type': 'fertilizer',
      'plot': 'แปลง B',
    },
    {
      'title': 'กำจัดวัชพืช · แปลง C',
      'detail': 'ใช้เวลา 2 วัน',
      'cost': 'ค่าแรง 800 บาท',
      'date': '5 มิ.ย.',
      'type': 'weeding',
      'plot': 'แปลง C',
    },
  ];

  Map<String, dynamic> _getTypeStyle(String type) {
    switch (type) {
      case 'fertilizer':
        return {
          'color': const Color(0xFF4CAF50),
          'bgColor': const Color(0xFFE8F5E9),
          'label': 'ใส่ปุ๋ย',
        };
      case 'pruning':
        return {
          'color': const Color(0xFFFF9800),
          'bgColor': const Color(0xFFFFF3E0),
          'label': 'ตัดแต่ง',
        };
      case 'weeding':
        return {
          'color': const Color(0xFF9C27B0),
          'bgColor': const Color(0xFFF3E5F5),
          'label': 'กำจัดวัชพืช',
        };
      default:
        return {
          'color': Colors.grey,
          'bgColor': Colors.grey[100],
          'label': 'อื่นๆ',
        };
    }
  }

  List<Map<String, dynamic>> get _filteredActivities {
    return _activities.where((item) {
      final matchPlot =
          _selectedPlot == 'ทั้งหมด' || item['plot'] == _selectedPlot;
      final matchType = _selectedTab == 'ทั้งหมด' ||
          (_selectedTab == 'ใส่ปุ๋ย' && item['type'] == 'fertilizer') ||
          (_selectedTab == 'ดูแลรักษา' && item['type'] != 'fertilizer');
      return matchPlot && matchType;
    }).toList();
  }

  Map<String, dynamic> get _stats {
    final filtered = _selectedPlot == 'ทั้งหมด'
        ? _activities
        : _activities.where((a) => a['plot'] == _selectedPlot).toList();

    int count = filtered.length;
    int cost = 0;
    for (var a in filtered) {
      final costStr = a['cost'] as String;
      final match = RegExp(r'[\d,]+').firstMatch(costStr);
      if (match != null) {
        cost += int.parse(match.group(0)!.replaceAll(',', ''));
      }
    }
    return {'count': count, 'cost': cost};
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final filtered = _filteredActivities;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Column(
          children: [
            Text(
              'การดูแลรักษาสวน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'บันทึกการดูแล / การใส่ปุ๋ย',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              // TODO: ไปหน้าเพิ่มบันทึก
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown เลือกแปลงสวน
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
                        icon: Icon(Icons.keyboard_arrow_down, color: primaryGreen),
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
                                Icon(Icons.forest_outlined,
                                    color: primaryGreen, size: 20),
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

                  // แท็บ
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTab('ดูแลรักษา', '🔧'),
                        _buildTab('ใส่ปุ๋ย', '💊'),
                        _buildTab('ทั้งหมด', '📋'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // สถิติ
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'กิจกรรมเดือนนี้',
                          '${stats['count']}',
                          'ครั้ง',
                          primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'ค่าปุ๋ยเดือนนี้',
                          '${stats['cost']}',
                          'บาท',
                          primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // หัวข้อรายการ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายการล่าสุด',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(
                              'ดูทั้งหมด',
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 12, color: primaryGreen),
                          ],
                        ),
                      ),
                    ],
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
                    ...filtered.map((item) => _buildActivityCard(item)),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGardenCareScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'บันทึกการดูแลใหม่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
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

  Widget _buildTab(String label, String emoji) {
    final isActive = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item) {
    final style = _getTypeStyle(item['type']);
    final color = style['color'] as Color;

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
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
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
                        item['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        item['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['detail'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('💰 ', style: TextStyle(fontSize: 12)),
                          Text(
                            item['cost'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: style['bgColor'] as Color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          style['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
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