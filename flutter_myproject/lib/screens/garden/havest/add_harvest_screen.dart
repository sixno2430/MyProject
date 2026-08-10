import 'package:flutter/material.dart';

class AddHarvestScreen extends StatelessWidget {
  const AddHarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 0,
        title: const Text('บันทึกการเก็บเกี่ยว', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField('แปลงสวน *', 'แปลง A — บ้านหนองกวาง'),
            const SizedBox(height: 16),
            _buildTextField('วันที่เก็บเกี่ยว *', '11 มิถุนายน 2568'),
            const SizedBox(height: 16),
            _buildTextField('ผลผลิต (กก.) *', '1,800', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('ราคาขาย/กก. (บาท) *', '5.50', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('ราคาขายรวม (คำนวณอัตโนมัติ)', '9,900 บาท', enabled: false),
            const SizedBox(height: 16),
            _buildTextField('ผู้รับซื้อ', 'สหกรณ์ปาล์มน้ำมันบ้านหนองกวาง'),
            const SizedBox(height: 16),
            _buildTextField('หมายเหตุ', 'เพิ่มเติม...', maxLines: 3),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: [value, 'แปลง B — ไร่นาสวน', 'แปลง C — สวนในบึง'].map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}