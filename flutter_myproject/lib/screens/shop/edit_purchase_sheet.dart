// ============================================================
// edit_purchase_sheet.dart — หน้าต่าง "แก้ไขการรับซื้อ" ของร้าน
//
// แก้น้ำหนัก / ราคาต่อกก. / วันที่ ยอดรวมคำนวณให้เอง
// สำเร็จ = คืน true (รายรับฝั่งเกษตรกรเปลี่ยนตามด้วย)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';
import 'package:flutter_myproject/utils/error_message.dart';

/// เปิดหน้าต่างแก้ไขการรับซื้อ — คืน true เมื่อบันทึกสำเร็จ
Future<bool> showEditPurchaseSheet(BuildContext context, ShopPurchase purchase) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditPurchaseSheet(purchase: purchase),
  );
  return done == true;
}

class _EditPurchaseSheet extends StatefulWidget {
  final ShopPurchase purchase;
  const _EditPurchaseSheet({required this.purchase});

  @override
  State<_EditPurchaseSheet> createState() => _EditPurchaseSheetState();
}

class _EditPurchaseSheetState extends State<_EditPurchaseSheet> {
  static const theme = RoleTheme.shop;
  final NumberFormat _money = NumberFormat('#,##0.00');
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late DateTime _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _qtyCtrl = TextEditingController(text: NumberFormat('0.##').format(p.quantity));
    _priceCtrl = TextEditingController(text: p.pricePerKg.toStringAsFixed(2));
    _date = DateTime(p.date.year, p.date.month, p.date.day);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;
  double get _price => double.tryParse(_priceCtrl.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_qty > 0)) {
      setState(() => _error = 'น้ำหนักต้องมากกว่า 0');
      return;
    }
    if (!(_price > 0)) {
      setState(() => _error = 'ราคาต้องมากกว่า 0');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ShopService.updatePurchase(
        userId: await AuthService.getUserId() ?? '',
        purchaseId: widget.purchase.purchaseId,
        quantity: _qty,
        pricePerKg: _price,
        purchaseDate: DateFormat('yyyy-MM-dd').format(_date),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyError(e);
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon, String suffix) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.primary),
      suffixText: suffix,
      floatingLabelStyle: TextStyle(color: theme.primary),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.purchase;
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
                const Text('แก้ไขการรับซื้อ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${p.farmerName}${p.gardenName.isEmpty ? '' : ' · ${p.gardenName}'}'
                  '${p.grade.isEmpty ? '' : ' · ${p.grade}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() => _error = null),
                  decoration: _decoration('น้ำหนัก', Icons.scale_outlined, 'กก.'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() => _error = null),
                  decoration: _decoration('ราคาต่อกก.', Icons.payments_outlined, '฿'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration('วันที่รับซื้อ', Icons.calendar_today_outlined, ''),
                    child: Text('${DateFormat('d MMMM', 'th_TH').format(_date)} ${_date.year + 543}'),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.soft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Text('ยอดรวม', style: TextStyle(color: Colors.grey[700])),
                      const Spacer(),
                      Text(
                        '฿${_money.format(_qty * _price)}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.primaryDark),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
