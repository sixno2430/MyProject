import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddGardenCareScreen extends StatefulWidget {
  final String userId;

  const AddGardenCareScreen({super.key, this.userId = 'U002'});

  @override
  State<AddGardenCareScreen> createState() => _AddGardenCareScreenState();
}

class _AddGardenCareScreenState extends State<AddGardenCareScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final _formKey = GlobalKey<FormState>();

  String get apiUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  String? _selectedGardenId;
  List<Map<String, dynamic>> _plots = [];
  bool _isLoadingPlots = true;

  String _selectedType = 'ใส่ปุ๋ย';
  DateTime _selectedDate = DateTime.now();
  final _detailController = TextEditingController();
  final _costController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _careTypes = [
    {'label': 'ใส่ปุ๋ย', 'icon': '💊', 'color': const Color(0xFF4CAF50), 'type': 'fertilizer', 'unit': 'กก.'},
    {'label': 'ตัดแต่ง', 'icon': '✂️', 'color': const Color(0xFFFF9800), 'type': 'pruning', 'unit': 'ต้น'},
    {'label': 'กำจัดวัชพืช', 'icon': '🌿', 'color': const Color(0xFF9C27B0), 'type': 'weeding', 'unit': 'แปลง'},
    {'label': 'ให้น้ำ', 'icon': '💧', 'color': const Color(0xFF2196F3), 'type': 'watering', 'unit': 'ครั้ง'},
    {'label': 'พ่นยา', 'icon': '🔫', 'color': const Color(0xFFF44336), 'type': 'spraying', 'unit': 'ครั้ง'},
    {'label': 'อื่นๆ', 'icon': '🛠️', 'color': const Color(0xFF607D8B), 'type': 'other', 'unit': 'รายการ'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPlotsFromBackend();
  }

  Future<void> _fetchPlotsFromBackend() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/gardens/${widget.userId}'));
      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        final List<dynamic> data = (resBody is Map && resBody.containsKey('data'))
            ? resBody['data']
            : (resBody is List ? resBody : []);

        setState(() {
          _plots = data.map((e) => {
            'id': e['garden_id'].toString(),
            'name': e['garden_name'].toString(),
          }).toList();

          if (_plots.isNotEmpty) {
            _selectedGardenId = _plots.first['id'];
          }
          _isLoadingPlots = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingPlots = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _thaiDate {
    final d = DateFormat('d MMMM yyyy', 'th_TH').format(_selectedDate);
    return d.replaceFirst(
      _selectedDate.year.toString(),
      (_selectedDate.year + 543).toString(),
    );
  }

  Future<void> _saveCareLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGardenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกแปลงสวน')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String careId = 'C${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // ดึงข้อมูลประเภทกิจกรรมที่เลือก
      final currentTypeObj = _careTypes.firstWhere(
        (element) => element['label'] == _selectedType,
        orElse: () => _careTypes.first,
      );

      // สกัดตัวเลขจำนวน
      String rawAmountText = _amountController.text.trim();
      String numericOnly = rawAmountText.replaceAll(RegExp(r'[^0-9.]'), '');
      double quantityVal = double.tryParse(numericOnly) ?? 0.0;

      double costVal = double.tryParse(_costController.text.replaceAll(',', '')) ?? 0.0;

      // รวมข้อความรายละเอียด + หมายเหตุ (ถ้ามี)
      String fullDetail = _detailController.text.trim();
      if (_noteController.text.trim().isNotEmpty) {
        fullDetail += ' (${_noteController.text.trim()})';
      }

      Map<String, dynamic> bodyData = {
        'care_id': careId,
        'garden_id': _selectedGardenId,
        'fertilizer_id': _selectedType == 'ใส่ปุ๋ย' ? 'F001' : null,
        'action_type': currentTypeObj['type'], // บันทึกประเภทกิจกรรมจริง
        'quantity': quantityVal,
        'quantity_type': currentTypeObj['unit'], // บันทึกหน่วยตามกิจกรรมจริง
        'cost': costVal,
        'record_date': formattedDate,
        'note': fullDetail, // บันทึกรายละเอียดลง DB
      };

      final response = await http.post(
        Uri.parse('$apiUrl/care-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกการดูแลรักษาสวนเรียบร้อยแล้ว')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Server ตอบกลับสถานะ: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('การดูแลรักษาสวน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 2),
            Text('บันทึกการดูแล / การใส่ปุ๋ย', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('แปลงสวน *'),
                    const SizedBox(height: 6),
                    _isLoadingPlots
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryGreen, width: 1.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedGardenId,
                                icon: Icon(Icons.keyboard_arrow_down, color: primaryGreen),
                                style: const TextStyle(color: Colors.black87, fontSize: 15),
                                items: _plots.map((plot) {
                                  return DropdownMenuItem<String>(
                                    value: plot['id'],
                                    child: Text(plot['name']),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGardenId = val);
                                },
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    _buildLabel('ประเภทกิจกรรม *'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _careTypes.map((type) {
                        final isSelected = _selectedType == type['label'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = type['label']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? (type['color'] as Color).withOpacity(0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? type['color'] as Color : Colors.grey[300]!,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(type['icon'], style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  type['label'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? type['color'] as Color : Colors.grey[700],
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('วันที่ดำเนินการ *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Text('📅 ', style: TextStyle(fontSize: 16)),
                            Text(_thaiDate, style: const TextStyle(fontSize: 15)),
                            const Spacer(),
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('รายละเอียด *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _detailController,
                      hint: 'เช่น ตัดแต่งทางใบใกล้วางกอง หรือ ปุ๋ย 15-15-15',
                      maxLines: 2,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('ปริมาณ / จำนวน'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _amountController, // 👈 ผูก Controller แล้ว
                      hint: 'เช่น 40 (กก. / ต้น / ครั้ง)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('ค่าใช้จ่าย (บาท)'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _costController,
                      hint: 'เช่น 1,200',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: const Text('💰 ', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('หมายเหตุเพิ่มเติม'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _noteController,
                      hint: 'เพิ่มเติม...',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveCareLog,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('🛠️', style: TextStyle(fontSize: 18)),
              label: Text(
                _isSubmitting ? 'กำลังบันทึก...' : 'บันทึกการดูแล',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40916C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefix,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'กรุณากรอกข้อมูลในช่องนี้';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}