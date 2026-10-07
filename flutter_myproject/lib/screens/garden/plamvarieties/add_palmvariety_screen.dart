// ============================================================
// add_palmvariety_screen.dart (plamvarieties/) — ฟอร์มเพิ่ม/แก้ไขพันธุ์ปาล์มของผู้ใช้
//
// กรอกชื่อพันธุ์ (บังคับ) และชื่อวิทยาศาสตร์ (ไม่บังคับ)
// ส่ง existing มา = แก้ไข, ไม่ส่ง = เพิ่มใหม่ — บันทึกสำเร็จปิดหน้าด้วย true
// (นำแบบฟอร์มเดิมจาก palmvarieties/ ที่ถูกลบไปตอนจัดโฟลเดอร์ซ้ำ กลับมาใช้)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/palm_variety_service.dart';
import 'palm_variety.dart';

/// ฟอร์มพันธุ์ปาล์ม
class AddPalmVarietyScreen extends StatefulWidget {
  /// ข้อมูลเดิม (ส่งมา = โหมดแก้ไข, ไม่ส่ง = เพิ่มใหม่)
  final PalmVariety? existing;

  const AddPalmVarietyScreen({super.key, this.existing});

  @override
  State<AddPalmVarietyScreen> createState() => _AddPalmVarietyScreenState();
}

class _AddPalmVarietyScreenState extends State<AddPalmVarietyScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.varietyName;
      _scientificController.text = e.scientificName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    super.dispose();
  }

  /// ตรวจฟอร์มแล้วบันทึก สำเร็จแล้วปิดหน้า
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await PalmVarietyService.saveVariety(
        id: widget.existing?.varietyId,
        name: _nameController.text.trim(),
        scientificName: _scientificController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'แก้ไขพันธุ์ปาล์มแล้ว' : 'เพิ่มพันธุ์ปาล์มแล้ว')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit ? 'แก้ไขพันธุ์ปาล์ม' : 'เพิ่มพันธุ์ปาล์ม',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              _buildTextField(
                label: 'ชื่อพันธุ์ปาล์ม *',
                hint: 'เช่น เทเนอรา (Tenera)',
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อพันธุ์' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'ชื่อวิทยาศาสตร์',
                hint: 'เช่น Elaeis guineensis var. tenera',
                controller: _scientificController,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('ยกเลิก', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _save,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 20),
                      label: const Text(
                        'บันทึก',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ช่องกรอกข้อความพร้อมหัวข้อ
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
        ),
      ],
    );
  }
}
