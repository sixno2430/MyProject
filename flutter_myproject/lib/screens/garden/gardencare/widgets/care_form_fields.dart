// ============================================================
// care_form_fields.dart — ส่วนประกอบของฟอร์มบันทึกการดูแลสวน
//
// - careInputDecoration : หน้าตาช่องกรอกของฟอร์ม (พื้นเทาอ่อน ขอบเขียวตอนพิมพ์)
// - parseNumber          : แปลงข้อความเป็นตัวเลข (รองรับคอมมา, กรอกผิด = 0)
// - FormSection          : การ์ดขาวมีเลขขั้นตอนวงกลม + หัวข้อ
// - CareTypeGrid         : ตารางเลือกประเภทกิจกรรม 3 คอลัมน์ (ใส่ปุ๋ย / ตัดแต่ง / ...)
// - UnitDropdown         : เลือกหน่วย
// - CareNumberField      : ช่องกรอกตัวเลข (ว่างได้ = 0)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/care_type.dart';

const Color careGreen = Color(0xFF2D6A4F);

/// หน้าตาช่องกรอกของฟอร์มดูแลสวน
InputDecoration careInputDecoration({String? label, String? hint, IconData? icon, String? suffix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffix,
    prefixIcon: icon == null ? null : Icon(icon, color: careGreen, size: 20),
    floatingLabelStyle: const TextStyle(color: careGreen),
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF7F8F7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: careGreen, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}

/// แปลงข้อความเป็นตัวเลข (รองรับคอมมา เช่น 1,500) กรอกผิด/ว่าง = 0
double parseNumber(String text) => double.tryParse(text.replaceAll(',', '').trim()) ?? 0;

/// การ์ดขาว 1 ส่วนของฟอร์ม: เลขขั้นตอนในวงกลม + หัวข้อ + เนื้อหา
class FormSection extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;

  const FormSection({super.key, required this.step, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
                decoration: const BoxDecoration(color: careGreen, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
}

/// ตารางเลือกประเภทกิจกรรม 3 คอลัมน์ (ช่องที่เลือกอยู่มีกรอบ/พื้นตามสีของประเภท)
class CareTypeGrid extends StatelessWidget {
  final CareType selected;
  final ValueChanged<CareType> onSelect;

  const CareTypeGrid({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: careTypes.map((t) {
        final isSelected = t.type == selected.type;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? t.bgColor : const Color(0xFFF7F8F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? t.color : Colors.transparent, width: 2),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? t.color : Colors.grey[700],
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
}

/// เลือกหน่วย (ค่าปัจจุบันไม่อยู่ในรายการ = ใช้หน่วยแรก)
class UnitDropdown extends StatelessWidget {
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;

  const UnitDropdown({super.key, required this.value, required this.units, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: units.contains(value) ? value : units.first,
      isExpanded: true,
      decoration: careInputDecoration(label: 'หน่วย'),
      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (u) {
        if (u != null) onChanged(u);
      },
    );
  }
}

/// ช่องกรอกตัวเลข (ไม่กรอก = 0, กรอกที่ไม่ใช่ตัวเลข = แจ้งเตือน)
class CareNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? suffix;

  const CareNumberField({super.key, required this.controller, required this.label, required this.icon, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return double.tryParse(v.replaceAll(',', '').trim()) == null ? 'ใส่เป็นตัวเลข' : null;
      },
      decoration: careInputDecoration(label: label, icon: icon, suffix: suffix),
    );
  }
}
