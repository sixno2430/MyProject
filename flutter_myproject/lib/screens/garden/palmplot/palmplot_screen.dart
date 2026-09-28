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
  Future<void> _editGarden(Garden garden) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
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

  int get totalPlants => gardens.fold(0, (sum, item) => sum + item.plantCount);
  double get totalArea => gardens.fold(0.0, (sum, item) => sum + item.areaSize);

  static const Color _bgColor = Color(0xFFF5F5F5);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  String _formatArea(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

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
// ← เพิ่มใหม่: Dialog แก้ไขสวน
// ==========================================
class _EditGardenDialog extends StatefulWidget {
  final Garden garden;
  final Color primaryGreen;

  const _EditGardenDialog({required this.garden, required this.primaryGreen});

  @override
  State<_EditGardenDialog> createState() => _EditGardenDialogState();
}

class _EditGardenDialogState extends State<_EditGardenDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _countCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.garden.gardenName);
    _addressCtrl = TextEditingController(text: widget.garden.address ?? '');
    _areaCtrl = TextEditingController(text: widget.garden.areaSize.toString());
    _yearCtrl = TextEditingController(
      text: widget.garden.plantYear?.toString() ?? '',
    );
    _countCtrl = TextEditingController(
      text: widget.garden.plantCount.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'แก้ไขแปลงสวน',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField('ชื่อแปลงสวน', _nameCtrl),
            _buildField('ที่อยู่', _addressCtrl),
            _buildField('ขนาด (ไร่)', _areaCtrl, TextInputType.number),
            _buildField('ปีที่ปลูก', _yearCtrl, TextInputType.number),
            _buildField('จำนวนต้น', _countCtrl, TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[700])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.pop(context, {
              'garden_name': _nameCtrl.text.trim(),
              'address': _addressCtrl.text.trim(),
              'area_size': double.tryParse(_areaCtrl.text.trim()) ?? 0,
              'plant_year': int.tryParse(_yearCtrl.text.trim()),
              'plant_count': int.tryParse(_countCtrl.text.trim()) ?? 0,
            });
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, [
    TextInputType? type,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        cursorColor: widget.primaryGreen,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          floatingLabelStyle: TextStyle(color: widget.primaryGreen),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryGreen, width: 1.5),
          ),
        ),
      ),
    );
  }
}
