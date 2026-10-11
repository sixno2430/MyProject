// ============================================================
// report_screen.dart — แท็บ "รายงาน" สรุปผลประจำปี (proposal 4.2.7 รายงานและวิเคราะห์ข้อมูล)
//
// ดูได้ 2 แบบ (ปุ่มสลับด้านบน):
//   - รายปี  : ทุกส่วนด้านล่าง
//   - รายเดือน: ตัวเลขสรุป + สรุปรายแปลงของเดือนนั้น + เทียบผลผลิตกับเดือนเดียวกันของปีก่อน
// รายปีแสดง:
//   1) ตัวเลขสรุป: ผลผลิตรวม, กำไรสุทธิ, รายรับ, รายจ่าย
//   2) สรุปรายแปลง: ผลผลิต, รายรับ, รายจ่าย, กำไร ของทุกแปลง + "ส่วนกลาง"
//      (รายการเงินที่ไม่ผูกแปลง — แบบเดียวกับตัวกรองในหน้าการเงิน)
//   3) กราฟแท่งรายรับ-รายจ่ายรายเดือน แตะเดือนเพื่อดูตัวเลขและกำไรของเดือนนั้น
//   4) ผลผลิตรายเดือนเทียบกับปีก่อน พร้อม % เพิ่ม/ลด
// API: GET /api/report/:userId?year=2026 (&month=10 = รายเดือน)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/utils/error_message.dart';

// ==========================================
// 1. MODEL
// ==========================================

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// สรุปของแปลง 1 แปลงในปีนั้น
class GardenSummary {
  final String gardenName;
  final double areaRai;
  final double totalKg;
  final double income;
  final double expense;
  final double profit;

  GardenSummary.fromJson(Map<String, dynamic> j)
    : gardenName = j['gardenName']?.toString() ?? '-',
      areaRai = _num(j['areaRai']),
      totalKg = _num(j['totalKg']),
      income = _num(j['income']),
      expense = _num(j['expense']),
      profit = _num(j['profit']);

  bool get hasData => totalKg > 0 || income > 0 || expense > 0;
}

/// รายรับ-รายจ่ายของเดือน 1 เดือน
class MonthlyMoney {
  final int month;
  final double income;
  final double expense;

  MonthlyMoney.fromJson(Map<String, dynamic> j)
    : month = (j['month'] as num).toInt(),
      income = _num(j['income']),
      expense = _num(j['expense']);
}

/// ผลผลิตของเดือน 1 เดือน ปีนี้กับปีก่อน
class MonthlyProduction {
  final int month;
  final double kg;
  final double prevKg;

  MonthlyProduction.fromJson(Map<String, dynamic> j)
    : month = (j['month'] as num).toInt(),
      kg = _num(j['kg']),
      prevKg = _num(j['prevKg']);
}

/// ข้อมูลรายงานทั้งปี
class YearlyReport {
  final int year;
  final int? month; // null = รายงานรายปี
  final double totalKg;
  final double prevTotalKg;
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final List<GardenSummary> byGarden;
  final double commonIncome; // ส่วนกลาง (รายการเงินที่ไม่ผูกแปลง)
  final double commonExpense;
  final List<MonthlyMoney> monthly;
  final List<MonthlyProduction> production;

  YearlyReport.fromJson(Map<String, dynamic> j)
    : year = (j['year'] as num).toInt(),
      month = (j['month'] as num?)?.toInt(),
      totalKg = _num(j['totalKg']),
      prevTotalKg = _num(j['prevTotalKg']),
      totalIncome = _num(j['totalIncome']),
      totalExpense = _num(j['totalExpense']),
      profit = _num(j['profit']),
      byGarden = (j['byGarden'] as List? ?? []).map((e) => GardenSummary.fromJson(e)).toList(),
      commonIncome = _num((j['common'] as Map?)?['income']),
      commonExpense = _num((j['common'] as Map?)?['expense']),
      monthly = (j['monthly'] as List? ?? []).map((e) => MonthlyMoney.fromJson(e)).toList(),
      production = (j['production'] as List? ?? []).map((e) => MonthlyProduction.fromJson(e)).toList();
}

// ==========================================
// 2. SERVICE
// ==========================================

/// เรียก API รายงาน
class ReportService {
  /// ดึงรายงานของปีที่กำหนด (ส่ง month = รายงานของเดือนนั้น) สำหรับ user ที่ล็อกอินอยู่
  static Future<YearlyReport> fetchYearly(int year, {int? month}) async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUri}/report/$userId?year=$year${month == null ? '' : '&month=$month'}'),
    );
    if (response.statusCode != 200) {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    if (body['isError'] == true) {
      throw Exception(body['errorMessage'] ?? 'โหลดรายงานไม่สำเร็จ');
    }
    return YearlyReport.fromJson(body['data']);
  }
}

