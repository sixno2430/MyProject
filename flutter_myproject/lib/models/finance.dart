// ============================================================
// finance.dart — model การเงิน (หน้ารายรับ-รายจ่าย)
//
// - TransactionItem: รายการเงิน 1 รายการ (รวมจากขายผลผลิต, ค่าดูแลสวน, รายการที่บันทึกเอง)
// - FinanceSummary : ยอดคงเหลือ / รายรับ / รายจ่าย
// ============================================================

/// ยอดสรุปของเดือน (คงเหลือ / รายรับ / รายจ่าย)
class FinanceSummary {
  final double balance;
  final double totalIncome;
  final double totalExpense;

  FinanceSummary({required this.balance, required this.totalIncome, required this.totalExpense});

  /// แปลง JSON เป็น FinanceSummary (รองรับชื่อ key หลายแบบ)
  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final income = parseNum(json['totalIncome'] ?? json['total_income']);
    final expense = parseNum(json['totalExpense'] ?? json['total_expense']);
    final bal = json['balance'] != null ? parseNum(json['balance']) : (income - expense);

    return FinanceSummary(balance: bal, totalIncome: income, totalExpense: expense);
  }
}

/// รายการเงิน 1 รายการ
class TransactionItem {
  final String id;
  final String title;
  final String type; // 'income' หรือ 'expense'
  final double amount;
  final String category;
  final String gardenName;
  final String gardenId;
  final String date;

  /// รายการที่บันทึกเองในหน้าการเงิน (รหัส FN...) แก้ไข/ลบได้ที่นี่
  /// ส่วนรายการจากผลผลิต (H...) และการดูแลสวน (C...) ต้องไปแก้ที่หน้านั้นๆ
  bool get isManualEntry => id.startsWith('FN');

  TransactionItem({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.category,
    required this.gardenName,
    this.gardenId = '',
    required this.date,
  });

  /// แปลง JSON เป็น TransactionItem ถ้าไม่ระบุประเภท จะเดาจากหมวด/ชื่อรายการ
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
      gardenId: json['gardenId']?.toString() ?? '',
      date: json['date'] ?? json['record_date'] ?? json['created_at'] ?? '',
    );
  }
}
