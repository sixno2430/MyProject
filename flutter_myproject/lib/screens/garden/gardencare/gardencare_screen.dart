// ============================================================
// gardencare_screen.dart — หน้า "การดูแลรักษาสวน"
//
// แสดงรายการดูแลสวน (ใส่ปุ๋ย, ตัดแต่ง, ให้น้ำ, พ่นยา ฯลฯ)
// - การ์ดสรุปค่าใช้จ่าย/จำนวนครั้ง ตามตัวกรองที่เลือก
// - กรองตามแปลงและประเภทด้วยชิปเลื่อนแนวนอน
// - รายการจัดกลุ่มตามเดือน แตะ/กดค้าง/ปุ่ม ⋮ เพื่อแก้ไขหรือลบ
// API: GET /api/care-logs?user_id=..., GET /api/gardens/:userId, DELETE /api/care-logs/:id
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_myproject/screens/garden/gardencare/add_gardencare_screen.dart';
import 'package:flutter_myproject/screens/garden/gardencare/care_types.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'package:flutter_myproject/config/app_config.dart';

/// รายการดูแลสวน 1 รายการ (แปลงจาก JSON ของ API แล้ว)
class _CareItem {
  final String careId;
  final CareType type;
  final String gardenName;
  final String? fertilizerName;
  final String note;
  final double quantity;
  final String unit;
  final double cost;
  final DateTime date;
  final Map<String, dynamic> raw; // ข้อมูลดิบไว้ส่งให้หน้าแก้ไข

  _CareItem({
    required this.careId,
    required this.type,
    required this.gardenName,
    required this.fertilizerName,
    required this.note,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.date,
    required this.raw,
  });

  factory _CareItem.fromJson(Map<String, dynamic> j) {
    final hasFertilizer = j['fertilizer_id'] != null && j['fertilizer_id'].toString().isNotEmpty;
    // รายการเก่าที่ไม่มี action_type -> "อื่นๆ"
    final type = hasFertilizer ? careTypeOf('fertilizer') : careTypeOf(j['action_type']?.toString());
    return _CareItem(
      careId: j['care_id'].toString(),
      type: type,
      gardenName: j['garden_name']?.toString() ?? 'ไม่ระบุแปลง',
      fertilizerName: hasFertilizer ? j['fertilizer_name']?.toString() : null,
      note: j['note']?.toString().trim() ?? '',
      quantity: double.tryParse(j['quantity']?.toString() ?? '') ?? 0,
      unit: j['quantity_type']?.toString() ?? type.unit,
      cost: double.tryParse(j['cost']?.toString() ?? '') ?? 0,
      // DB ส่งวันที่มาเป็น UTC ต้องแปลงเป็นเวลาไทย ไม่งั้นวันที่จะเลื่อนไป 1 วัน
      date: DateTime.tryParse(j['record_date']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      raw: j,
    );
  }
}

/// หน้ารายการดูแลสวน
class GardenCareScreen extends StatefulWidget {
  const GardenCareScreen({super.key});

  @override
  State<GardenCareScreen> createState() => _GardenCareScreenState();
}

class _GardenCareScreenState extends State<GardenCareScreen> {
  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const String _all = 'ทั้งหมด';

  final NumberFormat _money = NumberFormat('#,##0');

  String get apiUrl => AppConfig.apiBaseUri;

  String _selectedPlot = _all;
  String _selectedType = _all; // ค่า type ของ CareType หรือ "ทั้งหมด"

