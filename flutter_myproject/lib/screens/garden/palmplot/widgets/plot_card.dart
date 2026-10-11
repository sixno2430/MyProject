// ============================================================
// plot_card.dart — การ์ดแปลงสวน 1 แปลงในหน้ารายการแปลง
//
// แสดงชื่อแปลง, ที่อยู่, อายุ/พื้นที่/จำนวนต้น และพันธุ์ที่ปลูก พร้อมเมนู แก้ไข / ลบ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/models/garden.dart';

/// การ์ดแปลงสวน 1 แปลง (สไตล์เดียวกับการ์ดกิจกรรมในหน้าหลัก)
class PlotCard extends StatelessWidget {
  final Garden garden;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlotCard({super.key, required this.garden, required this.onEdit, required this.onDelete});

  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('🌴', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garden.gardenName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark),
                ),
                if (garden.detailText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(garden.detailText, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
                if (garden.varieties != null && garden.varieties!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: garden.varieties!
                        .map(
                          (v) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '🌿 ${v.varietyName} · ${v.plantCount} ต้น',
                              style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w500),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (garden.address != null && garden.address!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('📍', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          garden.address!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: primaryGreen),
                    const SizedBox(width: 10),
                    const Text('แก้ไข'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Color(0xFFD32F2F)),
                    SizedBox(width: 10),
                    Text('ลบ', style: TextStyle(color: Color(0xFFD32F2F))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
