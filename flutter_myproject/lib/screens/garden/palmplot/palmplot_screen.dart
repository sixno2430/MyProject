// ============================================================
// palmplot_screen.dart — หน้า "แปลงสวนของฉัน"
//
// แสดงรายการแปลงสวนของ user พร้อมสถิติรวม (จำนวนแปลง / ไร่ / ต้น) และค้นหาได้
// เพิ่มแปลงใหม่ -> AddPlotScreen, แก้ไข -> bottom sheet (_EditGardenDialog), ลบได้
// API: GET/PUT/DELETE /api/gardens
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_myproject/screens/garden/palmplot/add_plot_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/config/app_config.dart';


// ==========================================
// 1. MODEL (เพิ่ม address + detailText)
// ==========================================
// ==========================================
// MODEL: พันธุ์ปาล์ม
// ==========================================
/// พันธุ์ปาล์มที่ปลูกในแปลง (พร้อมจำนวนต้น)
class PalmVariety {
  final String varietyId;
  final String varietyName;
  final int plantCount;

  PalmVariety({
    required this.varietyId,
    required this.varietyName,
    required this.plantCount,
  });

  factory PalmVariety.fromJson(Map<String, dynamic> json) {
    return PalmVariety(
      varietyId: json['variety_id']?.toString() ?? '',
      varietyName: json['variety_name']?.toString() ?? 'ไม่ระบุพันธุ์',
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// ข้อมูลแปลงสวน 1 แปลง
class Garden {
  final String gardenId;
  final String userId;
  final String gardenName;
  final double areaSize;
  final int plantCount;
  final int? plantYear;
  final int? plantAge;
  final String? address; // ← เพิ่ม
  final List<PalmVariety>? varieties;

  Garden({
    required this.gardenId,
    required this.userId,
    required this.gardenName,
    required this.areaSize,
    required this.plantCount,
    this.plantYear,
    this.plantAge,
    this.address, // ← เพิ่ม
    this.varieties,
  });

  /// แปลง JSON จาก API เป็น Garden
  factory Garden.fromJson(Map<String, dynamic> json) {
    List<PalmVariety>? varietyList;
    if (json['varieties'] != null && json['varieties'] is List) {
      varietyList = (json['varieties'] as List)
          .map((v) => PalmVariety.fromJson(v))
          .toList();
    }
    return Garden(
      gardenId: json['garden_id'] ?? '',
      userId: json['user_id'] ?? '',
      gardenName: json['garden_name'] ?? 'ไม่ระบุชื่อแปลง',
      areaSize: double.tryParse(json['area_size']?.toString() ?? '0') ?? 0.0,
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
      plantYear: json['plant_year'] != null
          ? int.tryParse(json['plant_year'].toString())
          : null,
      plantAge: json['plant_age'] != null
          ? int.tryParse(json['plant_age'].toString())
          : null,
      address: json['address']?.toString(), // ← เพิ่ม
      varieties: varietyList,
    );
  }

  // ← เพิ่ม: สร้างข้อความ "เหนื่อย่า · 5 ปี · 12 ไร่ · 330 ต้น"
  String get detailText {
    final parts = <String>[];
    if (plantAge != null) parts.add('$plantAge ปี');
    if (areaSize > 0) {
      parts.add(
        '${areaSize.toStringAsFixed(areaSize.truncateToDouble() == areaSize ? 0 : 2)} ไร่',
      );
    }
    if (plantCount > 0) parts.add('$plantCount ต้น');
    return parts.join(' · ');
  }
}

// ==========================================
// 2. MAIN SCREEN
// ==========================================
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
      final response = await http.delete(
        Uri.parse('$baseUrl/gardens/${garden.gardenId}'),
      );
      final body = json.decode(response.body);
      if (!mounted) return;
      if (body['isError'] == false) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบสำเร็จ')));
        fetchGardens();
      } else {
        throw Exception(body['errorMessage']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
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
            errorMessage =
                body['errorMessage'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
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
        errorMessage = 'ไม่สามารถเชื่อมต่อ Server ได้ ($e)';
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
        filteredGardens = gardens
            .where(
              (g) => g.gardenName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
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
      builder: (context) =>
          _EditGardenDialog(garden: garden, primaryGreen: primaryGreen),
    );

    if (result != null) {
      setState(() => isLoading = true);
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/gardens/${garden.gardenId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(result),
        );
        final body = json.decode(response.body);
        if (!mounted) return;
        if (body['isError'] == false) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('แก้ไขสำเร็จ')));
          fetchGardens();
        } else {
          throw Exception(body['errorMessage']);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')));
      }
    }
  }

