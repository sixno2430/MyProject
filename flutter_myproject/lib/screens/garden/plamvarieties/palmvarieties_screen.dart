// ============================================================
// palmvarieties_screen.dart (plamvarieties/) — หน้าพันธุ์ปาล์มที่เปิดจากเมนูหลัก
//
// รายชื่อพันธุ์ปาล์มของผู้ใช้ (พันธุ์แยกตามผู้ใช้) ค้นหาได้
//   ปุ่ม + = เพิ่มพันธุ์, แตะการ์ด / ⋮ = แก้ไขหรือลบ (พันธุ์ที่มีแปลงปลูกอยู่ลบไม่ได้)
// ============================================================

import 'package:flutter/material.dart';
import '../../../../services/palm_variety_service.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'add_palmvariety_screen.dart';
import 'palm_variety.dart';

/// หน้ารายการพันธุ์ปาล์ม (ต้องส่ง token มาด้วย)
class PalmVarietiesScreen extends StatefulWidget {
  final String token;
  const PalmVarietiesScreen({super.key, required this.token});

  @override
  State<PalmVarietiesScreen> createState() => _PalmVarietiesScreenState();
}

class _PalmVarietiesScreenState extends State<PalmVarietiesScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  late Future<List<PalmVariety>> _future;
  String _keyword = '';

  final List<List<Color>> _palette = const [
    [Color(0xFF2D6A4F), Color(0xFFE8F5E9)],
    [Color(0xFFF9A825), Color(0xFFFFF8E1)],
    [Color(0xFF42A5F5), Color(0xFFE3F2FD)],
    [Color(0xFFAB47BC), Color(0xFFF3E5F5)],
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// เริ่มโหลดรายชื่อพันธุ์จาก API
  void _loadData() {
    _future = PalmVarietyService.getVarieties(widget.token);
  }

  /// โหลดใหม่ (ดึงหน้าจอลง)
  Future<void> _reload() async {
    setState(() {
      _loadData();
    });
  }

  /// เปิดฟอร์มเพิ่ม (existing = null) หรือแก้ไข บันทึกแล้วโหลดรายการใหม่
  Future<void> _openForm([PalmVariety? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddPalmVarietyScreen(existing: existing)),
    );
    if (saved == true) _reload();
  }

  /// แตะการ์ด / ⋮ : เลือกแก้ไขหรือลบ
  Future<void> _onVarietyActions(PalmVariety v) async {
    final action = await showItemActionsSheet(context);
    if (action == null || !mounted) return;
    if (action == ItemAction.edit) {
      _openForm(v);
      return;
    }
    // ปลูกอยู่ = ลบไม่ได้ (เซิร์ฟเวอร์ก็กันไว้) บอกเลยไม่ต้องถามยืนยัน
    if (v.gardenCount > 0) {
      _toast('ลบไม่ได้ เพราะมี ${v.gardenCount} แปลงที่ปลูกพันธุ์นี้อยู่');
      return;
    }
    if (!await confirmDelete(context, v.varietyName)) return;
    try {
      await PalmVarietyService.deleteVariety(v.varietyId);
      _toast('ลบพันธุ์ปาล์มแล้ว');
      _reload();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพันธุ์', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ====== Header สีเขียว ======
          Container(
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'พันธุ์ปาล์มน้ำมัน',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<PalmVariety>>(
                      future: _future,
                      builder: (context, snap) {
                        final count = snap.data?.length;
                        return Text(
                          count == null
                              ? 'ข้อมูลพันธุ์ปาล์ม'
                              : 'ข้อมูลพันธุ์ปาล์ม $count สายพันธุ์',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====== เนื้อหา ======
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              color: primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                // เว้นล่างให้พ้นปุ่ม + การ์ดสุดท้ายจะได้ไม่ถูกบัง
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  children: [
                    // ช่องค้นหา
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400], size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _keyword = v.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'ค้นหาพันธุ์ปาล์ม...',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // แสดงผลรายการพันธุ์ปาล์ม
                    FutureBuilder<List<PalmVariety>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snap.hasError) {
                          final errorMsg = snap.error
                              .toString()
                              .replaceAll('Exception: ', '');

                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red[300], size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'เกิดข้อผิดพลาด: $errorMsg',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _reload,
                                    child: const Text('ลองใหม่'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final items = (snap.data ?? []).where((v) {
                          return v.varietyName.toLowerCase().contains(_keyword) ||
                              (v.scientificName ?? '')
                                  .toLowerCase()
                                  .contains(_keyword);
                        }).toList();

                        if (items.isEmpty) {
                          // ยังไม่มีพันธุ์เลย (บัญชีใหม่) กับ ค้นหาไม่เจอ บอกคนละแบบ
                          final noData = (snap.data ?? []).isEmpty;
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.eco_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    noData
                                        ? 'ยังไม่มีพันธุ์ปาล์มของคุณ\nกด "เพิ่มพันธุ์" เพื่อเริ่มบันทึก'
                                        : 'ไม่พบพันธุ์ปาล์มที่ค้นหา',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          // ไม่ใส่ padding เอง ListView จะเติมช่องว่างเท่า safe area ด้านบนให้ (ช่องว่างเกินใต้ช่องค้นหา)
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final v = items[i];
                            return GestureDetector(
                              onTap: () => _onVarietyActions(v),
                              child: _buildVarietyCard(
                                topColor: _palette[i % _palette.length][0],
                                iconBgColor: _palette[i % _palette.length][1],
                                name: v.varietyName,
                                scientificName: (v.scientificName ?? '').isEmpty ? '-' : v.scientificName!,
                                description: '',
                                // บอกว่าปลูกอยู่กี่ต้น กี่แปลง (ยังไม่ได้ปลูก = ไม่แสดง)
                                usageText: v.gardenCount > 0
                                    ? 'ปลูก ${v.plantCount} ต้น ใน ${v.gardenCount} แปลง'
                                    : '',
                                usageColor: _palette[i % _palette.length][0],
                                onMore: () => _onVarietyActions(v),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดพันธุ์ปาล์ม 1 พันธุ์
  Widget _buildVarietyCard({
    required Color topColor,
    required Color iconBgColor,
    required String name,
    required String scientificName,
    required String description,
    required String usageText,
    required Color usageColor,
    String? badge,
    VoidCallback? onMore,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: topColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2D6A4F),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scientificName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onMore != null)
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: onMore,
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
                if (usageText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('🌴 ', style: TextStyle(fontSize: 14)),
                      Flexible(
                        child: Text(
                          usageText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: usageColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}