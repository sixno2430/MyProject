import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_myproject/config/app_config.dart';
import 'palm_variety.dart';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final body = jsonEncode({
      'variety_name': _nameController.text.trim(),
      'scientific_name': _scientificController.text.trim(),
    });
    const headers = {'Content-Type': 'application/json'};

    try {
      final response = _isEdit
          ? await http.put(
              Uri.parse('${AppConfig.apiBaseUri}/varieties/${widget.existing!.varietyId}'),
              headers: headers,
              body: body,
            )
          : await http.post(
              Uri.parse('${AppConfig.apiBaseUri}/varieties'),
              headers: headers,
              body: body,
            );
      final res = jsonDecode(response.body);
      if (res['isError'] == true) throw Exception(res['errorMessage']);
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
          decoration: InputDecoration(
            hintText: hint,
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
