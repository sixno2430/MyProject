import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'package:flutter_myproject/screens/garden/harvest/harvest_screen.dart' show HarvestData;
import 'package:flutter_myproject/screens/garden/harvest/add_harvest_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/add_gardencare_screen.dart';
import 'package:flutter_myproject/screens/finance/finance_screen.dart' show TransactionItem;
import 'package:flutter_myproject/screens/finance/add_transaction_screen.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_type_badge.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/utils/formatters.dart';

class ActivityDetailScreen extends StatelessWidget {
  final ActivityItem activity;
  const ActivityDetailScreen({super.key, required this.activity});

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  // เปิดฟอร์มแก้ไขให้ตรงประเภท โดยแปลงข้อมูลกิจกรรมเป็นรูปแบบที่ฟอร์มนั้นรับ
  Widget _buildEditForm() {
    final raw = activity.raw;
    final dateStr = DateFormat('yyyy-MM-dd').format(activity.recordDate);
    switch (activity.type) {
      case 'harvest':
        return AddHarvestScreen(
          existing: HarvestData(
            id: activity.id,
            gardenId: activity.gardenId,
            code: raw['code']?.toString() ?? activity.id,
            plotName: activity.gardenName,
            buyer: '',
            quantityKg: activity.quantity ?? 0,
            pricePerKg: _num(raw['price_per_kg']),
            totalPrice: activity.amount ?? 0,
            date: dateStr,
            status: raw['status']?.toString() ?? 'sold',
          ),
        );
      case 'care':
        return AddGardenCareScreen(
          existing: {
            'care_id': activity.id,
            'garden_id': activity.gardenId,
            'fertilizer_id': raw['fertilizer_id'],
            'action_type': raw['action_type'],
            'quantity': activity.quantity,
            'cost': activity.amount,
            'record_date': dateStr,
            'note': raw['note'],
          },
        );
      default: // income / expense
        return AddTransactionScreen(
          existing: TransactionItem(
            id: activity.id,
            title: activity.description ?? raw['category']?.toString() ?? '',
            type: activity.type,
            amount: activity.amount ?? 0,
            category: raw['category']?.toString() ?? '',
            gardenName: activity.gardenName,
            gardenId: activity.gardenId,
            date: dateStr,
          ),
        );
    }
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _buildEditForm()),
    );
    // แก้ไขแล้ว: ปิดหน้านี้พร้อมบอกหน้าก่อนหน้าให้โหลดใหม่ (ข้อมูลในหน้านี้เก่าแล้ว)
    if (saved == true && context.mounted) Navigator.pop(context, true);
  }

  Future<void> _delete(BuildContext context) async {
    if (!await confirmDelete(context, 'กิจกรรม ${activity.gardenName}')) return;

    final userId = await AuthService.getUserId();
    final path = switch (activity.type) {
      'harvest' => 'harvests',
      'care' => 'care-logs',
      _ => 'finance',
    };
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUri}/$path/${activity.id}?user_id=$userId'),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _resolveTheme(activity.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: theme.appBarColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _edit(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _delete(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.appBarColor, theme.appBarColor.withValues(alpha: 0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActivityTypeBadge(type: activity.type),
                        const SizedBox(height: 12),
                        Text(
                          activity.gardenName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatThaiDate(activity.recordDate),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // การ์ดสรุปตัวเลข
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _buildMainValue(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.valueColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildMainLabel(),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // รายละเอียด
                  const Text(
                    'รายละเอียด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.location_on_outlined, 'แปลงสวน', activity.gardenName),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'วันที่บันทึก',
                    formatThaiDate(activity.recordDate),
                  ),
                  if (activity.quantity != null)
                    _buildDetailRow(
                      Icons.scale_outlined,
                      'จำนวน',
                      '${formatNumber(activity.quantity!)} ${activity.raw['quantity_type'] ?? 'กิโลกรัม'}',
                    ),
                  if (activity.amount != null)
                    _buildDetailRow(
                      Icons.attach_money,
                      'จำนวนเงิน',
                      '${formatNumber(activity.amount!)} บาท',
                    ),
                  if (activity.description != null && activity.description!.isNotEmpty)
                    _buildDetailRow(
                      Icons.notes_outlined,
                      'หมายเหตุ',
                      activity.description!,
                    ),

                  const SizedBox(height: 32),

                  // ปุ่มแก้ไข / ลบ
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _edit(context),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('แก้ไข'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D6A4F),
                            side: const BorderSide(color: Color(0xFF2D6A4F)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _delete(context),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('ลบ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMainValue() {
    switch (activity.type) {
      case 'harvest':
      case 'care':
        return formatNumber(activity.quantity ?? 0);
      case 'income':
        return '+${formatNumber(activity.amount ?? 0)}';
      case 'expense':
        return '-${formatNumber(activity.amount ?? 0)}';
      default:
        return '-';
    }
  }

  String _buildMainLabel() {
    switch (activity.type) {
      case 'harvest':
        return 'กิโลกรัม (ผลผลิต)';
      case 'care':
        return 'กิโลกรัม (ปุ๋ย/สาร)';
      case 'income':
        return 'บาท (รายรับ)';
      case 'expense':
        return 'บาท (รายจ่าย)';
      default:
        return '';
    }
  }

  _DetailTheme _resolveTheme(String type) {
    switch (type) {
      case 'harvest':
        return _DetailTheme(
          appBarColor: const Color(0xFFE91E63),
          valueColor: const Color(0xFFC2185B),
        );
      case 'care':
        return _DetailTheme(
          appBarColor: const Color(0xFFFF9800),
          valueColor: const Color(0xFFE65100),
        );
      case 'income':
        return _DetailTheme(
          appBarColor: const Color(0xFF4CAF50),
          valueColor: const Color(0xFF2E7D32),
        );
      case 'expense':
        return _DetailTheme(
          appBarColor: const Color(0xFFF44336),
          valueColor: const Color(0xFFC62828),
        );
      default:
        return _DetailTheme(
          appBarColor: const Color(0xFF2D6A4F),
          valueColor: const Color(0xFF2D6A4F),
        );
    }
  }
}

class _DetailTheme {
  final Color appBarColor;
  final Color valueColor;
  _DetailTheme({required this.appBarColor, required this.valueColor});
}
