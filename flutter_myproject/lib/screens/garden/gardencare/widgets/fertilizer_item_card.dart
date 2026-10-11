// ============================================================
// fertilizer_item_card.dart — ปุ๋ย 1 ชนิดในฟอร์มใส่ปุ๋ย (ใส่ได้หลายชนิดในรอบเดียว)
//
// - FertilizerItem    : ข้อมูลปุ๋ย 1 ชนิดในฟอร์ม (ช่องชื่อ, ช่องปริมาณ, หน่วย) — ฟอร์มเก็บเป็นรายการ
// - FertilizerItemCard: การ์ดกรอก "ชนิดที่ N": ชื่อ/สูตรปุ๋ย (พิมพ์เองหรือเลือกจากที่เคยใช้), ปริมาณ, หน่วย
//                       ปุ่มถังขยะลบชนิดนี้ (มีเมื่อมีมากกว่า 1 ชนิด)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/care_type.dart';
import 'care_form_fields.dart';

/// ปุ๋ย 1 ชนิดในฟอร์ม (มีช่องกรอกของตัวเอง ต้อง dispose เมื่อลบ/ปิดฟอร์ม)
class FertilizerItem {
  final TextEditingController name;
  final TextEditingController quantity;
  final FocusNode focus = FocusNode(); // ใช้กับรายการแนะนำชื่อปุ๋ย
  String unit;

  FertilizerItem({String name = '', String quantity = '', this.unit = 'กก.'})
    : name = TextEditingController(text: name),
      quantity = TextEditingController(text: quantity);

  void dispose() {
    name.dispose();
    quantity.dispose();
    focus.dispose();
  }
}

class FertilizerItemCard extends StatelessWidget {
  final int index;
  final FertilizerItem item;
  final List<String> suggestions; // ชื่อปุ๋ยที่ผู้ใช้เคยบันทึก
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onUnitChanged;

  const FertilizerItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.suggestions,
    required this.canRemove,
    required this.onRemove,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                'ชนิดที่ ${index + 1}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: careGreen),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  tooltip: 'ลบปุ๋ยชนิดนี้',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: onRemove,
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
              return suggestions.where((s) => q.isEmpty || s.toLowerCase().contains(q));
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณาระบุชื่อปุ๋ย' : null,
              decoration: careInputDecoration(
                label: 'ชื่อ/สูตรปุ๋ย',
                hint: 'เช่น ปุ๋ยสูตร 15-15-15',
                icon: Icons.science_outlined,
              ),
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
                  validator: (v) => parseNumber(v ?? '') > 0 ? null : 'ระบุปริมาณ',
                  decoration: careInputDecoration(label: 'ปริมาณ', icon: Icons.scale_outlined),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: UnitDropdown(value: item.unit, units: fertilizerUnits, onChanged: onUnitChanged),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
