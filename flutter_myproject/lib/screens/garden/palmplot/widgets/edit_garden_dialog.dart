// ============================================================
// edit_garden_dialog.dart — หน้าต่างแก้ไขแปลงสวน
//
// แก้ชื่อ, พื้นที่, จำนวนต้น, ปีที่ปลูก, ที่อยู่ และพันธุ์ที่ปลูก แล้วคืนค่าที่แก้ให้หน้ารายการแปลงส่งไปบันทึก
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/models/garden.dart';

/// bottom sheet แก้ไขแปลงสวน คืนค่า Map ข้อมูลใหม่เมื่อกดบันทึก
class EditGardenDialog extends StatefulWidget {
  final Garden garden;
  final Color primaryGreen;

  const EditGardenDialog({super.key, required this.garden, required this.primaryGreen});

  @override
  State<EditGardenDialog> createState() => _EditGardenDialogState();
}

class _EditGardenDialogState extends State<EditGardenDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _countCtrl;

  /// เก็บเป็น ค.ศ. (ตามฐานข้อมูล) แต่แสดงผลเป็น พ.ศ.
  int? _plantYear;

  /// พันธุ์ปาล์มของผู้ใช้ [{variety_id, variety_name}] และพันธุ์ที่เลือก (null = ไม่ระบุพันธุ์)
  List<Map<String, String>> _varieties = [];
  bool _loadingVarieties = true;
  String? _varietyId;

  Color get _green => widget.primaryGreen;

  @override
  void initState() {
    super.initState();
    final g = widget.garden;
    _nameCtrl = TextEditingController(text: g.gardenName);
    _addressCtrl = TextEditingController(text: g.address ?? '');
    _areaCtrl = TextEditingController(text: g.areaSize > 0 ? _trimZero(g.areaSize) : '');
    _countCtrl = TextEditingController(text: g.plantCount > 0 ? '${g.plantCount}' : '');
    _plantYear = g.plantYear;
    // แปลงหนึ่งปลูกพันธุ์เดียว (ตามหน้าเพิ่มแปลง) -> เอาพันธุ์แรกเป็นค่าตั้งต้น
    final current = g.varieties ?? [];
    _varietyId = current.isNotEmpty && current.first.varietyId.isNotEmpty ? current.first.varietyId : null;
    _loadVarieties();
  }

  /// โหลดพันธุ์ปาล์มของผู้ใช้ (พันธุ์แยกตามผู้ใช้ เห็นเฉพาะของตัวเอง)
  Future<void> _loadVarieties() async {
    try {
      final userId = await AuthService.getUserId() ?? '';
      final res = await http.get(Uri.parse('${AppConfig.apiBaseUri}/varieties?user_id=$userId'));
      final body = jsonDecode(res.body);
      if (body is Map && body['isError'] == false && body['data'] is List) {
        _varieties = (body['data'] as List)
            .map((v) => {'id': v['variety_id'].toString(), 'name': v['variety_name'].toString()})
            .toList();
      }
    } catch (_) {
      // โหลดไม่ได้: ยังแก้ข้อมูลอื่นได้ และจะไม่ส่งพันธุ์ไป (คงพันธุ์เดิม)
    } finally {
      if (mounted) setState(() => _loadingVarieties = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  // 20.0 -> "20", 12.5 -> "12.5"
  /// ตัดทศนิยม .0 ทิ้ง (20.0 -> "20")
  String _trimZero(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// อายุต้นปาล์ม (ปี) คำนวณจากปีที่ปลูก
  int? get _plantAge {
    if (_plantYear == null) return null;
    final age = DateTime.now().year - _plantYear!;
    return age < 0 ? null : age;
  }

  /// เปิดรายการให้เลือกปีที่ปลูก (แสดงเป็น พ.ศ. เก็บเป็น ค.ศ.)
  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final years = List.generate(41, (i) => now - i); // ย้อนหลัง 40 ปี
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 360,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('เลือกปีที่ปลูก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, i) {
                    final y = years[i];
                    final selected = y == _plantYear;
                    return ListTile(
                      title: Text(
                        'พ.ศ. ${y + 543}',
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? _green : null,
                        ),
                      ),
                      trailing: Text(
                        now - y == 0 ? 'ปีนี้' : '${now - y} ปี',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      selected: selected,
                      onTap: () => Navigator.pop(context, y),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _plantYear = picked);
  }

  /// ตรวจฟอร์ม แล้วปิด sheet พร้อมส่งข้อมูลกลับ
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'garden_name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'area_size': double.tryParse(_areaCtrl.text.trim()) ?? 0,
      'plant_year': _plantYear,
      'plant_count': int.tryParse(_countCtrl.text.trim()) ?? 0,
      // ส่งพันธุ์เฉพาะเมื่อโหลดรายการพันธุ์ได้ (โหลดไม่ได้ = ไม่ส่ง เซิร์ฟเวอร์คงพันธุ์เดิมไว้)
      if (_varieties.isNotEmpty || _varietyId == null) 'variety_id': _varietyId,
    });
  }

  /// ช่องเลือกพันธุ์ปาล์ม (มีตัวเลือก "ไม่ระบุพันธุ์")
  Widget _varietySelector() {
    if (_loadingVarieties) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    // ค่าที่เลือกต้องอยู่ในรายการ ไม่งั้น Dropdown error
    final safeValue = _varieties.any((v) => v['id'] == _varietyId) ? _varietyId : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: safeValue,
            isExpanded: true,
            decoration: _decoration(label: 'พันธุ์ปาล์ม', icon: Icons.eco_outlined),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('ไม่ระบุพันธุ์')),
              ..._varieties.map(
                (v) => DropdownMenuItem<String?>(
                  value: v['id'],
                  child: Text(v['name']!, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _varietyId = v),
          ),
          if (_varieties.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'ยังไม่มีพันธุ์ปาล์มของคุณ เพิ่มได้ที่เมนู "พันธุ์ปาล์ม"',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ดันฟอร์มขึ้นตามความสูงคีย์บอร์ด ช่องล่างๆ จะได้ไม่ถูกบัง
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── หัว: แถบจับ + ชื่อ + ปุ่มปิด ──
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🌴', style: TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'แก้ไขแปลงสวน',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                            ),
                            Text(widget.garden.gardenId, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // ── ฟอร์ม ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('ข้อมูลทั่วไป'),
                        _field(
                          label: 'ชื่อแปลงสวน *',
                          controller: _nameCtrl,
                          icon: Icons.forest_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อแปลงสวน' : null,
                        ),
                        _field(
                          label: 'ที่อยู่ / ตำแหน่งแปลง',
                          hint: 'เช่น ม.3 ต.ท่าข้าม อ.พุนพิน',
                          controller: _addressCtrl,
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        _sectionTitle('ข้อมูลการปลูก'),
                        _varietySelector(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(
                                label: 'ขนาดพื้นที่',
                                controller: _areaCtrl,
                                icon: Icons.square_foot,
                                suffix: 'ไร่',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = double.tryParse(v.trim());
                                  return (n == null || n < 0) ? 'ตัวเลขไม่ถูกต้อง' : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: 'จำนวนต้น',
                                controller: _countCtrl,
                                icon: Icons.park_outlined,
                                suffix: 'ต้น',
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = int.tryParse(v.trim());
                                  return (n == null || n < 0) ? 'ใส่เป็นจำนวนเต็ม' : null;
                                },
                              ),
                            ),
                          ],
                        ),
                        _yearSelector(),
                      ],
                    ),
                  ),
                ),

                // ── ปุ่ม ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ยกเลิก', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text(
                            'บันทึกการแก้ไข',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// หัวข้อหมวดในฟอร์ม
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
      ),
    );
  }

  /// ช่องเลือกปีที่ปลูก พร้อมป้ายบอกอายุต้น
  Widget _yearSelector() {
    final age = _plantAge;
    return InkWell(
      onTap: _pickYear,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(label: 'ปีที่ปลูก', icon: Icons.calendar_month_outlined),
        child: Row(
          children: [
            // ปีขยายเต็มที่ว่าง (จอแคบตัดเป็น ...) ป้ายอายุกับลูกศรจะได้ไม่ล้น
            Expanded(
              child: Text(
                _plantYear == null ? 'เลือกปี' : 'พ.ศ. ${_plantYear! + 543}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: _plantYear == null ? Colors.grey[400] : const Color(0xFF1F2937)),
              ),
            ),
            if (age != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  age == 0 ? 'ปลูกปีนี้' : 'อายุ $age ปี',
                  style: TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  /// หน้าตาช่องกรอกที่ใช้ร่วมกันในฟอร์ม
  InputDecoration _decoration({required String label, required IconData icon, String? hint, String? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon, color: _green, size: 20),
      labelStyle: TextStyle(color: Colors.grey[600]),
      floatingLabelStyle: TextStyle(color: _green),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  /// ช่องกรอกข้อความ 1 ช่อง
  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? suffix,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        cursorColor: _green,
        decoration: _decoration(label: label, icon: icon, hint: hint, suffix: suffix),
      ),
    );
  }
}
