// ============================================================
// user_detail_sheet.dart — รายละเอียดบัญชีผู้ใช้ (แผ่นด้านล่างในหน้าจัดการบัญชี)
//
// - UserAvatar     : วงกลมตัวอักษรแรกของชื่อ สีตามบทบาท
// - UserDetailSheet: ข้อมูลบัญชี + ปุ่ม แก้ไขข้อมูล / ประวัติการใช้งาน / ระงับหรือเปิดใช้บัญชี
//   ปิดแผ่นพร้อมส่งชื่อการกระทำ (edit / logs / suspend / activate) กลับไปให้หน้าจัดการบัญชี
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/admin/admin_widgets.dart';
import 'package:flutter_myproject/models/admin.dart';

/// วงกลมตัวอักษรแรกของชื่อ
class UserAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double radius;

  const UserAvatar({super.key, required this.name, required this.color, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: radius * 0.8),
      ),
    );
  }
}

/// แผ่นรายละเอียดบัญชี: ข้อมูลทั้งหมด + ปุ่มจัดการ (ปิดแผ่นพร้อมส่งชื่อการกระทำกลับไป)
class UserDetailSheet extends StatelessWidget {
  final AdminUser user;
  const UserDetailSheet({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final color = roleColor(u.roleId);
    final lastLogin = DateTime.tryParse(u.lastLogin ?? '');
    final created = DateTime.tryParse(u.createdAt ?? '');
    final related = switch (u.roleId) {
      'R002' => ('แปลงสวน', '${u.gardenCount} แปลง'),
      'R003' => ('ร้านรับซื้อ', u.shopName ?? 'ยังไม่ได้ตั้งค่าข้อมูลร้าน'),
      _ => ('สิทธิ์การใช้งาน', 'ผู้ดูแลระบบ'),
    };
    final rows = [
      ('ชื่อผู้ใช้', u.username),
      ('เบอร์โทรศัพท์', u.phone.isEmpty ? '-' : u.phone),
      ('เลขบัตรประชาชน', maskCitizenId(u.citizenId)),
      related,
      ('วันที่ลงทะเบียน', created == null ? '-' : thaiShortDate(created)),
      ('เข้าสู่ระบบล่าสุด', lastLogin == null ? 'ยังไม่มีประวัติ' : thaiDateTime(lastLogin)),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AdminColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                UserAvatar(name: u.fullName, color: color, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.text),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusPill(u.roleLabel, color),
                          const SizedBox(width: 6),
                          u.isSuspended
                              ? const StatusPill('ถูกระงับ', AdminColors.danger)
                              : const StatusPill('ใช้งานปกติ', AdminColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: AdminColors.background, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  for (final (label, value) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(label, style: const TextStyle(fontSize: 13, color: AdminColors.textMuted)),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, color: AdminColors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'edit'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('แก้ไขข้อมูล'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'logs'),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('ประวัติการใช้งาน'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            u.isSuspended
                ? FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'activate'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('เปิดใช้งานบัญชี'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => Navigator.pop(context, 'suspend'),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('ระงับการใช้งานบัญชี'),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
