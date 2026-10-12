// ============================================================
// finance_screen.dart — แท็บ "การเงิน" (รายรับ-รายจ่าย)
//
// เลือกเดือน แล้วแสดงยอดคงเหลือ, รายรับ, รายจ่าย และรายการของเดือนนั้น
// รายการรวมมาจาก 3 แหล่ง: ขายผลผลิต (H...), ค่าดูแลสวน (C...), รายการที่บันทึกเอง (FN...)
// แก้ไข/ลบได้เฉพาะรายการ FN... (อีก 2 แหล่งต้องไปแก้ที่หน้าของมัน)
// API: GET /api/finance/transactions, DELETE /api/finance/:id
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_service.dart';
import 'package:flutter_myproject/services/finance_service.dart';
import 'package:flutter_myproject/services/garden_service.dart';
import 'add_transaction_screen.dart';
import 'package:flutter_myproject/widgets/item_actions.dart';
import 'package:flutter_myproject/models/care_type.dart';
import 'package:flutter_myproject/utils/error_message.dart';
import 'package:flutter_myproject/models/finance.dart';
import 'package:flutter_myproject/screens/finance/widgets/transaction_tile.dart';

// model: models/finance.dart · widget ย่อย: widgets/transaction_tile.dart (แถวรายการเงิน)

/// แท็บการเงิน (ส่ง userId มาได้ ถ้าไม่ส่งจะใช้ user ที่ล็อกอินอยู่)
class FinanceScreen extends StatefulWidget {
  final String? userId;

  /// สัญญาณให้โหลดข้อมูลใหม่ — หน้าแรก (HomeScreen) ส่งมาทุกครั้งที่กดแท็บ "การเงิน"
  /// เพราะแท็บถูกสร้างไว้ครั้งเดียว (IndexedStack) ไม่งั้นแปลง/รายการที่เพิ่มจากหน้าอื่นจะไม่ขึ้น
  final Listenable? refreshTrigger;

  const FinanceScreen({super.key, this.userId, this.refreshTrigger});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final Color primaryGreen = const Color(0xFF2D6A4F);

  late List<DateTime> _months;
  late DateTime _selectedMonth;

  String _filterType = 'all'; // 'all', 'income', 'expense'
  String? _effectiveUserId;

  bool _isLoading = false;

  // รายการของเดือนที่เลือก (ยังไม่กรองแปลง) — กรองแปลง/ประเภทและคำนวณยอดจากสองรายการนี้ในแอป
  List<TransactionItem> _incomeList = [];
  List<TransactionItem> _expenseList = [];

  // ตัวกรองแปลง: null = ทุกแปลง, _commonGarden = ส่วนกลาง (รายการที่ไม่ผูกกับแปลง), อื่นๆ = garden_id
  static const String _commonGarden = '__common__';
  String? _gardenFilter;
  List<Map<String, String>> _gardens = []; // [{id, name}] แปลงของผู้ใช้ สำหรับปุ่มกรอง

  bool _matchGarden(TransactionItem t) {
    if (_gardenFilter == null) return true;
    if (_gardenFilter == _commonGarden) return t.gardenId.isEmpty;
    return t.gardenId == _gardenFilter;
  }

  List<TransactionItem> get _filteredIncome => _incomeList.where(_matchGarden).toList();
  List<TransactionItem> get _filteredExpense => _expenseList.where(_matchGarden).toList();

  /// ยอดสรุปของแปลงที่เลือก
  FinanceSummary get _summary {
    final inc = _filteredIncome.fold<double>(0, (s, t) => s + t.amount);
    final exp = _filteredExpense.fold<double>(0, (s, t) => s + t.amount);
    return FinanceSummary(balance: inc - exp, totalIncome: inc, totalExpense: exp);
  }

