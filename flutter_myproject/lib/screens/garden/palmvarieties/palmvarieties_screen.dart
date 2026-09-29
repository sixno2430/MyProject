// ============================================================
// palmvarieties_screen.dart — หน้าพันธุ์ปาล์ม (เวอร์ชันที่เพิ่ม/แก้ไข/ลบได้)
//
// แสดงพันธุ์ทั้งหมดพร้อมจำนวนต้นที่ user ปลูก ค้นหาได้ กดค้างเพื่อแก้ไข/ลบ
// หมายเหตุ: ตอนนี้เมนูเปิดหน้าใน plamvarieties/ แทน หน้านี้จึงยังไม่มีทางเข้า
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'add_palmvariety_screen.dart';
import 'palm_variety.dart';

/// หน้ารายการพันธุ์ปาล์ม
class PalmVarietiesScreen extends StatefulWidget {
  const PalmVarietiesScreen({super.key});

  @override
  State<PalmVarietiesScreen> createState() => _PalmVarietiesScreenState();
}

class _PalmVarietiesScreenState extends State<PalmVarietiesScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  // สีแถบของการ์ด วนใช้ตามลำดับ
  static const List<Color> _cardColors = [
    Color(0xFF2D6A4F),
    Color(0xFFF9A825),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFF8D6E63),
  ];

  List<PalmVariety> _varieties = [];
  String _query = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVarieties();
  }

  /// ดึงรายชื่อพันธุ์ พร้อมจำนวนต้น/แปลงที่ user นี้ปลูก
  Future<void> _fetchVarieties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = await AuthService.getUserId();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUri}/varieties?user_id=${userId ?? ''}'),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      final list = (body['data'] as List).map((e) => PalmVariety.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _varieties = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'โหลดข้อมูลไม่สำเร็จ: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  /// พันธุ์ที่ตรงกับคำค้นหา (ชื่อ หรือชื่อวิทยาศาสตร์)
  List<PalmVariety> get _filtered {
    if (_query.isEmpty) return _varieties;
    final q = _query.toLowerCase();
    return _varieties
        .where((v) =>
            v.varietyName.toLowerCase().contains(q) ||
            (v.scientificName ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// เปิดฟอร์มเพิ่ม/แก้ไขพันธุ์ กลับมาแล้วโหลดใหม่
  Future<void> _openForm({PalmVariety? existing}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPalmVarietyScreen(existing: existing)),
    );
    if (result == true) _fetchVarieties();
  }

  /// กดค้างที่การ์ด: แก้ไข หรือลบ (ลบไม่ได้ถ้ามีแปลงปลูกพันธุ์นี้อยู่)
  Future<void> _onLongPress(PalmVariety v) async {
    final action = await showItemActionsSheet(context);
    if (action == null || !mounted) return;

    if (action == ItemAction.edit) {
      _openForm(existing: v);
      return;
    }

    if (!await confirmDelete(context, v.varietyName)) return;
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUri}/varieties/${v.varietyId}'),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบพันธุ์ปาล์มแล้ว')));
      _fetchVarieties();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
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
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                        const SizedBox(width: 36), // ให้สมดุลกับปุ่มย้อนกลับ
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoading ? 'กำลังโหลด...' : 'ข้อมูลพันธุ์ปาล์ม ${_varieties.length} สายพันธุ์',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====== เนื้อหา ======
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchVarieties,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  _buildSearchBox(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _fetchVarieties, child: const Text('ลองใหม่')),
                        ],
                      ),
                    )
                  else if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          _query.isEmpty ? 'ยังไม่มีข้อมูลพันธุ์ปาล์ม' : 'ไม่พบพันธุ์ที่ค้นหา',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'กดค้างที่การ์ดเพื่อแก้ไขหรือลบ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    for (final v in _filtered)
                      _buildVarietyCard(v, _cardColors[_varieties.indexOf(v) % _cardColors.length]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ช่องค้นหาพันธุ์ปาล์ม
  Widget _buildSearchBox() {
    return Container(
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
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'ค้นหาพันธุ์ปาล์ม...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดพันธุ์ปาล์ม 1 พันธุ์
  Widget _buildVarietyCard(PalmVariety v, Color color) {
    final isUsed = v.plantCount > 0;
    return GestureDetector(
      onLongPress: () => _onLongPress(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // แถบสีด้านบน
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🌿', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.varietyName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            if ((v.scientificName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                v.scientificName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(v.varietyId, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('🌴 ', style: TextStyle(fontSize: 14)),
                      Text(
                        isUsed
                            ? 'สวนของคุณปลูก ${v.plantCount} ต้น · ${v.gardenCount} แปลง'
                            : 'ยังไม่ได้ปลูกในสวนของคุณ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isUsed ? color : Colors.grey[500],
                          fontWeight: isUsed ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
