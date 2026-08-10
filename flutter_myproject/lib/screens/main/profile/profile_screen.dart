import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);
  final Color lightGreen = const Color(0xFF40916C);
  final Color bgColor = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Header เขียว
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text('👨‍🌾', style: TextStyle(fontSize: 44)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'สมชาย มีทรัพย์',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👨‍🌾 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'เกษตรกร · PalmTrack',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'U001 · สมชาย',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ข้อมูลส่วนตัว
          SliverToBoxAdapter(
            child: _buildCard(
              title: 'ข้อมูลส่วนตัว',
              child: Column(
                children: [
                  _buildInfoRow('ชื่อ-นามสกุล', 'สมชาย มีทรัพย์'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildInfoRow('เบอร์โทร', '081-234-5678'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildInfoRow('เลขบัตรประชาชน', '1-9001-00000-00-0'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildBadgeRow('บทบาท', '👨‍🌾 เกษตรกร'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildInfoRow('สมาชิกตั้งแต่', '1 มกราคม 2566'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildInfoRow('ชื่อผู้ใช้', 'somchai'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ปุ่มแก้ไข
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('✏️', style: TextStyle(fontSize: 16)),
                label: const Text(
                  'แก้ไขข้อมูลส่วนตัว',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // การตั้งค่า
          SliverToBoxAdapter(
            child: _buildCard(
              title: 'การตั้งค่า',
              child: Column(
                children: [
                  _buildSettingTile(icon: '🔒', title: 'เปลี่ยนรหัสผ่าน', onTap: () {}),
                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(icon: '🔔', title: 'การแจ้งเตือน', onTap: () {}),
                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(
                    icon: '🌐',
                    title: 'ภาษา / Language',
                    trailing: const Text('ภาษาไทย', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(
                    icon: 'ℹ️',
                    title: 'เกี่ยวกับแอป',
                    trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {},
                label: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 223, 85, 85),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
      
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: lightGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lightGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 24,
    );
  }
}