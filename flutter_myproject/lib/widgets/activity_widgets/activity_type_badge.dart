import 'package:flutter/material.dart';

class ActivityTypeBadge extends StatelessWidget {
  final String type;
  const ActivityTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _resolveConfig(String type) {
    switch (type) {
      case 'harvest':
        return _BadgeConfig(
          emoji: '🧺',
          label: 'เก็บเกี่ยว',
          bgColor: const Color(0xFFFCE4EC),
          textColor: const Color(0xFFC2185B),
        );
      case 'care':
        return _BadgeConfig(
          emoji: '💊',
          label: 'ดูแลรักษา',
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
        );
      case 'income':
        return _BadgeConfig(
          emoji: '💵',
          label: 'รายรับ',
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
        );
      case 'expense':
        return _BadgeConfig(
          emoji: '💸',
          label: 'รายจ่าย',
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
        );
      default:
        return _BadgeConfig(
          emoji: '📌',
          label: 'อื่นๆ',
          bgColor: const Color(0xFFF5F5F5),
          textColor: const Color(0xFF616161),
        );
    }
  }
}

class _BadgeConfig {
  final String emoji;
  final String label;
  final Color bgColor;
  final Color textColor;
  _BadgeConfig({
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}
