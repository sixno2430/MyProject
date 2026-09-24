import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        title: const Text('จัดการผู้ใช้งาน', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // แท็บกรอง
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('ทั้งหมด', true),
                const SizedBox(width: 8),
                _buildFilterChip('Admin', false),
                const SizedBox(width: 8),
                _buildFilterChip('เกษตรกร', false),
                const SizedBox(width: 8),
                _buildFilterChip('ร้านค้า', false),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildUserCard(
                  name: 'สมชาย มีทรัพย์',
                  phone: '081-234-5678',
                  role: 'เกษตรกร',
                  status: 'ใช้งาน',
                  color: Colors.green,
                ),
                _buildUserCard(
                  name: 'รวย พาณิชย์',
                  phone: '089-111-2233',
                  role: 'เกษตรกร',
                  status: 'ใช้งาน',
                  color: Colors.green,
                ),
                _buildUserCard(
                  name: 'สมหญิง สวยงาม',
                  phone: '085-567-8901',
                  role: 'Admin',
                  status: 'ใช้งาน',
                  color: Colors.blue,
                ),
                _buildUserCard(
                  name: 'กลมกล่อม จ่ายดี',
                  phone: '077-123-4567',
                  role: 'ร้านค้า',
                  status: 'รออนุมัติ',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E40AF) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required String name,
    required String phone,
    required String role,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Text(name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(role, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}