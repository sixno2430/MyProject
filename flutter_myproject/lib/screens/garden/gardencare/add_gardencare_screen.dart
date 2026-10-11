// ============================================================
// add_gardencare_screen.dart — ฟอร์มเพิ่ม/แก้ไขรายการดูแลสวน
//
// แบ่งเป็น 3 การ์ด: 1) เลือกกิจกรรม  2) รายละเอียด  3) ค่าใช้จ่ายและหมายเหตุ
// การ์ดที่ 2 เปลี่ยนตามประเภทกิจกรรม (กำหนดใน care_types.dart):
//   - ใส่ปุ๋ย : รายการปุ๋ยหลายชนิด แต่ละชนิดมี ชื่อ + ปริมาณ + หน่วย กด "+ เพิ่มปุ๋ยอีกชนิด" ได้
//              (ชีวิตจริงใส่ปุ๋ยหลายสูตรในรอบเดียว) ชื่อปุ๋ยพิมพ์เอง หรือเลือกจากปุ๋ยที่ตัวเองเคยบันทึกไว้
//              (ผู้ใช้ใหม่ยังไม่มีรายการแนะนำ บันทึกครั้งแรกแล้วชื่อนั้นจะขึ้นแนะนำครั้งต่อไป)
//   - อื่นๆ   : รายละเอียดเฉพาะประเภท (วิธีให้น้ำ, วิธีกำจัดวัชพืช, ชื่อสารที่พ่น ...) + ปริมาณพร้อมหน่วยที่เลือกได้
// ปุ่มบันทึกติดอยู่ด้านล่างจอเสมอ
// ส่ง existing มา = โหมดแก้ไข: โหลดข้อมูลเต็ม (รวมปุ๋ยทุกชนิด) จาก GET /care-logs/:care_id แล้ว PUT
// ไม่ส่ง = เพิ่มใหม่ (POST) — รหัสรายการใหม่เซิร์ฟเวอร์สร้างให้
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/screens/garden/gardencare/care_types.dart';
import 'package:flutter_myproject/utils/error_message.dart';

/// ปุ๋ย 1 ชนิดในฟอร์ม (มีช่องกรอกของตัวเอง)
class _FertilizerItem {
  final TextEditingController name;
  final TextEditingController quantity;
  final FocusNode focus = FocusNode(); // ใช้กับรายการแนะนำชื่อปุ๋ย
  String unit;

  _FertilizerItem({String name = '', String quantity = '', this.unit = 'กก.'})
      : name = TextEditingController(text: name),
        quantity = TextEditingController(text: quantity);

  void dispose() {
    name.dispose();
    quantity.dispose();
    focus.dispose();
  }
}

/// ฟอร์มบันทึกการดูแลสวน
class AddGardenCareScreen extends StatefulWidget {
  /// ข้อมูลเดิมจาก API (ส่งมา = โหมดแก้ไข, ไม่ส่ง = เพิ่มใหม่) ต้องมี care_id อย่างน้อย
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

  // ใส่ปุ๋ย: รายการปุ๋ย (อย่างน้อย 1 ชนิด) + ชื่อปุ๋ยแนะนำ = ปุ๋ยที่ผู้ใช้คนนี้เคยบันทึก
  final List<_FertilizerItem> _items = [_FertilizerItem()];
  List<String> _fertilizerSuggestions = [];

  // กิจกรรมอื่น: รายละเอียด + ปริมาณ + หน่วย
  final _detailController = TextEditingController();
  final _amountController = TextEditingController();
  String _unit = careTypes.first.unit;

