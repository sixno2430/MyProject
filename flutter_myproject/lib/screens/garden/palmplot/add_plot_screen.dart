import 'package:flutter/material.dart';

class AddPlotScreen extends StatelessWidget {
  const AddPlotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 0,
        title: const Text('เพิ่มแปลงสวนใหม่', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(label: 'ชื่อแปลงสวน *', hint: 'เช่น แปลง A — บ้านหนองกวาง'),
            const SizedBox(height: 16),
            _buildTextField(label: 'พื้นที่ (ไร่/งาน) *', hint: 'เช่น 5 ไร่ 3 งาน'),
            const SizedBox(height: 16),
            _buildTextField(label: 'จำนวนต้นปาล์ม *', hint: 'เช่น 12', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(label: 'พันธุ์ปาล์ม', hint: 'เลือกพันธุ์ปาล์ม'),
            const SizedBox(height: 16),
            _buildTextField(label: 'วันที่ปลูก', hint: '11 มิถุนายน 2568'),
            const SizedBox(height: 16),
            _buildTextField(label: 'หมายเหตุ', hint: 'เพิ่มเติม...', maxLines: 3),
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
                    onPressed: () => Navigator.pop(context),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}