// ============================================================
// transaction_tile.dart — แถวรายการเงิน 1 รายการในหน้าการเงิน
//
// ไอคอนหมวด + ชื่อรายการ + แปลง (ว่าง = "ส่วนกลาง") · วันที่ + จำนวนเงิน (รายรับเขียว / รายจ่ายแดง)
// กดค้างเพื่อแก้ไข/ลบ (onLongPress)
// ============================================================

import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final VoidCallback? onLongPress;
  final String title;
  final String gardenName;
  final String date;
  final String amount;
  final bool isIncome;
  final String icon;

  const TransactionTile({
    super.key,
    this.onLongPress,
    required this.title,
    required this.gardenName,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.icon,
  });

  static const Color primaryGreen = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // ไม่ผูกกับแปลง = รายการส่วนกลางของสวน
                      Text(
                        gardenName.isNotEmpty ? gardenName : 'ส่วนกลาง',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: gardenName.isNotEmpty ? primaryGreen : const Color(0xFF6D4C41),
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
