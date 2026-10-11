// ============================================================
// admin_widgets.dart — สี, widget และฟังก์ชันจัดรูปแบบที่ใช้ร่วมกันในหน้าแอดมิน
//
// ทุกหน้าของแอดมินใช้ชุดนี้ หน้าตาจึงไปทางเดียวกัน:
//   AdminColors   ชุดสี (น้ำเงินเป็นสีหลัก, เขียว/ส้ม/แดง ใช้เป็นสีสถานะเท่านั้น)
//   AdminCard     กล่องพื้นขาว มีหัวข้อ + คำอธิบาย + ปุ่มด้านขวา (ถ้ามี)
//   StatusPill    ป้ายสถานะเล็กๆ เช่น "ใช้งานปกติ" / "ถูกระงับ"
//   MonthBarChart กราฟแท่งรายเดือน (วาดด้วย Container ไม่ต้องพึ่ง package กราฟ)
//   thaiShortDate / thaiDateTime  วันที่แบบไทย ปี พ.ศ.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/models/admin.dart';

/// ชุดสีของฝั่งแอดมิน
class AdminColors {
  static const primary = Color(0xFF1E40AF); // น้ำเงินเข้ม
  static const primarySoft = Color(0xFFE8EEFB);
  static const background = Color(0xFFF4F6FA);
  static const border = Color(0xFFE5E7EB);
  static const text = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const farmer = Color(0xFF2D6A4F); // ใช้สีเดียวกับฝั่งเกษตรกร
  static const shop = Color(0xFFEA580C); // ใช้สีเดียวกับฝั่งร้านรับซื้อ
}

/// ครอบหน้าแอดมินให้ปุ่ม/ช่องกรอก/สวิตช์ของ Material ใช้โทนน้ำเงิน
/// (ธีมหลักของแอปเป็นสีเขียวของฝั่งเกษตรกร) — ใช้ตอน push หน้าแอดมิน: AdminTheme(child: หน้า)
/// dialog และ bottom sheet ที่เปิดจากในหน้าจะใช้ธีมนี้ต่อด้วย
class AdminTheme extends StatelessWidget {
  final Widget child;
  const AdminTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(colorScheme: ColorScheme.fromSeed(seedColor: AdminColors.primary)),
      child: child,
    );
  }
}

/// สีประจำบทบาท
Color roleColor(String roleId) => switch (roleId) {
  'R001' => AdminColors.primary,
  'R003' => AdminColors.shop,
  _ => AdminColors.farmer,
};

const _monthsShort = [
  '',
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

/// 'YYYY-MM' -> 'ต.ค.'
String thaiMonthShort(String yyyyMm) {
  final m = int.tryParse(yyyyMm.split('-').last) ?? 0;
  return m >= 1 && m <= 12 ? _monthsShort[m] : yyyyMm;
}

/// 'YYYY-MM' -> 'ต.ค. 2569'
String thaiMonthYear(String yyyyMm) {
  final y = int.tryParse(yyyyMm.split('-').first) ?? 0;
  return '${thaiMonthShort(yyyyMm)} ${y + 543}';
}

/// DateTime -> '11 ต.ค. 2569'
String thaiShortDate(DateTime d) => '${d.day} ${_monthsShort[d.month]} ${d.year + 543}';

/// DateTime -> '22:27 น.'
String thaiTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} น.';

/// DateTime -> '11 ต.ค. 2569 เวลา 22:27 น.'
String thaiDateTime(DateTime d) => '${thaiShortDate(d)} เวลา ${thaiTime(d)}';

/// กล่องพื้นขาวมุมมน ขอบบาง มีหัวข้อ + คำอธิบายใต้หัวข้อ + widget ด้านขวา (ถ้ามี)
class AdminCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    // ใช้ Material (ไม่ใช่ Container สีขาว) เพื่อให้แถวที่กดได้ข้างใน (ListTile/InkWell) แสดงเอฟเฟกต์ตอนแตะ
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AdminColors.border),
        ),
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: _content()),
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminColors.text),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
        ],
        child,
      ],
    );
  }
}

/// ป้ายสถานะ เช่น "ใช้งานปกติ" (เขียว) / "ถูกระงับ" (แดง)
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// หัวข้อหมวดในหน้า (ตัวเทาเล็ก เหนือกล่อง)
class AdminSectionTitle extends StatelessWidget {
  final String text;
  const AdminSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textMuted),
      ),
    );
  }
}

/// หน้าจอตอนโหลดไม่สำเร็จ: ไอคอน + ข้อความ + ปุ่มลองใหม่ (อยู่ใน ListView ให้ดึงลงรีเฟรชได้)
class AdminErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      children: [
        const Icon(Icons.cloud_off_outlined, size: 48, color: AdminColors.textMuted),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AdminColors.text),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่อีกครั้ง'),
          ),
        ),
      ],
    );
  }
}

/// ข้อความตอนไม่มีข้อมูล (อยู่กลางกล่อง)
class AdminEmptyText extends StatelessWidget {
  final String text;
  const AdminEmptyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text, style: const TextStyle(color: AdminColors.textMuted)),
      ),
    );
  }
}

/// กราฟแท่งรายเดือน: ความสูงของแท่งเทียบกับเดือนที่มากที่สุด ตัวเลขอยู่บนแท่ง
/// เดือนที่เป็น 0 แสดงเป็นขีดเทาเตี้ยๆ ให้รู้ว่าเดือนนั้นไม่มีข้อมูล (ไม่ใช่กราฟหาย)
class MonthBarChart extends StatelessWidget {
  final List<MonthValue> data;
  final Color color;
  final double height;

  const MonthBarChart({super.key, required this.data, required this.color, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    if (maxValue <= 0) {
      return SizedBox(height: height, child: const AdminEmptyText('ยังไม่มีข้อมูลในช่วงเวลานี้'));
    }
    const labelSpace = 44.0; // ตัวเลขบนแท่ง + ชื่อเดือนใต้แท่ง (เผื่อสระไทยที่สูงกว่าตัวอังกฤษ)
    final barArea = height - labelSpace;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in data)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    e.value > 0 ? compactNumber(e.value) : '-',
                    style: const TextStyle(fontSize: 10, color: AdminColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: e.value > 0 ? (barArea * e.value / maxValue).clamp(4.0, barArea) : 3,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: e.value > 0 ? color : AdminColors.border,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(thaiMonthShort(e.month), style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ย่อเลขยาวๆ เช่น 14000 -> 14K, 1250000 -> 1.3M (เลขไม่ถึงหมื่นแสดงเต็มพร้อม comma)
String compactNumber(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
  return formatNumber(v);
}

/// ปิดเลขบัตรประชาชนบางส่วน เช่น 1234567890123 -> 1-2345-xxxxx-12-3
String maskCitizenId(String id) {
  if (id.length != 13) return id.isEmpty ? '-' : id;
  return '${id[0]}-${id.substring(1, 5)}-xxxxx-${id.substring(10, 12)}-${id[12]}';
}
