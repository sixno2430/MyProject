// ============================================================
// record_purchase_screen.dart — บันทึกการรับซื้อ 1 รายการ
//
// ขั้นตอน: 1) ค้นหาเกษตรกร  2) เลือกผลผลิตที่ "รอขาย"  3) เลือกเกรด/ราคา + น้ำหนักที่ชั่งจริง
// เปิดจากล็อตที่เกษตรกรส่งมา (incoming) จะเลือกเกษตรกร + ผลผลิตไว้ให้แล้ว เหลือแค่ขั้น 3
// บันทึกแล้วเซิร์ฟเวอร์เปลี่ยนผลผลิตฝั่งเกษตรกรเป็น "ขายแล้ว" ให้อัตโนมัติ
// ปิดหน้าด้วย true เมื่อบันทึกสำเร็จ
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'package:flutter_myproject/services/shop_service.dart';
import 'package:flutter_myproject/theme/role_theme.dart';

class RecordPurchaseScreen extends StatefulWidget {
  final ShopInfo shop;

  /// ล็อตที่เกษตรกรส่งมาขายร้านนี้ (null = เริ่มจากค้นหาเกษตรกรเอง)
  final IncomingLot? lot;

  const RecordPurchaseScreen({super.key, required this.shop, this.lot});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  static const theme = RoleTheme.shop;
  final NumberFormat _money = NumberFormat('#,##0.00');
  final NumberFormat _kg = NumberFormat('#,##0.##');

  String _userId = '';

  // ขั้น 1: เกษตรกร
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<FarmerResult> _results = [];
  FarmerResult? _farmer;

  // ขั้น 2: ผลผลิต
  bool _loadingHarvests = false;
  List<PendingHarvest> _harvests = [];
  PendingHarvest? _harvest;

