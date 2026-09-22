import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_myproject/services/auth_server.dart';
import 'add_transaction_screen.dart';

// ==========================================
// 1. MODELS
// ==========================================

class FinanceSummary {
  final double balance;
  final double totalIncome;
  final double totalExpense;

  FinanceSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final income = parseNum(json['totalIncome'] ?? json['total_income']);
    final expense = parseNum(json['totalExpense'] ?? json['total_expense']);
    final bal = json['balance'] != null ? parseNum(json['balance']) : (income - expense);

    return FinanceSummary(
      balance: bal,
      totalIncome: income,
      totalExpense: expense,
    );
  }
}

class TransactionItem {
  final String id;
  final String title;
  final String type; // 'income' หรือ 'expense'
  final double amount;
  final String category;
  final String gardenName;
  final String date;

  TransactionItem({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.category,
    required this.gardenName,
    required this.date,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    String txType = (json['type'] ?? json['transaction_type'] ?? '').toString().toLowerCase();
    String cat = (json['category'] ?? json['activity_type'] ?? json['type_name'] ?? '').toString();
    String titleText = (json['title'] ?? json['description'] ?? '').toString();

    if (txType != 'income' && txType != 'expense') {
      if (cat.contains('ขาย') || cat.contains('เก็บเกี่ยว') || titleText.contains('ขาย')) {
        txType = 'income';
      } else {
        txType = 'expense';
      }
    }

    return TransactionItem(
      id: json['id']?.toString() ?? json['transaction_id']?.toString() ?? '',
      title: titleText.isNotEmpty ? titleText : (cat.isNotEmpty ? cat : 'รายการทั่วไป'),
      type: txType,
      amount: parseAmount(json['amount'] ?? json['total_price'] ?? json['cost']),
      category: cat.isNotEmpty ? cat : (txType == 'income' ? 'เก็บเกี่ยว/ขายผลผลิต' : 'ดูแลรักษา'),
      gardenName: json['gardenName'] ?? json['garden_name'] ?? '',
      date: json['date'] ?? json['record_date'] ?? json['created_at'] ?? '',
    );
  }
}

// ==========================================
// 2. MAIN SCREEN
// ==========================================

class FinanceScreen extends StatefulWidget {
  final String? userId;
  const FinanceScreen({super.key, this.userId});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final String baseUrl = 'http://localhost:3000/api';
  final Color primaryGreen = const Color(0xFF2D6A4F);

  late List<DateTime> _months;
  late DateTime _selectedMonth;

  String _filterType = 'all'; // 'all', 'income', 'expense'
  String? _effectiveUserId;

  bool _isLoading = false;
  FinanceSummary _summary = FinanceSummary(balance: 0, totalIncome: 0, totalExpense: 0);
  List<TransactionItem> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _initMonths();
    _initUserData();
  }

  void _initMonths() {
    final now = DateTime.now();
    _months = List.generate(12, (index) {
      return DateTime(now.year, index + 1, 1);
    });

    _selectedMonth = _months.firstWhere(
      (m) => m.month == now.month,
      orElse: () => _months[now.month - 1],
    );
  }

  Future<void> _initUserData() async {
    final loggedInUserId = widget.userId ?? await AuthService.getUserId();
    if (mounted) {
      setState(() {
        _effectiveUserId = loggedInUserId;
      });
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_effectiveUserId == null || _effectiveUserId!.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);

    // ดึงทั้งรายรับและรายจ่ายเพื่อนำมาคำนวณยอดเงินคงเหลือจริง
    final incomeList = await _fetchRawTransactions(monthKey, 'income', _effectiveUserId!);
    final expenseList = await _fetchRawTransactions(monthKey, 'expense', _effectiveUserId!);

    // คำนวณหายอดรวมรายรับและรายจ่าย
    double totalInc = 0;
    for (var item in incomeList) {
      totalInc += item.amount;
    }

    double totalExp = 0;
    for (var item in expenseList) {
      totalExp += item.amount;
    }

    if (mounted) {
      setState(() {
        _summary = FinanceSummary(
          balance: totalInc - totalExp,
          totalIncome: totalInc,
          totalExpense: totalExp,
        );

        // จัดการรายการธุรกรรมที่จะนำมาแสดงตาม Filter Tab
        if (_filterType == 'income') {
          _allTransactions = incomeList;
        } else if (_filterType == 'expense') {
          _allTransactions = expenseList;
        } else {
          _allTransactions = [...incomeList, ...expenseList];
          // เรียงลำดับจากวันที่ล่าสุด
          _allTransactions.sort((a, b) => b.date.compareTo(a.date));
        }

        _isLoading = false;
      });
    }
  }

  Future<List<TransactionItem>> _fetchRawTransactions(String monthKey, String type, String userId) async {
    try {
      final url = '$baseUrl/finance/transactions?month=$monthKey&type=$type&user_id=$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body);
        if (resMap['isError'] == false && resMap['data'] != null) {
          final rawData = resMap['data'];

          if (rawData is List) {
            return rawData.map((i) => TransactionItem.fromJson(i)).toList();
          } else if (rawData is Map<String, dynamic>) {
            return [TransactionItem.fromJson(rawData)];
          }
        }
      }
    } catch (_) {}

    return [];
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  String _formatThaiDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final thaiYear = dt.year + 543;
      final months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
      return '${dt.day} ${months[dt.month - 1]} $thaiYear';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatMonthLabel(DateTime dt) {
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[dt.month - 1];
  }

  String _getCategoryIcon(String category, String title, String type) {
    final text = '$category $title'.toLowerCase();
    if (type == 'income' || text.contains('ขาย') || text.contains('ผลผลิต') || text.contains('เก็บเกี่ยว')) {
      return '🧺';
    }
    if (text.contains('ปุ๋ย')) {
      return '🧪';
    }
    if (text.contains('ตัดแต่ง') || text.contains('หญ้า') || text.contains('ดูแล')) {
      return '🌿';
    }
    if (text.contains('แรงงาน') || text.contains('จ้าง')) {
      return '👷';
    }
    return '📝';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "th_TH");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
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
              // 1. Dropdown ประจำเดือน
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        const Text('ประจำเดือน:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              ),
              const SizedBox(height: 16),

              // 2. การ์ดสรุปยอดเงินคงเหลือ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text('ยอดเงินคงเหลือ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '${_summary.balance >= 0 ? '+' : ''}${formatter.format(_summary.balance)} ฿',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBalanceItem('รายรับ (เก็บเกี่ยว)', '+${formatter.format(_summary.totalIncome)} ฿', const Color(0xFF81C784)),
                        _buildBalanceItem('รายจ่าย (ดูแลรักษา)', '-${formatter.format(_summary.totalExpense)} ฿', const Color(0xFFE57373)),
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
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
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

                    return _buildTransactionItem(
                      title: item.title,
                      gardenName: item.gardenName,
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

  Widget _buildBalanceItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFilterTab(String label, String type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type;
        });
        _refreshData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.black12,
          ),
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

  Widget _buildTransactionItem({
    required String title,
    required String gardenName,
    required String date,
    required String amount,
    required bool isIncome,
    required String icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (gardenName.isNotEmpty) ...[
                      Text(
                        gardenName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primaryGreen),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    );
  }
}