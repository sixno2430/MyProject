// ============================================================
// admin_report_screen.dart — รายงานสรุประบบสำหรับผู้ดูแล (proposal 4.1.7)
//
// ช่วงเวลา: 6 เดือนล่าสุด
// - สรุปยอดรวมของช่วง: ผลผลิตทั้งชุมชน, ปริมาณรับซื้อผ่านระบบ, มูลค่ารับซื้อ
// - กราฟแท่งผลผลิต / การรับซื้อรายเดือน (สลับดู กิโลกรัม / บาท)
// - เกษตรกรที่มีผลผลิตสูงสุด 5 อันดับ (ทั้งหมดในระบบ)
// - สถิติการใช้งานระบบรายเดือน: จำนวนครั้งที่เข้าสู่ระบบ, รายการที่บันทึก, จำนวนผู้ใช้
// - ร้านรับซื้อ: สถานะ, ราคาล่าสุด, ยอดรับซื้อผ่านระบบ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/admin_service.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/screens/admin/widgets/admin_widgets.dart';
import 'package:flutter_myproject/models/admin.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  late Future<AdminReport> _future;
  bool _showAmount = false; // กราฟรับซื้อ: false = กิโลกรัม, true = บาท

  @override
  void initState() {
    super.initState();
    _future = AdminService.getReport();
  }

  Future<void> _reload() async {
    final future = AdminService.getReport();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  double _sum(List<MonthValue> list) => list.fold(0, (s, e) => s + e.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('รายงานสรุประบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<AdminReport>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return AdminErrorView(message: friendlyError(snap.error), onRetry: _reload);
            }
            final r = snap.data!;
            final months = r.harvestMonthly;
            final period = months.isEmpty
                ? ''
                : '${thaiMonthYear(months.first.month)} – ${thaiMonthYear(months.last.month)}';
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildPeriodSummary(r, period),
                const AdminSectionTitle('การผลิตและการซื้อขาย'),
                AdminCard(
                  title: 'ผลผลิตรวมทั้งชุมชนรายเดือน',
                  subtitle: 'หน่วย กิโลกรัม',
                  child: MonthBarChart(data: r.harvestMonthly, color: AdminColors.farmer),
                ),
                AdminCard(
                  title: 'การรับซื้อผ่านระบบรายเดือน',
                  subtitle: _showAmount ? 'หน่วย บาท' : 'หน่วย กิโลกรัม',
                  trailing: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('กก.')),
                      ButtonSegment(value: true, label: Text('บาท')),
                    ],
                    selected: {_showAmount},
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    onSelectionChanged: (s) => setState(() => _showAmount = s.first),
                  ),
                  child: MonthBarChart(
                    data: _showAmount ? r.purchaseMonthlyAmount : r.purchaseMonthlyQty,
                    color: AdminColors.shop,
                  ),
                ),
                AdminCard(
                  title: 'เกษตรกรที่มีผลผลิตสูงสุด',
                  subtitle: '5 อันดับแรก จากข้อมูลการเก็บเกี่ยวทั้งหมด',
                  child: _buildTopFarmers(r.topFarmers),
                ),
                const AdminSectionTitle('ร้านรับซื้อและการใช้งานระบบ'),
                AdminCard(
                  title: 'ร้านรับซื้อในระบบ',
                  subtitle: 'ราคาล่าสุดและยอดรับซื้อผ่านระบบ',
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _buildShops(r.shops),
                ),
                AdminCard(
                  title: 'สถิติการใช้งานระบบรายเดือน',
                  subtitle: 'จำนวนครั้งที่เข้าสู่ระบบ จำนวนรายการที่บันทึก และจำนวนผู้ใช้',
                  child: _buildUsageTable(r.usageMonthly),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// กล่องน้ำเงินด้านบน: ช่วงเวลาของรายงาน + ยอดรวม 3 ตัว
  Widget _buildPeriodSummary(AdminReport r, String period) {
    final items = [
      ('ผลผลิตรวม', '${formatNumber(_sum(r.harvestMonthly))} กก.'),
      ('รับซื้อผ่านระบบ', '${formatNumber(_sum(r.purchaseMonthlyQty))} กก.'),
      ('มูลค่ารับซื้อ', '${formatNumber(_sum(r.purchaseMonthlyAmount))} บาท'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สรุป 6 เดือนล่าสุด', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            period,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (label, value) in items)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// อันดับเกษตรกร: เลขอันดับ + ชื่อ + แถบเทียบกับอันดับ 1
  Widget _buildTopFarmers(List<Map<String, dynamic>> farmers) {
    if (farmers.isEmpty) return const AdminEmptyText('ยังไม่มีข้อมูลการเก็บเกี่ยว');
    final top = num.tryParse('${farmers.first['qty']}') ?? 0;
    return Column(
      children: [
        for (var i = 0; i < farmers.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == farmers.length - 1 ? 0 : 14),
            child: Builder(
              builder: (context) {
                final qty = num.tryParse('${farmers[i]['qty']}') ?? 0;
                return Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0 ? AdminColors.primary : AdminColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: i == 0 ? Colors.white : AdminColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${farmers[i]['full_name']}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${formatNumber(qty)} กก.',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: top == 0 ? 0 : qty / top,
                              minHeight: 6,
                              color: AdminColors.farmer,
                              backgroundColor: AdminColors.background,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${farmers[i]['lots']} ล็อต',
                            style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  /// ร้านรับซื้อ: ชื่อ + สถานะ, ราคาล่าสุด, ยอดรับซื้อ
  Widget _buildShops(List<Map<String, dynamic>> shops) {
    if (shops.isEmpty) {
      return const Padding(padding: EdgeInsets.only(bottom: 12), child: AdminEmptyText('ยังไม่มีร้านรับซื้อในระบบ'));
    }
    return Column(
      children: [
        for (var i = 0; i < shops.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AdminColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Builder(
              builder: (context) {
                final s = shops[i];
                final open = '${s['status']}'.toUpperCase() == 'ACTIVE';
                final price = s['latest_price'];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${s['shop_name']}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              open
                                  ? const StatusPill('เปิดรับซื้อ', AdminColors.success)
                                  : const StatusPill('ปิดรับซื้อ', AdminColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'รับซื้อผ่านระบบ ${s['purchase_count']} รายการ · '
                            '${formatNumber(num.tryParse('${s['purchase_qty']}') ?? 0)} กก.',
                            style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (price == null)
                          const Text('ยังไม่กำหนดราคา', style: TextStyle(fontSize: 12, color: AdminColors.textMuted))
                        else ...[
                          Text(
                            (num.tryParse('$price') ?? 0).toStringAsFixed(2),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const Text('บาท/กก.', style: TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// ตารางสถิติการใช้งาน: เดือนล่าสุดอยู่บน
  Widget _buildUsageTable(List<Map<String, dynamic>> usage) {
    const head = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textMuted);
    const cell = TextStyle(fontSize: 13, color: AdminColors.text);
    Widget row(List<String> cells, TextStyle style, {bool header = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: header ? AdminColors.background : null,
        borderRadius: header ? BorderRadius.circular(8) : null,
        border: header ? null : const Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(cells[0], style: style)),
          for (final c in cells.skip(1))
            Expanded(
              flex: 2,
              child: Text(c, textAlign: TextAlign.right, style: style),
            ),
        ],
      ),
    );
    return Column(
      children: [
        row(['เดือน', 'เข้าระบบ', 'ทำรายการ', 'ผู้ใช้'], head, header: true),
        for (final u in usage.reversed)
          row([
            thaiMonthYear('${u['month']}'),
            formatNumber(num.tryParse('${u['logins']}') ?? 0),
            formatNumber(num.tryParse('${u['actions']}') ?? 0),
            formatNumber(num.tryParse('${u['users']}') ?? 0),
          ], cell),
      ],
    );
  }
}
