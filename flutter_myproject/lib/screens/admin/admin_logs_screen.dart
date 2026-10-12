// ============================================================
// admin_logs_screen.dart — ประวัติการใช้งานระบบ (ตาราง USER_LOG)
//
// แสดง log ล่าสุด 200 รายการ: ใคร ทำอะไร เมื่อไร จาก IP ไหน จัดกลุ่มตามวัน
// กรองตามหมวดได้: การเข้าสู่ระบบ / เพิ่มข้อมูล / แก้ไข-ลบข้อมูล / การจัดการบัญชี (logCategories ใน admin_service.dart)
// ส่ง userId มา = ดูเฉพาะบัญชีนั้น (เปิดจากรายละเอียดบัญชีในหน้าจัดการผู้ใช้)
// log ถูกบันทึกฝั่ง server ตอนล็อกอินและตอนทำรายการสำคัญ (userAccount.logAction)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/admin_service.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/screens/admin/widgets/admin_widgets.dart';
import 'package:flutter_myproject/models/admin.dart';

class AdminLogsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const AdminLogsScreen({super.key, this.userId, this.userName});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  late Future<List<AdminLog>> _future;
  String? _actions; // null = ทุกหมวด, ไม่งั้นเป็น action ในหมวดคั่นด้วย comma

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminLog>> _load() => AdminService.getLogs(action: _actions, userId: widget.userId);

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  void _filter(String? actions) {
    _actions = actions;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ประวัติการใช้งานระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (widget.userName != null)
              Text('บัญชี: ${widget.userName}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final (label, actions) in logCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _actions == actions,
                        showCheckmark: false,
                        selectedColor: AdminColors.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: _actions == actions ? AdminColors.primary : AdminColors.border),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: _actions == actions ? Colors.white : AdminColors.text,
                        ),
                        onSelected: (_) => _filter(actions),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: FutureBuilder<List<AdminLog>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return AdminErrorView(message: friendlyError(snap.error), onRetry: _reload);
                  }
                  final logs = snap.data ?? [];
                  if (logs.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [AdminCard(child: AdminEmptyText('ไม่พบประวัติการใช้งานในหมวดนี้'))],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      for (final group in _groupByDay(logs)) ...[
                        AdminSectionTitle(group.$1),
                        AdminCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < group.$2.length; i++) ...[
                                if (i > 0) const Divider(height: 1, indent: 60, color: AdminColors.border),
                                _buildLog(group.$2[i]),
                              ],
                            ],
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'แสดงรายการล่าสุด ${logs.length} รายการ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// จัดกลุ่ม log ตามวัน -> [('วันนี้', [...]), ('เมื่อวาน', [...]), ('8 ต.ค. 2569', [...])]
  List<(String, List<AdminLog>)> _groupByDay(List<AdminLog> logs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <(String, List<AdminLog>)>[];
    for (final l in logs) {
      final d = DateTime.tryParse(l.logDate);
      String label = 'ไม่ทราบวันที่';
      if (d != null) {
        final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
        label = diff == 0 ? 'วันนี้' : (diff == 1 ? 'เมื่อวาน' : thaiShortDate(d));
      }
      if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
      groups.last.$2.add(l);
    }
    return groups;
  }

  /// ไอคอน + สีตามประเภทของการกระทำ: ลบ/ยกเลิก = แดง, แก้ไข = ส้ม, ร้าน = ส้มเข้ม, บัญชี = น้ำเงิน, เพิ่มข้อมูล = เขียว
  (IconData, Color) _style(String action) {
    if (action == 'LOGIN') return (Icons.login, AdminColors.primary);
    if (action == 'SUSPEND_USER' || action == 'REJECT_HARVEST') return (Icons.block, AdminColors.danger);
    if (action.startsWith('DELETE_') || action == 'CANCEL_PURCHASE') return (Icons.delete_outline, AdminColors.danger);
    if (action.startsWith('EDIT_') || action == 'CHANGE_PASSWORD') return (Icons.edit_outlined, AdminColors.warning);
    if (action.contains('PURCHASE') || action.contains('PRICE') || action.contains('SHOP')) {
      return (Icons.storefront_outlined, AdminColors.shop);
    }
    if (action.contains('USER') || action == 'REGISTER') return (Icons.manage_accounts_outlined, AdminColors.primary);
    return (Icons.add_circle_outline, AdminColors.farmer); // เพิ่มข้อมูลของเกษตรกร
  }

  /// IP จาก Node มักขึ้นต้นด้วย ::ffff: (IPv4 ที่ห่อเป็น IPv6) ตัดออกให้อ่านง่าย, ::1 = เครื่องเดียวกับเซิร์ฟเวอร์
  String _ip(String? ip) {
    if (ip == null || ip.isEmpty) return '';
    if (ip == '::1') return '127.0.0.1';
    return ip.replaceFirst('::ffff:', '');
  }

  Widget _buildLog(AdminLog l) {
    final (icon, color) = _style(l.action);
    final d = DateTime.tryParse(l.logDate);
    final ip = _ip(l.ipAddress);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  logActionLabels[l.action] ?? l.action,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l.fullName} (${l.username})',
                  style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                ),
                if (ip.isNotEmpty) Text('IP $ip', style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
              ],
            ),
          ),
          if (d != null) Text(thaiTime(d), style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
        ],
      ),
    );
  }
}
