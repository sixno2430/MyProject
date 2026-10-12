// ============================================================
// admin_dashboard_screen.dart — หน้าหลักของผู้ดูแลระบบ (role R001)
//
// เข้าจากหน้าล็อกอิน (บัญชี R001 กดปุ่มบทบาทไหนก็เข้าหน้านี้)
// - ตัวชี้วัดหลัก 4 ช่อง: ผู้ใช้งาน, ผู้ใช้งานใน 7 วัน, แปลงสวน, ปริมาณรับซื้อเดือนนี้
// - เมนูจัดการ: บัญชีผู้ใช้ / ประวัติการใช้งาน / รายงานสรุป
// - กราฟผลผลิตทั้งชุมชน 6 เดือน, สรุปการซื้อขาย, กิจกรรมล่าสุด
// ข้อมูลทั้งหมดมาจาก AdminService (ดึงสดจากฐานข้อมูล) ดึงหน้าจอลงเพื่อโหลดใหม่
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/admin_service.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'admin_logs_screen.dart';
import 'admin_report_screen.dart';
import 'package:flutter_myproject/screens/admin/widgets/admin_widgets.dart';
import 'user_management_screen.dart';
import 'package:flutter_myproject/models/admin.dart';

/// หน้าภาพรวมสำหรับ Admin
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.getOverview();
  }

  Future<void> _reload() async {
    final future = AdminService.getOverview();
    setState(() {
      _future = future;
    });
    try {
      await future; // ให้วงหมุนของ RefreshIndicator หายตอนโหลดเสร็จ (error แสดงใน FutureBuilder แล้ว)
    } catch (_) {}
  }

  /// เปิดหน้าย่อย กลับมาแล้วโหลดตัวเลขใหม่ (เช่น เพิ่มผู้ใช้แล้ว)
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTheme(child: page)));
    if (mounted) _reload();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ยืนยันการออกจากระบบผู้ดูแลระบบ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ผู้ดูแลระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(formatThaiDate(DateTime.now()), style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'ออกจากระบบ', onPressed: _logout),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<AdminOverview>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return AdminErrorView(message: friendlyError(snap.error), onRetry: _reload);
            }
            final o = snap.data!;
            final harvestTotal = o.harvestMonthly.fold<double>(0, (s, e) => s + e.value);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildKpiGrid(o),
                const AdminSectionTitle('การจัดการระบบ'),
                _buildMenu(),
                const AdminSectionTitle('ข้อมูลการผลิตและการซื้อขาย'),
                AdminCard(
                  title: 'ผลผลิตรวมทั้งชุมชน',
                  subtitle: '6 เดือนล่าสุด · หน่วย กิโลกรัม',
                  trailing: _totalLabel('${formatNumber(harvestTotal)} กก.'),
                  child: MonthBarChart(data: o.harvestMonthly, color: AdminColors.farmer),
                ),
                _buildTradeSummary(o),
                AdminCard(
                  title: 'กิจกรรมล่าสุด',
                  subtitle: 'การเก็บเกี่ยว การรับซื้อ และผู้ใช้ใหม่',
                  child: o.recent.isEmpty
                      ? const AdminEmptyText('ยังไม่มีกิจกรรมในระบบ')
                      : Column(
                          children: [
                            for (var i = 0; i < o.recent.length; i++)
                              _buildActivity(o.recent[i], last: i == o.recent.length - 1),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ตัวเลขรวมด้านขวาของหัวกล่อง
  Widget _totalLabel(String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text('รวม', style: TextStyle(fontSize: 11, color: AdminColors.textMuted)),
      Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.text),
      ),
    ],
  );

  /// ตัวชี้วัดหลัก 4 ช่อง (2 x 2) แต่ละช่องมีตัวเลขใหญ่ + คำอธิบายย่อย
  Widget _buildKpiGrid(AdminOverview o) {
    final items = [
      (
        Icons.people_alt_outlined,
        AdminColors.primary,
        'ผู้ใช้งานทั้งหมด',
        formatNumber(o.userCount),
        'บัญชี',
        'เกษตรกร ${o.farmerCount} · ร้าน ${o.shopCount}',
      ),
      (
        Icons.login,
        AdminColors.success,
        'เข้าใช้งานใน 7 วัน',
        formatNumber(o.active7d),
        'บัญชี',
        'จากทั้งหมด ${o.userCount} บัญชี',
      ),
      (
        Icons.forest_outlined,
        AdminColors.farmer,
        'แปลงสวนในระบบ',
        formatNumber(o.gardenCount),
        'แปลง',
        'พื้นที่รวม ${formatNumber(o.gardenArea)} ไร่',
      ),
      (
        Icons.scale_outlined,
        AdminColors.shop,
        'รับซื้อเดือนนี้',
        formatNumber(o.monthPurchaseQty),
        'กก.',
        'มูลค่า ${formatNumber(o.monthPurchaseAmount)} บาท',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        for (final (icon, color, label, value, unit, caption) in items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminColors.text),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// เมนูจัดการ 3 รายการ อยู่ในกล่องเดียว คั่นด้วยเส้น
  Widget _buildMenu() {
    final menus = [
      (
        Icons.manage_accounts_outlined,
        'จัดการบัญชีผู้ใช้',
        'เพิ่ม แก้ไข และระงับการใช้งานบัญชี',
        const UserManagementScreen(),
      ),
      (Icons.history, 'ประวัติการใช้งานระบบ', 'การเข้าสู่ระบบและการทำรายการของผู้ใช้', const AdminLogsScreen()),
      (Icons.assessment_outlined, 'รายงานสรุประบบ', 'ผลผลิต การรับซื้อ และสถิติการใช้งาน', const AdminReportScreen()),
    ];
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < menus.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68, color: AdminColors.border),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => _open(menus[i].$4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AdminColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(menus[i].$1, color: AdminColors.primary),
              ),
              title: Text(
                menus[i].$2,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AdminColors.text),
              ),
              subtitle: Text(menus[i].$3, style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
              trailing: const Icon(Icons.chevron_right, color: AdminColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  /// สรุปการซื้อขาย: สัดส่วนล็อตรอขาย/ขายแล้ว + ยอดรับซื้อผ่านระบบทั้งหมด
  Widget _buildTradeSummary(AdminOverview o) {
    final total = o.harvestPending + o.harvestSold;
    final soldRatio = total == 0 ? 0.0 : o.harvestSold / total;
    return AdminCard(
      title: 'สรุปการซื้อขาย',
      subtitle: 'ล็อตผลผลิตทั้งหมด ${formatNumber(o.harvestCount)} ล็อต',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: soldRatio,
              minHeight: 10,
              color: AdminColors.success,
              backgroundColor: AdminColors.warning.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(AdminColors.success, 'ขายแล้ว ${o.harvestSold} ล็อต'),
              const SizedBox(width: 16),
              _legend(AdminColors.warning.withValues(alpha: 0.6), 'รอขาย ${o.harvestPending} ล็อต'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AdminColors.border),
          ),
          const Text('การรับซื้อผ่านระบบ (สะสม)', style: TextStyle(fontSize: 12, color: AdminColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              _figure(formatNumber(o.purchaseCount), 'รายการ'),
              _figure(formatNumber(o.purchaseQty), 'กิโลกรัม'),
              _figure(formatNumber(o.purchaseAmount), 'บาท'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: AdminColors.text)),
    ],
  );

  Widget _figure(String value, String unit) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.text),
        ),
        Text(unit, style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
      ],
    ),
  );

  /// แถวกิจกรรม 1 รายการ: ไอคอนตามประเภท + ใคร + รายละเอียด + วันที่
  Widget _buildActivity(RecentActivity a, {required bool last}) {
    final (icon, color, kind) = switch (a.type) {
      'harvest' => (Icons.agriculture_outlined, AdminColors.farmer, 'บันทึกการเก็บเกี่ยว'),
      'purchase' => (Icons.storefront_outlined, AdminColors.shop, 'รับซื้อผลผลิต'),
      _ => (Icons.person_add_alt_1_outlined, AdminColors.primary, 'ลงทะเบียนผู้ใช้ใหม่'),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  a.type == 'register' ? a.who : '${a.who} · ${a.detail}',
                  style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                ),
              ],
            ),
          ),
          if (a.at != null)
            Text(thaiShortDate(a.at!), style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
        ],
      ),
    );
  }
}
