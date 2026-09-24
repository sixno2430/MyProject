import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddHarvestScreen extends StatefulWidget {
  const AddHarvestScreen({Key? key}) : super(key: key);

  @override
  State<AddHarvestScreen> createState() => _AddHarvestScreenState();
}

class _AddHarvestScreenState extends State<AddHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = 'http://localhost:3000/api';

  // State สำหรับ Dropdown แปลงสวน
  String? _selectedGardenId;
  List<Map<String, String>> _gardens = [];
  bool _isLoadingGardens = true;

  // Controller สำหรับ ฟอร์ม
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pricePerKgController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // สถานะ: sold = ขายแล้ว, pending = รอขาย / รอดำเนินการ
  String _status = 'sold'; 
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _updateDateDisplay();
    _fetchGardens();

    // ฟังค่าเมื่อผู้ใช้พิมพ์ผลผลิตหรือราคา เพื่อคำนวณราคารวมทันที
    _quantityController.addListener(_calculateTotal);
    _pricePerKgController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _quantityController.dispose();
    _pricePerKgController.dispose();
    _totalPriceController.dispose();
    _buyerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ดึงรายชื่อแปลงสวนจาก Backend
  Future<void> _fetchGardens() async {
    try {
      // 1. ลองดึงจาก /plots ก่อน (ถ้ามี)
      var response = await http.get(Uri.parse('$baseUrl/plots'));
      List<dynamic> list = [];

      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body);
        if (resMap is Map && resMap['data'] is List) {
          list = resMap['data'];
        }
      }

      // 2. ถ้าไม่มี /plots หรือได้ค่าว่าง ให้ลองดึงจาก /gardens
      if (list.isEmpty) {
        response = await http.get(Uri.parse('$baseUrl/gardens'));
        if (response.statusCode == 200) {
          final resMap = jsonDecode(response.body);
          if (resMap is Map && resMap['data'] != null) {
            list = resMap['data'] is List ? resMap['data'] : [];
          } else if (resMap is List) {
            list = resMap;
          }
        }
      }

      // Map ข้อมูลอย่างรัดกุม รองรับชื่อคีย์ทุกรูปแบบใน DB
      final parsedGardens = list.map<Map<String, String>>((item) {
        final id = (item['garden_id'] ?? item['plot_id'] ?? item['id'] ?? '').toString();
        
        String name = item['display_name']?.toString() ?? '';
        if (name.isEmpty) {
          final gardenName = (item['garden_name'] ?? item['name'] ?? '').toString();
          final plotName = (item['plot_name'] ?? '').toString();
          if (gardenName.isNotEmpty && plotName.isNotEmpty) {
            name = '$plotName — $gardenName';
          } else {
            name = gardenName.isNotEmpty ? gardenName : plotName;
          }
        }
        if (name.isEmpty) name = 'แปลงสวน ($id)';

        return {'id': id, 'name': name};
      }).where((g) => g['id']!.isNotEmpty).toList();

      if (parsedGardens.isNotEmpty) {
        setState(() {
          _gardens = parsedGardens;
          _selectedGardenId = _gardens.first['id'];
          _isLoadingGardens = false;
        });
        return;
      }

      _useFallbackGardens();
    } catch (e) {
      print('Error fetching gardens: $e');
      _useFallbackGardens();
    }
  }

  void _useFallbackGardens() {
    setState(() {
      _gardens = [
        {'id': '1', 'name': 'แปลง A — บ้านหนองกวาง'},
        {'id': '2', 'name': 'แปลง B — สวนปาล์มใหญ่'},
      ];
      _selectedGardenId = '1';
      _isLoadingGardens = false;
    });
  }

  // คำนวณราคารวมอัตโนมัติ
  void _calculateTotal() {
    final qty = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
    final price = double.tryParse(_pricePerKgController.text.replaceAll(',', '')) ?? 0;
    final total = qty * price;

    if (total > 0) {
      final formatter = NumberFormat("#,##0.00", "th_TH");
      _totalPriceController.text = '${formatter.format(total)} บาท';
    } else {
      _totalPriceController.text = '';
    }
  }

  // แปลงวันที่แสดงผลเป็นรูปแบบ พ.ศ.
  void _updateDateDisplay() {
    final thaiYear = _selectedDate.year + 543;
    final monthNames = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    _dateController.text = '${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} $thaiYear';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E5631)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateDisplay();
      });
    }
  }

  // ส่งข้อมูลไปบันทึกที่ Backend
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final qty = double.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
    final price = double.tryParse(_pricePerKgController.text.replaceAll(',', '')) ?? 0;

    final bodyData = {
      'garden_id': _selectedGardenId,
      'plot_id': _selectedGardenId,
      'harvest_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'total_quantity': qty,
      'price_per_kg': price,
      'total_price': qty * price,
      'buyer': _buyerController.text.trim(),
      'note': _noteController.text.trim(),
      'status': _status, // ส่งค่า 'sold' หรือ 'pending'
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/harvests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกข้อมูลการเก็บเกี่ยวเรียบร้อย'), backgroundColor: Color(0xFF1E5631)),
          );
          Navigator.pop(context, true); // คืนค่า true เพื่อให้หน้าหลัก Refresh ข้อมูล
        }
      } else {
        throw Exception('เกิดข้อผิดพลาดจาก Server');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E5631),
        elevation: 0,
        title: const Text(
          'บันทึกการเก็บเกี่ยว',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. แปลงสวน
              _buildLabel('แปลงสวน *'),
              _isLoadingGardens
                  ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
                  : DropdownButtonFormField<String>(
                      value: _selectedGardenId,
                      isExpanded: true,
                      decoration: _buildInputDecoration(),
                      items: _gardens.map((g) {
                        return DropdownMenuItem<String>(
                          value: g['id'],
                          child: Text(
                            g['name'] ?? '',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGardenId = val),
                    ),
              const SizedBox(height: 16),

              // 2. วันที่เก็บเกี่ยว
              _buildLabel('วันที่เก็บเกี่ยว *'),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: _buildInputDecoration(suffixIcon: Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // 3. สถานะการเก็บเกี่ยว (ติ๊กเลือก ขายแล้ว / รอขาย)
              _buildLabel('สถานะการเก็บเกี่ยว *'),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusChip(
                      label: 'ขายแล้ว',
                      value: 'sold',
                      icon: Icons.check_circle_outline,
                      activeColor: const Color(0xFF1E5631),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusChip(
                      label: 'รอขาย / รอดำเนินการ',
                      value: 'pending',
                      icon: Icons.access_time_rounded,
                      activeColor: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. ผลผลิต (กก.)
              _buildLabel('ผลผลิต (กก.) *'),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(hintText: '1,800'),
                validator: (val) => (val == null || val.isEmpty) ? 'กรุณากรอกผลผลิต' : null,
              ),
              const SizedBox(height: 16),

              // 5. ราคาขาย/กก. (บาท)
              _buildLabel('ราคาขาย/กก. (บาท) *'),
              TextFormField(
                controller: _pricePerKgController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(hintText: '5.50'),
                validator: (val) => (val == null || val.isEmpty) ? 'กรุณากรอกราคาขาย' : null,
              ),
              const SizedBox(height: 16),

              // 6. ราคาขายรวม (คำนวณอัตโนมัติ)
              _buildLabel('ราคาขายรวม (คำนวณอัตโนมัติ)'),
              TextFormField(
                controller: _totalPriceController,
                readOnly: true,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
                decoration: _buildInputDecoration(hintText: '9,900 บาท').copyWith(
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // 7. ผู้รับซื้อ
              _buildLabel('ผู้รับซื้อ'),
              TextFormField(
                controller: _buyerController,
                decoration: _buildInputDecoration(hintText: 'สหกรณ์ปาล์มน้ำมันบ้านหนองกวาง'),
              ),
              const SizedBox(height: 16),

              // 8. หมายเหตุ
              _buildLabel('หมายเหตุ'),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: _buildInputDecoration(hintText: 'เพิ่มเติม...'),
              ),
              const SizedBox(height: 24),

              // ปุ่มกด ยกเลิก / บันทึก
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก', style: TextStyle(color: Colors.black87, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5631),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E5631), width: 1.5),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black26,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}