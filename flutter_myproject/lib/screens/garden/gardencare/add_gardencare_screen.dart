// ============================================================
// add_gardencare_screen.dart — ฟอร์มเพิ่ม/แก้ไขรายการดูแลสวน
//
// แบ่งเป็น 3 การ์ด: 1) เลือกกิจกรรม  2) รายละเอียด (แปลง, ปุ๋ย, วันที่, ปริมาณ, ค่าใช้จ่าย)  3) หมายเหตุ
// ปุ่มบันทึกติดอยู่ด้านล่างจอเสมอ
// ส่ง existing มา = โหมดแก้ไข (PUT) ไม่ส่ง = เพิ่มใหม่ (POST) — รหัสรายการใหม่เซิร์ฟเวอร์สร้างให้
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/screens/garden/gardencare/care_types.dart';
import 'package:flutter_myproject/utils/error_message.dart';

/// ฟอร์มบันทึกการดูแลสวน
class AddGardenCareScreen extends StatefulWidget {
  /// ข้อมูลเดิมจาก API (ส่งมา = โหมดแก้ไข, ไม่ส่ง = เพิ่มใหม่)
  final Map<String, dynamic>? existing;

  const AddGardenCareScreen({super.key, this.existing});

  @override
  State<AddGardenCareScreen> createState() => _AddGardenCareScreenState();
}

class _AddGardenCareScreenState extends State<AddGardenCareScreen> {
  static const Color primaryGreen = Color(0xFF2D6A4F);
  final _formKey = GlobalKey<FormState>();

  String get apiUrl => AppConfig.apiBaseUri;

  // แปลงสวน
  String? _selectedGardenId;
  List<Map<String, String>> _plots = [];
  bool _isLoadingPlots = true;

  // ประเภทกิจกรรม
  CareType _type = careTypes.first; // ค่าเริ่มต้น: ใส่ปุ๋ย
  bool get _isFertilizer => _type.type == 'fertilizer';

