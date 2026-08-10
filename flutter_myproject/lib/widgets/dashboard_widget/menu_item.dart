import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final Color labelColor;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.onTap,
    this.labelColor = const Color(0xFF2D6A4F),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
