// ============================================================
// shop_dashboard_screen.dart — แดชบอร์ดภาพรวมร้านรับซื้อ (ภาพ 4.3.1)
// ============================================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  bool _isLoading = true;
  String _shopName = 'ร้านรับซื้อ';
  String _shopId = 'S001';
  Map<String, dynamic> _summary = {
    'total_kg': 0.0,
    'total_farmers': 0,
    'total_amount': 0.0,
    'latest_price': 0.0,
  };
  List<dynamic> _recentPurchases = [];

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await AuthService.getUserId() ?? '';
      
      // 1. ดึงข้อมูลโปรไฟล์ร้านค้าตาม user_id
      final profileRes = await http.get(
        Uri.parse('${AppConfig.apiBaseUri}/shop/profile/$userId'),
      );
      final profileJson = jsonDecode(profileRes.body);

      if (!profileJson['isError'] && profileJson['data'] != null) {
        _shopId = profileJson['data']['shop_id'] ?? 'S001';
        _shopName = profileJson['data']['shop_name'] ?? 'ร้านรับซื้อ';
      }

      // 2. ดึงข้อมูลแดชบอร์ดตาม shop_id
      final dashRes = await http.get(
        Uri.parse('${AppConfig.apiBaseUri}/shop/$_shopId/dashboard'),
      );
      final dashJson = jsonDecode(dashRes.body);

      if (!dashJson['isError'] && dashJson['data'] != null) {
        setState(() {
          _summary = dashJson['data']['summary'] ?? _summary;
          _recentPurchases = dashJson['data']['recentPurchases'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loadShopData: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ล้าง token และ user_id ทั้งหมดในเครื่อง (ไม่ error แดงแน่นอน)
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _shopName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF15803D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShopData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF15803D)))
          : RefreshIndicator(
              onRefresh: _loadShopData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // การ์ดสรุป 4 การ์ด
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSummaryCard(
                          title: 'ยอดรับซื้อรวม',
                          value: '${_summary['total_kg']} กก.',
                          icon: Icons.scale,
                          color: const Color(0xFF15803D),
                        ),
                        _buildSummaryCard(
                          title: 'เกษตรกรที่มาขาย',
                          value: '${_summary['total_farmers']} ราย',
                          icon: Icons.people,
                          color: const Color(0xFF0284C7),
                        ),
                        _buildSummaryCard(
                          title: 'ยอดเงินจ่ายรวม',
                          value: '${_summary['total_amount']} ฿',
                          icon: Icons.payments,
                          color: const Color(0xFFD97706),
                        ),
                        _buildSummaryCard(
                          title: 'ราคาล่าสุด (เกรด A)',
                          value: '${_summary['latest_price']} ฿/กก.',
                          icon: Icons.price_check,
                          color: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // เมนูจัดการร้านค้า
                    const Text(
                      'การจัดการร้านค้า',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildActionButton('บันทึกรับซื้อ', Icons.add_shopping_cart, const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _buildActionButton('กำหนดราคา', Icons.tune, const Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        _buildActionButton('รายงานสรุป', Icons.bar_chart, const Color(0xFF2563EB)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ประวัติรายการรับซื้อล่าสุด
                    const Text(
                      'รายการรับซื้อล่าสุด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_recentPurchases.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ยังไม่มีรายการรับซื้อ',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentPurchases.length,
                        itemBuilder: (context, index) {
                          final item = _recentPurchases[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFDCFCE7),
                                child: Icon(Icons.person, color: Color(0xFF15803D)),
                              ),
                              title: Text(
                                item['farmer_name'] ?? 'ไม่ระบุชื่อ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('วันที่: ${item['purchase_date']?.toString().split('T')[0] ?? ''}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['quantity']} กก.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  Text(
                                    '${item['total_price']} ฿',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}