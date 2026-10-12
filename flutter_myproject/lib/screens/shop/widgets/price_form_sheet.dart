// ============================================================
// price_form_sheet.dart — ฟอร์มตั้ง / แก้ไขราคารับซื้อ (เกรด, ราคาต่อกิโลกรัม, วันเริ่มใช้ - วันสิ้นสุด)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/models/shop.dart';
import 'package:flutter_myproject/screens/shop/widgets/sheet_frame.dart';

class PriceFormSheet extends StatefulWidget {
  final String shopId;
  final ShopPriceRate? rate;
  const PriceFormSheet({super.key, required this.shopId, this.rate});

  @override
  State<PriceFormSheet> createState() => _PriceFormSheetState();
}

class _PriceFormSheetState extends State<PriceFormSheet> {
  static const _quickGrades = ['เกรด A', 'เกรด B', 'เกรด C', 'ทะลายสด'];
  final _formKey = GlobalKey<FormState>();
  late final _grade = TextEditingController(text: widget.rate?.grade ?? 'เกรด A');
  late final _price = TextEditingController(
    text: widget.rate == null ? '' : widget.rate!.pricePerKg.toStringAsFixed(2),
  );
  late DateTime _start = DateTime.tryParse(widget.rate?.effectiveDate ?? '') ?? DateTime.now();
  late DateTime? _end = DateTime.tryParse(widget.rate?.endDate ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _grade.dispose();
    _price.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _thai(DateTime d) => '${DateFormat('d MMMM', 'th_TH').format(d)} ${d.year + 543}';

  Future<void> _pick({required bool isEnd}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_end ?? _start) : _start,
      firstDate: isEnd ? _start : DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: RoleTheme.shop.primary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _end = picked;
      } else {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null; // วันหมดอายุต้องไม่ก่อนวันเริ่ม
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = await AuthService.getUserId();
      await ShopService.savePrice(
        userId: userId ?? '',
        shopId: widget.shopId,
        id: widget.rate?.id,
        grade: _grade.text.trim(),
        pricePerKg: double.parse(_price.text.trim()),
        effectiveDate: _ymd(_start),
        endDate: _end == null ? null : _ymd(_end!),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = RoleTheme.shop;
    return SheetFrame(
      title: widget.rate == null ? 'เพิ่มราคารับซื้อ' : 'แก้ไขราคารับซื้อ',
      buttonText: _saving ? 'กำลังบันทึก...' : 'บันทึกราคา',
      onSubmit: _saving ? null : _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ปุ่มลัดเลือกเกรดที่ใช้บ่อย
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickGrades.map((g) {
                final selected = _grade.text.trim() == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: selected,
                  selectedColor: theme.primary,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey[800]),
                  backgroundColor: theme.soft,
                  side: BorderSide(color: selected ? theme.primary : theme.border),
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _grade.text = g),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            sheetField(
              _grade,
              'เกรด / ชนิด *',
              Icons.grade_outlined,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกเกรด' : null,
            ),
            sheetField(
              _price,
              'ราคาต่อกิโลกรัม *',
              Icons.payments_outlined,
              suffix: 'บาท/กก.',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return (n == null || n <= 0) ? 'กรุณาใส่ราคาที่มากกว่า 0' : null;
              },
            ),
            _dateRow('เริ่มใช้', _thai(_start), () => _pick(isEnd: false)),
            const SizedBox(height: 10),
            _dateRow(
              'หมดอายุ',
              _end == null ? 'ไม่มีวันหมดอายุ' : _thai(_end!),
              () => _pick(isEnd: true),
              trailing: _end == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'ไม่มีวันหมดอายุ',
                      onPressed: () => setState(() => _end = null),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRow(String label, String value, VoidCallback onTap, {Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: sheetDecoration(label, Icons.calendar_today_outlined),
        child: Row(
          children: [
            Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
