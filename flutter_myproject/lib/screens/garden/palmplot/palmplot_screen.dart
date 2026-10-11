// ============================================================
// palmplot_screen.dart — หน้า "แปลงสวนของฉัน"
//
// แสดงรายการแปลงสวนของ user พร้อมสถิติรวม (จำนวนแปลง / ไร่ / ต้น) และค้นหาได้
// เพิ่มแปลงใหม่ -> AddPlotScreen, แก้ไข -> bottom sheet (EditGardenDialog), ลบได้
// API: GET/PUT/DELETE /api/gardens
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_myproject/screens/garden/palmplot/add_plot_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/config/app_config.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/models/garden.dart';
import 'package:flutter_myproject/screens/garden/palmplot/widgets/plot_card.dart';
import 'package:flutter_myproject/screens/garden/palmplot/widgets/edit_garden_dialog.dart';

// model: models/garden.dart · widget ย่อย: widgets/plot_card.dart (การ์ดแปลง), widgets/edit_garden_dialog.dart (แก้ไขแปลง)
/// หน้ารายการแปลงสวน
class PalmplotScreen extends StatefulWidget {
  const PalmplotScreen({super.key});

  @override
  State<PalmplotScreen> createState() => _PalmplotScreenState();
}

class _PalmplotScreenState extends State<PalmplotScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  List<Garden> gardens = [];
  List<Garden> filteredGardens = [];
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController searchController = TextEditingController();

  String get baseUrl => AppConfig.apiBaseUri;

  @override
  void initState() {
    super.initState();
    fetchGardens();
  }

  /// ยืนยันแล้วลบแปลงสวน จากนั้นโหลดรายการใหม่
  Future<void> _deleteGarden(Garden garden) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันการลบ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        content: Text(
          'ต้องการลบ "${garden.gardenName}" ใช่หรือไม่?\nข้อมูลที่ลบแล้วจะกู้คืนไม่ได้',
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      // ส่ง user_id ไปด้วย เซิร์ฟเวอร์ให้ลบได้เฉพาะแปลงของตัวเอง
      final userId = await AuthService.getUserId();
      final response = await http.delete(Uri.parse('$baseUrl/gardens/${garden.gardenId}?user_id=$userId'));
      final body = json.decode(response.body);
      if (!mounted) return;
      if (body['isError'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบสำเร็จ')));
        fetchGardens();
      } else {
        throw Exception(body['errorMessage']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: ${friendlyError(e)}')));
    }
  }

  /// ดึงแปลงสวนทั้งหมดของ user ที่ล็อกอินอยู่
  Future<void> fetchGardens() async {
    final userId = await AuthService.getUserId();
    if (userId == null || userId.isEmpty) {
      setState(() {
        errorMessage = 'ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่';
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseUrl/gardens/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['isError'] == false && body['data'] != null) {
          final List rawData = body['data'];
          final loadedGardens = rawData.map((e) => Garden.fromJson(e)).toList();
          setState(() {
            gardens = loadedGardens;
            filteredGardens = loadedGardens;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = body['errorMessage'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server Error (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = friendlyError(e);
        isLoading = false;
      });
    }
  }

  /// ค้นหาแปลงจากชื่อ (กรองในเครื่อง ไม่เรียก API)
  void _filterGardens(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredGardens = gardens;
      } else {
        filteredGardens = gardens.where((g) => g.gardenName.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  // ← เพิ่ม: ฟังก์ชันแก้ไขสวน
  /// เปิด bottom sheet แก้ไขแปลง แล้วส่งข้อมูลใหม่ไปบันทึก
  Future<void> _editGarden(Garden garden) async {
    // bottom sheet เลื่อนขึ้นจากด้านล่าง (isScrollControlled ให้สูงได้เกินครึ่งจอและดันขึ้นตามคีย์บอร์ด)
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGardenDialog(garden: garden, primaryGreen: primaryGreen),
    );

    if (result != null) {
      setState(() => isLoading = true);
      try {
        // ส่ง user_id ไปด้วย เซิร์ฟเวอร์ให้แก้ได้เฉพาะแปลงของตัวเอง
        final userId = await AuthService.getUserId();
        final response = await http.put(
          Uri.parse('$baseUrl/gardens/${garden.gardenId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({...result, 'user_id': userId}),
        );
        final body = json.decode(response.body);
        if (!mounted) return;
        if (body['isError'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('แก้ไขสำเร็จ')));
          fetchGardens();
        } else {
          throw Exception(body['errorMessage']);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('แก้ไขไม่สำเร็จ: ${friendlyError(e)}')));
      }
    }
  }

  /// จำนวนต้นรวมทุกแปลง
  int get totalPlants => gardens.fold(0, (sum, item) => sum + item.plantCount);

  /// พื้นที่รวมทุกแปลง (ไร่)
  double get totalArea => gardens.fold(0.0, (sum, item) => sum + item.areaSize);

  static const Color _bgColor = Color(0xFFF5F5F5);
  static const Color _textDark = Color(0xFF1F2937);

  /// แสดงพื้นที่ ตัดทศนิยม .0 ทิ้ง (20.0 -> "20")
  String _formatArea(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  /// เปิดหน้าเพิ่มแปลง กลับมาแล้วโหลดรายการใหม่
  void _openAddPlot() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPlotScreen())).then((_) => fetchGardens());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: RefreshIndicator(
          onRefresh: fetchGardens,
          color: primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildListTitle()),
              _buildListSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ส่วนหัวสีเขียว + การ์ดสถิติลอยทับ (แบบเดียวกับหน้าหลัก)
  /// ส่วนหัวสีเขียว (ปุ่มย้อนกลับ, ชื่อหน้า, ปุ่มเพิ่ม)
  Widget _buildHeader() {
    // หน้านี้เป็นทั้งแท็บในแถบล่างและหน้าที่ push มาจากเมนู → แสดงปุ่มย้อนกลับเฉพาะตอนที่ย้อนได้
    final canPop = Navigator.of(context).canPop();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 72),
              child: Row(
                children: [
                  if (canPop) ...[
                    _buildHeaderButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แปลงสวนของฉัน 🌴',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('จัดการข้อมูลแปลงปาล์มน้ำมัน', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildHeaderButton(icon: Icons.add, onTap: _openAddPlot),
                ],
              ),
            ),
          ),
        ),
        Positioned(bottom: -40, left: 16, right: 16, child: _buildStatsCard()),
      ],
    );
  }

  /// ปุ่มกลมในส่วนหัว
  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  /// การ์ดสถิติรวม 3 ช่อง
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _buildSummary('${gardens.length}', 'แปลงสวน\nทั้งหมด'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildSummary(_formatArea(totalArea), 'ไร่\nพื้นที่รวม'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildSummary('$totalPlants', 'ต้น\nปาล์มทั้งหมด'),
        ],
      ),
    );
  }

  /// สถิติ 1 ช่อง (ตัวเลข + คำอธิบาย)
  Widget _buildSummary(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
          ),
        ],
      ),
    );
  }

  /// ช่องค้นหาแปลง
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: _filterGardens,
          decoration: InputDecoration(
            hintText: 'ค้นหาแปลงสวน...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  /// หัวข้อ "รายการแปลงสวน" พร้อมจำนวน
  Widget _buildListTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'รายการแปลงสวน',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
            ),
          ),
          if (!isLoading && errorMessage.isEmpty)
            Text('${filteredGardens.length} แปลง', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// รายการการ์ดแปลงสวน (หรือข้อความเมื่อกำลังโหลด/ผิดพลาด/ว่าง)
  Widget _buildListSliver() {
    if (isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(color: primaryGreen)),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return SliverToBoxAdapter(
        child: _buildMessageState(
          emoji: '⚠️',
          title: 'โหลดข้อมูลไม่สำเร็จ',
          subtitle: errorMessage,
          buttonLabel: 'ลองใหม่',
          onPressed: () {
            setState(() {
              isLoading = true;
              errorMessage = '';
            });
            fetchGardens();
          },
        ),
      );
    }

    if (filteredGardens.isEmpty) {
      final isSearching = searchController.text.isNotEmpty;
      return SliverToBoxAdapter(
        child: _buildMessageState(
          emoji: isSearching ? '🔍' : '🌱',
          title: isSearching ? 'ไม่พบแปลงสวนที่ค้นหา' : 'ยังไม่มีแปลงสวน',
          subtitle: isSearching ? 'ลองค้นหาด้วยชื่ออื่น' : 'เพิ่มแปลงสวนแรกของคุณเพื่อเริ่มบันทึกข้อมูล',
          buttonLabel: isSearching ? null : 'เพิ่มแปลงสวน',
          onPressed: isSearching ? null : _openAddPlot,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: filteredGardens.length,
        itemBuilder: (context, index) {
          final garden = filteredGardens[index];
          return PlotCard(garden: garden, onEdit: () => _editGarden(garden), onDelete: () => _deleteGarden(garden));
        },
      ),
    );
  }

  /// หน้าข้อความกลางจอ (โหลดไม่สำเร็จ / ยังไม่มีแปลง)
  Widget _buildMessageState({
    required String emoji,
    required String title,
    required String subtitle,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonLabel),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// Bottom sheet แก้ไขแปลงสวน
// ==========================================
