import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/plamvarieties/palm_variety.dart';
/// Dropdown เลือกพันธุ์ปาล์ม
///
/// ใช้งาน 2 แบบ:
/// 1. มีข้อมูลแล้ว → ส่งผ่าน [varieties]
/// 2. ยังไม่มีข้อมูล → ส่งผ่าน [futureVarieties] ให้ Widget โหลดเอง
///
/// ตัวอย่างใช้งาน:
/// ```dart
/// PalmVarietyDropdown(
///   varieties: listFromService, // ถ้ามีข้อมูลแล้ว
///   value: _selectedVarietyId,
///   onChanged: (v) => setState(() => _selectedVarietyId = v),
/// )
/// ```
class PalmVarietyDropdown extends StatefulWidget {
  /// รายการพันธุ์ปาล์ม (ถ้ามีข้อมูลแล้ว)
  final List<PalmVariety>? varieties;

  /// Future สำหรับโหลดข้อมูล (ถ้าอยากให้ Widget จัดการเอง)
  final Future<List<PalmVariety>>? futureVarieties;

  /// ค่าที่เลือกปัจจุบัน (variety_id)
  final String? value;

  /// Callback เมื่อเลือกเปลี่ยน
  final ValueChanged<String?> onChanged;

  /// Validator (optional)
  final String? Function(String?)? validator;

  /// ข้อความ hint
  final String hintText;

  const PalmVarietyDropdown({
    super.key,
    this.varieties,
    this.futureVarieties,
    this.value,
    required this.onChanged,
    this.validator,
    this.hintText = 'เลือกพันธุ์ปาล์ม',
  });

  @override
  State<PalmVarietyDropdown> createState() => _PalmVarietyDropdownState();
}

class _PalmVarietyDropdownState extends State<PalmVarietyDropdown> {
  List<PalmVariety>? _varieties;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.varieties != null) {
      _varieties = widget.varieties;
    } else if (widget.futureVarieties != null) {
      _isLoading = true;
      _loadVarieties();
    }
  }

  Future<void> _loadVarieties() async {
    try {
      final list = await widget.futureVarieties!;
      if (mounted) {
        setState(() {
          _varieties = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (_isLoading) {
      return _buildLoading();
    }

    // Error
    if (_error != null) {
      return _buildError();
    }

    // ไม่มีข้อมูลเลย
    if (_varieties == null || _varieties!.isEmpty) {
      return _buildEmpty();
    }

    // Dropdown ปกติ
    return DropdownButtonFormField<String>(
      value: widget.value,
      hint: Text(widget.hintText),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2D6A4F)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _varieties!.map((v) {
        return DropdownMenuItem<String>(
          value: v.varietyId,
          child: Text(
            v.varietyName,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
          ),
        );
      }).toList(),
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D6A4F)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'โหลดพันธุ์ปาล์มไม่สำเร็จ',
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _loadVarieties();
            },
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          'ไม่มีข้อมูลพันธุ์ปาล์ม',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ),
    );
  }
}
