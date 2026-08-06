import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_myproject/screens/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers สำหรับดึงค่าจากฟอร์ม
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int selectedRole = 0;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> roles = [
    {'label': 'เกษตรกร', 'icon': Icons.agriculture},
    {'label': 'ร้านรับซื้อ', 'icon': Icons.store},
  ];

  // ============================================
  // 🔥 _registerAPI() - ส่งข้อมูลไปเซิร์ฟเวอร์
  // ============================================
  Future<bool> _registerAPI() async {

    //ใช้สำหรับมีApiนะจ๊ะ
    try {
      // 1. กำหนด URL ของ API
      // ถ้ารันบนเครื่องจริง: ใช้ IP จริง เช่น 'https://yourserver.com/api/register'
      // ถ้ารันบน emulator: ใช้ 'http://10.0.2.2:8000/api/register' (ชี้ไป localhost ของคอม)
      final url = Uri.parse('https://your-api.com/api/register');

      // 2. เตรียมข้อมูลที่จะส่ง (Map → JSON)
      final bodyData = {
        'role': roles[selectedRole]['label'],      // 'เกษตรกร' หรือ 'ร้านรับซื้อ'
        'full_name': _nameController.text.trim(),   // 'ฟีฟ่า วิดยา'
        'id_card': _idCardController.text.trim(),   // '1-2345-67890-12-3'
        'phone': _phoneController.text.trim(),      // '081-234-5678'
        'username': _usernameController.text.trim(), // 'fifa123'
        'password': _passwordController.text,        // 'password123'
      };

      print('📤 ส่งข้อมูล: $bodyData'); // ดูข้อมูลใน console

      // 3. ส่ง HTTP POST Request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',  // บอกเซิร์ฟเวอร์ว่าเป็น JSON
          'Accept': 'application/json',        // รับคืนเป็น JSON
        },
        body: jsonEncode(bodyData),  // แปลง Map → String JSON
      );

      print('📥 ตอบกลับ: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      // 4. ตรวจสอบผลลัพธ์
      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ สำเร็จ! (200=OK, 201=Created)
        final data = jsonDecode(response.body);
        print('✅ สมัครสำเร็จ: ${data['message']}');
        return true;

      } else {
        // ❌ ผิดพลาด (400, 401, 422, 500, etc.)
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'สมัครไม่สำเร็จ');
      }

    } catch (e) {
      // ❌ Error เช่น ไม่มีเน็ต, เซิร์ฟเวอร์ล่ม, URL ผิด
      print('❌ Error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF064E3B), Color(0xFF15803D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF86EFAC), size: 16),
                        label: const Text('กลับ', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 14)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('กรอกข้อมูลให้ครบถ้วน', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Form Card
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role Selector
                          const Text('ประเภทผู้ใช้', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(roles.length, (index) {
                              final isSelected = selectedRole == index;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: index < roles.length - 1 ? 10 : 0),
                                  child: GestureDetector(
                                    onTap: () => setState(() => selectedRole = index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF15803D) : const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(14),
                                        border: isSelected ? null : Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(roles[index]['icon'] as IconData, size: 16, color: isSelected ? Colors.white : const Color(0xFF15803D)),
                                          const SizedBox(width: 6),
                                          Text(roles[index]['label'] as String, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF15803D), fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),

                          // ช่องกรอกข้อมูลทั้งหมด
                          _buildLabel('ชื่อ-นามสกุล'),
                          _buildTextField(controller: _nameController, hintText: 'ฟีฟ่า วิดยา', validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null),
                          const SizedBox(height: 14),

                          _buildLabel('เลขบัตรประชาชน'),
                          _buildTextField(controller: _idCardController, hintText: 'X-XXXX-XXXXX-XX-X', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'กรุณากรอกเลขบัตร' : null),
                          const SizedBox(height: 14),

                          _buildLabel('เบอร์โทรศัพท์'),
                          _buildTextField(controller: _phoneController, hintText: '08X-XXX-XXXX', keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null),
                          const SizedBox(height: 14),

                          _buildLabel('Username'),
                          _buildTextField(controller: _usernameController, hintText: 'ตั้งชื่อผู้ใช้งาน', validator: (v) => v!.isEmpty ? 'กรุณาตั้งชื่อผู้ใช้' : null),
                          const SizedBox(height: 14),

                          _buildLabel('รหัสผ่าน'),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'อย่างน้อย 8 ตัวอักษร',
                            obscureText: obscurePassword,
                            validator: (v) {
                              if (v!.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                              if (v.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัว';
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF), size: 20),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildLabel('ยืนยันรหัสผ่าน'),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: 'กรอกรหัสผ่านอีกครั้ง',
                            obscureText: obscureConfirmPassword,
                            validator: (v) {
                              if (v!.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                              if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF), size: 20),
                              onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 🔥 ปุ่ม "เสร็จสิ้น" - เรียก _registerAPI()
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF064E3B)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFF064E3B).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () async {
                                // 1. Validate ฟอร์มก่อน
                                if (!_formKey.currentState!.validate()) return;

                                // 2. แสดง Loading
                                setState(() => _isLoading = true);

                                // 3. เรียก API
                                final success = await _registerAPI();

                                // 4. ซ่อน Loading
                                setState(() => _isLoading = false);

                                // 5. ถ้าสำเร็จ → ไปหน้า Login
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!'), backgroundColor: Color(0xFF22C55E)),
                                  );
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('เสร็จสิ้น', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 8),
                                        Icon(Icons.check, color: Colors.white, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w500)));
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF0FDF4).withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF15803D), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        suffixIcon: suffixIcon,
      ),
    );
  }
}