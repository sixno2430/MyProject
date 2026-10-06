// ============================================================
// shop_report_screen.dart — แท็บ "รายงาน" ของร้านรับซื้อ (ภาพ 4.3.5)
//
// เลือกปี -> สรุปทั้งปี (ยอดซื้อ / น้ำหนัก / ราคาเฉลี่ย / เกษตรกร)
//          กราฟแท่งรายเดือน (สลับดูยอดเงิน/น้ำหนัก กดแท่งเพื่อดูรายละเอียดเดือนนั้น)
//          เกษตรกรที่ขายให้มากที่สุด 5 อันดับ
// กราฟวาดด้วย widget ธรรมดา ไม่ต้องลงแพ็กเกจกราฟเพิ่ม
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';

class ShopReportScreen extends StatefulWidget {
  final ShopInfo? shop;

  /// เพิ่มขึ้นทุกครั้งที่มีการรับซื้อ/ยกเลิก -> โหลดรายงานใหม่
  final int dataVersion;

  const ShopReportScreen({super.key, required this.shop, this.dataVersion = 0});

  @override
  State<ShopReportScreen> createState() => _ShopReportScreenState();
}

class _ShopReportScreenState extends State<ShopReportScreen> {
  static const theme = RoleTheme.shop;
  static const _monthShort = [
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
  final NumberFormat _money = NumberFormat('#,##0');
  final NumberFormat _kg = NumberFormat('#,##0.##');

  Future<ShopReport>? _future;
  int _year = DateTime.now().year;
  bool _showAmount = true; // true = กราฟยอดเงิน, false = กราฟน้ำหนัก
  int? _selectedMonth; // index 0-11 ของแท่งที่กด

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ShopReportScreen old) {
    super.didUpdateWidget(old);
    if (old.shop?.shopId != widget.shop?.shopId || old.dataVersion != widget.dataVersion) _load();
  }

  void _load() {
    final shop = widget.shop;
    if (shop == null) return;
    setState(() {
      _future = ShopService.fetchReport(shop.shopId, _year);
    });
  }

  void _changeYear(int y) {
    _year = y;
    _selectedMonth = null;
    _load();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (widget.shop == null) {
      return Column(
        children: [
          _buildHeader(null),
          Expanded(
            child: Center(
              child: Text('สร้างร้านก่อนจึงจะดูรายงานได้', style: TextStyle(color: Colors.grey[600])),
            ),
          ),
        ],
      );
    }
    return FutureBuilder<ShopReport>(
      future: _future,
      builder: (context, snap) {
        final report = snap.data;
        Widget body;
        if (snap.connectionState == ConnectionState.waiting) {
          body = Center(child: CircularProgressIndicator(color: theme.primary));
        } else if (snap.hasError || report == null) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snap.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
                ],
              ),
            ),
          );
        } else {
          body = RefreshIndicator(
            color: theme.primary,
            onRefresh: () async {
              _load();
              try {
                await _future;
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildStats(report),
                const SizedBox(height: 14),
                _buildChartCard(report),
                const SizedBox(height: 14),
                _buildTopFarmers(report),
              ],
            ),
          );
        }
        return Column(
          children: [
            _buildHeader(report),
            Expanded(child: body),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ShopReport? report) {
    final years = {...?report?.years, _year}.toList()..sort((a, b) => b.compareTo(a));
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: theme.headerGradient),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
          child: Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'รายงานการรับซื้อ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.shop != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _year,
                      dropdownColor: theme.primaryDark,
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text('ปี ${y + 543}'))).toList(),
                      onChanged: (y) {
                        if (y != null) _changeYear(y);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- การ์ดสรุป ----------

  Widget _buildStats(ShopReport r) {
    return Column(
      children: [
        Row(
          children: [
            _statCard('💰', 'ยอดซื้อรวม', '฿${_money.format(r.totalAmount)}'),
            const SizedBox(width: 10),
            _statCard('⚖️', 'น้ำหนักรวม', '${_kg.format(r.totalKg)} กก.'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard('🏷️', 'ราคาเฉลี่ย', '${r.avgPrice.toStringAsFixed(2)} ฿/กก.'),
            const SizedBox(width: 10),
            _statCard('👨‍🌾', 'เกษตรกร', '${r.farmerCount} คน · ${r.purchaseCount} ครั้ง'),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- กราฟรายเดือน ----------

  Widget _buildChartCard(ShopReport r) {
    final values = r.months.map((m) => _showAmount ? m.amount : m.kg).toList();
    final maxValue = values.fold<double>(0, (a, b) => b > a ? b : a);
    final selected = _selectedMonth == null ? null : r.months[_selectedMonth!];

    return _card(
      title: 'ยอดรับซื้อรายเดือน',
      trailing: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('บาท')),
          ButtonSegment(value: false, label: Text('กก.')),
        ],
        selected: {_showAmount},
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: theme.primary,
          selectedForegroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: (v) => setState(() => _showAmount = v.first),
      ),
      child: maxValue == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text('ยังไม่มีการรับซื้อในปี ${r.year + 543}', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(12, (i) {
                      final ratio = values[i] / maxValue;
                      final isSelected = _selectedMonth == i;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _selectedMonth = isSelected ? null : i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // แท่งค่อยๆ ยืดขึ้นตอนเปิด/เปลี่ยนโหมด
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: ratio),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, _) => Container(
                                  height: values[i] == 0 ? 3 : 4 + v * 136,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    gradient: values[i] == 0
                                        ? null
                                        : LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: isSelected
                                                ? [theme.primaryDark, theme.primary]
                                                : [theme.primary, theme.primaryLight],
                                          ),
                                    color: values[i] == 0 ? const Color(0xFFEDEDED) : null,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                child: Text(
                                  _monthShort[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? theme.primaryDark : Colors.grey[600],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected == null
                      ? Text(
                          'แตะที่แท่งเพื่อดูรายละเอียดเดือนนั้น',
                          key: const ValueKey('hint'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        )
                      : _monthDetail(_selectedMonth!, selected),
                ),
              ],
            ),
    );
  }

  Widget _monthDetail(int index, ShopReportRow m) {
    return Container(
      key: ValueKey(index),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('MMMM', 'th_TH').format(DateTime(2000, index + 1))} ${_year + 543}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _detailText('ยอดซื้อ', '฿${_money.format(m.amount)}'),
              _detailText('น้ำหนัก', '${_kg.format(m.kg)} กก.'),
              _detailText('ราคาเฉลี่ย', '${m.avgPrice.toStringAsFixed(2)} ฿'),
              _detailText('จำนวน', '${m.count} ครั้ง'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailText(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------- เกษตรกรอันดับต้น ----------

  Widget _buildTopFarmers(ShopReport r) {
    final maxKg = r.topFarmers.isEmpty ? 0.0 : r.topFarmers.first.kg;
    const medals = ['🥇', '🥈', '🥉'];
    return _card(
      title: 'เกษตรกรที่ขายให้มากที่สุด',
      child: r.topFarmers.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          : Column(
              children: List.generate(r.topFarmers.length, (i) {
                final f = r.topFarmers[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: i < 3
                            ? Text(medals[i], style: const TextStyle(fontSize: 20))
                            : Text(
                                '${i + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500]),
                              ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    f.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_kg.format(f.kg)} กก.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: maxKg == 0 ? 0 : f.kg / maxKg,
                                minHeight: 6,
                                backgroundColor: theme.soft,
                                color: theme.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${_money.format(f.amount)} · ${f.count} ครั้ง',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
