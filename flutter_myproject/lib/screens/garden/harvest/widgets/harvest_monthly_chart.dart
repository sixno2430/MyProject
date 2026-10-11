// ============================================================
// harvest_monthly_chart.dart — กราฟแท่งผลผลิต 12 เดือนในหน้าเก็บเกี่ยว
//
// แตะแท่งเพื่อเลือกเดือน (แตะซ้ำ = ยกเลิก) แล้วแจ้งหน้าแม่ผ่าน onHoverMonth
// ให้การ์ดสรุปด้านบนเปลี่ยนเป็นยอดของเดือนนั้น
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/utils/formatters.dart';

/// กราฟแท่งผลผลิต 12 เดือน แตะแท่งเพื่อดูยอดของเดือนนั้น (แตะซ้ำ = ยกเลิก)
class HarvestMonthlyChart extends StatefulWidget {
  final Map<String, double> monthlyData;
  final ValueChanged<String?>? onHoverMonth;

  const HarvestMonthlyChart({super.key, required this.monthlyData, this.onHoverMonth});

  @override
  State<HarvestMonthlyChart> createState() => _HarvestMonthlyChartState();
}

class _HarvestMonthlyChartState extends State<HarvestMonthlyChart> {
  static const _green = Color(0xFF2D6A4F);
  static const _greenDark = Color(0xFF1B4332);
  String? _selected; // เดือนที่แตะเลือกอยู่ (null = ไม่ได้เลือก)

  /// แตะเดือนเดิมซ้ำ = ยกเลิกการเลือก แล้วแจ้งหน้าแม่ให้เปลี่ยนตัวเลขสรุปด้านบน
  void _toggle(String month) {
    setState(() => _selected = _selected == month ? null : month);
    widget.onHoverMonth?.call(_selected);
  }

  /// ย่อตัวเลขบนแท่งให้พอดีช่องแคบ เช่น 8200 -> 8.2K, 950 -> 950
  String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.monthlyData;
    final maxKg = data.values.fold<double>(0, (m, v) => v > m ? v : m);
    final total = data.values.fold<double>(0, (s, v) => s + v);
    const chartHeight = 150.0;
    const labelSpace = 44.0; // ตัวเลขบนแท่ง + ชื่อเดือนใต้แท่ง
    const barArea = chartHeight - labelSpace;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ผลผลิตรายเดือน', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                      'หน่วย กิโลกรัม · แตะแท่งเพื่อดูยอดของเดือนนั้น',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('รวมทั้งปี', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${formatNumber(total)} กก.', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (maxKg <= 0)
            const SizedBox(
              height: chartHeight,
              child: Center(
                child: Text('ยังไม่มีผลผลิตในปีนี้', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  // เส้นฐานของกราฟ
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: labelSpace - 22,
                    child: Container(height: 1, color: const Color(0xFFE5E7EB)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final e in data.entries) Expanded(child: _buildBar(e.key, e.value, maxKg, barArea)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// แท่ง 1 เดือน: ตัวเลขด้านบน (เฉพาะเดือนที่มีผลผลิต) + แท่ง + ชื่อเดือน
  /// เดือนที่ไม่มีผลผลิต = ไม่มีแท่ง ไม่มีเลข 0 ให้รก แต่ยังแตะเลือกได้
  Widget _buildBar(String month, double kg, double maxKg, double barArea) {
    final hasData = kg > 0;
    final selected = _selected == month;
    final dimmed = _selected != null && !selected;
    final barHeight = hasData ? (barArea * kg / maxKg).clamp(6.0, barArea) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // แตะบริเวณว่างเหนือแท่งก็เลือกเดือนได้
      onTap: () => _toggle(month),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ตัวเลขบนแท่ง: เลือกอยู่ = ป้ายเข้มพร้อมคอมมา, ปกติ = ตัวเลขย่อสีเทา
          if (selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: _greenDark, borderRadius: BorderRadius.circular(4)),
              child: FittedBox(
                child: Text(
                  hasData ? formatNumber(kg) : 'ไม่มี',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Text(hasData ? _compact(kg) : '', style: TextStyle(fontSize: 9, color: Colors.grey[dimmed ? 400 : 600])),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: selected ? _greenDark : (dimmed ? _green.withValues(alpha: 0.35) : _green),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            month,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? _greenDark : (hasData ? Colors.black87 : Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