  /// รายการที่แสดงตามแท็บ ทั้งหมด / รายรับ / รายจ่าย (เรียงวันที่ล่าสุดก่อน)
  List<TransactionItem> get _allTransactions {
    final list = switch (_filterType) {
      'income' => _filteredIncome,
      'expense' => _filteredExpense,
      _ => [..._filteredIncome, ..._filteredExpense],
    };
    return list..sort((a, b) => b.date.compareTo(a.date));
  }

  /// ชื่อขอบเขตที่กำลังดู (แสดงใต้หัวการ์ดยอดคงเหลือ)
  String get _scopeLabel {
    if (_gardenFilter == null) return 'ทุกแปลง';
    if (_gardenFilter == _commonGarden) return 'ส่วนกลาง';
    return 'แปลง${_gardens.firstWhere((g) => g['id'] == _gardenFilter, orElse: () => {'name': ''})['name']}';
  }

  @override
  void initState() {
    super.initState();
    _initMonths();
    _initUserData();
    widget.refreshTrigger?.addListener(_refreshData);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_refreshData);
    super.dispose();
  }

  /// สร้างรายการเดือนย้อนหลังให้เลือกใน dropdown
  void _initMonths() {
    final now = DateTime.now();
    _months = List.generate(12, (index) {
      return DateTime(now.year, index + 1, 1);
    });

    _selectedMonth = _months.firstWhere((m) => m.month == now.month, orElse: () => _months[now.month - 1]);
  }

  /// หา user_id ที่จะใช้ แล้วโหลดข้อมูลครั้งแรก
  Future<void> _initUserData() async {
    final loggedInUserId = widget.userId ?? await AuthService.getUserId();
    if (mounted) {
      setState(() {
        _effectiveUserId = loggedInUserId;
      });
      _refreshData();
    }
  }

  /// โหลดรายรับและรายจ่ายของเดือนที่เลือก (ยอดสรุปคำนวณจากรายการตามแปลงที่เลือก ดู _summary)
  /// โหลดรายชื่อแปลงใหม่ด้วยทุกครั้ง แปลงที่เพิ่ม/ลบจากหน้าสวนจะขึ้นเป็นปุ่มกรองทันที
  Future<void> _refreshData() async {
    if (_effectiveUserId == null || _effectiveUserId!.isEmpty) return;
    _fetchGardens();

    setState(() {
      _isLoading = true;
    });

    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);

    // ดึงทั้งรายรับและรายจ่ายเพื่อนำมาคำนวณยอดเงินคงเหลือจริง
    final incomeList = await FinanceService.fetchTransactions(monthKey, 'income', _effectiveUserId!);
    final expenseList = await FinanceService.fetchTransactions(monthKey, 'expense', _effectiveUserId!);

    if (mounted) {
      setState(() {
        _incomeList = incomeList;
        _expenseList = expenseList;
        _isLoading = false;
      });
    }
  }

  /// โหลดแปลงสวนของผู้ใช้ มาทำปุ่มกรองรายแปลง
  /// (โหลดไม่ได้ก็ยังดูแบบทุกแปลงได้ ปุ่มกรองจะมีแค่ "ทุกแปลง" / "ส่วนกลาง")
  Future<void> _fetchGardens() async {
    final gardens = await GardenService.fetchGardenOptions(_effectiveUserId!);
    if (!mounted) return;
    setState(() {
      _gardens = gardens;
      // แปลงที่เลือกอยู่ถูกลบไปแล้ว -> กลับไปดูทุกแปลง
      if (_gardenFilter != null && _gardenFilter != _commonGarden && !_gardens.any((g) => g['id'] == _gardenFilter)) {
        _gardenFilter = null;
      }
    });
  }

  /// กดค้างที่รายการ: แก้ไข/ลบได้เฉพาะ FN... ถ้าเป็นรายการจากหน้าอื่นจะบอกให้ไปแก้ที่หน้านั้น
  Future<void> _onTransactionLongPress(TransactionItem item) async {
    if (!item.isManualEntry) {
      final where = item.id.startsWith('H') ? 'บันทึกการเก็บเกี่ยว' : 'การดูแลรักษาสวน';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('รายการนี้มาจากหน้า$where กรุณาแก้ไขที่หน้านั้น')));
      return;
    }

    final action = await showItemActionsSheet(context);
    if (action == null || !mounted) return;

    if (action == ItemAction.edit) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddTransactionScreen(existing: item)),
      );
      if (result == true) _refreshData();
      return;
    }

    if (!await confirmDelete(context, item.title)) return;
    try {
      await FinanceService.deleteTransaction(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  /// เปิดฟอร์มบันทึกรายการใหม่ กลับมาแล้วโหลดใหม่
  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen()));

    if (result == true) {
      _refreshData();
    }
  }

  /// แปลงวันที่ yyyy-MM-dd เป็นแบบไทยสั้นๆ
  String _formatThaiDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final thaiYear = dt.year + 543;
      final months = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      return '${dt.day} ${months[dt.month - 1]} $thaiYear';
    } catch (_) {
      return dateStr;
    }
  }

  /// ชื่อเดือนภาษาไทย ปี พ.ศ. สำหรับ dropdown
  String _formatMonthLabel(DateTime dt) {
    final months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return months[dt.month - 1];
  }

  /// เลือก emoji ตามหมวดก่อน แล้วค่อยดูชื่อรายการ (รายการเก่า/หมวดที่ไม่รู้จัก)
  /// ค่าดูแลสวนใช้ emoji เดียวกับฟอร์มดูแลสวนและการ์ดกิจกรรม (models/care_type.dart) เช่น ตัดแต่ง = ✂️
  String _getCategoryIcon(String category, String title, String type) {
    switch (category) {
      case 'ขายผลผลิต':
        return '🧺';
      case 'เงินอุดหนุน':
        return '🏛️';
      case 'รายรับอื่นๆ':
        return '💵';
      case 'ค่าปุ๋ย':
        return careTypeOf('fertilizer').emoji;
      case 'ค่าดูแลรักษา':
        // ชื่อรายการจากเซิร์ฟเวอร์เป็น "ดูแลสวน: ตัดแต่ง" -> หาประเภทจากชื่อ
        for (final t in careTypes) {
          if (title.contains(t.label)) return t.emoji;
        }
        return '🌿';
      case 'ค่าแรงงาน':
        return '👷';
      case 'ค่าน้ำมัน/เชื้อเพลิง':
        return '⛽';
      case 'ค่าอุปกรณ์':
        return '🧰';
    }
    // หมวดอื่น/รายการเก่า: ดูจากชื่อรายการ
    if (title.contains('ขาย') || title.contains('ผลผลิต')) return '🧺';
    if (title.contains('ปุ๋ย')) return careTypeOf('fertilizer').emoji;
    if (title.contains('แรงงาน') || title.contains('จ้าง')) return '👷';
    return type == 'income' ? '💵' : '📝';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "th_TH");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        // หน้านี้เปิดได้ 2 ทาง: เมนูในหน้าหลัก (เปิดซ้อน ย้อนกลับได้) กับแท็บ "การเงิน" ด้านล่าง (ไม่มีหน้าให้ย้อน)
        // แสดงปุ่มย้อนกลับเฉพาะตอนที่ย้อนได้ ไม่งั้นเป็นปุ่มที่กดแล้วไม่เกิดอะไร (เหมือนหน้าสวน)
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'การเงินและรายรับรายจ่าย',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: _navigateToAddTransaction,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ตัวกรอง: เดือน + แปลง (ทุกแปลง / แต่ละแปลง / ส่วนกลาง)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            const Text('ประจำเดือน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        DropdownButton<DateTime>(
                          value: _selectedMonth,
                          underline: const SizedBox(),
                          icon: Icon(Icons.arrow_drop_down_rounded, color: primaryGreen, size: 26),
                          menuMaxHeight: 300,
                          items: _months.map((m) {
                            return DropdownMenuItem<DateTime>(
                              value: m,
                              child: Text(
                                _formatMonthLabel(m),
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedMonth = val;
                              });
                              _refreshData();
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 4),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.forest_outlined, color: primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        const Text('ดูตามแปลง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // แถวเดียวเลื่อนซ้าย-ขวา: กล่องสูงเท่าเดิมไม่ว่าจะมีกี่แปลง
                    // "ทุกแปลง" กับ "ส่วนกลาง" อยู่หน้าสุดเสมอ (ไม่ถูกดันไปท้ายจนมองไม่เห็น)
                    // ขอบขวาจางลง (ShaderMask) ให้รู้ว่ายังเลื่อนดูแปลงต่อได้
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Colors.white, Colors.white, Colors.transparent],
                        stops: [0, 0.9, 1],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 24), // ปุ่มสุดท้ายเลื่อนพ้นช่วงที่จางได้
                        child: Row(
                          spacing: 8,
                          children: [
                            _buildGardenChip('ทุกแปลง', null, icon: Icons.select_all_rounded),
                            _buildGardenChip('ส่วนกลาง', _commonGarden, icon: Icons.home_work_outlined),
                            for (final g in _gardens) _buildGardenChip(g['name']!, g['id'], icon: Icons.park_outlined),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. การ์ดสรุปยอดเงินคงเหลือ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Text('ยอดเงินคงเหลือ · $_scopeLabel', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '${_summary.balance >= 0 ? '+' : ''}${formatter.format(_summary.balance)} ฿',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBalanceItem(
                          'รายรับ',
                          '+${formatter.format(_summary.totalIncome)} ฿',
                          const Color(0xFF81C784),
                        ),
                        _buildBalanceItem(
                          'รายจ่าย',
                          '-${formatter.format(_summary.totalExpense)} ฿',
                          const Color(0xFFE57373),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. แท็บสลับ รายรับ / รายจ่าย
              Row(
                children: [
                  Expanded(child: _buildFilterTab('ทั้งหมด', 'all')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterTab('รายรับ', 'income')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterTab('รายจ่าย', 'expense')),
                ],
              ),
              const SizedBox(height: 16),

              // 4. รายการธุรกรรม
              if (_isLoading)
                const Center(
                  child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                )
              else if (_allTransactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('ไม่มีรายการในเดือนนี้', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allTransactions.length,
                  itemBuilder: (context, index) {
                    final item = _allTransactions[index];
                    final isIncome = item.type == 'income';

                    return TransactionTile(
                      onLongPress: () => _onTransactionLongPress(item),
                      title: item.title,
                      // ไม่ผูกกับแปลง (gardenId ว่าง) = ส่งชื่อว่าง แล้วแถวรายการจะแสดงเป็น "ส่วนกลาง"
                      gardenName: item.gardenId.isEmpty ? '' : item.gardenName,
                      date: _formatThaiDate(item.date),
                      amount: '${isIncome ? '+' : '-'}${formatter.format(item.amount)} ฿',
                      isIncome: isIncome,
                      icon: _getCategoryIcon(item.category, item.title, item.type),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ปุ่มกรองแปลง 1 ปุ่ม (value: null = ทุกแปลง, _commonGarden = ส่วนกลาง, อื่นๆ = garden_id)
  Widget _buildGardenChip(String label, String? value, {required IconData icon}) {
    final selected = _gardenFilter == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : primaryGreen),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: primaryGreen,
      backgroundColor: const Color(0xFFF1F8F4),
      side: BorderSide(color: selected ? primaryGreen : const Color(0xFFD7E8DE)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? Colors.white : const Color(0xFF1B4332),
      ),
      onSelected: (_) => setState(() => _gardenFilter = value),
    );
  }

  /// ตัวเลขรายรับ/รายจ่ายในการ์ดยอดคงเหลือ
  Widget _buildBalanceItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// ปุ่มกรอง ทั้งหมด / รายรับ / รายจ่าย
  Widget _buildFilterTab(String label, String type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type; // กรองจากข้อมูลที่โหลดไว้แล้ว ไม่ต้องโหลดใหม่
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? primaryGreen : Colors.black12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
