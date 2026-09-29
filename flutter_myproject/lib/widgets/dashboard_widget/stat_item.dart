// ============================================================
// stat_item.dart — ช่องสถิติแบบเดิม (ตัวเลข + คำอธิบาย)
//
// หมายเหตุ: ตอนนี้ไม่มีหน้าไหนใช้แล้ว (Dashboard เปลี่ยนไปใช้ _StatTile ใน dashboard_header.dart)
// ============================================================

import 'package:flutter/material.dart';

/// ช่องสถิติ 1 ช่อง ขยายเต็มพื้นที่ที่เหลือ (Expanded)
class StatItem extends StatelessWidget {
  final String value;
  final String label;
  const StatItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
