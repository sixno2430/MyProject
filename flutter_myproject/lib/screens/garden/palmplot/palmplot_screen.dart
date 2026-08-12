import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/palmplot/add_plot_screen.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. MODEL (เพิ่ม address + detailText)
// ==========================================
// ==========================================
// MODEL: พันธุ์ปาล์ม
// ==========================================
class PalmVariety {
  final String varietyId;
  final String varietyName;
  final int plantCount;

  PalmVariety({
    required this.varietyId,
    required this.varietyName,
    required this.plantCount,
  });

  factory PalmVariety.fromJson(Map<String, dynamic> json) {
    return PalmVariety(
      varietyId: json['variety_id']?.toString() ?? '',
      varietyName: json['variety_name']?.toString() ?? 'ไม่ระบุพันธุ์',
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
    );
  }
}
class Garden {
  final String gardenId;
  final String userId;
  final String gardenName;
  final double areaSize;
  final int plantCount;
  final int? plantYear;
  final int? plantAge;
  final String? address; // ← เพิ่ม
  final List<PalmVariety>? varieties;

  Garden({
    required this.gardenId,
    required this.userId,
    required this.gardenName,
    required this.areaSize,
    required this.plantCount,
    this.plantYear,
    this.plantAge,
    this.address, // ← เพิ่ม
    this.varieties,
  });

  factory Garden.fromJson(Map<String, dynamic> json) {
    
    List<PalmVariety>? varietyList;
    if (json['varieties'] != null && json['varieties'] is List) {
      varietyList = (json['varieties'] as List)
          .map((v) => PalmVariety.fromJson(v))
          .toList();
    }
    return Garden(
      gardenId: json['garden_id'] ?? '',
      userId: json['user_id'] ?? '',
      gardenName: json['garden_name'] ?? 'ไม่ระบุชื่อแปลง',
      areaSize: double.tryParse(json['area_size']?.toString() ?? '0') ?? 0.0,
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
      plantYear: json['plant_year'] != null ? int.tryParse(json['plant_year'].toString()) : null,
      plantAge: json['plant_age'] != null ? int.tryParse(json['plant_age'].toString()) : null,
      address: json['address']?.toString(), // ← เพิ่ม
      varieties: varietyList,
    );
  }

  // ← เพิ่ม: สร้างข้อความ "เหนื่อย่า · 5 ปี · 12 ไร่ · 330 ต้น"
  String get detailText {
    final parts = <String>[];
    if (plantAge != null) parts.add('$plantAge ปี');
    if (areaSize > 0) parts.add('${areaSize.toStringAsFixed(areaSize.truncateToDouble() == areaSize ? 0 : 2)} ไร่');
    if (plantCount > 0) parts.add('$plantCount ต้น');
    return parts.join(' · ');
  }
}

// ==========================================
// 2. MAIN SCREEN
// ==========================================
class PalmplotScreen extends StatefulWidget {
  const PalmplotScreen({super.key});

  @override
  State<PalmplotScreen> createState() => _PalmplotScreenState();
}

