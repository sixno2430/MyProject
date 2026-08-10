import 'package:flutter/material.dart';

class AddPalmVarietyScreen extends StatefulWidget {
  const AddPalmVarietyScreen({super.key});

  @override
  State<AddPalmVarietyScreen> createState() => _AddPalmVarietyScreenState();
}

class _AddPalmVarietyScreenState extends State<AddPalmVarietyScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final _formKey = GlobalKey<FormState>();

  // ตัวเลือกสีแถบประจำพันธุ์
  final List<Color> _varietyColors = [
    const Color(0xFF2D6A4F), // เขียว (Tenera)
    const Color(0xFFF9A825), // เหลือง (Dura)
    const Color(0xFF42A5F5), // ฟ้า (Compact)
    const Color(0xFFAB47BC), // ม่วง (Pisifera)
    const Color(0xFFEF5350), // แดง
    const Color(0xFF8D6E63), // น้ำตาล
  ];

  int _selectedColorIndex = 0;
  bool _isPopular = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          'เพิ่มพันธุ์ปาล์ม',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ชื่อพันธุ์ปาล์ม
              _buildTextField(
                label: 'ชื่อพันธุ์ปาล์ม *',
                hint: 'เช่น เทเนอร่า (Tenera)',
                icon: Icons.label_outline,
              ),
              const SizedBox(height: 16),

              // ชื่อวิทยาศาสตร์
              _buildTextField(
                label: 'ชื่อวิทยาศาสตร์',
                hint: 'เช่น Elaeis guineensis var. tenera',
                icon: Icons.science_outlined,
              ),
              const SizedBox(height: 16),

              // คำอธิบาย
              _buildTextField(
                label: 'คำอธิบาย *',
                hint: 'เช่น พันธุ์นิยมปลูกมากที่สุด ได้น้ำมันสูง...',
                maxLines: 3,
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              // ลักษณะเด่น
              _buildTextField(
                label: 'ลักษณะเด่น',
                hint: 'เช่น เปลือกบาง น้ำมันสูง โตเร็ว',
                icon: Icons.star_border,
              ),
              const SizedBox(height: 24),

              // เลือกสีแถบประจำพันธุ์
              const Text(
                'สีแถบประจำพันธุ์ *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_varietyColors.length, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _varietyColors[index],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _varietyColors[index].withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // สถานะนิยม
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFF2D6A4F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'พันธุ์ยอดนิยม',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'แสดง Badge "นิยม" บนการ์ดพันธุ์ปาล์ม',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPopular,
                      onChanged: (value) {
                        setState(() {
                          _isPopular = value;
                        });
                      },
                      activeColor: primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ปุ่มบันทึก
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('ยกเลิก', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: บันทึกข้อมูล
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text(
                        'บันทึก',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          maxLines: maxLines,
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'กรุณากรอก$label';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}