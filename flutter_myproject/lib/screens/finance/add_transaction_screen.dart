// ============================================================
// add_transaction_screen.dart — ฟอร์มบันทึก/แก้ไขรายรับ-รายจ่าย
//
// เลือกประเภท (รายรับ/รายจ่าย), หมวด, ชื่อรายการ, จำนวนเงิน, วันที่ และแปลงที่เกี่ยวข้อง
// ส่ง existing มา = แก้ไข (PUT /api/finance/:id) ไม่ส่ง = เพิ่มใหม่ (POST /api/finance/add)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:intl/intl.dart';
import 'finance_screen.dart' show TransactionItem;
import 'package:flutter_myproject/services/auth_server.dart';

/// ฟอร์มบันทึกรายการเงิน
class AddTransactionScreen extends StatefulWidget {
  /// ข้อมูลเดิม (ส่งมา = โหมดแก้ไข, ไม่ส่ง = เพิ่มใหม่)
  final TransactionItem? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String get baseUrl => AppConfig.apiBaseUri;
  
  // 🟢 ปรับเปลี่ยนสีธีมหลักเป็นสีเขียวเข้มของแอป
  final Color primaryGreen = const Color(0xFF2D6A4F);

  // Form State
  String _recordType = 'INCOME'; // 'INCOME' หรือ 'EXPENSE'
  String _selectedCategory = 'ขายผลผลิต';
  String? _selectedGardenId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Categories Mapping
  final List<String> _incomeCategories = ['ขายผลผลิต', 'เงินอุดหนุน', 'รายรับอื่นๆ'];
  final List<String> _expenseCategories = ['ค่าปุ๋ย', 'ค่าแรงงาน', 'ค่าน้ำมัน/เชื้อเพลิง', 'ค่าอุปกรณ์', 'รายจ่ายอื่นๆ'];

