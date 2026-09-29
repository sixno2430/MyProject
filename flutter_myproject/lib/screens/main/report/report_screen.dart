// ============================================================
// report_screen.dart — แท็บ "รายงาน" สรุปผลประจำปี
//
// แสดงผลผลิตรวม, กำไร, รายรับ, รายจ่าย, กราฟวงกลมสัดส่วนผลผลิตตามแปลง
// และกราฟเส้นรายรับ-รายจ่ายรายเดือน เปลี่ยนปีได้
// API: GET /api/report/:userId?year=2026
// ============================================================

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';

// ==========================================
// 1. MODEL
// ==========================================

/// ผลผลิตรวมของแปลง 1 แปลง (ใช้ในกราฟวงกลม)
class GardenProduction {
  final String gardenName;
  final double totalKg;

  GardenProduction({required this.gardenName, required this.totalKg});

  factory GardenProduction.fromJson(Map<String, dynamic> json) => GardenProduction(
        gardenName: json['gardenName']?.toString() ?? 'ไม่ระบุแปลง',
        totalKg: (json['totalKg'] as num?)?.toDouble() ?? 0,
      );
}

/// รายรับ-รายจ่ายของเดือน 1 เดือน (ใช้ในกราฟเส้น)
class MonthlyMoney {
  final int month;
  final double income;
  final double expense;

  MonthlyMoney({required this.month, required this.income, required this.expense});

  factory MonthlyMoney.fromJson(Map<String, dynamic> json) => MonthlyMoney(
        month: (json['month'] as num).toInt(),
        income: (json['income'] as num?)?.toDouble() ?? 0,
        expense: (json['expense'] as num?)?.toDouble() ?? 0,
      );
}

/// ข้อมูลรายงานทั้งปี
class YearlyReport {
  final int year;
  final double totalKg;
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final List<GardenProduction> byGarden;
  final List<MonthlyMoney> monthly;

  YearlyReport({
    required this.year,
    required this.totalKg,
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
    required this.byGarden,
    required this.monthly,
  });

  factory YearlyReport.fromJson(Map<String, dynamic> json) => YearlyReport(
        year: (json['year'] as num).toInt(),
        totalKg: (json['totalKg'] as num?)?.toDouble() ?? 0,
        totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0,
        totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
        profit: (json['profit'] as num?)?.toDouble() ?? 0,
        byGarden: (json['byGarden'] as List? ?? [])
            .map((e) => GardenProduction.fromJson(e))
            .toList(),
        monthly: (json['monthly'] as List? ?? [])
            .map((e) => MonthlyMoney.fromJson(e))
            .toList(),
      );
}

// ==========================================
// 2. SERVICE
// ==========================================

/// เรียก API รายงาน
class ReportService {
  /// ดึงรายงานของปีที่กำหนด สำหรับ user ที่ล็อกอินอยู่
  static Future<YearlyReport> fetchYearly(int year) async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUri}/report/$userId?year=$year'),
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

