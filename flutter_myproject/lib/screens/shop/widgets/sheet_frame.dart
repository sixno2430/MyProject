// ============================================================
// sheet_frame.dart — ส่วนประกอบของฟอร์มในหน้าร้าน (ใช้ร่วมกันในฟอร์มข้อมูลร้านและฟอร์มราคา)
//
// - SheetFrame     : กรอบหน้าต่างด้านล่าง หัวข้อ + ปุ่มปิด + เนื้อหาเลื่อนได้ หลบคีย์บอร์ด
// - sheetField     : ช่องกรอก 1 ช่อง (มีหัวข้อ ไอคอน หน่วย)
// - sheetDecoration: หน้าตาช่องกรอก โทนสีร้านรับซื้อ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/theme/role_theme.dart';

/// กรอบ bottom sheet: แถบจับ + หัวข้อ + เนื้อหา + ปุ่มบันทึก (ดันขึ้นตามคีย์บอร์ด)
class SheetFrame extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback? onSubmit;
  final Widget child;

  const SheetFrame({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onSubmit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = RoleTheme.shop;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: child),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration sheetDecoration(String label, IconData icon, {String? hint, String? suffix}) {
  final theme = RoleTheme.shop;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffix,
    prefixIcon: Icon(icon, color: theme.primary, size: 20),
    floatingLabelStyle: TextStyle(color: theme.primary),
    filled: true,
    fillColor: const Color(0xFFF9F7F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.primary, width: 1.5),
    ),
  );
}

Widget sheetField(
  TextEditingController c,
  String label,
  IconData icon, {
  String? hint,
  String? suffix,
  TextInputType? keyboard,
  String? Function(String?)? validator,
  ValueChanged<String>? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: validator,
      onChanged: onChanged,
      cursorColor: RoleTheme.shop.primary,
      decoration: sheetDecoration(label, icon, hint: hint, suffix: suffix),
    ),
  );
}