  /// จำนวนต้นรวมทุกแปลง
  int get totalPlants => gardens.fold(0, (sum, item) => sum + item.plantCount);
  /// พื้นที่รวมทุกแปลง (ไร่)
  double get totalArea => gardens.fold(0.0, (sum, item) => sum + item.areaSize);

  static const Color _bgColor = Color(0xFFF5F5F5);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  /// แสดงพื้นที่ ตัดทศนิยม .0 ทิ้ง (20.0 -> "20")
  String _formatArea(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  /// เปิดหน้าเพิ่มแปลง กลับมาแล้วโหลดรายการใหม่
  void _openAddPlot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPlotScreen()),
    ).then((_) => fetchGardens());
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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 72),
              child: Row(
                children: [
                  if (canPop) ...[
                    _buildHeaderButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แปลงสวนของฉัน 🌴',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'จัดการข้อมูลแปลงปาล์มน้ำมัน',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
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
  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
          const Text(
            'รายการแปลงสวน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const Spacer(),
          if (!isLoading && errorMessage.isEmpty)
            Text(
              '${filteredGardens.length} แปลง',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
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
          subtitle: isSearching
              ? 'ลองค้นหาด้วยชื่ออื่น'
              : 'เพิ่มแปลงสวนแรกของคุณเพื่อเริ่มบันทึกข้อมูล',
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
          return _buildPlotCard(
            garden: garden,
            onEdit: () => _editGarden(garden),
            onDelete: () => _deleteGarden(garden),
          );
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ],
        ],
      ),
    );
  }

  // การ์ดแปลงสวน: สไตล์เดียวกับการ์ดกิจกรรมในหน้าหลัก
  /// การ์ดแปลงสวน 1 แปลง พร้อมเมนูแก้ไข/ลบ
  Widget _buildPlotCard({
    required Garden garden,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🌴', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garden.gardenName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                if (garden.detailText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    garden.detailText,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
                if (garden.varieties != null &&
                    garden.varieties!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: garden.varieties!
                        .map(
                          (v) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _lightGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🌿 ${v.varietyName} · ${v.plantCount} ต้น',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFD32F2F),
                    ),
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

// ==========================================
// Bottom sheet แก้ไขแปลงสวน
// ==========================================
/// bottom sheet แก้ไขแปลงสวน คืนค่า Map ข้อมูลใหม่เมื่อกดบันทึก
class _EditGardenDialog extends StatefulWidget {
  final Garden garden;
  final Color primaryGreen;

  const _EditGardenDialog({required this.garden, required this.primaryGreen});

  @override
  State<_EditGardenDialog> createState() => _EditGardenDialogState();
}

class _EditGardenDialogState extends State<_EditGardenDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _countCtrl;

  /// เก็บเป็น ค.ศ. (ตามฐานข้อมูล) แต่แสดงผลเป็น พ.ศ.
  int? _plantYear;

  Color get _green => widget.primaryGreen;

  @override
  void initState() {
    super.initState();
    final g = widget.garden;
    _nameCtrl = TextEditingController(text: g.gardenName);
    _addressCtrl = TextEditingController(text: g.address ?? '');
    _areaCtrl = TextEditingController(text: g.areaSize > 0 ? _trimZero(g.areaSize) : '');
    _countCtrl = TextEditingController(text: g.plantCount > 0 ? '${g.plantCount}' : '');
    _plantYear = g.plantYear;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  // 20.0 -> "20", 12.5 -> "12.5"
  /// ตัดทศนิยม .0 ทิ้ง (20.0 -> "20")
  String _trimZero(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// อายุต้นปาล์ม (ปี) คำนวณจากปีที่ปลูก
  int? get _plantAge {
    if (_plantYear == null) return null;
    final age = DateTime.now().year - _plantYear!;
    return age < 0 ? null : age;
  }

  /// เปิดรายการให้เลือกปีที่ปลูก (แสดงเป็น พ.ศ. เก็บเป็น ค.ศ.)
  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final years = List.generate(41, (i) => now - i); // ย้อนหลัง 40 ปี
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 360,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('เลือกปีที่ปลูก',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, i) {
                    final y = years[i];
                    final selected = y == _plantYear;
                    return ListTile(
                      title: Text(
                        'พ.ศ. ${y + 543}',
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? _green : null,
                        ),
                      ),
                      trailing: Text(
                        now - y == 0 ? 'ปีนี้' : '${now - y} ปี',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      selected: selected,
                      onTap: () => Navigator.pop(context, y),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _plantYear = picked);
  }

  /// ตรวจฟอร์ม แล้วปิด sheet พร้อมส่งข้อมูลกลับ
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'garden_name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'area_size': double.tryParse(_areaCtrl.text.trim()) ?? 0,
      'plant_year': _plantYear,
      'plant_count': int.tryParse(_countCtrl.text.trim()) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    // ดันฟอร์มขึ้นตามความสูงคีย์บอร์ด ช่องล่างๆ จะได้ไม่ถูกบัง
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── หัว: แถบจับ + ชื่อ + ปุ่มปิด ──
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🌴', style: TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'แก้ไขแปลงสวน',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              widget.garden.gardenId,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // ── ฟอร์ม ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('ข้อมูลทั่วไป'),
                        _field(
                          label: 'ชื่อแปลงสวน *',
                          controller: _nameCtrl,
                          icon: Icons.forest_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อแปลงสวน' : null,
                        ),
                        _field(
                          label: 'ที่อยู่ / ตำแหน่งแปลง',
                          hint: 'เช่น ม.3 ต.ท่าข้าม อ.พุนพิน',
                          controller: _addressCtrl,
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        _sectionTitle('ข้อมูลการปลูก'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(
                                label: 'ขนาดพื้นที่',
                                controller: _areaCtrl,
                                icon: Icons.square_foot,
                                suffix: 'ไร่',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = double.tryParse(v.trim());
                                  return (n == null || n < 0) ? 'ตัวเลขไม่ถูกต้อง' : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: 'จำนวนต้น',
                                controller: _countCtrl,
                                icon: Icons.park_outlined,
                                suffix: 'ต้น',
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = int.tryParse(v.trim());
                                  return (n == null || n < 0) ? 'ใส่เป็นจำนวนเต็ม' : null;
                                },
                              ),
                            ),
                          ],
                        ),
                        _yearSelector(),
                      ],
                    ),
                  ),
                ),

                // ── ปุ่ม ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ยกเลิก', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text(
                            'บันทึกการแก้ไข',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// หัวข้อหมวดในฟอร์ม
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
      ),
    );
  }

  /// ช่องเลือกปีที่ปลูก พร้อมป้ายบอกอายุต้น
  Widget _yearSelector() {
    final age = _plantAge;
    return InkWell(
      onTap: _pickYear,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(label: 'ปีที่ปลูก', icon: Icons.calendar_month_outlined),
        child: Row(
          children: [
            Text(
              _plantYear == null ? 'เลือกปี' : 'พ.ศ. ${_plantYear! + 543}',
              style: TextStyle(
                fontSize: 15,
                color: _plantYear == null ? Colors.grey[400] : const Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            if (age != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  age == 0 ? 'ปลูกปีนี้' : 'อายุ $age ปี',
                  style: TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  /// หน้าตาช่องกรอกที่ใช้ร่วมกันในฟอร์ม
  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon, color: _green, size: 20),
      labelStyle: TextStyle(color: Colors.grey[600]),
      floatingLabelStyle: TextStyle(color: _green),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  /// ช่องกรอกข้อความ 1 ช่อง
  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? suffix,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        cursorColor: _green,
        decoration: _decoration(label: label, icon: icon, hint: hint, suffix: suffix),
      ),
    );
  }
}
