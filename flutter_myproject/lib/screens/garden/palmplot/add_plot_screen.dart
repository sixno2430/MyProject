// ============================================================
// add_plot_screen.dart — หน้าเพิ่มแปลงสวนใหม่
//
// กรอกชื่อ, พื้นที่, จำนวนต้น, ปีที่ปลูก, ที่อยู่ และเลือกพันธุ์ปาล์ม
// ส่งไป POST /api/gardens โดยผูกกับ user ที่ล็อกอินอยู่
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../config/app_config.dart'; // ← ใช้ config ที่มีอยู่
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/utils/error_message.dart';

/// หน้าเพิ่มแปลงสวน
class AddPlotScreen extends StatefulWidget {
  const AddPlotScreen({super.key});

  @override
  State<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  
  // ← แก้ตรงนี้: ใช้ AppConfig แทน hardcode
  String get apiUrl => AppConfig.apiBaseUri;

  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _treeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  // ← เพิ่มตรงนี้: ตัวแปรเก็บพันธุ์ปาล์ม
  List<dynamic> _varieties = [];
  String? _selectedVarietyId;
  bool _loadingVarieties = true;

  // ← เพิ่มตรงนี้: initState (ถ้าไม่มีอยู่แล้ว)
  @override
  void initState() {
    super.initState();
    _fetchVarieties();  // เรียกดึงพันธุ์ตอนเปิดหน้า
  }

  // ← เพิ่มตรงนี้: ฟังก์ชันดึงพันธุ์จาก API
  /// โหลดรายชื่อพันธุ์ปาล์มมาใส่ dropdown
  Future<void> _fetchVarieties() async {
    try {
      // พันธุ์แยกตามผู้ใช้: ได้เฉพาะพันธุ์ของตัวเอง (บัญชีใหม่จะว่าง)
      final userId = await AuthService.getUserId() ?? '';
      final response = await http.get(Uri.parse('$apiUrl/varieties?user_id=$userId'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['isError'] == false && body['data'] != null) {
          _varieties = body['data'];
        }
      }
    } catch (_) {
      // โหลดไม่ได้ก็ยังเพิ่มแปลงได้ (พันธุ์ไม่บังคับ)
    } finally {
      // เดิมโหลดไม่สำเร็จแล้ววงกลมหมุนค้างตลอด -> ปิดตัวโหลดเสมอ
      if (mounted) setState(() => _loadingVarieties = false);
    }
  }

  /// เลือกวันที่ปลูก (ใช้เฉพาะปี)
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// ตรวจข้อมูลแล้วบันทึกแปลงใหม่ สำเร็จแล้วปิดหน้า
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _areaCtrl.text.trim().isEmpty || _treeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลที่มี * ให้ครบ')),
      );
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
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/gardens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'garden_name': _nameCtrl.text.trim(),
          'area_size': double.tryParse(_areaCtrl.text.trim()) ?? 0.0,
          'plant_count': int.tryParse(_treeCtrl.text.trim()) ?? 0,
          'plant_year': _selectedDate?.year ?? DateTime.now().year,
          'address': _addressCtrl.text.trim(),
          'variety_id': _selectedVarietyId,
        }),
      );

      final res = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && res['isError'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เพิ่มแปลงสวนสำเร็จ!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(res['errorMessage'] ?? 'บันทึกไม่สำเร็จ');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
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
        title: const Text('เพิ่มแปลงสวนใหม่', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field('ชื่อแปลงสวน *', _nameCtrl),
            _field('พื้นที่ (ไร่) *', _areaCtrl, TextInputType.number),
            _field('จำนวนต้นปาล์ม *', _treeCtrl, TextInputType.number),
             const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'พันธุ์ปาล์มที่ปลูก',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _loadingVarieties
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedVarietyId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                              hintText: 'เลือกพันธุ์ปาล์ม',
                            ),
                            items: _varieties.map<DropdownMenuItem<String>>((v) {
                              return DropdownMenuItem<String>(
                                value: v['variety_id'].toString(),
                                child: Text(v['variety_name'].toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedVarietyId = value);
                            },
                          ),
                        ),
                ),
                // บัญชีที่ยังไม่มีพันธุ์ของตัวเอง (พันธุ์ไม่บังคับ บันทึกแปลงได้เลย)
                if (!_loadingVarieties && _varieties.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'ยังไม่มีพันธุ์ปาล์มของคุณ เพิ่มได้ที่เมนู "พันธุ์ปาล์ม" (ไม่เลือกก็บันทึกแปลงได้)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // วันที่ปลูก
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'เลือกวันที่ปลูก'
                          : DateFormat('d MMMM yyyy', 'th_TH').format(_selectedDate!),
                      style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                    ),
                    Icon(Icons.calendar_month, color: primaryGreen),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _field('ที่อยู่ / หมายเหตุ', _addressCtrl, TextInputType.text, 3),
            const SizedBox(height: 24),
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
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  /// ช่องกรอกข้อความ 1 ช่อง
  Widget _field(String label, TextEditingController ctrl, [TextInputType? type, int lines = 1]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}