  // ชนิดปุ๋ย (โหลดจาก /api/fertilizers) ใช้เมื่อเลือก "ใส่ปุ๋ย"
  List<Map<String, String>> _fertilizers = [];
  String? _selectedFertilizerId;

  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  final _costController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedGardenId = e['garden_id']?.toString();
      _selectedDate = DateTime.tryParse(e['record_date']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final hasFertilizer = e['fertilizer_id'] != null && e['fertilizer_id'].toString().isNotEmpty;
      _type = hasFertilizer ? careTypeOf('fertilizer') : careTypeOf(e['action_type']?.toString());
      _selectedFertilizerId = hasFertilizer ? e['fertilizer_id'].toString() : null;
      _noteController.text = e['note']?.toString() ?? '';
      _amountController.text = _numText(e['quantity']);
      _costController.text = _numText(e['cost']);
    }
    _fetchPlots();
    _fetchFertilizers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// แปลงตัวเลขจาก DB เป็นข้อความในช่องกรอก (40.00 -> "40", 0 -> "")
  String _numText(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '');
    if (n == null || n == 0) return '';
    return n % 1 == 0 ? n.toInt().toString() : n.toString();
  }

  /// โหลดแปลงสวนของ user มาใส่ dropdown
  Future<void> _fetchPlots() async {
    final userId = await AuthService.getUserId();
    try {
      if (userId == null || userId.isEmpty) return;
      final response = await http.get(Uri.parse('$apiUrl/gardens/$userId'));
      final body = jsonDecode(response.body);
      final List data = body is Map && body['data'] is List ? body['data'] : [];
      if (!mounted) return;
      setState(() {
        _plots = data
            .map((g) => {'id': g['garden_id'].toString(), 'name': g['garden_name'].toString()})
            .toList();
        // โหมดแก้ไขคงแปลงเดิมไว้ ถ้าไม่มีค่อยเลือกแปลงแรก
        if (!_plots.any((p) => p['id'] == _selectedGardenId) && _plots.isNotEmpty) {
          _selectedGardenId = _plots.first['id'];
        }
      });
    } catch (_) {
      // โหลดไม่ได้ -> แสดงข้อความ "ยังไม่มีแปลงสวน" แทน
    } finally {
      if (mounted) setState(() => _isLoadingPlots = false);
    }
  }

  /// โหลดรายชื่อปุ๋ยจาก /api/fertilizers มาใส่ dropdown
  Future<void> _fetchFertilizers() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/fertilizers'));
      final body = jsonDecode(response.body);
      if (body is! Map || body['isError'] == true) return;
      final list = (body['data'] as List)
          .map((f) => {'id': f['fertilizer_id'].toString(), 'name': f['fertilizer_name'].toString()})
          .toList();
      if (!mounted) return;
      setState(() {
        _fertilizers = list;
        if (!list.any((f) => f['id'] == _selectedFertilizerId) && list.isNotEmpty) {
          _selectedFertilizerId = list.first['id'];
        }
      });
    } catch (_) {
      // โหลดไม่ได้ก็ยังบันทึกได้ แค่จะไม่ระบุชนิดปุ๋ย
    }
  }

  /// เลือกวันที่ดำเนินการ (เลือกวันในอนาคตไม่ได้)
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// วันที่ที่เลือก แสดงเป็นภาษาไทย ปี พ.ศ. เช่น "29 กันยายน 2569"
  String get _thaiDate =>
      '${DateFormat('d MMMM', 'th_TH').format(_selectedDate)} ${_selectedDate.year + 543}';

  /// ตรวจฟอร์ม แล้วส่งบันทึก (เพิ่มใหม่หรือแก้ไข) สำเร็จแล้วปิดหน้า
  Future<void> _save() async {
    if (_selectedGardenId == null) {
      _showMessage('กรุณาเลือกแปลงสวน');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      _showMessage('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final body = jsonEncode({
        'user_id': userId,
        'garden_id': _selectedGardenId,
        'fertilizer_id': _isFertilizer ? _selectedFertilizerId : null,
        'action_type': _type.type,
        'quantity': double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0,
        'quantity_type': _type.unit,
        'cost': double.tryParse(_costController.text.replaceAll(',', '').trim()) ?? 0,
        'record_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'note': _noteController.text.trim(),
      });
      const headers = {'Content-Type': 'application/json'};

      final response = _isEdit
          ? await http.put(Uri.parse('$apiUrl/care-logs/${widget.existing!['care_id']}'),
              headers: headers, body: body)
          : await http.post(Uri.parse('$apiUrl/care-logs'), headers: headers, body: body);

      final res = jsonDecode(response.body);
      if (res is Map && res['isError'] == true) {
        throw Exception(res['errorMessage'] ?? 'บันทึกไม่สำเร็จ');
      }
      if (!mounted) return;
      _showMessage(_isEdit ? 'แก้ไขรายการเรียบร้อยแล้ว' : 'บันทึกการดูแลเรียบร้อยแล้ว', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: success ? primaryGreen : null,
    ));
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEdit ? 'แก้ไขการดูแล' : 'บันทึกการดูแล',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      // ปุ่มบันทึกติดด้านล่างจอเสมอ ไม่ต้องเลื่อนหา
      bottomNavigationBar: _buildSaveBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _section(
              step: '1',
              title: 'ทำกิจกรรมอะไร',
              child: _buildTypeGrid(),
            ),
            _section(
              step: '2',
              title: 'รายละเอียด',
              child: Column(
                children: [
                  _buildGardenField(),
                  if (_isFertilizer && _fertilizers.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildFertilizerField(),
                  ],
                  const SizedBox(height: 14),
                  _buildDateField(),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          controller: _amountController,
                          label: 'ปริมาณ',
                          icon: Icons.scale_outlined,
                          suffix: _type.unit, // หน่วยเปลี่ยนตามประเภท
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          controller: _costController,
                          label: 'ค่าใช้จ่าย',
                          icon: Icons.payments_outlined,
                          suffix: 'บาท',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(
              step: '3',
              title: _type.type == 'other' ? 'หมายเหตุ *' : 'หมายเหตุ (ไม่บังคับ)',
              child: TextFormField(
                controller: _noteController,
                maxLines: 3,
                minLines: 2,
                // "อื่นๆ" ต้องบอกว่าทำอะไร ไม่งั้นดูย้อนหลังแล้วไม่รู้เรื่อง
                validator: (v) => _type.type == 'other' && (v == null || v.trim().isEmpty)
                    ? 'กรุณาบอกว่าทำกิจกรรมอะไร'
                    : null,
                decoration: _decoration(
                  hint: _isFertilizer ? 'เช่น ใส่รอบโคนต้น ต้นละ 2 กก.' : 'เช่น ตัดทางใบแห้ง จ้างคนงาน 2 คน',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- การ์ดแต่ละส่วน ----------

  Widget _section({required String step, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                child: Center(
                  child: Text(step,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// ตารางเลือกประเภทกิจกรรม 3 คอลัมน์
  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: careTypes.map((t) {
        final selected = t.type == _type.type;
        return GestureDetector(
          onTap: () => setState(() => _type = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? t.bgColor : const Color(0xFFF7F8F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? t.color : Colors.transparent, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            // FittedBox: จอแคบจะย่อ emoji + ชื่อลงให้พอดีช่อง แทนการล้น
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? t.color : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGardenField() {
    if (_isLoadingPlots) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_plots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
        child: const Text('ยังไม่มีแปลงสวน กรุณาเพิ่มแปลงสวนก่อนบันทึกการดูแล',
            style: TextStyle(color: Color(0xFFE65100))),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _plots.any((p) => p['id'] == _selectedGardenId) ? _selectedGardenId : null,
      isExpanded: true,
      decoration: _decoration(label: 'แปลงสวน', icon: Icons.forest_outlined),
      items: _plots
          .map((p) => DropdownMenuItem<String>(value: p['id'], child: Text(p['name']!)))
          .toList(),
      onChanged: (v) => setState(() => _selectedGardenId = v),
    );
  }

  Widget _buildFertilizerField() {
    return DropdownButtonFormField<String>(
      // key: สร้างใหม่เมื่อรายการปุ๋ยโหลดเสร็จ ให้แสดงค่าที่เลือกไว้ถูกต้อง
      key: ValueKey('fert-${_fertilizers.length}'),
      initialValue: _fertilizers.any((f) => f['id'] == _selectedFertilizerId) ? _selectedFertilizerId : null,
      isExpanded: true,
      decoration: _decoration(label: 'ชนิดปุ๋ย', icon: Icons.science_outlined),
      items: _fertilizers
          .map((f) => DropdownMenuItem<String>(value: f['id'], child: Text(f['name']!)))
          .toList(),
      onChanged: (v) => setState(() => _selectedFertilizerId = v),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(label: 'วันที่ดำเนินการ', icon: Icons.calendar_today_outlined),
        child: Row(
          children: [
            Expanded(
              child: Text(_thaiDate, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null; // ไม่กรอก = 0
        return double.tryParse(v.replaceAll(',', '').trim()) == null ? 'ใส่เป็นตัวเลข' : null;
      },
      decoration: _decoration(label: label, icon: icon, suffix: suffix),
    );
  }

  InputDecoration _decoration({String? label, String? hint, IconData? icon, String? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: icon == null ? null : Icon(icon, color: primaryGreen, size: 20),
      floatingLabelStyle: const TextStyle(color: primaryGreen),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF7F8F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting || _plots.isEmpty ? null : _save,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check),
          label: Text(
            _isSubmitting ? 'กำลังบันทึก...' : (_isEdit ? 'บันทึกการแก้ไข' : 'บันทึก${_type.label}'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
