import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/palmplot/add_plot_screen.dart';
import 'package:http/http.dart' as http;



// ==========================================
// 1. MODEL CLASS: สำหรับแปลงข้อมูล JSON จาก Server
// ==========================================
class Garden {
  final String gardenId;
  final String userId;
  final String gardenName;
  final double areaSize;
  final int plantCount;
  final int? plantYear;
  final int? plantAge;

  Garden({
    required this.gardenId,
    required this.userId,
    required this.gardenName,
    required this.areaSize,
    required this.plantCount,
    this.plantYear,
    this.plantAge,
  });

  // ฟังก์ชันแปลงข้อมูล JSON ที่ส่งมาจาก Node.js API ให้เป็น Object ใน Flutter
  factory Garden.fromJson(Map<String, dynamic> json) {
    return Garden(
      gardenId: json['garden_id'] ?? '',
      userId: json['user_id'] ?? '',
      gardenName: json['garden_name'] ?? 'ไม่ระบุชื่อแปลง',
      // ป้องกัน Error โดยการแปลงตัวเลขเป็น double/int แบบปลอดภัย
      areaSize: double.tryParse(json['area_size']?.toString() ?? '0') ?? 0.0,
      plantCount: int.tryParse(json['plant_count']?.toString() ?? '0') ?? 0,
      plantYear: json['plant_year'] != null
          ? int.tryParse(json['plant_year'].toString())
          : null,
      plantAge: json['plant_age'] != null
          ? int.tryParse(json['plant_age'].toString())
          : null,
    );
  }
}

// ==========================================
// 2. MAIN SCREEN CLASS: หน้าจอหลัก (StatefulWidget)
// ==========================================
class PalmplotScreen extends StatefulWidget {
  const PalmplotScreen({super.key});

  @override
  State<PalmplotScreen> createState() => _PalmplotScreenState();
}

class _PalmplotScreenState extends State<PalmplotScreen> {
  // กำหนดสีหลักของหน้าจอ (สีเขียวสวนปาล์ม)
  final Color primaryGreen = const Color(0xFF2D6A4F);

  // ตัวแปรสำหรับเก็บข้อมูล
  List<Garden> gardens = []; // เก็บแปลงสวนทั้งหมดที่ดึงมาจาก DB
  List<Garden> filteredGardens =
      []; // เก็บแปลงสวนที่ผ่านการค้นหา (เอาไว้แสดงบน UI)
  bool isLoading = true; // สถานะกำลังโหลดข้อมูล ( true = แสดงตัวหมุนโหลด )
  String errorMessage = ''; // ข้อความแจ้งเตือนเมื่อเกิด Error

  // ตัวควบคุมช่องกรอกข้อความค้นหา
  final TextEditingController searchController = TextEditingController();