class _PalmplotScreenState extends State<PalmplotScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  List<Garden> gardens = [];
  List<Garden> filteredGardens = [];
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController searchController = TextEditingController();

  String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://127.0.0.1:3000';
  }

  @override
  void initState() {
    super.initState();
    fetchGardens();
  }
  Future<void> _deleteGarden(Garden garden) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${garden.gardenName}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/gardens/${garden.gardenId}'),
      );
      final body = json.decode(response.body);
      if (body['isError'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบสำเร็จ')),
        );
        fetchGardens();
      } else {
        throw Exception(body['errorMessage']);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> fetchGardens() async {
    const String userId = 'U002';
    final url = Uri.parse('$baseUrl/api/gardens/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['isError'] == false && body['data'] != null) {
          final List rawData = body['data'];
          final loadedGardens = rawData.map((e) => Garden.fromJson(e)).toList();
          setState(() {
            gardens = loadedGardens;
            filteredGardens = loadedGardens;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = body['errorMessage'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server Error (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'ไม่สามารถเชื่อมต่อ Server ได้ ($e)';
        isLoading = false;
      });
    }
  }

  void _filterGardens(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredGardens = gardens;
      } else {
        filteredGardens = gardens
            .where((g) => g.gardenName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // ← เพิ่ม: ฟังก์ชันแก้ไขสวน
  Future<void> _editGarden(Garden garden) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditGardenDialog(garden: garden, primaryGreen: primaryGreen),
    );

    if (result != null) {
      setState(() => isLoading = true);
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/api/gardens/${garden.gardenId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(result),
        );
        final body = json.decode(response.body);
        if (body['isError'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขสำเร็จ')),
          );
          fetchGardens();
        } else {
          throw Exception(body['errorMessage']);
        }
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')),
        );
      }
    }
  }

  int get totalPlants => gardens.fold(0, (sum, item) => sum + item.plantCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แปลงสวนของฉัน',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPlotScreen()),
              ).then((_) => fetchGardens());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchGardens,
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ช่องค้นหา
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterGardens,
                  decoration: const InputDecoration(
                    hintText: 'ค้นหาแปลงสวน...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // สถิติ
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSummary('${gardens.length}', 'แปลงสวน'),
                    const SizedBox(width: 60),
                    _buildSummary('$totalPlants', 'ต้นปาล์ม'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // รายการ
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
              else if (errorMessage.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () { setState(() => isLoading = true); fetchGardens(); },
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              else if (filteredGardens.isEmpty)
                const Center(child: Text('ไม่พบข้อมูลแปลงสวน', style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredGardens.length,
                  itemBuilder: (context, index) {
                    final garden = filteredGardens[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      // ← แก้ตรงนี้: ส่ง garden + onEdit
                      child: _buildPlotCard(
                        garden: garden,
                        onEdit: () => _editGarden(garden),
                        onDelete: () => _deleteGarden(garden),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  // ==========================================
  // ← แก้ตรงนี้: UI การ์ดใหม่ (เหมือนรูปแรก)
  // ==========================================
  Widget _buildPlotCard({
    required Garden garden,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // รูปปาล์มซ้าย
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.park,
                color: Color(0xFF2D6A4F),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // ข้อมูลตรงกลาง
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อแปลง
                  Text(
                    garden.gardenName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // รายละเอียด: 5 ปี · 12 ไร่ · 330 ต้น
                  Text(
                    garden.detailText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (garden.varieties != null && garden.varieties!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: garden.varieties!.map((v) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🌿 ${v.varietyName} (${v.plantCount} ต้น)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  
                  const SizedBox(height: 6),
                  // ที่อยู่
                  if (garden.address != null && garden.address!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            garden.address!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
                        // ปากกาแก้ไข
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
              splashRadius: 20,
            ),
            // ถังขยะลบ
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ← เพิ่มใหม่: Dialog แก้ไขสวน
// ==========================================
class _EditGardenDialog extends StatefulWidget {
  final Garden garden;
  final Color primaryGreen;

  const _EditGardenDialog({required this.garden, required this.primaryGreen});

  @override
  State<_EditGardenDialog> createState() => _EditGardenDialogState();
}

class _EditGardenDialogState extends State<_EditGardenDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _countCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.garden.gardenName);
    _addressCtrl = TextEditingController(text: widget.garden.address ?? '');
    _areaCtrl = TextEditingController(text: widget.garden.areaSize.toString());
    _yearCtrl = TextEditingController(text: widget.garden.plantYear?.toString() ?? '');
    _countCtrl = TextEditingController(text: widget.garden.plantCount.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขแปลงสวน'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField('ชื่อแปลงสวน', _nameCtrl),
            _buildField('ที่อยู่', _addressCtrl),
            _buildField('ขนาด (ไร่)', _areaCtrl, TextInputType.number),
            _buildField('ปีที่ปลูก', _yearCtrl, TextInputType.number),
            _buildField('จำนวนต้น', _countCtrl, TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.primaryGreen),
          onPressed: () {
            Navigator.pop(context, {
              'garden_name': _nameCtrl.text.trim(),
              'address': _addressCtrl.text.trim(),
              'area_size': double.tryParse(_areaCtrl.text.trim()) ?? 0,
              'plant_year': int.tryParse(_yearCtrl.text.trim()),
              'plant_count': int.tryParse(_countCtrl.text.trim()) ?? 0,
            });
          },
          child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
  
}