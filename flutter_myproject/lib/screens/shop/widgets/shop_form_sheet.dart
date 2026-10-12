// ============================================================
// shop_form_sheet.dart — ฟอร์มสร้าง / แก้ไขข้อมูลร้าน (ชื่อร้าน, ที่ตั้ง, เบอร์โทร, เวลาเปิดรับซื้อ)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/shop.dart';
import 'package:flutter_myproject/screens/shop/widgets/sheet_frame.dart';

class ShopFormSheet extends StatefulWidget {
  final ShopInfo? shop;
  const ShopFormSheet({super.key, this.shop});

  @override
  State<ShopFormSheet> createState() => _ShopFormSheetState();
}

class _ShopFormSheetState extends State<ShopFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.shop?.name ?? '');
  late final _location = TextEditingController(text: widget.shop?.location ?? '');
  late final _phone = TextEditingController(text: widget.shop?.phone ?? '');
  late final _schedule = TextEditingController(text: widget.shop?.openSchedule ?? '');

  @override
  void dispose() {
    for (final c in [_name, _location, _phone, _schedule]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'shop_name': _name.text.trim(),
      'location': _location.text.trim(),
      'phone': _phone.text.trim().replaceAll('-', ''),
      'open_schedule': _schedule.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: widget.shop == null ? 'สร้างร้าน' : 'แก้ไขข้อมูลร้าน',
      buttonText: widget.shop == null ? 'สร้างร้าน' : 'บันทึก',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            sheetField(
              _name,
              'ชื่อร้าน *',
              Icons.storefront,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อร้าน' : null,
            ),
            sheetField(_location, 'ที่ตั้ง', Icons.location_on_outlined, hint: 'เช่น 88 ม.2 ต.ท่าข้าม อ.พุนพิน'),
            sheetField(
              _phone,
              'เบอร์โทร',
              Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: (v) {
                final p = (v ?? '').replaceAll('-', '').trim();
                if (p.isEmpty) return null;
                return RegExp(r'^0\d{8,9}$').hasMatch(p) ? null : 'เบอร์โทรไม่ถูกต้อง';
              },
            ),
            sheetField(_schedule, 'เวลาเปิด-ปิด', Icons.access_time, hint: 'เช่น จันทร์-เสาร์ 08:00-17:00'),
          ],
        ),
      ),
    );
  }
}