  // กำหนด IP/URL ของ Server ตามอุปกรณ์ที่รันแอป
  String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000'; // สำหรับ Web Browser
    if (Platform.isAndroid)
      return 'http://10.0.2.2:3000'; // สำหรับ Android Emulator
    return 'http://127.0.0.1:3000'; // สำหรับ iOS / เครื่องจริง
  }

  // ฟังก์ชันที่จะทำงานทันทีที่เปิดหน้านี้ขึ้นมา
  @override
  void initState() {
    super.initState();
    fetchGardens(); // สั่งดึงข้อมูลจาก Server ทันที
  }

  // ==========================================
  // API FUNCTION: ดึงข้อมูลแปลงสวนจาก Node.js
  // ==========================================
  Future<void> fetchGardens() async {
    const String userId =
        'U002'; // รหัส User ที่ต้องการดูสวน (สามารถปรับเปลี่ยนตาม Login ได้)
    final url = Uri.parse('$baseUrl/api/gardens/$userId');

    try {
      // ยิง HTTP GET Request ไปยัง Server
      final response = await http.get(url);

      // ถ้า Server ตอบกลับสำเร็จ (HTTP 200 OK)
      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        // ตรวจสอบว่า API ไม่ติด Error
        if (body['isError'] == false && body['data'] != null) {
          final List rawData = body['data'];
          // แปลงข้อมูล Array JSON ให้เป็น List<Garden>
          final loadedGardens = rawData.map((e) => Garden.fromJson(e)).toList();

          // อัปเดตหน้าจอด้วยข้อมูลใหม่
          setState(() {
            gardens = loadedGardens;
            filteredGardens = loadedGardens; // ตั้งค่าเริ่มต้นให้แสดงทั้งหมด
            isLoading = false; // ปิดสถานะกำลังโหลด
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
      // หากเชื่อมต่อ Server ไม่ติด (เช่น ลืมเปิด node server.js)
      setState(() {
        errorMessage = 'ไม่สามารถเชื่อมต่อ Server ได้ ($e)';
        isLoading = false;
      });
    }
  }

  // ==========================================
  // SEARCH FUNCTION: กรองข้อมูลแปลงสวนตามคำค้นหา
  // ==========================================
  void _filterGardens(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredGardens = gardens; // ถ้าช่องค้นหาว่าง ให้แสดงสวนทั้งหมด
      } else {
        // กรองหาเฉพาะสวนที่มีชื่อตรงกับคำที่พิมพ์
        filteredGardens = gardens
            .where(
              (g) => g.gardenName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  // CALCULATE FUNCTION: คำนวณผลรวมต้นปาล์มทั้งหมดจากทุกสวน
  int get totalPlants => gardens.fold(0, (sum, item) => sum + item.plantCount);

  // ==========================================
  // BUILD UI: ส่วนการแสดงผลหน้าจอ
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247),

      // แถบด้านบน (AppBar)
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text(
          'แปลงสวนของฉัน',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // ปุ่มเครื่องหมาย + มุมขวาบน (สำหรับกดไปหน้าเพิ่มแปลงสวน)
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPlotScreen()),
              ).then(
                (_) => fetchGardens(),
              ); // เมื่อกดกลับมาหน้านี้ ให้รีโหลดข้อมูลใหม่
            },
          ),
        ],
      ),

      // RefreshIndicator: ดึงหน้าจอลงล่างสุดเพื่อสั่งดึงข้อมูลใหม่ (Pull to Refresh)
      body: RefreshIndicator(
        onRefresh: fetchGardens,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------
              // 1. ช่องกรอกค้นหา (TextField)
              // ----------------------------------
              TextField(
                controller: searchController,
                onChanged: _filterGardens, // สั่งทำงานเมื่อพิมพ์ข้อความ
                decoration: InputDecoration(
                  hintText: 'ค้นหาแปลงสวน...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------
              // 2. ส่วนสรุปยอด (คำนวณจากข้อมูลจริง)
              // ----------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummary(
                    '${gardens.length}',
                    'แปลงสวน',
                  ), // ดึงจำนวนแปลงจริง
                  _buildSummary(
                    '$totalPlants',
                    'ต้นปาล์ม',
                  ), // ดึงผลรวมจำนวนต้นจริง
                ],
              ),
              const SizedBox(height: 20),

              // ----------------------------------
              // 3. ส่วนแสดงรายการการ์ดแปลงสวน (ตาม State)
              // ----------------------------------

              // ถ้ากำลังโหลดข้อมูล -> แสดงวงกลมหมุนๆ
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              // ถ้ามี Error -> แสดงข้อความพร้อมปุ่มกดลองใหม่
              else if (errorMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isLoading = true);
                            fetchGardens();
                          },
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              // ถ้าไม่พบข้อมูลสวนเลย -> แสดงข้อความแจ้งเตือน
              else if (filteredGardens.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'ไม่พบข้อมูลแปลงสวน',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              // แสดงรายการสวนปาล์มจริงที่ดึงได้จาก Database
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // ปิดการ Scroll ซ้อนกัน
                  itemCount: filteredGardens.length,
                  itemBuilder: (context, index) {
                    final garden = filteredGardens[index];
                    return _buildPlotCard(
                      name: garden.gardenName, // ชื่อสวนจริง
                      // ขนาดไร่ (ถ้าเป็นจำนวนเต็มไม่แสดงทศนิยม ถ้าเป็นเศษแสดง 2 ตำแหน่ง)
                      area:
                          '${garden.areaSize.toStringAsFixed(garden.areaSize.truncateToDouble() == garden.areaSize ? 0 : 2)} ไร่',
                      trees: '${garden.plantCount} ต้น', // จำนวนต้นจริง
                      progress: 0.75, // แถบความสมบูรณ์ ( Mockup ไว้ก่อน )
                      progressColor: Colors.green,
                      status: 'สมบูรณ์',
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGET 1: ข้อความสรุปตัวเลขด้านบน
  // ==========================================
  Widget _buildSummary(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGET 2: การ์ดแสดงข้อมูลแต่ละแปลงสวน
  // ==========================================
  Widget _buildPlotCard({
    required String name,
    required String area,
    required String trees,
    required double progress,
    required Color progressColor,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row แถวบน: ไอคอนต้นไม้, ชื่อแปลง, ขนาดไร่/จำนวนต้น, และ ป้ายสถานะ
          Row(
            children: [
              const Text('🌴', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$area · $trees',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // ป้ายสถานะ (สมบูรณ์/ต้องดูแล)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // แถบหลอดพลังความสมบูรณ์ (LinearProgressIndicator)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          // Row แถวล่าง: เปอร์เซ็นต์ความสมบูรณ์ และ ผลผลิต กก.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความสมบูรณ์ ${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '1,800 กก.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
