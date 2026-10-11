// ============================================================
// report_screen.dart — แท็บ "รายงาน" สรุปผลการผลิต (proposal 4.2.7 รายงานและวิเคราะห์ข้อมูล)
//
// ดูได้ 2 แบบ (ปุ่มสลับด้านบน) เลื่อนช่วงเวลาด้วยลูกศรซ้าย/ขวา (เลือกช่วงในอนาคตไม่ได้):
//   - รายปี   : ตัวเลขสรุป + สรุปรายแปลง + กราฟรายรับ-รายจ่ายรายเดือน + เทียบผลผลิตกับปีก่อน
//   - รายเดือน: ตัวเลขสรุป + สรุปรายแปลงของเดือนนั้น + เทียบกับเดือนเดียวกันของปีก่อน
//
// ไฟล์นี้มีแค่ส่วนเลือกช่วงเวลาและการจัดวาง ส่วนประกอบแต่ละการ์ดอยู่ในโฟลเดอร์ widgets/
//   report_common.dart (สี, การ์ด, ตัวเลข), garden_summary_card.dart, monthly_money_chart.dart,
//   production_compare_card.dart
// model: models/report.dart · เรียก API: services/report_service.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/report.dart';
import 'package:flutter_myproject/services/report_service.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'widgets/garden_summary_card.dart';
import 'widgets/monthly_money_chart.dart';
import 'widgets/production_compare_card.dart';
import 'widgets/report_common.dart';

/// แท็บรายงาน
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _monthly = false; // false = รายปี, true = รายเดือน
  int _year = DateTime.now().year;
  int _month = DateTime.now().month; // ใช้ตอนดูรายเดือน
  late Future<YearlyReport> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// โหลดรายงานของปี (หรือเดือน) ที่เลือก
  void _load() {
    setState(() {
      _future = ReportService.fetchYearly(_year, month: _monthly ? _month : null);
    });
  }

  /// เลื่อนช่วงเวลาไปข้างหน้า/ถอยหลัง: รายปี = ทีละปี, รายเดือน = ทีละเดือน (ข้ามปีได้)
  void _changePeriod(int delta) {
    if (_monthly) {
      final next = DateTime(_year, _month + delta);
      if (_isFuture(next.year, next.month)) return;
      _year = next.year;
      _month = next.month;
    } else {
      if (_year + delta > DateTime.now().year) return;
      _year += delta;
    }
    _load();
  }

  bool _isFuture(int year, int month) {
    final now = DateTime.now();
    return year > now.year || (year == now.year && month > now.month);
  }

  /// สลับรายปี / รายเดือน (สลับไปรายเดือนของปีที่ผ่านมา = ธันวาคมของปีนั้น)
  void _setMonthly(bool monthly) {
    if (monthly == _monthly) return;
    _monthly = monthly;
    if (monthly) {
      final now = DateTime.now();
      _month = _year == now.year ? now.month : 12;
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ReportColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('รายงานสรุปผลการผลิต', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _load();
          try {
            await _future;
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 8),
            FutureBuilder<YearlyReport>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) return _buildError(friendlyError(snapshot.error));
                return _buildReport(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ปุ่มสลับ รายปี / รายเดือน + แถบเลือกช่วงเวลา (ลูกศรซ้าย/ขวา)
  Widget _buildPeriodSelector() {
    final now = DateTime.now();
    final atLatest = _monthly ? (_year == now.year && _month >= now.month) : _year >= now.year;
    final label = _monthly ? '${monthFullTh[_month - 1]} ${_year + 543}' : 'ปี พ.ศ. ${_year + 543}';
    return Column(
      children: [
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('รายปี'), icon: Icon(Icons.calendar_today_outlined, size: 16)),
            ButtonSegment(value: true, label: Text('รายเดือน'), icon: Icon(Icons.date_range_outlined, size: 16)),
          ],
          selected: {_monthly},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: ReportColors.primary,
            selectedForegroundColor: Colors.white,
            foregroundColor: ReportColors.primary,
            side: const BorderSide(color: ReportColors.primary),
          ),
          onSelectionChanged: (v) => _setMonthly(v.first),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _changePeriod(-1),
              icon: const Icon(Icons.chevron_left, color: ReportColors.primary),
            ),
            SizedBox(
              width: 170,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ReportColors.primary),
              ),
            ),
            IconButton(
              onPressed: atLatest ? null : () => _changePeriod(1),
              icon: Icon(Icons.chevron_right, color: atLatest ? Colors.grey[300] : ReportColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  /// ข้อความผิดพลาดพร้อมปุ่มลองใหม่
  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  /// เนื้อหารายงาน: ตัวเลขสรุป 4 ช่อง แล้วตามด้วยการ์ดแต่ละส่วน
  Widget _buildReport(YearlyReport r) {
    Widget stat(String label, double value, String unit, Color color) => Expanded(
      child: StatCard(label: label, value: formatNumber(value), unit: unit, color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            stat('ผลผลิตรวม', r.totalKg, 'กก.', ReportColors.primary),
            const SizedBox(width: 12),
            stat('กำไรสุทธิ', r.profit, 'บาท', r.profit >= 0 ? ReportColors.income : ReportColors.expense),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            stat('รายรับ', r.totalIncome, 'บาท', ReportColors.income),
            const SizedBox(width: 12),
            stat('รายจ่าย', r.totalExpense, 'บาท', ReportColors.expense),
          ],
        ),
        const SizedBox(height: 16),
        GardenSummaryCard(report: r),
        const SizedBox(height: 16),
        // รายเดือนไม่มีกราฟรายเดือน (ดูเดือนเดียวอยู่แล้ว) เทียบกับเดือนเดียวกันของปีก่อนแทน
        if (r.month == null) ...[
          // key ตามปี: เปลี่ยนปีแล้วเดือนที่แตะเลือกไว้ในกราฟจะถูกล้าง
          MonthlyMoneyChart(key: ValueKey(r.year), report: r),
          const SizedBox(height: 16),
          YearCompareCard(report: r),
        ] else
          MonthCompareCard(report: r),
      ],
    );
  }
}
