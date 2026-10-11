// ============================================================
// production_compare_card.dart — การ์ด "เทียบผลผลิตกับปีก่อน" ในหน้ารายงาน
//
// - YearCompareCard : รายปี — ยอดรวมปีนี้ vs ปีก่อน + ตารางรายเดือน (เฉพาะเดือนที่มีผลผลิต)
// - MonthCompareCard: รายเดือน — เดือนนี้ vs เดือนเดียวกันของปีก่อน
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/report.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'report_common.dart';

/// รายปี: เทียบผลผลิตปีนี้กับปีก่อน
class YearCompareCard extends StatelessWidget {
  final YearlyReport report;

  const YearCompareCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final thisYear = r.year + 543;
    final lastYear = thisYear - 1;
    final rows = r.production.where((p) => p.kg > 0 || p.prevKg > 0).toList();

    return ReportCard(
      title: 'เทียบผลผลิตกับปีก่อน',
      subtitle: 'ปี $thisYear เทียบกับปี $lastYear (กิโลกรัม)',
      child: rows.isEmpty
          ? const NoDataText('ยังไม่มีข้อมูลผลผลิตทั้ง 2 ปี')
          : Column(
              children: [
                _TotalsRow(lastLabel: 'ปี $lastYear', last: r.prevTotalKg, thisLabel: 'ปี $thisYear', now: r.totalKg),
                if (r.prevTotalKg == 0) _NoPrevNote('ปี $lastYear'),
                const SizedBox(height: 14),
                _CompareRow(cells: ['เดือน', '$lastYear', '$thisYear', 'เปลี่ยนแปลง'], header: true),
                for (final p in rows)
                  _CompareRow(
                    cells: [monthFullTh[p.month - 1], formatNumber(p.prevKg), formatNumber(p.kg)],
                    change: ChangePill(prev: p.prevKg, now: p.kg),
                  ),
              ],
            ),
    );
  }
}

/// รายเดือน: ผลผลิตเดือนนี้เทียบกับเดือนเดียวกันของปีก่อน
class MonthCompareCard extends StatelessWidget {
  final YearlyReport report;

  const MonthCompareCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final m = r.month!;
    final p = r.production.firstWhere((e) => e.month == m);
    final thisLabel = '${monthShortTh[m - 1]} ${r.year + 543}';
    final lastLabel = '${monthShortTh[m - 1]} ${r.year + 542}';
    return ReportCard(
      title: 'เทียบผลผลิตกับปีก่อน',
      subtitle: '${monthFullTh[m - 1]} ${r.year + 543} เทียบกับ${monthFullTh[m - 1]} ${r.year + 542} (กิโลกรัม)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TotalsRow(lastLabel: lastLabel, last: p.prevKg, thisLabel: thisLabel, now: p.kg),
          if (p.prevKg == 0) _NoPrevNote(lastLabel),
        ],
      ),
    );
  }
}

/// ยอดก่อนหน้า → ยอดปัจจุบัน + ป้าย % เปลี่ยนแปลง
class _TotalsRow extends StatelessWidget {
  final String lastLabel;
  final double last;
  final String thisLabel;
  final double now;

  const _TotalsRow({required this.lastLabel, required this.last, required this.thisLabel, required this.now});

  @override
  Widget build(BuildContext context) {
    Widget total(String label, double kg, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: ReportColors.muted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${formatNumber(kg)} กก.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
    return Row(
      children: [
        Expanded(child: total(lastLabel, last, ReportColors.muted)),
        const Icon(Icons.arrow_forward, size: 18, color: ReportColors.muted),
        const SizedBox(width: 12),
        Expanded(child: total(thisLabel, now, ReportColors.primary)),
        ChangePill(prev: last, now: now),
      ],
    );
  }
}

/// หมายเหตุเมื่อช่วงก่อนหน้ายังไม่มีข้อมูล
class _NoPrevNote extends StatelessWidget {
  final String label;
  const _NoPrevNote(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('$label ยังไม่มีข้อมูลผลผลิตในระบบ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    );
  }
}

/// แถวตารางเทียบรายเดือน (header = แถวหัวสีเทา)
class _CompareRow extends StatelessWidget {
  final List<String> cells;
  final bool header;
  final Widget? change;

  const _CompareRow({required this.cells, this.header = false, this.change});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: header ? 11 : 13,
      fontWeight: header ? FontWeight.w600 : FontWeight.normal,
      color: header ? ReportColors.muted : Colors.black87,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: header ? const Color(0xFFF3F4F6) : null,
        borderRadius: header ? BorderRadius.circular(8) : null,
        border: header ? null : const Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(cells[0], style: style)),
          Expanded(
            flex: 2,
            child: Text(cells[1], textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(cells[2], textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: header ? Text(cells[3], style: style) : change,
            ),
          ),
        ],
      ),
    );
  }
}