  DateTime _selectedDate = DateTime.now();
  final _costController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingExisting = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedGardenId = e['garden_id']?.toString();
      _loadExisting(e['care_id'].toString());
    }
    _fetchPlots();
    _fetchFertilizers();
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    _detailController.dispose();
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

  /// โหมดแก้ไข: โหลดรายการเต็มจากเซิร์ฟเวอร์ (มีรายการปุ๋ยทุกชนิด + รายละเอียด) แล้วเติมลงฟอร์ม
  Future<void> _loadExisting(String careId) async {
    setState(() => _isLoadingExisting = true);
    try {
      final userId = await AuthService.getUserId() ?? '';
      final res = await http.get(Uri.parse('$apiUrl/care-logs/$careId?user_id=$userId'));
      final body = jsonDecode(res.body);
      if (body is! Map || body['isError'] == true) throw Exception(body is Map ? body['errorMessage'] : null);
      final d = body['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _selectedGardenId = d['garden_id']?.toString() ?? _selectedGardenId;
        _selectedDate = DateTime.tryParse(d['record_date']?.toString() ?? '') ?? _selectedDate;
        final items = (d['fertilizer_items'] as List?) ?? [];
        // รายการเก่าที่ไม่มี action_type แต่มีปุ๋ย = ใส่ปุ๋ย
        _type = items.isNotEmpty ? careTypeOf('fertilizer') : careTypeOf(d['action_type']?.toString());
        _costController.text = _numText(d['cost']);
        _noteController.text = d['note']?.toString() ?? '';
        if (items.isNotEmpty) {
          for (final it in _items) {
            it.dispose();
          }
          _items
            ..clear()
            ..addAll(items.map((it) => _FertilizerItem(
                  name: it['fertilizer_name']?.toString() ?? '',
                  quantity: _numText(it['quantity']),
                  unit: it['unit']?.toString() ?? 'กก.',
                )));
        } else {
          _detailController.text = d['detail']?.toString() ?? '';
          _amountController.text = _numText(d['quantity']);
          final unit = d['quantity_type']?.toString();
          _unit = _type.units.contains(unit) ? unit! : _type.unit;
        }
      });
    } catch (e) {
      _showMessage('โหลดข้อมูลรายการไม่สำเร็จ: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
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

  /// ชื่อปุ๋ยแนะนำ = ปุ๋ยที่ผู้ใช้คนนี้เคยบันทึก เรียงจากที่ใช้ล่าสุด (GET /fertilizers/used)
  Future<void> _fetchFertilizers() async {
    try {
      final userId = await AuthService.getUserId() ?? '';
      final response = await http.get(Uri.parse('$apiUrl/fertilizers/used?user_id=$userId'));
      final body = jsonDecode(response.body);
      if (body is! Map || body['isError'] == true) return;
      if (!mounted) return;
      setState(() => _fertilizerSuggestions = (body['data'] as List).map((n) => n.toString()).toList());
    } catch (_) {
      // โหลดไม่ได้ก็ยังพิมพ์ชื่อปุ๋ยเองได้ แค่จะไม่มีรายการแนะนำ
    }
  }

  /// เปลี่ยนประเภทกิจกรรม: หน่วยกลับเป็นค่าเริ่มต้นของประเภทใหม่ ล้างรายละเอียดที่เป็นตัวเลือกของประเภทเดิม
  void _selectType(CareType t) {
    if (t.type == _type.type) return;
    setState(() {
      if (_type.detailOptions != null && _type.detailOptions!.contains(_detailController.text)) {
        _detailController.clear();
      }
      _type = t;
      _unit = t.unit;
    });
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
  String get _thaiDate => '${DateFormat('d MMMM', 'th_TH').format(_selectedDate)} ${_selectedDate.year + 543}';

  double _parse(String text) => double.tryParse(text.replaceAll(',', '').trim()) ?? 0;

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
        'action_type': _type.type,
        'cost': _parse(_costController.text),
        'record_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'note': _noteController.text.trim(),
        if (_isFertilizer)
          'fertilizer_items': [
            for (final it in _items)
              {'fertilizer_name': it.name.text.trim(), 'quantity': _parse(it.quantity.text), 'unit': it.unit},
          ]
        else ...{
          'detail': _detailController.text.trim(),
          'quantity': _type.hasQuantity ? _parse(_amountController.text) : 0,
          'quantity_type': _type.hasQuantity ? _unit : null,
        },
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
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _section(step: '1', title: 'ทำกิจกรรมอะไร', child: _buildTypeGrid()),
                  _section(
                    step: '2',
                    title: 'รายละเอียดการ${_type.label}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGardenField(),
                        const SizedBox(height: 14),
                        _buildDateField(),
                        const SizedBox(height: 18),
                        if (_isFertilizer) _buildFertilizerList() else _buildTypeDetail(),
                      ],
                    ),
                  ),
                  _section(
                    step: '3',
                    title: 'ค่าใช้จ่ายและหมายเหตุ',
                    child: Column(
                      children: [
                        _numberField(
                          controller: _costController,
                          label: _isFertilizer ? 'ค่าใช้จ่ายรวม (ค่าปุ๋ย + ค่าแรง)' : 'ค่าใช้จ่ายรวม',
                          icon: Icons.payments_outlined,
                          suffix: 'บาท',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          minLines: 2,
                          decoration: _decoration(
                            label: 'หมายเหตุ (ไม่บังคับ)',
                            hint: _isFertilizer ? 'เช่น ใส่รอบโคนต้น ต้นละ 2 กก.' : 'เช่น จ้างคนงาน 2 คน',
                          ),
                        ),
                      ],
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
      padding: EdgeInsets.zero,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: careTypes.map((t) {
        final selected = t.type == _type.type;
        return GestureDetector(
          onTap: () => _selectType(t),
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

  /// ใส่ปุ๋ย: การ์ดปุ๋ยทีละชนิด + ปุ่มเพิ่มอีกชนิด
  Widget _buildFertilizerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ปุ๋ยที่ใส่ในรอบนี้ (${_items.length} ชนิด)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (var i = 0; i < _items.length; i++) _buildFertilizerCard(i),
        OutlinedButton.icon(
          onPressed: () => setState(() => _items.add(_FertilizerItem())),
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มปุ๋ยอีกชนิด'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreen,
            side: const BorderSide(color: primaryGreen),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFertilizerCard(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E6E3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('ชนิดที่ ${index + 1}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryGreen)),
              const Spacer(),
              if (_items.length > 1)
                IconButton(
                  tooltip: 'ลบปุ๋ยชนิดนี้',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => setState(() => _items.removeAt(index).dispose()),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // ชื่อปุ๋ย: พิมพ์เองได้ หรือเลือกจากรายการแนะนำที่ขึ้นมาตอนพิมพ์
          RawAutocomplete<String>(
            textEditingController: item.name,
            focusNode: item.focus,
            optionsBuilder: (value) {
              final q = value.text.trim().toLowerCase();
              return _fertilizerSuggestions.where((s) => q.isEmpty || s.toLowerCase().contains(q));
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณาระบุชื่อปุ๋ย' : null,
              decoration: _decoration(label: 'ชื่อ/สูตรปุ๋ย', hint: 'เช่น ปุ๋ยสูตร 15-15-15', icon: Icons.science_outlined),
            ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final o in options) ListTile(dense: true, title: Text(o), onTap: () => onSelected(o)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _parse(v ?? '') > 0 ? null : 'ระบุปริมาณ',
                  decoration: _decoration(label: 'ปริมาณ', icon: Icons.scale_outlined),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _unitDropdown(
                  value: item.unit,
                  units: fertilizerUnits,
                  onChanged: (u) => setState(() => item.unit = u),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// กิจกรรมอื่นนอกจากใส่ปุ๋ย: รายละเอียดเฉพาะประเภท + ปริมาณพร้อมหน่วย
  Widget _buildTypeDetail() {
    final t = _type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.detailLabel != null) ...[
          if (t.detailOptions != null) ...[
            Text('${t.detailLabel} (เลือกได้ 1 อย่าง)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // ค่าเดิมที่ไม่อยู่ในตัวเลือก (บันทึกไว้ก่อนหน้า) ก็แสดงให้เห็นด้วย
                for (final o in {
                  ...t.detailOptions!,
                  if (_detailController.text.isNotEmpty) _detailController.text,
                })
                  ChoiceChip(
                    label: Text(o),
                    selected: _detailController.text == o,
                    showCheckmark: false,
                    selectedColor: t.bgColor,
                    side: BorderSide(color: _detailController.text == o ? t.color : const Color(0xFFE0E6E3)),
                    labelStyle: TextStyle(
                      color: _detailController.text == o ? t.color : Colors.grey[800],
                      fontWeight: _detailController.text == o ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (sel) => setState(() => _detailController.text = sel ? o : ''),
                  ),
              ],
            ),
          ] else
            TextFormField(
              controller: _detailController,
              maxLength: 200,
              validator: (v) =>
                  t.detailRequired && (v ?? '').trim().isEmpty ? 'กรุณาระบุ${t.detailLabel}' : null,
              decoration: _decoration(
                label: '${t.detailLabel}${t.detailRequired ? ' *' : ''}',
                hint: t.detailHint,
                icon: Icons.edit_note,
              ).copyWith(counterText: ''),
            ),
          const SizedBox(height: 14),
        ],
        if (t.hasQuantity)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _numberField(
                  controller: _amountController,
                  label: t.quantityLabel,
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: t.units.length == 1
                    ? InputDecorator(decoration: _decoration(label: 'หน่วย'), child: Text(t.units.first))
                    : _unitDropdown(value: _unit, units: t.units, onChanged: (u) => setState(() => _unit = u)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _unitDropdown({
    required String value,
    required List<String> units,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: units.contains(value) ? value : units.first,
      isExpanded: true,
      decoration: _decoration(label: 'หน่วย'),
      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (u) {
        if (u != null) onChanged(u);
      },
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
      // key: เปลี่ยนเมื่อโหลดข้อมูลเดิมเสร็จ ให้ dropdown แสดงแปลงที่ถูกต้อง
      key: ValueKey('garden-$_selectedGardenId'),
      initialValue: _plots.any((p) => p['id'] == _selectedGardenId) ? _selectedGardenId : null,
      isExpanded: true,
      decoration: _decoration(label: 'แปลงสวน', icon: Icons.forest_outlined),
      items: _plots.map((p) => DropdownMenuItem<String>(value: p['id'], child: Text(p['name']!))).toList(),
      onChanged: (v) => setState(() => _selectedGardenId = v),
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
    String? suffix,
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
          onPressed: _isSubmitting || _isLoadingExisting || _plots.isEmpty ? null : _save,
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
