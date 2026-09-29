// ============================================================
// change_password_screen.dart — หน้าเปลี่ยนรหัสผ่าน
//
// ต้องกรอกรหัสเดิมให้ถูก และรหัสใหม่อย่างน้อย 8 ตัว
// ส่งไป PUT /api/user/:userId/password (เซิร์ฟเวอร์ตรวจรหัสเดิมอีกครั้ง)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';

/// หน้าเปลี่ยนรหัสผ่าน (เปิดจากเมนูในหน้าโปรไฟล์)
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final _formKey = GlobalKey<FormState>();

  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// ตรวจฟอร์มแล้วส่งรหัสเดิม/ใหม่ไปเซิร์ฟเวอร์ สำเร็จแล้วปิดหน้า
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      _showMessage('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUri}/user/$userId/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'old_password': _oldController.text,
          'new_password': _newController.text,
        }),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) {
        throw Exception(body['errorMessage'] ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ');
      }
      if (!mounted) return;
      _showMessage('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว', success: true);
      Navigator.pop(context);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// แสดงข้อความแจ้งเตือน (สีเขียว = สำเร็จ, สีแดง = ผิดพลาด)
  void _showMessage(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? const Color(0xFF22C55E) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(
                label: 'รหัสผ่านเดิม',
                controller: _oldController,
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่านเดิม' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'รหัสผ่านใหม่',
                controller: _newController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่านใหม่';
                  if (v.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
                  if (v == _oldController.text) return 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสเดิม';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'ยืนยันรหัสผ่านใหม่',
                controller: _confirmController,
                obscure: _obscureNew,
                validator: (v) => v != _newController.text ? 'รหัสผ่านไม่ตรงกัน' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ช่องกรอกรหัสผ่าน มีปุ่มแสดง/ซ่อนรหัส
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggle,
              ),
      ),
    );
  }
}
