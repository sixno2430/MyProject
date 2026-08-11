import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddPlotScreen extends StatefulWidget {
  final String userId; // รับ user_id ของผู้ใช้ที่กำลังล็อกอินอยู่

  const AddPlotScreen({super.key, this.userId = 'U002'}); // Default U002 ไว้ทดสอบ

  @override
  State<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final String apiUrl = 'http://10.0.2.2:3000/api'; // ปรับ IP/Port ให้ตรงกับ Backend

  // Controllers สำหรับดึงค่าจาก Form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _treeCountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _treeCountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเปิด Calendar เลือกวันที่ปลูก
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryGreen),
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

  // ฟังก์ชันยิง API บันทึกข้อมูลไปยัง Backend
  Future<void> _saveGarden() async {
    // Validation เบื้องต้น
    if (_nameController.text.trim().isEmpty ||
        _areaController.text.trim().isEmpty ||
        _treeCountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลที่มีเครื่องหมาย * ให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/gardens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'garden_name': _nameController.text.trim(),
          'area_size': double.tryParse(_areaController.text.trim()) ?? 0.0,
          'plant_count': int.tryParse(_treeCountController.text.trim()) ?? 0,
          'plant_year': _selectedDate != null ? _selectedDate!.year : DateTime.now().year,
          'address': _addressController.text.trim(),
        }),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกข้อมูลแปลงสวนสำเร็จ!')),
          );
          Navigator.pop(context, true); // ส่งค่า true กลับเพื่อสั่ง Refresh หน้าก่อนหน้า
        }
      } else {
        throw Exception(resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึก');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text('เพิ่มแปลงสวนใหม่', style: TextStyle(fontSize: 18, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'ชื่อแปลงสวน *',
              hint: 'เช่น แปลง A — บ้านหนองกวาง',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'พื้นที่ (ไร่) *',
              hint: 'เช่น 15.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: _areaController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'จำนวนต้นปาล์ม *',
              hint: 'เช่น 330',
              keyboardType: TextInputType.number,
              controller: _treeCountController,
            ),
            const SizedBox(height: 16),
            
            // วันที่ปลูก (เลือกจาก Calendar)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('วันที่ปลูก / ปีที่ปลูก', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                        Text(
                          _selectedDate == null
                              ? 'เลือกวันที่ปลูก'
                              : DateFormat('d MMMM yyyy', 'th_TH').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey[600] : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                        Icon(Icons.calendar_month, color: primaryGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'ที่อยู่ / หมายเหตุ',
              hint: 'เช่น 123 ม.1 ต.เขาชัยทรง...',
              maxLines: 3,
              controller: _addressController,
            ),
            const SizedBox(height: 24),

            // ปุ่มกด ยกเลิก / บันทึก
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGarden,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}