import 'package:flutter/material.dart';

class ActivityFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ActivityFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<_FilterItem> _filters = const [
    _FilterItem(label: 'ทั้งหมด', value: 'all', emoji: '📋'),
    _FilterItem(label: 'เก็บเกี่ยว', value: 'harvest', emoji: '🧺'),
    _FilterItem(label: 'ดูแล', value: 'care', emoji: '💊'),
    _FilterItem(label: 'รายรับ', value: 'income', emoji: '💵'),
    _FilterItem(label: 'รายจ่าย', value: 'expense', emoji: '💸'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _filters[index];
          final isSelected = selectedFilter == item.value;
          return GestureDetector(
            onTap: () => onFilterChanged(item.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2D6A4F) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2D6A4F).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final String label;
  final String value;
  final String emoji;
  const _FilterItem({required this.label, required this.value, required this.emoji});
}
