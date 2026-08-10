import 'package:flutter/material.dart';

class AddGardenCareScreen extends StatefulWidget {
  const AddGardenCareScreen({super.key});

  @override
  State<AddGardenCareScreen> createState() => _AddGardenCareScreenState();
}

class _AddGardenCareScreenState extends State<AddGardenCareScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final _formKey = GlobalKey<FormState>();

  String _selectedPlot = 'แปลง A — บ้านหน่งกวาง';
  String _selectedType = 'ใส่ปุ๋ย';
  DateTime _selectedDate = DateTime.now();
  final _detailController = TextEditingController();
  final _costController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _plots = [
    'แปลง A — บ้านหน่งกวาง',
    'แปลง B — ไร่นาสวน',
    'แปลง C — สวนในบึง',
    'แปลง D — ห้วยป่าซาง',
  ];

  final List<Map<String, dynamic>> _careTypes = [
    {'label': 'ใส่ปุ๋ย', 'icon': '💊', 'color': Color(0xFF4CAF50)},
    {'label': 'ตัดแต่ง', 'icon': '✂️', 'color': Color(0xFFFF9800)},
    {'label': 'กำจัดวัชพืช', 'icon': '🌿', 'color': Color(0xFF9C27B0)},
    {'label': 'ให้น้ำ', 'icon': '💧', 'color': Color(0xFF2196F3)},
    {'label': 'พ่นยา', 'icon': '🔫', 'color': Color(0xFFF44336)},
    {'label': 'อื่นๆ', 'icon': '🛠️', 'color': Color(0xFF607D8B)},
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // String get _thaiDate {
  //   final d = DateFormat('d MMMM yyyy', 'th').format(_selectedDate);
  //   return d.replaceFirst(
  //     _selectedDate.year.toString(),
  //     (_selectedDate.year + 543).toString(),
  //   );
  // }

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
        title: const Column(
          children: [
            Text(
              'การดูแลรักษาสวน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'บันทึกการดูแล / การใส่ปุ๋ย',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // เลือกแปลงสวน
                    _buildLabel('แปลงสวน *'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryGreen, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPlot,
                          icon: Icon(Icons.keyboard_arrow_down, color: primaryGreen),
                          style: const TextStyle(color: Colors.black87, fontSize: 15),
                          items: _plots.map((plot) {
                            return DropdownMenuItem(value: plot, child: Text(plot));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPlot = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // เลือกประเภทกิจกรรม
                    _buildLabel('ประเภทกิจกรรม *'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _careTypes.map((type) {
                        final isSelected = _selectedType == type['label'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = type['label']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? (type['color'] as Color).withOpacity(0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? type['color'] as Color : Colors.grey[300]!,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(type['icon'], style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  type['label'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? type['color'] as Color : Colors.grey[700],
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // วันที่ดำเนินการ
                    _buildLabel('วันที่ดำเนินการ *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Text('📅 ', style: TextStyle(fontSize: 16)),
                            //Text(_thaiDate, style: const TextStyle(fontSize: 15)),
                            const Spacer(),
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // รายละเอียด
                    _buildLabel('รายละเอียด *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _detailController,
                      hint: 'เช่น ปุ๋ย 15-15-15 · 40 กก.',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // ปริมาณ / จำนวน
                    _buildLabel('ปริมาณ / จำนวน'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _amountController,
                      hint: 'เช่น 40 กก. / 480 ต้น / 2 วัน',
                    ),
                    const SizedBox(height: 16),

                    // ค่าใช้จ่าย
                    _buildLabel('ค่าใช้จ่าย (บาท)'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _costController,
                      hint: 'เช่น 1,200',
                      keyboardType: TextInputType.number,
                      prefix: const Text('💰 ', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),

                    // หมายเหตุ
                    _buildLabel('หมายเหตุ'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: null,
                      hint: 'เพิ่มเติม...',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ปุ่มบันทึก
          Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: บันทึกข้อมูล
                  Navigator.pop(context);
                }
              },
              icon: const Text('🛠️', style: TextStyle(fontSize: 18)),
              label: const Text(
                'บันทึกการดูแล',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40916C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) return 'กรุณากรอกข้อมูล';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}