// ============================================================
// garden_summary_card.dart — การ์ด "สรุปรายแปลง" ในหน้ารายงาน
//
// ส่วนกลาง (รายการเงินที่ไม่ผูกแปลง) อยู่บนสุดเสมอ แล้วตามด้วยแปลงที่มีข้อมูล:
// ชื่อแปลง + พื้นที่, ผลผลิต, รายรับ / รายจ่าย / กำไร
// แปลงที่ยังไม่มีข้อมูลในช่วงนั้น รวมไว้บรรทัดเดียวด้านล่าง ไม่ให้รายการยาว
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/report.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'report_common.dart';

class GardenSummaryCard extends StatelessWidget {
  final YearlyReport report;

  const GardenSummaryCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final active = r.byGarden.where((g) => g.hasData).toList();
    final idle = r.byGarden.where((g) => !g.hasData).toList();
    final hasCommon = r.commonIncome > 0 || r.commonExpense > 0;
    final period = r.month == null ? 'ปีนี้' : 'เดือนนี้';

    return ReportCard(
      title: 'สรุปรายแปลง',
      subtitle: 'ผลผลิตและการเงินของแต่ละแปลงใน$period',
      child: r.byGarden.isEmpty && !hasCommon
          ? const NoDataText('ยังไม่มีแปลงสวน')
          : Column(
              children: [
                _CommonRow(income: r.commonIncome, expense: r.commonExpense),
                for (final g in active) ...[const Divider(height: 24), _GardenRow(g)],
                if (idle.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ยังไม่มีข้อมูลใน$period: ${idle.map((g) => g.gardenName).join(', ')}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// แปลง 1 แปลง: ชื่อ + พื้นที่, ผลผลิต, รายรับ / รายจ่าย / กำไร
class _GardenRow extends StatelessWidget {
  final GardenSummary g;
  const _GardenRow(this.g);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.park_outlined, size: 18, color: ReportColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(g.gardenName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            if (g.areaRai > 0)
              Text('${formatNumber(g.areaRai)} ไร่', style: const TextStyle(fontSize: 12, color: ReportColors.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ผลผลิต ${formatNumber(g.totalKg)} กก.',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        MoneyTriple(income: g.income, expense: g.expense),
      ],
    );
  }
}

/// แถว "ส่วนกลาง" (รายการเงินที่ไม่ผูกกับแปลง)
class _CommonRow extends StatelessWidget {
  final double income;
  final double expense;
  const _CommonRow({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home_work_outlined, size: 18, color: Color(0xFF6D4C41)),
            SizedBox(width: 6),
            Text('ส่วนกลาง', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        MoneyTriple(income: income, expense: expense),
      ],
    );
  }
}
