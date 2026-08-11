import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_myproject/screens/garden/gardencare/add_gardencare_screen.dart';

class GardenCareScreen extends StatefulWidget {
  final String userId;

  // รับ userId เข้ามาจากหน้า Login หรือหน้าก่อนหน้า (ตั้ง Default เป็น U002 กันพัง)
  const GardenCareScreen({super.key, this.userId = 'U002'});

  @override
  State<GardenCareScreen> createState() => _GardenCareScreenState();
}

class _GardenCareScreenState extends State<GardenCareScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  // กำหนด IP/URL ตามอุปกรณ์ที่รันอัตโนมัติ
  String get apiUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  // ดึง userId ที่ส่งมาจาก Widget
  String get currentUserId => widget.userId;

  String _selectedPlot = 'ทั้งหมด';
  String _selectedTab = 'ทั้งหมด'; // ตั้งเริ่มต้นเป็น "ทั้งหมด" เพื่อให้แสดงข้อมูลจาก DB ทันที

  List<String> _plots = ['ทั้งหมด'];
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDataFromBackend();
  }

  Future<void> _fetchDataFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final careResponse = await http.get(Uri.parse('$apiUrl/care-logs'));
      final gardenResponse = await http.get(Uri.parse('$apiUrl/gardens/$currentUserId'));

      if (careResponse.statusCode == 200) {
        final resBody = jsonDecode(careResponse.body);
        
        // รองรับ Format { isError: false, data: [...] }
        final List<dynamic> careData = (resBody is Map && resBody.containsKey('data')) 
            ? resBody['data'] 
            : (resBody is List ? resBody : []);

        List<Map<String, dynamic>> loadedActivities = careData.map((item) {
          DateTime recordDate = DateTime.tryParse(item['record_date']?.toString() ?? '') ?? DateTime.now();
          String formattedDate = DateFormat('d MMM yyyy', 'th_TH').format(recordDate);

          bool isFertilizer = item['fertilizer_id'] != null && item['fertilizer_id'].toString().isNotEmpty;
          String type = isFertilizer ? 'fertilizer' : (item['action_type'] ?? 'pruning');

          // 🛠️ แปลงจำนวนทศนิยมเป็นตัวเลขสวยๆ
          double numVal = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
          String formattedQty = (numVal % 1 == 0) ? numVal.toInt().toString() : numVal.toString();

          // 🛠️ ดึงข้อมูลรายละเอียด/หมายเหตุมาโชว์ในการ์ด
          String userNote = (item['note'] != null && item['note'].toString().trim().isNotEmpty)
              ? '${item['note']} · '
              : '';
              
          String unitStr = item['quantity_type'] ?? (isFertilizer ? 'กก.' : 'ต้น');
          String detail = '$userNoteจำนวน $formattedQty $unitStr';

          double costValue = double.tryParse(item['cost']?.toString() ?? '0') ?? 0.0;
          String costText = '${isFertilizer ? 'ค่าใช้จ่าย' : 'ค่าแรง'} ${NumberFormat('#,##0').format(costValue)} บาท';

          return {
            'care_id': item['care_id'],
            'title': '${isFertilizer ? 'ใส่ปุ๋ย' : 'ดูแลรักษา'} · ${item['garden_name'] ?? 'ไม่ระบุแปลง'}',
            'detail': detail,
            'cost': costText,
            'cost_value': costValue,
            'date': formattedDate,
            'type': type,
            'plot': item['garden_name'] ?? 'ไม่ระบุแปลง',
          };
        }).toList();

        // แกะรายชื่อสวนจาก gardenResponse มาใส่ใน Dropdown
        List<String> plotList = ['ทั้งหมด'];
        if (gardenResponse.statusCode == 200) {
          final gardenResBody = jsonDecode(gardenResponse.body);
          final List<dynamic> gardenData = (gardenResBody is Map && gardenResBody.containsKey('data'))
              ? gardenResBody['data']
              : (gardenResBody is List ? gardenResBody : []);
          
          plotList.addAll(
            gardenData
                .where((g) => g['garden_name'] != null)
                .map((g) => g['garden_name'].toString())
                .toList(),
          );
        }

        setState(() {
          _activities = loadedActivities;
          _plots = plotList.toSet().toList(); // ตัดชื่อสวนซ้ำออก
          _isLoading = false;
        });
      } else {
        throw Exception('เซิร์ฟเวอร์ตอบกลับด้วยสถานะ: ${careResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อข้อมูลได้ ($e)';
        _isLoading = false;
      });
    }
  }

  // กำหนดป้ายสไตล์และสีของแต่ละกิจกรรม
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
      case 'watering':
        return {
          'color': const Color(0xFF2196F3),
          'bgColor': const Color(0xFFE3F2FD),
          'label': 'ให้น้ำ',
        };
      case 'spraying':
        return {
          'color': const Color(0xFFF44336),
          'bgColor': const Color(0xFFFFEBEE),
          'label': 'พ่นยา',
        };
      default:
        return {
          'color': const Color(0xFF607D8B),
          'bgColor': const Color(0xFFECEFF1),
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
    double cost = 0;
    for (var a in filtered) {
      cost += (a['cost_value'] as double? ?? 0.0);
    }
    return {'count': count, 'cost': NumberFormat('#,##0').format(cost)};
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
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGardenCareScreen()),
              );
              if (result == true) {
                _fetchDataFromBackend();
              }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchDataFromBackend,
                        child: const Text('ลองใหม่'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDataFromBackend,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ตัวเลือกแปลงสวน (Dropdown)
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
                                    value: _plots.contains(_selectedPlot) ? _selectedPlot : 'ทั้งหมด',
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
                              
                              // แท็บสลับประเภทกิจกรรม
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

                              // การ์ดสรุปตัวเลข
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'กิจกรรมทั้งหมด',
                                      '${stats['count']}',
                                      'ครั้ง',
                                      primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'ค่าใช้จ่ายรวม',
                                      '${stats['cost']}',
                                      'บาท',
                                      primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // หัวข้อรายการล่าสุด
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
                                    onTap: _fetchDataFromBackend,
                                    child: Row(
                                      children: [
                                        Text(
                                          'รีเฟรช',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(Icons.refresh,
                                            size: 14, color: primaryGreen),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // รายการการ์ดกิจกรรม
                              if (filtered.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(
                                      'ไม่มีรายการ${_selectedPlot != 'ทั้งหมด' ? 'ใน $_selectedPlot' : ''}',
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

                      // ปุ่มบันทึกการดูแลใหม่ด้านล่าง
                      Container(
                        color: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddGardenCareScreen()),
                            );
                            if (result == true) {
                              _fetchDataFromBackend();
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'บันทึกการดูแลใหม่',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
          Container(
            width: 4,
            height: 90,
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