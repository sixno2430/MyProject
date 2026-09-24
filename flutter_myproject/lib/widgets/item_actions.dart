import 'package:flutter/material.dart';

enum ItemAction { edit, delete }

/// เมนูด้านล่างจอให้เลือก "แก้ไข" หรือ "ลบ" (ใช้ตอนกดค้างที่รายการ)
Future<ItemAction?> showItemActionsSheet(BuildContext context, {bool canEdit = true}) {
  return showModalBottomSheet<ItemAction>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (canEdit)
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF2D6A4F)),
              title: const Text('แก้ไข'),
              onTap: () => Navigator.pop(context, ItemAction.edit),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
            title: const Text('ลบ', style: TextStyle(color: Color(0xFFD32F2F))),
            onTap: () => Navigator.pop(context, ItemAction.delete),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// กล่องยืนยันก่อนลบ คืนค่า true ถ้าผู้ใช้กด "ลบ"
Future<bool> confirmDelete(BuildContext context, String name) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('ยืนยันการลบ'),
      content: Text('ต้องการลบ "$name" ใช่หรือไม่?\nข้อมูลที่ลบแล้วจะกู้คืนไม่ได้'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('ลบ'),
        ),
      ],
    ),
  );
  return confirm == true;
}
