// ============================================================
// reject_lot_sheet.dart — หน้าต่าง "ไม่รับล็อตนี้" ของร้าน
//
// ร้านพิมพ์เหตุผลเอง (บังคับ ไม่เกิน 255 ตัว) แล้วส่งไปที่เซิร์ฟเวอร์
// สำเร็จ = คืน true (ล็อตกลับเป็น "รอขาย · ยังไม่เลือกร้าน" เกษตรกรเห็นเหตุผลบนการ์ด)
// ใช้จาก: รายการ "ล็อตที่ส่งมาขายร้านนี้" และหน้าบันทึกการรับซื้อ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/services/shop_service.dart';

/// เปิดหน้าต่างไม่รับล็อต — คืน true เมื่อบันทึกสำเร็จ
Future<bool> showRejectLotSheet(
  BuildContext context, {
  required String shopId,
  required String harvestId,
  required String lotLabel, // เช่น "Jacob · หน้าเขา · H013"
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RejectLotSheet(shopId: shopId, harvestId: harvestId, lotLabel: lotLabel),
  );
  return done == true;
}

class _RejectLotSheet extends StatefulWidget {
  final String shopId;
  final String harvestId;
  final String lotLabel;
  const _RejectLotSheet({required this.shopId, required this.harvestId, required this.lotLabel});

  @override
  State<_RejectLotSheet> createState() => _RejectLotSheetState();
}

class _RejectLotSheetState extends State<_RejectLotSheet> {
  static const red = Color(0xFFDC2626);
  final _reasonCtrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'กรุณาเขียนเหตุผลที่ไม่รับ');
      return;
    }
    setState(() => _saving = true);
    try {
      await ShopService.rejectHarvest(
        userId: await AuthService.getUserId() ?? '',
        shopId: widget.shopId,
        harvestId: widget.harvestId,
        reason: reason,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('ไม่รับล็อตนี้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  widget.lotLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  'เกษตรกรจะเห็นเหตุผลนี้ และล็อตจะกลับไปให้เกษตรกรเลือกร้านใหม่',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[700], height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonCtrl,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 255, // ตามขนาดคอลัมน์ reason
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'เหตุผลที่ไม่รับ *',
                    hintText: 'เช่น ผลปาล์มยังไม่สุก, วันนี้ลานเต็ม รับได้พรุ่งนี้',
                    alignLabelWithHint: true,
                    errorText: _error,
                    floatingLabelStyle: const TextStyle(color: red),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: red, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
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
                        : const Text('ยืนยันไม่รับ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
