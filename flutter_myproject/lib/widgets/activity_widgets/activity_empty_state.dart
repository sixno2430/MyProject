import 'package:flutter/material.dart';

class ActivityEmptyState extends StatelessWidget {
  final String filter;
  const ActivityEmptyState({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final (emoji, title, subtitle) = _resolveMessage();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  (String, String, String) _resolveMessage() {
    switch (filter) {
      case 'harvest':
        return ('🧺', 'ยังไม่มีการเก็บเกี่ยว', 'เริ่มบันทึกการเก็บเกี่ยวผลผลิต\nจากแปลงสวนของคุณ');
      case 'care':
        return ('💊', 'ยังไม่มีการดูแลรักษา', 'บันทึกการใส่ปุ๋ยหรือดูแลต้นปาล์ม\nเพื่อติดตามความเจริญเติบโต');
      case 'income':
        return ('💵', 'ยังไม่มีรายรับ', 'บันทึกรายรับจากการขายผลผลิต\nหรือบริการอื่นๆ');
      case 'expense':
        return ('💸', 'ยังไม่มีรายจ่าย', 'บันทึกค่าใช้จ่าย เช่น ค่าปุ๋ย\nค่าแรงงาน หรือค่าอุปกรณ์');
      default:
        return ('🌴', 'ยังไม่มีกิจกรรม', 'เริ่มต้นบันทึกกิจกรรมแรกของคุณ\nเพื่อจัดการสวนปาล์มอย่างมีประสิทธิภาพ');
    }
  }
}