  List<String> _plots = [];
  List<_CareItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// ดึงรายการดูแลสวนและรายชื่อแปลงของ user
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = 'ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่';
        _isLoading = false;
      });
      return;
    }

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiUrl/care-logs?user_id=$userId')),
        http.get(Uri.parse('$apiUrl/gardens/$userId')),
      ]);
      if (responses[0].statusCode != 200) {
        throw Exception('เซิร์ฟเวอร์ตอบกลับด้วยสถานะ ${responses[0].statusCode}');
      }

      // care-logs ส่ง array มาตรงๆ ส่วน gardens ห่อใน { data: [...] }
      List<dynamic> listOf(String body) {
        final decoded = jsonDecode(body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'];
        return [];
      }

      final items = listOf(responses[0].body)
          .map((e) => _CareItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final plots = listOf(responses[1].body)
          .map((g) => g['garden_name']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _plots = plots;
        if (_selectedPlot != _all && !plots.contains(_selectedPlot)) _selectedPlot = _all;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลได้\n${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  /// รายการที่ผ่านตัวกรองแปลงและประเภท
  List<_CareItem> get _filtered => _items
      .where((i) =>
          (_selectedPlot == _all || i.gardenName == _selectedPlot) &&
          (_selectedType == _all || i.type.type == _selectedType))
      .toList();

  /// เปิดฟอร์มเพิ่ม/แก้ไข กลับมาแล้วโหลดใหม่ถ้ามีการบันทึก
  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddGardenCareScreen(existing: existing)),
    );
    if (saved == true) _fetchData();
  }

  /// เมนูแก้ไข/ลบ ของรายการ
  Future<void> _showActions(_CareItem item) async {
    final action = await showItemActionsSheet(context);
    if (action == null || !mounted) return;

    if (action == ItemAction.edit) {
      _openForm(existing: item.raw);
      return;
    }

    if (!await confirmDelete(context, '${item.type.label} · ${item.gardenName}')) return;
    final userId = await AuthService.getUserId();
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/care-logs/${item.careId}?user_id=$userId'),
      );
      final body = jsonDecode(response.body);
      if (body['isError'] == true) throw Exception(body['errorMessage']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('การดูแลรักษาสวน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: _items.isEmpty && !_isLoading
          ? null // หน้าว่างมีปุ่มกลางจออยู่แล้ว
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('บันทึกการดูแล', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return _buildCenterMessage(
        emoji: '⚠️',
        title: _errorMessage!,
        buttonText: 'ลองใหม่',
        onPressed: _fetchData,
      );
    }

    if (_items.isEmpty) {
      return _buildCenterMessage(
        emoji: '🌱',
        title: 'ยังไม่มีบันทึกการดูแลสวน',
        subtitle: 'บันทึกการใส่ปุ๋ย ตัดแต่ง ให้น้ำ ฯลฯ\nเพื่อติดตามการดูแลและค่าใช้จ่าย',
        buttonText: 'บันทึกการดูแลครั้งแรก',
        onPressed: () => _openForm(),
      );
    }

    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96), // เว้นที่ให้ปุ่มลอยด้านล่าง
        children: [
          _buildSummaryCard(filtered),
          _buildPlotFilter(),
          const SizedBox(height: 8),
          _buildTypeFilter(),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('ไม่มีรายการที่ตรงกับตัวกรอง', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            ..._buildGroupedList(filtered),
        ],
      ),
    );
  }

  // ---------- การ์ดสรุป ----------

  Widget _buildSummaryCard(List<_CareItem> items) {
    final totalCost = items.fold<double>(0, (s, i) => s + i.cost);
    final last = items.isEmpty ? null : items.first.date;
    final daysAgo = last == null ? null : DateTime.now().difference(last).inDays;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ค่าใช้จ่ายการดูแล${_selectedPlot == _all ? '' : ' · $_selectedPlot'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${_money.format(totalCost)} ฿',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryPill(Icons.event_note, '${items.length} ครั้ง'),
              if (daysAgo != null)
                _summaryPill(
                  Icons.history,
                  daysAgo == 0 ? 'ล่าสุด วันนี้' : 'ล่าสุด $daysAgo วันก่อน',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ---------- ตัวกรอง ----------

  Widget _buildPlotFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            label: '🌴 ทุกแปลง',
            selected: _selectedPlot == _all,
            color: primaryGreen,
            onTap: () => setState(() => _selectedPlot = _all),
          ),
          for (final p in _plots)
            _chip(
              label: p,
              selected: _selectedPlot == p,
              color: primaryGreen,
              onTap: () => setState(() => _selectedPlot = p),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    // นับจำนวนต่อประเภท (ตามแปลงที่เลือก) ไว้แสดงบนชิป
    final inPlot = _items.where((i) => _selectedPlot == _all || i.gardenName == _selectedPlot);
    int countOf(String type) => inPlot.where((i) => i.type.type == type).length;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            label: 'ทั้งหมด ${inPlot.length}',
            selected: _selectedType == _all,
            color: primaryGreen,
            onTap: () => setState(() => _selectedType = _all),
          ),
          for (final t in careTypes)
            if (countOf(t.type) > 0) // ซ่อนประเภทที่ไม่มีรายการ ไม่ให้แถบยาวเกินไป
              _chip(
                label: '${t.emoji} ${t.label} ${countOf(t.type)}',
                selected: _selectedType == t.type,
                color: t.color,
                onTap: () => setState(() => _selectedType = t.type),
              ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : Colors.grey[800],
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- รายการจัดกลุ่มตามเดือน ----------

  List<Widget> _buildGroupedList(List<_CareItem> items) {
    final widgets = <Widget>[];
    String? currentMonth;
    for (final item in items) {
      final month = '${DateFormat('MMMM', 'th_TH').format(item.date)} ${item.date.year + 543}';
      if (month != currentMonth) {
        currentMonth = month;
        final inMonth = items.where((i) => i.date.year == item.date.year && i.date.month == item.date.month);
        final monthCost = inMonth.fold<double>(0, (s, i) => s + i.cost);
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(month, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Text(
                '${inMonth.length} รายการ · ${_money.format(monthCost)} ฿',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ));
      }
      widgets.add(_buildCareCard(item));
    }
    return widgets;
  }

  Widget _buildCareCard(_CareItem item) {
    final t = item.type;
    final qty = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    // บรรทัดรายละเอียด: ชื่อปุ๋ย / หมายเหตุ / จำนวน
    final details = [
      if (item.fertilizerName != null) item.fertilizerName!,
      if (item.note.isNotEmpty) item.note,
      if (item.quantity > 0) '$qty ${item.unit}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showActions(item),
          onLongPress: () => _showActions(item),
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
                        TextSpan(children: [
                          TextSpan(
                            text: t.label,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.color),
                          ),
                          TextSpan(
                            text: '  ·  ${item.gardenName}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ]),
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
                  onPressed: () => _showActions(item),
                  tooltip: 'แก้ไข / ลบ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- ข้อความกลางจอ (ว่าง / ผิดพลาด) ----------

  Widget _buildCenterMessage({
    required String emoji,
    required String title,
    String? subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonText == 'ลองใหม่' ? Icons.refresh : Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
