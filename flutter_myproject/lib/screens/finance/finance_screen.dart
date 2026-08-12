import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

    return FinanceSummary(
      balance: parseNum(json['balance']),
      totalIncome: parseNum(json['totalIncome']),
      totalExpense: parseNum(json['totalExpense']),
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
    double parsedAmount = 0.0;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        parsedAmount = (json['amount'] as num).toDouble();
      } else {
        parsedAmount = double.tryParse(json['amount'].toString()) ?? 0.0;
      }
    }

    return TransactionItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['category'] ?? 'รายการทั่วไป',
      type: json['type'] ?? 'income',
      amount: parsedAmount,
      category: json['category'] ?? '',
      gardenName: json['gardenName'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

// ==========================================
// 2. MAIN SCREEN
// ==========================================

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // 💡 ปรับเปลี่ยน IP ตามสภาพแวดล้อมที่ใช้ทดสอบ (Emulator ใช้ 10.0.2.2, Chrome/Web ใช้ localhost)
  final String baseUrl = 'http://localhost:3000/api';
  final Color primaryGreen = const Color(0xFF2D6A4F);

  late List<DateTime> _months;
  late DateTime _selectedMonth;

  String _filterType = 'all'; 

  late Future<FinanceSummary> _summaryFuture;
  late Future<List<TransactionItem>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _initMonths();
    _refreshData();
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

  void _refreshData() {
    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
    setState(() {
      _summaryFuture = fetchFinanceSummary(monthKey);
      _transactionsFuture = fetchTransactions(monthKey, _filterType);
    });
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

  Future<FinanceSummary> fetchFinanceSummary(String monthKey) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/finance/summary?month=$monthKey'));
      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body);
        if (resMap['isError'] == false && resMap['data'] != null) {
          return FinanceSummary.fromJson(resMap['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetchFinanceSummary: $e');
    }

    return FinanceSummary(balance: 0, totalIncome: 0, totalExpense: 0);
  }

  Future<List<TransactionItem>> fetchTransactions(String monthKey, String type) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/finance/transactions?month=$monthKey&type=$type'));
      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body);
        if (resMap['isError'] == false && resMap['data'] is List) {
          return (resMap['data'] as List).map((i) => TransactionItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetchTransactions: $e');
    }

    return [];
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

  // ✨ เอาปีออก ให้โชว์แค่ชื่อเดือนเพียวๆ
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
    if (type == 'income' || text.contains('ขาย') || text.contains('ผลผลิต') || text.contains('ปาล์ม')) {
      return '🌴';
    }
    if (text.contains('ปุ๋ย')) {
      return '🧪';
    }
    if (text.contains('แรงงาน') || text.contains('จ้าง') || text.contains('ดูแล')) {
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
        title: const Text('การเงินและรายรับรายจ่าย', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: _navigateToAddTransaction,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Dropdown เลือกเดือน ---
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
                            _refreshData();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- 2. การ์ดสรุปยอดการเงิน ---
              FutureBuilder<FinanceSummary>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  final summary = snapshot.data ?? FinanceSummary(balance: 0, totalIncome: 0, totalExpense: 0);

                  return Container(
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
                          '${summary.balance >= 0 ? '+' : ''}${formatter.format(summary.balance)} ฿',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBalanceItem('รายรับ', '+${formatter.format(summary.totalIncome)} ฿', const Color(0xFF81C784)),
                            _buildBalanceItem('รายจ่าย', '-${formatter.format(summary.totalExpense)} ฿', const Color(0xFFE57373)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // --- 3. ปุ่มสลับ Tab (รายรับ / รายจ่าย) ---
              Row(
                children: [
                  Expanded(child: _buildFilterTab('รายรับ', 'income')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterTab('รายจ่าย', 'expense')),
                ],
              ),
              const SizedBox(height: 16),

              // --- 4. รายการธุรกรรมประจำเดือน ---
              FutureBuilder<List<TransactionItem>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('ไม่มีรายการในเดือนนี้', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
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
          _filterType = isSelected ? 'all' : type;
          _refreshData();
        });
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