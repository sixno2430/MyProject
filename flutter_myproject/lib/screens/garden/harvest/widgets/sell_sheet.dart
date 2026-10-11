// ============================================================
// sell_sheet.dart — หน้าต่างด้านล่าง "บันทึกขายนอกระบบ"
//
// ขายให้ร้านที่ไม่อยู่ในแอป: ถามราคาต่อกิโลกรัม ชื่อร้าน (ไม่บังคับ) เกรด และวันที่ขาย
// คำนวณรายได้ให้ดูทันที แล้วคืนค่าที่กรอกให้หน้าเก็บเกี่ยวส่งไปบันทึก
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/harvest.dart';
import 'package:flutter_myproject/screens/garden/harvest/widgets/sale_fields.dart';

/// ขายให้ร้านที่ไม่อยู่ในแอป: ถามราคาต่อกิโลกรัม ชื่อร้าน (ไม่บังคับ) และวันที่ขาย
/// คำนวณรายได้ให้ดูทันที แล้วคืนค่าที่กรอก
class SellSheet extends StatefulWidget {
  final HarvestData item;
  const SellSheet({super.key, required this.item});

  @override
  State<SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<SellSheet> {
  static const green = Color(0xFF1E5631);
  late final TextEditingController _priceCtrl;
  final _buyerCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  DateTime _soldDate = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.item.pricePerKg;
    _priceCtrl = TextEditingController(text: p > 0 ? (p % 1 == 0 ? p.toInt().toString() : p.toString()) : '');
    _priceCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _buyerCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  /// ราคาที่กรอก (null ถ้าไม่ใช่ตัวเลข)
  double? get _price => double.tryParse(_priceCtrl.text.trim());

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    // ขายได้ตั้งแต่วันเก็บเกี่ยวถึงวันนี้ (วันเก็บเกี่ยวอยู่ในอนาคต = เริ่มที่วันนี้ กัน firstDate > lastDate)
    final today = DateUtils.dateOnly(DateTime.now());
    final harvested = DateTime.tryParse(widget.item.date);
    final first = harvested == null || harvested.isAfter(today) ? today : harvested;
    final picked = await showDatePicker(
      context: context,
      initialDate: _soldDate.isBefore(first) ? first : _soldDate,
      firstDate: first,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _soldDate = picked);
  }

  /// ตรวจว่าราคามากกว่า 0 แล้วปิด sheet พร้อมส่งค่ากลับ
  void _confirm() {
    final price = _price;
    if (price == null || price <= 0) {
      setState(() => _error = 'กรุณาใส่ราคาที่มากกว่า 0');
      return;
    }
    Navigator.pop(context, (
      price: price,
      buyerName: _buyerCtrl.text.trim(),
      soldDate: _ymd(_soldDate),
      grade: _gradeCtrl.text.trim(),
    ));
  }

  InputDecoration _decoration(String label, IconData icon, {String? suffix, String? hint, String? error}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      errorText: error,
      prefixIcon: Icon(icon, color: green),
      floatingLabelStyle: const TextStyle(color: green),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = (_price ?? 0) * item.quantityKg;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ขายนอกระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${item.code} · ${item.plotName} · ${item.quantityKg.toStringAsFixed(0)} กก.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                // บอกทางที่ถูกถ้าร้านอยู่ในแอป: ให้ร้านเป็นคนยืนยัน ยอดสองฝั่งจะได้ตรงกัน
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFFC2410C)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ขายให้ร้านที่อยู่ในแอป? กดค้างที่รายการ > แก้ไข แล้วเลือกร้าน '
                          'ร้านจะเป็นคนยืนยันรับซื้อ',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF7C2D12), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: green,
                  decoration: _decoration(
                    'ราคาขายต่อกิโลกรัม',
                    Icons.payments_outlined,
                    suffix: 'บาท/กก.',
                    error: _error,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buyerCtrl,
                  cursorColor: green,
                  maxLength: 100,
                  decoration: _decoration(
                    'ชื่อร้านที่ขายให้ (ไม่บังคับ)',
                    Icons.storefront_outlined,
                    hint: 'เช่น ลานเทสมชาย',
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                GradePicker(controller: _gradeCtrl),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration('วันที่ขาย', Icons.calendar_today_outlined),
                    child: Text('${_soldDate.day}/${_soldDate.month}/${_soldDate.year + 543}'),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Text('รายได้จากการขาย', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${total.toStringAsFixed(2)} ฿',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันขายแล้ว', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
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
        ),
      ),
    );
  }
}
