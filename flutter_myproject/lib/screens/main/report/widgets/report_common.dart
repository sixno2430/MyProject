// ============================================================
// report_common.dart — สี, ข้อความเดือน และ widget ชิ้นเล็กที่ใช้ร่วมกันในหน้ารายงาน
//
// - ReportColors : ชุดสีของหน้ารายงาน (เขียว = รายรับ/กำไร, แดง = รายจ่าย/ขาดทุน)
// - ReportCard   : กล่องขาวมีหัวข้อ + คำอธิบาย
// - StatCard     : การ์ดตัวเลข 1 ช่อง (ผลผลิตรวม, กำไรสุทธิ ...)
// - MoneyTriple  : รายรับ / รายจ่าย / กำไร 3 ช่อง
// - ChangePill   : ป้าย % เพิ่ม/ลด
// - LegendDot, NoDataText
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/utils/formatters.dart';

/// ชุดสีของหน้ารายงาน
class ReportColors {
  static const primary = Color(0xFF2D6A4F);
  static const income = Color(0xFF2E7D32);
  static const expense = Color(0xFFD32F2F);
  static const muted = Color(0xFF6B7280);
}

const monthShortTh = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];
const monthFullTh = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// กรอบการ์ดสีขาวพร้อมหัวข้อ + คำอธิบาย
class ReportCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ReportCard({super.key, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: ReportColors.muted)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// ข้อความเมื่อยังไม่มีข้อมูล
class NoDataText extends StatelessWidget {
  final String text;
  const NoDataText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }
}

/// การ์ดตัวเลข 1 ช่อง
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// รายรับ / รายจ่าย / กำไร 3 ช่องในกล่องพื้นเทาอ่อน (กำไรติดลบ = สีแดง)
class MoneyTriple extends StatelessWidget {
  final double income;
  final double expense;

  const MoneyTriple({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final profit = income - expense;
    Widget cell(String label, String value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ReportColors.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF7F8F7), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          cell('รายรับ', '${formatNumber(income)} ฿', ReportColors.income),
          cell('รายจ่าย', '${formatNumber(expense)} ฿', ReportColors.expense),
          cell(
            'กำไร',
            '${profit < 0 ? '-' : ''}${formatNumber(profit.abs())} ฿',
            profit >= 0 ? ReportColors.primary : ReportColors.expense,
          ),
        ],
      ),
    );
  }
}

/// ป้าย % เปลี่ยนแปลง: เพิ่ม = เขียว ลูกศรขึ้น, ลด = แดง ลูกศรลง, ค่าก่อนหน้าเป็น 0 = "ใหม่"
class ChangePill extends StatelessWidget {
  final double prev;
  final double now;

  const ChangePill({super.key, required this.prev, required this.now});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData? arrow;
    if (prev == 0 && now == 0) {
      text = '-';
      color = ReportColors.muted;
    } else if (prev == 0) {
      text = 'ใหม่';
      color = const Color(0xFF1565C0);
    } else {
      final pct = (now - prev) / prev * 100;
      text = '${pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0)}%';
      color = pct >= 0 ? ReportColors.income : ReportColors.expense;
      arrow = pct >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrow != null) Icon(arrow, size: 12, color: color),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

/// จุดสี + ชื่อ (คำอธิบายสีของกราฟ)
class LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const LegendDot({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