// ==========================================
// 3. UI
// ==========================================

const _monthShort = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
const _monthFull = [
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

/// แท็บรายงาน
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color incomeColor = Color(0xFF2E7D32);
  static const Color expenseColor = Color(0xFFD32F2F);
  static const Color mutedText = Color(0xFF6B7280);

  final NumberFormat _number = NumberFormat('#,##0');
  bool _monthly = false; // false = รายปี, true = รายเดือน
  int _year = DateTime.now().year;
  int _month = DateTime.now().month; // ใช้ตอนดูรายเดือน
  late Future<YearlyReport> _future;
  int? _selectedMonth; // เดือนที่แตะในกราฟรายรับ-รายจ่าย (1-12)

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// โหลดรายงานของปี (หรือเดือน) ที่เลือก
  void _load() {
    setState(() {
      _selectedMonth = null;
      _future = ReportService.fetchYearly(_year, month: _monthly ? _month : null);
    });
  }

  /// เลื่อนช่วงเวลาไปข้างหน้า/ถอยหลัง: รายปี = ทีละปี, รายเดือน = ทีละเดือน (ข้ามปีได้)
  /// ไม่ให้เลือกช่วงในอนาคต
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

  String _fmt(double v) => _number.format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
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
            _buildYearSelector(),
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
                if (snapshot.hasError) {
                  return _buildError(friendlyError(snapshot.error));
                }
                return _buildReport(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ปุ่มสลับ รายปี / รายเดือน + แถบเลือกช่วงเวลา (ลูกศรซ้าย/ขวา)
  Widget _buildYearSelector() {
    final now = DateTime.now();
    final atLatest = _monthly ? (_year == now.year && _month >= now.month) : _year >= now.year;
    final label = _monthly ? '${_monthFull[_month - 1]} ${_year + 543}' : 'ปี พ.ศ. ${_year + 543}';
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
            selectedBackgroundColor: primaryGreen,
            selectedForegroundColor: Colors.white,
            foregroundColor: primaryGreen,
            side: const BorderSide(color: primaryGreen),
          ),
          onSelectionChanged: (v) => _setMonthly(v.first),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _changePeriod(-1),
              icon: const Icon(Icons.chevron_left, color: primaryGreen),
            ),
            SizedBox(
              width: 170,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryGreen),
              ),
            ),
            IconButton(
              onPressed: atLatest ? null : () => _changePeriod(1),
              icon: Icon(Icons.chevron_right, color: atLatest ? Colors.grey[300] : primaryGreen),
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

  /// เนื้อหารายงานทั้งหมด
  Widget _buildReport(YearlyReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ตัวเลขสรุป 4 ช่อง ──
        Row(
          children: [
            Expanded(child: _buildStatCard('ผลผลิตรวม', _fmt(r.totalKg), 'กก.', primaryGreen)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('กำไรสุทธิ', _fmt(r.profit), 'บาท', r.profit >= 0 ? incomeColor : expenseColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('รายรับ', _fmt(r.totalIncome), 'บาท', incomeColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('รายจ่าย', _fmt(r.totalExpense), 'บาท', expenseColor)),
          ],
        ),
        const SizedBox(height: 16),
        _buildGardenSummary(r),
        const SizedBox(height: 16),
        // รายเดือน: ไม่มีกราฟรายเดือน (ดูเดือนเดียวอยู่แล้ว) เทียบกับเดือนเดียวกันของปีก่อนแทน
        if (r.month == null) ...[
          _buildMonthlyMoney(r),
          const SizedBox(height: 16),
          _buildYearCompare(r),
        ] else
          _buildMonthCompare(r),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // สรุปรายแปลง
  // ---------------------------------------------------------------------------

  Widget _buildGardenSummary(YearlyReport r) {
    final active = r.byGarden.where((g) => g.hasData).toList();
    final idle = r.byGarden.where((g) => !g.hasData).toList();
    final hasCommon = r.commonIncome > 0 || r.commonExpense > 0;
    return _buildCard(
      title: 'สรุปรายแปลง',
      subtitle: 'ผลผลิตและการเงินของแต่ละแปลงใน${r.month == null ? 'ปีนี้' : 'เดือนนี้'}',
      child: r.byGarden.isEmpty && !hasCommon
          ? _buildNoData('ยังไม่มีแปลงสวน')
          : Column(
              children: [
                // ส่วนกลางอยู่บนสุดเสมอ (ยอดเป็น 0 ก็แสดง) แล้วตามด้วยแปลงที่มีข้อมูล
                _buildCommonRow(r),
                for (final g in active) ...[const Divider(height: 24), _buildGardenRow(g)],
                // แปลงที่ยังไม่มีข้อมูลในปีนี้ รวมไว้บรรทัดเดียว ไม่ให้รายการยาว
                if (idle.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ยังไม่มีข้อมูลใน${r.month == null ? 'ปีนี้' : 'เดือนนี้'}: ${idle.map((g) => g.gardenName).join(', ')}',
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

  /// แปลง 1 แปลง: ชื่อ + พื้นที่, ผลผลิต, รายรับ / รายจ่าย / กำไร
  Widget _buildGardenRow(GardenSummary g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.park_outlined, size: 18, color: primaryGreen),
            const SizedBox(width: 6),
            Expanded(
              child: Text(g.gardenName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            if (g.areaRai > 0) Text('${_fmt(g.areaRai)} ไร่', style: const TextStyle(fontSize: 12, color: mutedText)),
          ],
        ),
        const SizedBox(height: 8),
        Text('ผลผลิต ${_fmt(g.totalKg)} กก.', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _buildMoneyTriple(g.income, g.expense, g.profit),
      ],
    );
  }

  /// แถว "ส่วนกลาง" (รายการเงินที่ไม่ผูกกับแปลง)
  Widget _buildCommonRow(YearlyReport r) {
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
        _buildMoneyTriple(r.commonIncome, r.commonExpense, r.commonIncome - r.commonExpense),
      ],
    );
  }

  /// รายรับ / รายจ่าย / กำไร 3 ช่องในกล่องพื้นเทาอ่อน
  Widget _buildMoneyTriple(double income, double expense, double profit) {
    Widget cell(String label, String value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: mutedText)),
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
          cell('รายรับ', '${_fmt(income)} ฿', incomeColor),
          cell('รายจ่าย', '${_fmt(expense)} ฿', expenseColor),
          cell('กำไร', '${profit < 0 ? '-' : ''}${_fmt(profit.abs())} ฿', profit >= 0 ? primaryGreen : expenseColor),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // กราฟแท่งรายรับ-รายจ่ายรายเดือน
  // ---------------------------------------------------------------------------

  Widget _buildMonthlyMoney(YearlyReport r) {
    final hasData = r.monthly.any((m) => m.income > 0 || m.expense > 0);
    final maxValue = r.monthly.fold<double>(0, (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b));
    final selected = _selectedMonth == null ? null : r.monthly.firstWhere((m) => m.month == _selectedMonth);

    return _buildCard(
      title: 'รายรับ-รายจ่ายรายเดือน',
      subtitle: 'แตะเดือนเพื่อดูยอดและกำไรของเดือนนั้น',
      child: !hasData
          ? _buildNoData('ยังไม่มีรายการเงินในปีนี้')
          : Column(
              children: [
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [for (final m in r.monthly) Expanded(child: _buildMoneyBars(m, maxValue))],
                  ),
                ),
                const SizedBox(height: 12),
                // รายละเอียดของเดือนที่แตะ / คำอธิบายสี
                selected == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendDot('รายรับ', incomeColor),
                          const SizedBox(width: 20),
                          _buildLegendDot('รายจ่าย', expenseColor),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_monthFull[selected.month - 1]} ${r.year + 543}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildMoneyTriple(selected.income, selected.expense, selected.income - selected.expense),
                        ],
                      ),
              ],
            ),
    );
  }

  /// แท่งคู่ของเดือน 1 เดือน (เขียว = รายรับ, แดง = รายจ่าย) แตะเลือก / แตะซ้ำยกเลิก
  Widget _buildMoneyBars(MonthlyMoney m, double maxValue) {
    const barArea = 118.0; // ความสูงสุดของแท่ง (เหลือที่ให้ชื่อเดือน)
    final isSelected = _selectedMonth == m.month;
    final dimmed = _selectedMonth != null && !isSelected;
    final empty = m.income == 0 && m.expense == 0;
    double h(double v) => v <= 0 || maxValue <= 0 ? 0 : (barArea * v / maxValue).clamp(3.0, barArea);
    Color c(Color base) => dimmed ? base.withValues(alpha: 0.25) : base;

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
                Flexible(
                  child: Container(
                    height: h(m.income),
                    decoration: BoxDecoration(
                      color: c(incomeColor),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Container(
                    height: h(m.expense),
                    decoration: BoxDecoration(
                      color: c(expenseColor),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE5E7EB)), // เส้นฐาน
          const SizedBox(height: 6),
          Text(
            _monthShort[m.month - 1],
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryGreen : (empty ? Colors.grey[400] : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // เทียบผลผลิตกับปีก่อน
  // ---------------------------------------------------------------------------

  Widget _buildYearCompare(YearlyReport r) {
    final thisYear = r.year + 543;
    final lastYear = thisYear - 1;
    // แสดงเฉพาะเดือนที่มีผลผลิตในปีใดปีหนึ่ง
    final rows = r.production.where((p) => p.kg > 0 || p.prevKg > 0).toList();

    return _buildCard(
      title: 'เทียบผลผลิตกับปีก่อน',
      subtitle: 'ปี $thisYear เทียบกับปี $lastYear (กิโลกรัม)',
      child: rows.isEmpty
          ? _buildNoData('ยังไม่มีข้อมูลผลผลิตทั้ง 2 ปี')
          : Column(
              children: [
                // สรุปทั้งปี
                Row(
                  children: [
                    Expanded(child: _buildYearTotal('ปี $lastYear', r.prevTotalKg, mutedText)),
                    const Icon(Icons.arrow_forward, size: 18, color: mutedText),
                    const SizedBox(width: 12),
                    Expanded(child: _buildYearTotal('ปี $thisYear', r.totalKg, primaryGreen)),
                    _buildChangePill(r.prevTotalKg, r.totalKg),
                  ],
                ),
                if (r.prevTotalKg == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'ปี $lastYear ยังไม่มีข้อมูลผลผลิตในระบบ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 14),
                // ตารางรายเดือน
                _buildCompareRow(['เดือน', '$lastYear', '$thisYear', 'เปลี่ยนแปลง'], header: true),
                for (final p in rows)
                  _buildCompareRow([
                    _monthFull[p.month - 1],
                    _fmt(p.prevKg),
                    _fmt(p.kg),
                  ], change: _buildChangePill(p.prevKg, p.kg)),
              ],
            ),
    );
  }

  /// รายเดือน: ผลผลิตเดือนนี้เทียบกับเดือนเดียวกันของปีก่อน
  Widget _buildMonthCompare(YearlyReport r) {
    final m = r.month!;
    final p = r.production.firstWhere((e) => e.month == m);
    final thisLabel = '${_monthShort[m - 1]} ${r.year + 543}';
    final lastLabel = '${_monthShort[m - 1]} ${r.year + 542}';
    return _buildCard(
      title: 'เทียบผลผลิตกับปีก่อน',
      subtitle: '${_monthFull[m - 1]} ${r.year + 543} เทียบกับ${_monthFull[m - 1]} ${r.year + 542} (กิโลกรัม)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildYearTotal(lastLabel, p.prevKg, mutedText)),
              const Icon(Icons.arrow_forward, size: 18, color: mutedText),
              const SizedBox(width: 12),
              Expanded(child: _buildYearTotal(thisLabel, p.kg, primaryGreen)),
              _buildChangePill(p.prevKg, p.kg),
            ],
          ),
          if (p.prevKg == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$lastLabel ยังไม่มีข้อมูลผลผลิตในระบบ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYearTotal(String label, double kg, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: mutedText)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${_fmt(kg)} กก.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  /// ป้าย % เปลี่ยนแปลง: เพิ่ม = เขียว ลูกศรขึ้น, ลด = แดง ลูกศรลง, ปีก่อนเป็น 0 = "ใหม่"
  Widget _buildChangePill(double prev, double now) {
    String text;
    Color color;
    IconData? arrow;
    if (prev == 0 && now == 0) {
      text = '-';
      color = mutedText;
    } else if (prev == 0) {
      text = 'ใหม่';
      color = const Color(0xFF1565C0);
    } else {
      final pct = (now - prev) / prev * 100;
      text = '${pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0)}%';
      color = pct >= 0 ? incomeColor : expenseColor;
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

  /// แถวตารางเทียบรายเดือน (header = แถวหัวสีเทา)
  Widget _buildCompareRow(List<String> cells, {bool header = false, Widget? change}) {
    final style = TextStyle(
      fontSize: header ? 11 : 13,
      fontWeight: header ? FontWeight.w600 : FontWeight.normal,
      color: header ? mutedText : Colors.black87,
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

  // ---------------------------------------------------------------------------
  // ส่วนประกอบทั่วไป
  // ---------------------------------------------------------------------------

  /// กรอบการ์ดสีขาวพร้อมหัวข้อ + คำอธิบาย
  Widget _buildCard({required String title, String? subtitle, required Widget child}) {
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
            Text(subtitle, style: const TextStyle(fontSize: 12, color: mutedText)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// ข้อความเมื่อยังไม่มีข้อมูล
  Widget _buildNoData(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }

  /// การ์ดตัวเลข 1 ช่อง
  Widget _buildStatCard(String label, String value, String unit, Color color) {
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

  /// จุดสี + ชื่อ (คำอธิบายสีของกราฟ)
  Widget _buildLegendDot(String label, Color color) {
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
