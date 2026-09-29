// ============================================================
// menu_item.dart — ปุ่มเมนู 1 ช่อง (ไอคอน emoji + ชื่อ) ใช้ใน MenuGrid
// ============================================================

import 'package:flutter/material.dart';

/// ปุ่มเมนู 1 ช่อง: กล่องไล่สีมี emoji และชื่อเมนูด้านล่าง
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              // ไล่สีอ่อนๆ จากสีพื้นของเมนู ให้ดูมีมิติ
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, Color.lerp(bgColor, labelColor, 0.12)!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
