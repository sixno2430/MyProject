import 'package:flutter/material.dart';

class PalmVarietiesScreen extends StatelessWidget {
  const PalmVarietiesScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                              color: Colors.white.withOpacity(0.15),
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
                        const SizedBox(width: 36), // บалансกับปุ่มย้อนกลับ
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ข้อมูลพันธุ์ปาล์ม 4 สายพันธุ์',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                          color: Colors.black.withOpacity(0.03),
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
                  ),
                  const SizedBox(height: 16),

                  // รายการพันธุ์ปาล์ม
                  _buildVarietyCard(
                    topColor: const Color(0xFF2D6A4F),
                    iconBgColor: const Color(0xFFE8F5E9),
                    name: 'เทเนอร่า (Tenera)',
                    scientificName: 'Elaeis guineensis var. tenera',
                    description: 'พันธุ์นิยมปลูกมากที่สุด ได้น้ำมันสูง\nเบลอิบานา · Dura × Pisifera',
                    usageText: 'ใช้ในสวนของคุณ: 2 แปลง',
                    usageColor: const Color(0xFF2D6A4F),
                    badge: 'นิยม',
                  ),
                  _buildVarietyCard(
                    topColor: const Color(0xFFF9A825),
                    iconBgColor: const Color(0xFFFFF8E1),
                    name: 'ดูร่าไวน์ (Dura)',
                    scientificName: 'Elaeis guineensis var. dura',
                    description: 'พันธุ์ตั้งต้น เปลือกหนา แข็งแกร่ง',
                    usageText: 'ใช้ในสวนของคุณ: 1 แปลง',
                    usageColor: const Color(0xFFF9A825),
                  ),
                  _buildVarietyCard(
                    topColor: const Color(0xFF42A5F5),
                    iconBgColor: const Color(0xFFE3F2FD),
                    name: 'คอมแพคท์ (Compact)',
                    scientificName: 'Elaeis guineensis (Compact)',
                    description: 'ต้นเตี้ย เหมาะพื้นที่เล็ก เก็บเกี่ยวง่าย',
                    usageText: 'ใช้ในสวนของคุณ: 1 แปลง',
                    usageColor: const Color(0xFF42A5F5),
                  ),
                  _buildVarietyCard(
                    topColor: const Color(0xFFAB47BC),
                    iconBgColor: const Color(0xFFF3E5F5),
                    name: 'ปิซิเฟอร่า (Pisifera)',
                    scientificName: 'Elaeis guineensis var. pisifera',
                    description: 'พันธุ์ผู้ ใช้ผสมพันธุ์เพื่อผลิต Tenera',
                    usageText: 'ไม่ได้ใช้ในสวนของคุณ',
                    usageColor: const Color(0xFFAB47BC),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarietyCard({
    required Color topColor,
    required Color iconBgColor,
    required String name,
    required String scientificName,
    required String description,
    required String usageText,
    required Color usageColor,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: topColor,
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
                    // ไอคอน
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
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('🌴 ', style: const TextStyle(fontSize: 14)),
                    Text(
                      usageText,
                      style: TextStyle(
                        fontSize: 13,
                        color: usageColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}