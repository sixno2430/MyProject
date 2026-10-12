// ============================================================
// admin_user_form_screen.dart — แอดมินเพิ่ม / แก้ไขบัญชีผู้ใช้
//
// ส่ง existing มา = แก้ไข (ชื่อผู้ใช้แก้ไม่ได้, รหัสผ่านเว้นว่าง = คงเดิม)
// ไม่ส่ง = เพิ่มบัญชีใหม่ เลือกประเภทได้เฉพาะ เกษตรกร / ร้านรับซื้อ
// บัญชีแอดมินล็อกไว้: ตั้งใครเป็นแอดมินไม่ได้ และแก้บัญชีแอดมินได้แต่ข้อมูลส่วนตัว (ประเภทบัญชีเปลี่ยนไม่ได้)
// server ตรวจซ้ำอีกชั้น: ชื่อผู้ใช้/เลขบัตรซ้ำ, บทบาทแอดมิน, เปลี่ยนประเภทบัญชีที่มีแปลง/ร้านแล้วไม่ได้
// บันทึกสำเร็จปิดหน้าด้วย true
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_myproject/services/admin_service.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/screens/admin/widgets/admin_widgets.dart';
import 'package:flutter_myproject/models/admin.dart';

class AdminUserFormScreen extends StatefulWidget {
  final AdminUser? existing;

  const AdminUserFormScreen({super.key, this.existing});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _citizenCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _roleId = 'R002';
  bool _saving = false;
  bool _showPassword = false;

  bool get _isEdit => widget.existing != null;
  bool get _isAdminAccount => widget.existing?.roleId == 'R001';

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    if (u != null) {
      _nameCtrl.text = u.fullName;
      _usernameCtrl.text = u.username;
      _citizenCtrl.text = u.citizenId;
      _phoneCtrl.text = u.phone;
      _roleId = u.roleId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _citizenCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AdminService.saveUser(
        id: widget.existing?.userId,
        roleId: _roleId,
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        citizenId: _citizenCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'บันทึกการแก้ไขเรียบร้อยแล้ว' : 'เพิ่มบัญชีผู้ใช้เรียบร้อยแล้ว')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit ? 'แก้ไขบัญชีผู้ใช้' : 'เพิ่มบัญชีผู้ใช้',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const AdminSectionTitle('ประเภทบัญชี'),
            AdminCard(child: _buildRolePicker()),
            const AdminSectionTitle('ข้อมูลส่วนตัว'),
            AdminCard(
              child: Column(
                children: [
                  _field(
                    'ชื่อ-นามสกุล',
                    _nameCtrl,
                    required: true,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                  ),
                  _field(
                    'เลขบัตรประชาชน',
                    _citizenCtrl,
                    hint: 'ตัวเลข 13 หลัก (ไม่บังคับ)',
                    digitsOnly: true,
                    maxLength: 13,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      return t.isEmpty || RegExp(r'^\d{13}$').hasMatch(t) ? null : 'เลขบัตรประชาชนต้องมี 13 หลัก';
                    },
                  ),
                  _field(
                    'เบอร์โทรศัพท์',
                    _phoneCtrl,
                    hint: 'เช่น 0812345678',
                    digitsOnly: true,
                    maxLength: 10,
                    last: true,
                  ),
                ],
              ),
            ),
            const AdminSectionTitle('ข้อมูลสำหรับเข้าสู่ระบบ'),
            AdminCard(
              child: Column(
                children: [
                  _field(
                    'ชื่อผู้ใช้ (Username)',
                    _usernameCtrl,
                    required: !_isEdit,
                    enabled: !_isEdit,
                    hint: _isEdit ? null : 'ใช้สำหรับเข้าสู่ระบบ',
                    helper: _isEdit ? 'ชื่อผู้ใช้ไม่สามารถเปลี่ยนแปลงได้' : null,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
                  ),
                  _field(
                    _isEdit ? 'รหัสผ่านใหม่' : 'รหัสผ่าน',
                    _passwordCtrl,
                    required: !_isEdit,
                    obscure: !_showPassword,
                    helper: _isEdit ? 'เว้นว่างไว้หากไม่ต้องการเปลี่ยนรหัสผ่าน' : 'อย่างน้อย 4 ตัวอักษร',
                    suffix: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                    last: true,
                    validator: (v) {
                      final t = v ?? '';
                      if (_isEdit && t.isEmpty) return null;
                      return t.length < 4 ? 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร' : null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isEdit ? 'บันทึกการแก้ไข' : 'สร้างบัญชี',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ],
        ),
      ),
    );
  }

  /// เลือกประเภทบัญชี: การ์ด 2 ใบ (เกษตรกร / ร้านรับซื้อ) — บัญชีแอดมินแสดงเป็นข้อความล็อกไว้
  Widget _buildRolePicker() {
    if (_isAdminAccount) {
      return const Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: AdminColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ผู้ดูแลระบบ — ประเภทบัญชีนี้ไม่สามารถเปลี่ยนแปลงได้',
              style: TextStyle(fontSize: 13, color: AdminColors.text),
            ),
          ),
        ],
      );
    }
    final options = [
      ('R002', Icons.agriculture_outlined, 'เกษตรกร', 'บันทึกแปลง การดูแล และผลผลิต'),
      ('R003', Icons.storefront_outlined, 'ร้านรับซื้อ', 'กำหนดราคาและรับซื้อผลผลิต'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IntrinsicHeight + stretch = การ์ดสองใบสูงเท่ากันแม้คำอธิบายยาวไม่เท่ากัน
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (id, icon, label, desc) in options) ...[
                if (id != options.first.$1) const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _roleId = id),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _roleId == id ? roleColor(id).withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _roleId == id ? roleColor(id) : AdminColors.border,
                          width: _roleId == id ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 20, color: roleColor(id)),
                              const Spacer(),
                              Icon(
                                _roleId == id ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                size: 18,
                                color: _roleId == id ? roleColor(id) : AdminColors.border,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(desc, style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_isEdit)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'หมายเหตุ: บัญชีที่มีข้อมูลแปลงสวนหรือร้านแล้ว จะเปลี่ยนประเภทบัญชีไม่ได้',
              style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
            ),
          ),
      ],
    );
  }

  /// ช่องกรอก 1 ช่อง (มีดอกจันแดงเมื่อบังคับ)
  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    bool digitsOnly = false,
    int? maxLength,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AdminColors.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            validator: validator,
            keyboardType: digitsOnly ? TextInputType.number : null,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            obscureText: obscure,
            enabled: enabled,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              hintStyle: const TextStyle(fontSize: 14, color: AdminColors.textMuted),
              counterText: '',
              isDense: true,
              suffixIcon: suffix,
              filled: true,
              fillColor: enabled ? Colors.white : AdminColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
