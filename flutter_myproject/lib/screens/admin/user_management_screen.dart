// ============================================================
// user_management_screen.dart — จัดการบัญชีผู้ใช้ (ผู้ดูแลระบบ)
//
// ดึงจาก AdminService.getUsers() กรองตามประเภทบัญชี / บัญชีที่ถูกระงับ และค้นหาชื่อ / username / เบอร์โทรได้
// แตะรายการ = เปิดรายละเอียดบัญชี (ข้อมูลส่วนตัว, เข้าสู่ระบบล่าสุด) พร้อมปุ่ม
//   แก้ไขข้อมูล / ประวัติการใช้งาน / ระงับหรือเปิดใช้บัญชี
// ปุ่ม "เพิ่มบัญชี" = สร้างบัญชีเกษตรกรหรือร้านรับซื้อ (บัญชีแอดมินล็อกไว้ เพิ่มผ่านแอปไม่ได้)
// ไม่มีปุ่มลบบัญชี: ใช้ระงับแทน เพราะลบแล้วข้อมูลแปลง/การซื้อขายที่ผูกกับบัญชีจะหายตามไปด้วย
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/admin_service.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'admin_logs_screen.dart';
import 'admin_user_form_screen.dart';
import 'package:flutter_myproject/screens/admin/widgets/admin_widgets.dart';
import 'package:flutter_myproject/models/admin.dart';
import 'package:flutter_myproject/screens/admin/widgets/user_detail_sheet.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<AdminUser>> _future;
  String? _filter; // null = ทั้งหมด, 'R002' / 'R003' / 'R001' = ประเภทบัญชี, 'suspended' = ถูกระงับ
  String _keyword = '';

  static const _filters = [
    (null, 'ทั้งหมด'),
    ('R002', 'เกษตรกร'),
    ('R003', 'ร้านรับซื้อ'),
    ('R001', 'ผู้ดูแลระบบ'),
    ('suspended', 'ถูกระงับ'),
  ];

  bool _matchFilter(AdminUser u, String? filter) =>
      filter == null || (filter == 'suspended' ? u.isSuspended : u.roleId == filter);

  @override
  void initState() {
    super.initState();
    _future = AdminService.getUsers();
  }

  Future<void> _reload() async {
    final future = AdminService.getUsers();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  /// เปิดฟอร์มเพิ่ม (existing = null) หรือแก้ไขบัญชี
  Future<void> _openForm([AdminUser? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminTheme(child: AdminUserFormScreen(existing: existing)),
      ),
    );
    if (saved == true) _reload();
  }

  /// แผ่นรายละเอียดบัญชีด้านล่างจอ + ปุ่มจัดการ
  Future<void> _showDetail(AdminUser u) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => UserDetailSheet(user: u),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'edit':
        _openForm(u);
      case 'logs':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminTheme(
              child: AdminLogsScreen(userId: u.userId, userName: u.fullName),
            ),
          ),
        );
      case 'suspend':
      case 'activate':
        _setSuspended(u, action == 'suspend');
    }
  }

  Future<void> _setSuspended(AdminUser u, bool suspend) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suspend ? 'ระงับการใช้งานบัญชี' : 'เปิดใช้งานบัญชี'),
        content: Text(
          suspend
              ? 'บัญชี "${u.fullName}" จะไม่สามารถเข้าสู่ระบบได้จนกว่าจะเปิดใช้งานอีกครั้ง\nข้อมูลเดิมของบัญชีจะยังอยู่ครบถ้วน'
              : 'บัญชี "${u.fullName}" จะกลับมาเข้าสู่ระบบได้ตามปกติ',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: suspend ? AdminColors.danger : AdminColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: Text(suspend ? 'ระงับบัญชี' : 'เปิดใช้งาน'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.setSuspended(u.userId, suspend);
      _toast(suspend ? 'ระงับการใช้งานบัญชีเรียบร้อยแล้ว' : 'เปิดใช้งานบัญชีเรียบร้อยแล้ว');
      _reload();
    } catch (e) {
      _toast(friendlyError(e));
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('จัดการบัญชีผู้ใช้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('เพิ่มบัญชี', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<List<AdminUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AdminErrorView(message: friendlyError(snap.error), onRetry: _reload);
          }
          final all = snap.data ?? [];
          final shown = all.where((u) {
            if (!_matchFilter(u, _filter)) return false;
            if (_keyword.isEmpty) return true;
            return u.fullName.toLowerCase().contains(_keyword) ||
                u.username.toLowerCase().contains(_keyword) ||
                u.phone.contains(_keyword);
          }).toList();

          return Column(
            children: [
              _buildToolbar(all),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), // เว้นล่างให้พ้นปุ่มเพิ่มบัญชี
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'แสดง ${shown.length} จาก ${all.length} บัญชี',
                          style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                        ),
                      ),
                      if (shown.isEmpty)
                        const AdminCard(child: AdminEmptyText('ไม่พบบัญชีที่ตรงกับเงื่อนไข'))
                      else
                        AdminCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < shown.length; i++) ...[
                                if (i > 0) const Divider(height: 1, indent: 72, color: AdminColors.border),
                                _buildUserRow(shown[i]),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ส่วนบน: ช่องค้นหา + ตัวกรองประเภทบัญชี (มีจำนวนในวงเล็บ)
  Widget _buildToolbar(List<AdminUser> all) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _keyword = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อ ชื่อผู้ใช้ หรือเบอร์โทรศัพท์',
              hintStyle: const TextStyle(fontSize: 14, color: AdminColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AdminColors.textMuted),
              isDense: true,
              filled: true,
              fillColor: AdminColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$label (${all.where((u) => _matchFilter(u, value)).length})'),
                      selected: _filter == value,
                      showCheckmark: false,
                      selectedColor: AdminColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _filter == value ? AdminColors.primary : AdminColors.border),
                      labelStyle: TextStyle(fontSize: 13, color: _filter == value ? Colors.white : AdminColors.text),
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// แถวบัญชี 1 รายการ: ชื่อ + สถานะ, ประเภทบัญชี · username, เข้าสู่ระบบล่าสุด
  Widget _buildUserRow(AdminUser u) {
    final color = roleColor(u.roleId);
    final lastLogin = DateTime.tryParse(u.lastLogin ?? '');
    return InkWell(
      onTap: () => _showDetail(u),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(name: u.fullName, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AdminColors.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (u.isSuspended) const StatusPill('ถูกระงับ', AdminColors.danger),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${u.roleLabel} · ${u.username}',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastLogin == null
                        ? 'ยังไม่มีประวัติการเข้าสู่ระบบ'
                        : 'เข้าสู่ระบบล่าสุด ${thaiDateTime(lastLogin)}',
                    style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AdminColors.textMuted),
          ],
        ),
      ),
    );
  }
}
