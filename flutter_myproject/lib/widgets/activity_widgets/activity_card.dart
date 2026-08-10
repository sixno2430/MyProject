import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/main/HOME/activity_detail_screen.dart';
import 'package:flutter_myproject/widgets/activity_widgets/activity_type_badge.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/utils/formatters.dart';

class ActivityCard extends StatelessWidget { 
  final ActivityItem activity;
  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = _resolveTheme(activity.type);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activity: activity),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // แถบสีด้านซ้าย
            Container(
              width: 5,
              height: 110,
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Icon วงกลม
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(theme.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            // เนื้อหา
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ActivityTypeBadge(type: activity.type),
                  const SizedBox(height: 6),
                  Text(
                    activity.gardenName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        formatRelativeDate(activity.recordDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ยอดเงิน / จำนวน + ลูกศร
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _buildValueText(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.valueColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (activity.description != null && activity.description!.isNotEmpty) {
      return activity.description!;
    }
    switch (activity.type) {
      case 'harvest':
        return 'เก็บเกี่ยวผลผลิตจากแปลง';
      case 'care':
        return 'ดูแลรักษาและใส่ปุ๋ย';
      case 'income':
        return 'บันทึกรายรับ';
      case 'expense':
        return 'บันทึกรายจ่าย';
      default:
        return 'กิจกรรมทั่วไป';
    }
  }

  String _buildValueText() {
    switch (activity.type) {
      case 'harvest':
      case 'care':
        return '${formatNumber(activity.quantity ?? 0)} กก.';
      case 'income':
        return '+${formatNumber(activity.amount ?? 0)}';
      case 'expense':
        return '-${formatNumber(activity.amount ?? 0)}';
      default:
        return '';
    }
  }

  _CardTheme _resolveTheme(String type) {
    switch (type) {
      case 'harvest':
        return _CardTheme(
          emoji: '🧺',
          accentColor: const Color(0xFFE91E63),
          iconBg: const Color(0xFFFCE4EC),
          valueColor: const Color(0xFFC2185B),
        );
      case 'care':
        return _CardTheme(
          emoji: '💊',
          accentColor: const Color(0xFFFF9800),
          iconBg: const Color(0xFFFFF3E0),
          valueColor: const Color(0xFFE65100),
        );
      case 'income':
        return _CardTheme(
          emoji: '💵',
          accentColor: const Color(0xFF4CAF50),
          iconBg: const Color(0xFFE8F5E9),
          valueColor: const Color(0xFF2E7D32),
        );
      case 'expense':
        return _CardTheme(
          emoji: '💸',
          accentColor: const Color(0xFFF44336),
          iconBg: const Color(0xFFFFEBEE),
          valueColor: const Color(0xFFC62828),
        );
      default:
        return _CardTheme(
          emoji: '📌',
          accentColor: Colors.grey,
          iconBg: const Color(0xFFF5F5F5),
          valueColor: Colors.grey,
        );
    }
  }
}

class _CardTheme {
  final String emoji;
  final Color accentColor;
  final Color iconBg;
  final Color valueColor;
  _CardTheme({
    required this.emoji,
    required this.accentColor,
    required this.iconBg,
    required this.valueColor,
  });
}
