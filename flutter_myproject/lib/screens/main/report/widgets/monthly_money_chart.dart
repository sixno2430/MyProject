// ============================================================
// monthly_money_chart.dart — การ์ด "รายรับ-รายจ่ายรายเดือน" (กราฟแท่งคู่) ในหน้ารายงานรายปี
//
// แท่งเขียว = รายรับ, แท่งแดง = รายจ่าย ของแต่ละเดือน
// แตะเดือน = แสดงรายรับ / รายจ่าย / กำไรของเดือนนั้นใต้กราฟ (แตะซ้ำ = ยกเลิก)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/report.dart';
import 'report_common.dart';

class MonthlyMoneyChart extends StatefulWidget {
  final YearlyReport report;

  const MonthlyMoneyChart({super.key, required this.report});

  @override
  State<MonthlyMoneyChart> createState() => _MonthlyMoneyChartState();
}

class _MonthlyMoneyChartState extends State<MonthlyMoneyChart> {
  int? _selectedMonth; // เดือนที่แตะ (1-12)

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final hasData = r.monthly.any((m) => m.income > 0 || m.expense > 0);
    final maxValue = r.monthly.fold<double>(0, (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b));
    final selected = _selectedMonth == null ? null : r.monthly.firstWhere((m) => m.month == _selectedMonth);

    return ReportCard(
      title: 'รายรับ-รายจ่ายรายเดือน',
      subtitle: 'แตะเดือนเพื่อดูยอดและกำไรของเดือนนั้น',
      child: !hasData
          ? const NoDataText('ยังไม่มีรายการเงินในปีนี้')
          : Column(
              children: [
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [for (final m in r.monthly) Expanded(child: _buildBars(m, maxValue))],
                  ),
                ),
                const SizedBox(height: 12),
                // รายละเอียดของเดือนที่แตะ / คำอธิบายสี
                selected == null
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LegendDot(label: 'รายรับ', color: ReportColors.income),
                          SizedBox(width: 20),
                          LegendDot(label: 'รายจ่าย', color: ReportColors.expense),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${monthFullTh[selected.month - 1]} ${r.year + 543}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          MoneyTriple(income: selected.income, expense: selected.expense),
                        ],
                      ),
              ],
            ),
    );
  }

  /// แท่งคู่ของเดือน 1 เดือน แตะเลือก / แตะซ้ำยกเลิก
  Widget _buildBars(MonthlyMoney m, double maxValue) {
    const barArea = 118.0; // ความสูงสุดของแท่ง (เหลือที่ให้ชื่อเดือน)
    final isSelected = _selectedMonth == m.month;
    final dimmed = _selectedMonth != null && !isSelected;
    final empty = m.income == 0 && m.expense == 0;
    double h(double v) => v <= 0 || maxValue <= 0 ? 0 : (barArea * v / maxValue).clamp(3.0, barArea);
    Color c(Color base) => dimmed ? base.withValues(alpha: 0.25) : base;

    Widget bar(double value, Color color) => Flexible(
      child: Container(
        height: h(value),
        decoration: BoxDecoration(
          color: c(color),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedMonth = isSelected ? null : m.month),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F0EC) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                bar(m.income, ReportColors.income),
                const SizedBox(width: 2),
                bar(m.expense, ReportColors.expense),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE5E7EB)), // เส้นฐาน
          const SizedBox(height: 6),
          Text(
            monthShortTh[m.month - 1],
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? ReportColors.primary : (empty ? Colors.grey[400] : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
