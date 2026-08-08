import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/auth/register_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_myproject/screens/main/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  int selectedRole = 0;
  bool obscurePassword = true;

  final List<Map<String, dynamic>> roles = [
    {'label': 'เกษตรกร', 'icon': Icons.agriculture},
    {'label': 'ร้านค้า', 'icon': Icons.store},
  ];

  // ขั้นที่ 1: เช็ค username/password กับ server -> ได้ authenToken (อายุสั้น)
  Future<(bool, String, String)> _authenRequest() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUri}/authen_request"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    final json = jsonDecode(response.body);

    return (
      json["isError"] as bool,
      json["data"] as String,
      json["errorMessage"] as String,
    );
  }

  // ขั้นที่ 2: เอา authenToken ไปแลก accessToken (อายุยาวขึ้น)
  Future<({bool isError, String errorMessage, String data})> _accessRequest(
    String token,
  ) async {
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUri}/access_request"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'token': token}),
    );

    final json = jsonDecode(response.body);

    return (
      isError: json["isError"] as bool,
      errorMessage: json["errorMessage"] as String,
      data: json["data"] as String,
    );
  }

  // เก็บ accessToken ลง SharedPreferences เพื่อใช้เรียก API อื่นๆ ต่อไป
  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
  }

  void _doLogin(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      var (isError, authenToken, errorMessage) = await _authenRequest();

      if (isError) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(content: Text(errorMessage));
            },
          );
        }
      } else {
        var result = await _accessRequest(authenToken);

        setState(() => _isLoading = false);

        if (result.isError) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(content: Text(result.errorMessage));
              },
            );
          }
        } else {
          await _saveAccessToken(result.data);

          print("Login success! access_token: ${result.data}");

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("เข้าสู่ระบบสำเร็จ"),
                backgroundColor: Color(0xFF22C55E),
                duration: Duration(seconds: 2),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("เกิดข้อผิดพลาดตอน login: $e");
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(content: Text("เกิดข้อผิดพลาด: $e"));
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Center(
                    child: Text('🌴', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PalmTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ระบบจัดการสวนปาล์มน้ำมัน',
                  style: TextStyle(color: Color(0xFF86EFAC), fontSize: 14),
                ),
                const SizedBox(height: 32),
                // Login Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Selector
                      const Text(
                        'เลือกบทบาท',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(roles.length, (index) {
                          final isSelected = selectedRole == index;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < roles.length - 1 ? 8 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedRole = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFFBBF7D0),
                                          ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        roles[index]['icon'] as IconData,
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF15803D),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        roles[index]['label'] as String,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF15803D),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Username
                      const Text(
                        'ชื่อผู้ใช้',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'กรอกชื่อผู้ใช้',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF15803D),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password
                      const Text(
                        'รหัสผ่าน',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          suffixIcon: TextButton(
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            child: Text(
                              'แสดง',
                              style: TextStyle(
                                color: const Color(0xFF15803D),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF15803D),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Login Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _doLogin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Forgot Password
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // สมัครสมาชิก
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'สมัครสมาชิก',
                          style: TextStyle(color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
