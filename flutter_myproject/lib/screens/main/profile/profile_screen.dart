// ============================================================
// profile_screen.dart — แท็บ "โปรไฟล์"
//
// แสดงข้อมูลผู้ใช้, แก้ไขชื่อ/เบอร์โทร, เปลี่ยนรหัสผ่าน และออกจากระบบ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/profile_service.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:flutter_myproject/screens/main/profile/change_password_screen.dart';
import 'package:flutter_myproject/notifications/notifications_screen.dart';

/// แท็บโปรไฟล์
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  String? errorMessage;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  /// ดึง user_id จาก AuthService (คนที่ล็อคอิน)
  Future<void> _loadUserId() async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      setState(() {
        errorMessage = 'กรุณาเข้าสู่ระบบใหม่';
        isLoading = false;
      });
      return;
    }

    setState(() {
      currentUserId = userId;
    });

    _loadProfile();
  }

  /// ดึงข้อมูลโปรไฟล์จาก API
  Future<void> _loadProfile() async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ProfileService.getProfile(currentUserId!);

    if (result['success'] == true) {
      setState(() {
        profile = result['profile'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'ไม่สามารถโหลดข้อมูลได้';
        isLoading = false;
      });
    }
  }

  /// หน้าต่าง Modal Bottom Sheet สำหรับแก้ไขข้อมูลส่วนตัว
  void _showEditProfileSheet() {
    if (profile == null) return;

    final nameController =
        TextEditingController(text: profile!['full_name'] ?? '');
    final phoneController =
        TextEditingController(text: profile!['phone'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แก้ไขข้อมูลส่วนตัว',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // ช่องกรอกชื่อ-นามสกุล
              const Text(
                'ชื่อ-นามสกุล',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'กรอกชื่อและนามสกุล',
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ช่องกรอกเบอร์โทรศัพท์
              const Text(
                'เบอร์โทรศัพท์',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'กรอกเบอร์โทรศัพท์',
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          final newPhone = phoneController.text.trim();

                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);

                          final updateRes = await ProfileService.updateProfile(
                            currentUserId!,
                            {
                              'full_name': newName,
                              'phone': newPhone,
                            },
                          );

                          setModalState(() => isSaving = false);

                          if (updateRes['success'] == true) {
                            if (context.mounted) Navigator.pop(context);
                            _loadProfile(); // โหลดข้อมูลใหม่มาแสดงทันที
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('บันทึกข้อมูลส่วนตัวเรียบร้อยแล้ว'),
                                  backgroundColor: Color(0xFF4A7C59),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(updateRes['message'] ??
                                      'เกิดข้อผิดพลาดในการบันทึก'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7C59),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserId,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    final p = profile!;
    final role = p['role'] ?? {'role_name': 'ผู้ใช้'};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A7C59),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Text('👨‍🌾', style: TextStyle(fontSize: 50)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p['full_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${role['role_name']} · PalmTrack',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p['user_id']} · ${role['role_name']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              // ── ข้อมูลส่วนตัว ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ข้อมูลส่วนตัว',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow('ชื่อ-นามสกุล', p['full_name']),
                        _buildInfoRow('เบอร์โทร', p['phone']),
                        _buildInfoRow('เลขบัตรประชาชน', p['citizen_id']),
                        _buildInfoRowWithBadge('บทบาท', role['role_name'] ?? '-'),
                        _buildInfoRow('สมาชิกตั้งแต่', p['member_since']),
                        _buildInfoRow('ชื่อผู้ใช้', p['username']),
                      ],
                    ),
                  ),
                ),
              ),

              // ── ปุ่มแก้ไข ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showEditProfileSheet,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'แก้ไขข้อมูลส่วนตัว',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C59),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── การตั้งค่า ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.lock,
                        title: 'เปลี่ยนรหัสผ่าน',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        icon: Icons.notifications,
                        title: 'การแจ้งเตือน',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        icon: Icons.language,
                        title: 'ภาษา / Language',
                        trailing: 'ภาษาไทย',
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('ภาษา / Language'),
                            content: const Text(
                                'แอปเวอร์ชันนี้รองรับภาษาไทยเท่านั้น\nThis version supports Thai only.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('ตกลง'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        icon: Icons.info,
                        title: 'เกี่ยวกับแอป',
                        trailing: 'v1.0.0',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'PalmTrack',
                          applicationVersion: 'v1.0.0',
                          applicationIcon: const Text('🌴',
                              style: TextStyle(fontSize: 40)),
                          children: const [
                            Text(
                                'ระบบจัดการสวนปาล์มน้ำมัน: บันทึกแปลงสวน การดูแล '
                                'การเก็บเกี่ยว รายรับ-รายจ่าย และดูรายงานสรุปรายปี'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── ปุ่มออกจากระบบ ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService.clear();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// แถวข้อมูล (หัวข้อ + ค่า)
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value ?? '-',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// แถวข้อมูลที่แสดงค่าเป็นป้าย (เช่น บทบาทผู้ใช้)
  Widget _buildInfoRowWithBadge(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👨‍🌾', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A7C59),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// แถวเมนูการตั้งค่า (ไอคอน + ชื่อ + ลูกศร)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: trailing != null
          ? Text(trailing, style: TextStyle(color: Colors.grey[500]))
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}