  // Gardens List
  List<Map<String, String>> _gardens = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _recordType = e.type == 'income' ? 'INCOME' : 'EXPENSE';
      _selectedCategory = e.category;
      _selectedGardenId = e.gardenId.isNotEmpty ? e.gardenId : null;
      _selectedDate = DateTime.tryParse(e.date) ?? DateTime.now();
      _titleController.text = e.title;
      _amountController.text = e.amount % 1 == 0 ? e.amount.toInt().toString() : e.amount.toString();
    }
    _fetchGardens();
  }

  // ดึงแปลงสวนจาก Backend
  /// โหลดแปลงสวนของ user มาใส่ dropdown "แปลงที่เกี่ยวข้อง"
  Future<void> _fetchGardens() async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/gardens/$userId'));
      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body);
        final data = resMap['data'] ?? resMap;
        if (data is List) {
          setState(() {
            _gardens = data.map<Map<String, String>>((g) {
              return {
                'id': g['garden_id']?.toString() ?? '',
                'name': g['garden_name']?.toString() ?? 'ไม่ระบุชื่อแปลง',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetchGardens: $e');
    }
  }

  // เลือกวันที่
  /// เลือกวันที่ของรายการ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen, // สีหัวปฏิทินและปุ่ม
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ส่งข้อมูลบันทึกเข้า DB
  /// ตรวจข้อมูลแล้วบันทึก (เพิ่มใหม่หรือแก้ไข) สำเร็จแล้วปิดหน้า
  Future<void> _submitData() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อรายการ')));
      return;
    }

    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง')));
      return;
    }

    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      "user_id": userId,
      "garden_id": _selectedGardenId,
      "record_type": _recordType,
      "amount": double.parse(amountText),
      "expense_category": _selectedCategory,
      "description": _noteController.text.trim().isEmpty ? title : '$title ${_noteController.text.trim()}',
      "record_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    try {
      final response = _isEdit
          ? await http.put(
              Uri.parse('$baseUrl/finance/${widget.existing!.id}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse('$baseUrl/finance/add'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body);
        if (resMap['isError'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_isEdit ? 'แก้ไขรายการเรียบร้อยแล้ว' : 'บันทึกข้อมูลเรียบร้อยแล้ว')),
            );
            Navigator.pop(context, true);
          }
          return;
        }
      }
      throw Exception('ไม่สามารถบันทึกได้');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// วันที่แบบไทย ปี พ.ศ. สำหรับแสดงในฟอร์ม
  String _formatThaiDate(DateTime dt) {
    final thaiYear = dt.year + 543;
    final months = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
    return '${dt.day} ${months[dt.month - 1]} $thaiYear';
  }

  @override
  Widget build(BuildContext context) {
    final categories = _recordType == 'INCOME' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen, // 🟢 เปลี่ยน AppBar เป็นสีเขียว
        elevation: 0,
        title: Text(_isEdit ? 'แก้ไขรายการ' : 'บันทึกการซื้อขาย', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. สลับประเภทธุรกรรม (รายรับ / รายจ่าย) ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _recordType = 'INCOME';
                        _selectedCategory = _incomeCategories.first;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _recordType == 'INCOME' ? primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _recordType == 'INCOME' ? primaryGreen : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          'รายรับ',
                          style: TextStyle(
                            color: _recordType == 'INCOME' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _recordType = 'EXPENSE';
                        _selectedCategory = _expenseCategories.first;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _recordType == 'EXPENSE' ? const Color(0xFFD32F2F) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _recordType == 'EXPENSE' ? const Color(0xFFD32F2F) : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          'รายจ่าย',
                          style: TextStyle(
                            color: _recordType == 'EXPENSE' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 2. หมวดหมู่ ---
            _buildLabel('หมวดหมู่ *'),
            const SizedBox(height: 6),
            _buildDropdownContainer(
              child: DropdownButton<String>(
                isExpanded: true,
                value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- 3. ชื่อรายการ ---
            _buildTextField('รายการ *', 'เช่น ขายผลปาล์มน้ำมัน แปลง D', controller: _titleController),
            const SizedBox(height: 16),

            // --- 4. จำนวนเงิน ---
            _buildTextField('จำนวนเงิน *', '0.00', controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),

            // --- 5. วันที่ ---
            _buildLabel('วันที่ *'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatThaiDate(_selectedDate), style: const TextStyle(fontSize: 14)),
                    Icon(Icons.calendar_month, color: primaryGreen, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 6. แปลงที่เกี่ยวข้อง ---
            _buildLabel('แปลงที่เกี่ยวข้อง'),
            const SizedBox(height: 6),
            _buildDropdownContainer(
              child: DropdownButton<String?>(
                isExpanded: true,
                // กันจอแดง: ค่าที่เลือกต้องมีอยู่ในรายการ (ตอนแก้ไข รายการแปลงอาจยังโหลดไม่เสร็จ)
                value: _gardens.any((g) => g['id'] == _selectedGardenId) ? _selectedGardenId : null,
                hint: const Text('ไม่ระบุแปลง'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('ไม่ระบุแปลง')),
                  ..._gardens.map((g) => DropdownMenuItem<String?>(value: g['id'], child: Text(g['name']!))),
                ],
                onChanged: (val) => setState(() => _selectedGardenId = val),
              ),
            ),
            const SizedBox(height: 16),

            // --- 7. หมายเหตุ ---
            _buildTextField('หมายเหตุ', 'เพิ่มเติม...', controller: _noteController, maxLines: 3),
            const SizedBox(height: 24),

            // --- 8. ปุ่มยกเลิก/บันทึก ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen, // 🟢 เปลี่ยนปุ่มบันทึกเป็นสีเขียว
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// หัวข้อเหนือช่องกรอก
  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));
  }

  /// กรอบของ dropdown ให้หน้าตาเหมือนช่องกรอกอื่น
  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  /// ช่องกรอกข้อความ
  Widget _buildTextField(
    String label,
    String hint, {
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}