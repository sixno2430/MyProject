// ============================================================
// sale_fields.dart — ช่องกรอกตอนขายผลผลิต (ใช้ร่วมกันในฟอร์มเก็บเกี่ยวและหน้าต่างขายนอกระบบ)
//
// - ShopDropdown : เลือกร้านในแอปที่จะขายให้ (ตอนสถานะรอขาย)
// - ShopSaleHint : ข้อความบอกว่าเลือกร้านแล้ว ร้านจะเป็นคนยืนยันรับซื้อ
// - GradePicker  : เลือกเกรดที่ขาย (ชิปเกรด + พิมพ์เองได้)
// ============================================================

import 'package:flutter/material.dart';

/// Dropdown เลือกร้านรับซื้อในแอป ตัวเลือกแรกคือ "ยังไม่เลือกร้าน" (value = null)
/// ร้านที่ปิดรับซื้อชั่วคราวแสดงไว้แต่เลือกไม่ได้
class ShopDropdown extends StatelessWidget {
  final List<Map<String, String>> shops;
  final String? value;
  final ValueChanged<String?> onChanged;

  const ShopDropdown({super.key, required this.shops, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // ค่าที่เลือกต้องมีอยู่ในรายการ ไม่งั้น Dropdown จะ error (เช่น ตอนรายชื่อร้านยังโหลดไม่เสร็จ)
    final safeValue = shops.any((s) => s['id'] == value) ? value : null;
    return DropdownButtonFormField<String?>(
      // initialValue ถูกอ่านแค่ตอนสร้าง -> เปลี่ยน key เมื่อรายชื่อร้าน/ค่าที่เลือกเปลี่ยน ให้สร้างใหม่แสดงค่าที่ถูกต้อง
      key: ValueKey('${shops.length}-$safeValue'),
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'ร้านในแอปที่จะขายให้',
        prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFF1E5631)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('ยังไม่เลือกร้าน')),
        ...shops.map((s) {
          final open = s['open'] != 'false';
          return DropdownMenuItem<String?>(
            value: s['id'],
            enabled: open || s['id'] == value,
            child: Text(
              open ? s['name']! : '${s['name']} (ปิดรับซื้อชั่วคราว)',
              overflow: TextOverflow.ellipsis,
              style: open ? null : const TextStyle(color: Colors.grey),
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

/// ข้อความใต้ช่องเลือกร้าน บอกว่าการเลือกนี้มีผลยังไง
class ShopSaleHint extends StatelessWidget {
  final String? shopName; // null = ยังไม่เลือกร้าน
  const ShopSaleHint({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    final chosen = shopName != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(chosen ? Icons.sync_alt : Icons.info_outline, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            chosen
                ? '$shopName จะเห็นล็อตนี้ และเป็นคนกดยืนยันรับซื้อ รายการจะเปลี่ยนเป็น "ขายแล้ว" เอง'
                : 'ร้านในแอปค้นหาแล้วรับซื้อได้ หรือคุณบันทึก "ขายนอกระบบ" เองภายหลัง',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// ปุ่มลัดเกรดที่ใช้บ่อย + ช่องพิมพ์เอง (ไม่บังคับ) ค่าอยู่ใน controller
class GradePicker extends StatefulWidget {
  final TextEditingController controller;
  const GradePicker({super.key, required this.controller});

  static const quickGrades = ['เกรด A', 'เกรด B', 'เกรด C', 'ลูกร่วง', 'ทะลายสด'];

  @override
  State<GradePicker> createState() => _GradePickerState();
}

class _GradePickerState extends State<GradePicker> {
  static const green = Color(0xFF1E5631);

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GradePicker.quickGrades.map((g) {
            final selected = current == g;
            return ChoiceChip(
              label: Text(g),
              selected: selected,
              showCheckmark: false,
              selectedColor: green,
              backgroundColor: const Color(0xFFF1F8F3),
              side: BorderSide(color: selected ? green : const Color(0xFFD5E8DB)),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey[800], fontSize: 13),
              // แตะซ้ำที่เกรดที่เลือกอยู่ = ยกเลิก (ไม่ระบุเกรด)
              onSelected: (_) => setState(() => widget.controller.text = selected ? '' : g),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.controller,
          maxLength: 100,
          cursorColor: green,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'เกรดที่ขาย (ไม่บังคับ)',
            hintText: 'เลือกด้านบน หรือพิมพ์เอง',
            counterText: '',
            prefixIcon: const Icon(Icons.grade_outlined, color: green),
            floatingLabelStyle: const TextStyle(color: green),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