/// แท็บรายงาน
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  static const Color incomeColor = Color(0xFF2E7D32);
  static const Color expenseColor = Color(0xFFD32F2F);

  // สีของแต่ละแปลงในกราฟวงกลม (วนใช้ถ้าแปลงเยอะกว่านี้)
  static const List<Color> gardenColors = [
    Color(0xFF2D6A4F),
    Color(0xFFF4A261),
    Color(0xFF457B9D),
    Color(0xFF9C6ADE),
    Color(0xFFE76F51),
    Color(0xFF2A9D8F),
  ];

  final NumberFormat _number = NumberFormat('#,##0');
  int _year = DateTime.now().year;
  late Future<YearlyReport> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// โหลดรายงานของปีที่เลือก
  void _load() {
    setState(() {
      _future = ReportService.fetchYearly(_year);
    });
  }

  /// เลื่อนปีไปข้างหน้า/ถอยหลัง (ไม่ให้เลือกปีอนาคต)
  void _changeYear(int delta) {
    final next = _year + delta;
    if (next > DateTime.now().year) return; // ไม่ให้เลือกปีอนาคต
    _year = next;
    _load();
  }

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
          await _future.catchError((_) => _emptyReport());
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildYearSelector(),
            const SizedBox(height: 16),
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
                  return _buildError(snapshot.error.toString().replaceFirst('Exception: ', ''));
                }
                return _buildReport(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// รายงานว่าง (ใช้ตอนดึงหน้าจอลงแล้วโหลดไม่สำเร็จ)
  YearlyReport _emptyReport() => YearlyReport(
        year: _year,
        totalKg: 0,
        totalIncome: 0,
        totalExpense: 0,
        profit: 0,
        byGarden: [],
        monthly: [],
      );

  /// แถบเลือกปี (ลูกศรซ้าย/ขวา)
  Widget _buildYearSelector() {
    final isCurrentYear = _year >= DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _changeYear(-1),
          icon: Icon(Icons.chevron_left, color: primaryGreen),
        ),
        Text(
          'ปี พ.ศ. ${_year + 543}',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
        IconButton(
          onPressed: isCurrentYear ? null : () => _changeYear(1),
          icon: Icon(Icons.chevron_right, color: isCurrentYear ? Colors.grey[300] : primaryGreen),
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
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  /// เนื้อหารายงานทั้งหมด (การ์ดสถิติ + กราฟ 2 แบบ)
  Widget _buildReport(YearlyReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ตัวเลขสรุป 4 ช่อง ──
        Row(
          children: [
            Expanded(child: _buildStatCard('ผลผลิตรวม', _number.format(r.totalKg), 'กก.', primaryGreen)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'กำไรสุทธิ',
                _number.format(r.profit),
                'บาท',
                r.profit >= 0 ? incomeColor : expenseColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('รายรับ', _number.format(r.totalIncome), 'บาท', incomeColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('รายจ่าย', _number.format(r.totalExpense), 'บาท', expenseColor)),
          ],
        ),
        const SizedBox(height: 20),

        // ── กราฟวงกลม: สัดส่วนผลผลิตตามแปลง ──
        _buildCard(
          title: 'สัดส่วนผลผลิตตามแปลง',
          child: r.byGarden.isEmpty
              ? _buildNoData('ยังไม่มีข้อมูลการเก็บเกี่ยวในปีนี้')
              : Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: PieChartPainter(
                          values: r.byGarden.map((g) => g.totalKg).toList(),
                          colors: gardenColors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < r.byGarden.length; i++)
                            _buildLegend(
                              r.byGarden[i].gardenName,
                              gardenColors[i % gardenColors.length],
                              '${(r.byGarden[i].totalKg / r.totalKg * 100).toStringAsFixed(0)}%',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),

        // ── กราฟเส้น: รายรับ-รายจ่ายรายเดือน ──
        _buildCard(
          title: 'รายรับ-รายจ่ายรายเดือน',
          child: r.monthly.every((m) => m.income == 0 && m.expense == 0)
              ? _buildNoData('ยังไม่มีรายการเงินในปีนี้')
              : Column(
                  children: [
                    SizedBox(
                      height: 170,
                      child: CustomPaint(
                        painter: LineChartPainter(
                          income: r.monthly.map((m) => m.income).toList(),
                          expense: r.monthly.map((m) => m.expense).toList(),
                          incomeColor: incomeColor,
                          expenseColor: expenseColor,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend('รายรับ', incomeColor, ''),
                        const SizedBox(width: 20),
                        _buildLegend('รายจ่าย', expenseColor, ''),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// กรอบการ์ดสีขาวพร้อมหัวข้อ
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  /// ข้อความเมื่อยังไม่มีข้อมูล
  Widget _buildNoData(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text(text, style: TextStyle(color: Colors.grey[500]))),
    );
  }

  /// การ์ดตัวเลข 1 ช่อง
  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// คำอธิบายสีของกราฟ (จุดสี + ชื่อ + %)
  Widget _buildLegend(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          if (percent.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 4. CHART PAINTERS
// ==========================================

/// กราฟโดนัท: แต่ละชิ้นกว้างตามสัดส่วนของค่า
class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2; // เริ่มที่ 12 นาฬิกา
    for (var i = 0; i < values.length; i++) {
      final sweepAngle = values[i] / total * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = colors[i % colors.length],
      );
      startAngle += sweepAngle;
    }

    // วงกลมสีขาวตรงกลางให้เป็นโดนัท
    canvas.drawCircle(center, radius * 0.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

/// กราฟเส้น 12 เดือน: รายรับ (เขียว) กับ รายจ่าย (แดง)
class LineChartPainter extends CustomPainter {
  final List<double> income;
  final List<double> expense;
  final Color incomeColor;
  final Color expenseColor;

  static const monthLabels = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  LineChartPainter({
    required this.income,
    required this.expense,
    required this.incomeColor,
    required this.expenseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final maxValue = [...income, ...expense].fold<double>(0, math.max);
    if (maxValue <= 0) return;

    // เส้นแนวนอนจางๆ เป็นพื้นหลัง
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // แปลง (เดือน, ค่า) เป็นพิกัดบนจอ — ค่ามาก = อยู่สูง (y น้อย)
    Offset point(int month, double value) => Offset(
          size.width * (month + 0.5) / 12,
          chartHeight - (value / maxValue) * (chartHeight - 8),
        );

    void drawSeries(List<double> data, Color color) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(point(0, data[0]).dx, point(0, data[0]).dy);
      for (var i = 1; i < data.length; i++) {
        path.lineTo(point(i, data[i]).dx, point(i, data[i]).dy);
      }
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = color;
      for (var i = 0; i < data.length; i++) {
        if (data[i] > 0) canvas.drawCircle(point(i, data[i]), 3.5, dotPaint);
      }
    }

    drawSeries(expense, expenseColor);
    drawSeries(income, incomeColor);

    // ชื่อเดือนด้านล่าง
    for (var i = 0; i < 12; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: monthLabels[i],
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(size.width * (i + 0.5) / 12 - tp.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) =>
      oldDelegate.income != income || oldDelegate.expense != expense;
}
