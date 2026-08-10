import 'package:flutter/material.dart';
import 'dart:math' as math;

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text('รายงานสรุปผลการผลิต', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // สรุปตัวเลข
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReportStat('5,850', 'ผลผลิตรวม\n(กก.)'),
                _buildReportStat('29,528', 'รายได้รวม\n(บาท)'),
              ],
            ),
            const SizedBox(height: 20),

            // กราฟวงกลม (Pie Chart แบบง่าย)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สัดส่วนผลผลิตตามแปลง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: PieChartPainter(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegend('แปลง A', Colors.green, '45%'),
                          _buildLegend('แปลง B', Colors.orange, '30%'),
                          _buildLegend('แปลง C', Colors.blue, '15%'),
                          _buildLegend('แปลง D', Colors.purple, '10%'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // กราฟเส้น (แบบง่าย)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('แนวโน้มรายได้', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      painter: LineChartPainter(),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่ม Export
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLegend(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// Pie Chart แบบ CustomPaint
class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final data = [
      PieData(Colors.green, 0.45),
      PieData(Colors.orange, 0.30),
      PieData(Colors.blue, 0.15),
      PieData(Colors.purple, 0.10),
    ];

    double startAngle = -math.pi / 2;
    for (final item in data) {
      final sweepAngle = item.percent * 2 * math.pi;
      final paint = Paint()..color = item.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // วงกลมตรงกลางให้เป็น Donut
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieData {
  final Color color;
  final double percent;
  PieData(this.color, this.percent);
}

// Line Chart แบบ CustomPaint
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.55, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.5),
      Offset(size.width * 0.85, size.height * 0.3),
      Offset(size.width * 0.95, size.height * 0.2),
    ];

    final paint = Paint()
      ..color = const Color(0xFF2D6A4F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // จุด
    final dotPaint = Paint()..color = const Color(0xFF2D6A4F);
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}