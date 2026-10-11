// ============================================================
// care_log_card.dart — การ์ดรายการดูแลสวน 1 รายการในหน้า "ดูแลรักษา"
//
// ไอคอน/สีตามประเภทกิจกรรม, แปลง, รายละเอียด (ชื่อปุ๋ย / วิธี / จำนวน / หมายเหตุ), วันที่ และค่าใช้จ่าย
// แตะ / กดค้าง / ปุ่ม ⋮ = เปิดเมนูแก้ไข-ลบ (onActions)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/models/care_log.dart';

class CareLogCard extends StatelessWidget {
  final CareLog item;
  final VoidCallback onActions;

  const CareLogCard({super.key, required this.item, required this.onActions});

  static final NumberFormat _money = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final t = item.type;
    final qty = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    // บรรทัดรายละเอียด: ชื่อปุ๋ย / รายละเอียดตามประเภท / จำนวน / หมายเหตุ
    final details = [
      if (item.fertilizerName != null) item.fertilizerName!,
      if (item.detail.isNotEmpty) item.detail,
      if (item.quantity > 0) '$qty ${item.unit}',
      if (item.note.isNotEmpty) item.note,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onActions(),
          onLongPress: () => onActions(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
            child: Row(
              children: [
                // ไอคอนประเภท + วันที่
                Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: t.bgColor, borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM', 'th_TH').format(item.date),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: t.label,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.color),
                            ),
                            TextSpan(
                              text: '  ·  ${item.gardenName}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.cost > 0 ? '-${_money.format(item.cost)} ฿' : '-',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.cost > 0 ? const Color(0xFFD32F2F) : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                  onPressed: () => onActions(),
                  tooltip: 'แก้ไข / ลบ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