  // ขั้น 3: ราคา + น้ำหนัก
  List<ShopPriceRate> _rates = [];
  String? _grade; // null = กำหนดราคาเอง
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final lot = widget.lot;
    if (lot != null) {
      _farmer = lot.farmer;
      _harvests = [lot.harvest];
      _selectHarvest(lot.harvest);
    }
    _init();
  }

  Future<void> _init() async {
    _userId = await AuthService.getUserId() ?? '';
    try {
      final all = await ShopService.fetchPrices(widget.shop.shopId);
      // ราคาที่ใช้อยู่วันนี้ เกรดละ 1 ราคา (เริ่มใช้ล่าสุด)
      final byGrade = <String, ShopPriceRate>{};
      for (final r in all.where((r) => r.status == 'current')) {
        final old = byGrade[r.grade];
        if (old == null || (r.effectiveDate ?? '').compareTo(old.effectiveDate ?? '') > 0) byGrade[r.grade] = r;
      }
      if (!mounted) return;
      setState(() {
        _rates = byGrade.values.toList()..sort((a, b) => b.pricePerKg.compareTo(a.pricePerKg));
        if (_rates.isNotEmpty) _pickGrade(_rates.first);
      });
    } catch (_) {
      // โหลดราคาไม่ได้ก็ยังกรอกราคาเองได้
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ---------- ขั้น 1 ----------

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    // รอให้หยุดพิมพ์ก่อนค่อยค้น ไม่ยิง API ทุกตัวอักษร
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String text) async {
    if (text.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await ShopService.searchFarmers(_userId, text.trim());
      if (!mounted || text != _searchCtrl.text) return; // ผลของคำค้นเก่า ทิ้งไป
      setState(() => _results = r);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectFarmer(FarmerResult f) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _farmer = f;
      _harvest = null;
      _harvests = [];
      _loadingHarvests = true;
    });
    try {
      final list = await ShopService.fetchPendingHarvests(_userId, f.userId);
      if (!mounted) return;
      setState(() {
        _harvests = list;
        if (list.length == 1) _selectHarvest(list.first);
      });
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loadingHarvests = false);
    }
  }

  // ---------- ขั้น 2-3 ----------

  void _selectHarvest(PendingHarvest h) {
    _harvest = h;
    // น้ำหนักตั้งต้น = ที่เกษตรกรบันทึกไว้ ร้านแก้เป็นน้ำหนักที่ชั่งจริงได้
    _qtyCtrl.text = h.quantity == 0 ? '' : _kg.format(h.quantity).replaceAll(',', '');
  }

  void _pickGrade(ShopPriceRate r) {
    _grade = r.grade;
    _priceCtrl.text = r.pricePerKg.toStringAsFixed(2);
  }

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;
  double get _price => double.tryParse(_priceCtrl.text.trim()) ?? 0;
  double get _total => _qty * _price;
  bool get _canSave => _harvest != null && _qty > 0 && _price > 0 && !_saving;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: theme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ShopService.createPurchase(
        userId: _userId,
        shopId: widget.shop.shopId,
        harvestId: _harvest!.harvestId,
        quantity: _qty,
        pricePerKg: _price,
        purchaseDate: DateFormat('yyyy-MM-dd').format(_date),
      );
      if (!mounted) return;
      _toast('บันทึกการรับซื้อแล้ว ผลผลิตของ ${_farmer!.name} เปลี่ยนเป็น "ขายแล้ว"');
      Navigator.pop(context, true);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red : theme.primary));
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('บันทึกการรับซื้อ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (!widget.shop.isOpen)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Text(
                'ร้านตั้งสถานะ "ปิดรับซื้อชั่วคราว" อยู่ ยังบันทึกได้ตามปกติ',
                style: TextStyle(fontSize: 13, color: Color(0xFF8D6E00)),
              ),
            ),
          _section(1, 'เกษตรกร', _buildFarmerStep()),
          if (_farmer != null) _section(2, 'ผลผลิตที่รอขาย', _buildHarvestStep()),
          if (_harvest != null) _section(3, 'ราคาและน้ำหนัก', _buildPriceStep()),
        ],
      ),
      bottomNavigationBar: _harvest == null ? null : _buildSaveBar(),
    );
  }

  Widget _section(int no, String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.primary,
                child: Text(
                  '$no',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildFarmerStep() {
    final f = _farmer;
    if (f != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                f.name.characters.first,
                style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (f.phone.isNotEmpty) Text(f.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _farmer = null;
                _harvest = null;
              }),
              style: TextButton.styleFrom(foregroundColor: theme.primary),
              child: const Text('เปลี่ยน'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          cursorColor: theme.primary,
          decoration: InputDecoration(
            hintText: 'ชื่อ เบอร์โทร หรือเลขบัตรประชาชน',
            prefixIcon: Icon(Icons.search, color: theme.primary),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF9F7F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
          ),
        ),
        if (_searchCtrl.text.trim().length >= 2 && !_searching && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text('ไม่พบเกษตรกร', style: TextStyle(color: Colors.grey[500])),
          ),
        // Material ของตัวเอง ไม่งั้นเอฟเฟกต์ตอนกดจะถูกพื้นขาวของการ์ดบัง
        ..._results.map(
          (f) => Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              onTap: () => _selectFarmer(f),
              leading: CircleAvatar(
                backgroundColor: theme.soft,
                child: Text(f.name.characters.first, style: TextStyle(color: theme.primary)),
              ),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(f.phone.isEmpty ? '-' : f.phone),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: f.pendingCount > 0 ? theme.soft : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  f.pendingCount > 0 ? 'รอขาย ${f.pendingCount}' : 'ไม่มีรอขาย',
                  style: TextStyle(fontSize: 11, color: f.pendingCount > 0 ? theme.primary : Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHarvestStep() {
    if (_loadingHarvests) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }
    if (_harvests.isEmpty) {
      return Text(
        'เกษตรกรคนนี้ไม่มีผลผลิตที่ "รอขาย"\nให้เกษตรกรบันทึกการเก็บเกี่ยวเป็น "รอขาย" ในแอปก่อน',
        style: TextStyle(color: Colors.grey[600], height: 1.5),
      );
    }
    return Column(
      children: _harvests.map((h) {
        final selected = _harvest?.harvestId == h.harvestId;
        return GestureDetector(
          onTap: () => setState(() => _selectHarvest(h)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? theme.soft : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? theme.primary : const Color(0xFFE5E5E5), width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? theme.primary : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.gardenName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (h.reserved)
                        Text('เกษตรกรเลือกขายให้ร้านคุณ',
                            style: TextStyle(fontSize: 11.5, color: theme.primary, fontWeight: FontWeight.w600)),
                      Text(
                        'เก็บเกี่ยว ${DateFormat('d MMM', 'th_TH').format(h.date)} ${h.date.year + 543} · ${h.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('~${_kg.format(h.quantity)} กก.', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_rates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'ยังไม่มีราคาที่ใช้อยู่ กรอกราคาเองได้ หรือตั้งราคาในแท็บ "ร้านของฉัน"',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        else ...[
          const Text('เกรด', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._rates.map(
                (r) => _gradeChip(
                  '${r.grade} · ${r.pricePerKg.toStringAsFixed(2)}',
                  _grade == r.grade,
                  () => setState(() => _pickGrade(r)),
                ),
              ),
              _gradeChip('กำหนดเอง', _grade == null, () => setState(() => _grade = null)),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: _numberField(
                _priceCtrl,
                'ราคา/กก.',
                'บาท',
                onChanged: (_) => setState(() => _grade = null),
              ), // แก้ราคาเอง = ไม่ตรงกับเกรดแล้ว
            ),
            const SizedBox(width: 10),
            Expanded(child: _numberField(_qtyCtrl, 'น้ำหนักที่ชั่ง', 'กก.', onChanged: (_) => setState(() {}))),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _decoration(
              'วันที่รับซื้อ',
            ).copyWith(prefixIcon: Icon(Icons.calendar_today_outlined, color: theme.primary, size: 20)),
            child: Text('${DateFormat('d MMMM', 'th_TH').format(_date)} ${_date.year + 543}'),
          ),
        ),
      ],
    );
  }

  Widget _gradeChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: theme.primary,
      backgroundColor: theme.soft,
      side: BorderSide(color: selected ? theme.primary : theme.border),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey[800]),
      onSelected: (_) => onTap(),
    );
  }

  Widget _numberField(TextEditingController c, String label, String suffix, {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      cursorColor: theme.primary,
      decoration: _decoration(label).copyWith(suffixText: suffix),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    floatingLabelStyle: TextStyle(color: theme.primary),
    filled: true,
    fillColor: const Color(0xFFF9F7F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.primary, width: 1.5),
    ),
  );

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยอดที่ต้องจ่าย', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '฿${_money.format(_total)}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _canSave ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
