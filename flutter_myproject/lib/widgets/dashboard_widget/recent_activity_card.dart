import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/screens/main/HOME/activity_detail_screen.dart';

/// การ์ดแสดงกิจกรรมล่าสุดในหน้า Dashboard
/// แตกต่างจาก ActivityCard ในหน้า Activity ตรงที่ดีไซน์กะทัดรัดกว่า
class RecentActivityCard extends StatelessWidget {
  final ActivityItem activity;
  const RecentActivityCard({super.key, required this.activity});

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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // ไอคอนวงกลม
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(theme.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            // เนื้อหา
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _buildTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
                ],
              ),
            ),
            // เวลา + ลูกศร
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRelativeDate(activity.recordDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildTitle() {
    switch (activity.type) {
      case 'harvest':
        return 'เก็บเกี่ยว ${activity.gardenName}';
      case 'care':
        return 'ใส่ปุ๋ย ${activity.gardenName}';
      case 'income':
        return activity.description ?? 'รับเงิน ${activity.gardenName}';
      case 'expense':
        return activity.description ?? 'จ่ายเงิน ${activity.gardenName}';
      default:
        return activity.gardenName;
    }
  }

  String _buildSubtitle() {
    switch (activity.type) {
      case 'harvest':
        return '${formatNumber(activity.quantity ?? 0)} กก.';
      case 'care':
        if (activity.description != null && activity.description!.isNotEmpty) {
          return '${activity.description} · ${formatNumber(activity.quantity ?? 0)} กก.';
        }
        return '${formatNumber(activity.quantity ?? 0)} กก.';
      case 'income':
        return '+${formatNumber(activity.amount ?? 0)} บาท';
      case 'expense':
        return '-${formatNumber(activity.amount ?? 0)} บาท';
      default:
        return '';
    }
  }

  _CardTheme _resolveTheme(String type) {
    switch (type) {
      case 'harvest':
        return _CardTheme(
          emoji: '🧺',
          iconBg: const Color(0xFFFCE4EC),
        );
      case 'care':
        return _CardTheme(
          emoji: '💊',
          iconBg: const Color(0xFFFFEBEE),
        );
      case 'income':
        return _CardTheme(
          emoji: '💵',
          iconBg: const Color(0xFFE0F2F1),
        );
      case 'expense':
        return _CardTheme(
          emoji: '💸',
          iconBg: const Color(0xFFFFEBEE),
        );
      default:
        return _CardTheme(
          emoji: '📌',
          iconBg: const Color(0xFFF5F5F5),
        );
    }
  }
}

class _CardTheme {
  final String emoji;
  final Color iconBg;
  _CardTheme({required this.emoji, required this.iconBg});
}
