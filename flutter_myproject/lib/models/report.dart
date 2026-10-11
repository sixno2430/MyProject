// ============================================================
// report.dart — model รายงานสรุปของเกษตรกร (หน้า "รายงาน")
//
// - YearlyReport     : รายงานทั้งปี หรือรายเดือน (month != null)
// - GardenSummary    : ผลผลิต / รายรับ / รายจ่าย / กำไร ของแปลง 1 แปลง
// - MonthlyMoney     : รายรับ-รายจ่ายของเดือน (กราฟแท่ง)
// - MonthlyProduction: ผลผลิตของเดือน ปีนี้กับปีก่อน (ตารางเทียบ)
// ============================================================

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// สรุปของแปลง 1 แปลงในปีนั้น
class GardenSummary {
  final String gardenName;
  final double areaRai;
  final double totalKg;
  final double income;
  final double expense;
  final double profit;

  GardenSummary.fromJson(Map<String, dynamic> j)
    : gardenName = j['gardenName']?.toString() ?? '-',
      areaRai = _num(j['areaRai']),
      totalKg = _num(j['totalKg']),
      income = _num(j['income']),
      expense = _num(j['expense']),
      profit = _num(j['profit']);

  bool get hasData => totalKg > 0 || income > 0 || expense > 0;
}

/// รายรับ-รายจ่ายของเดือน 1 เดือน
class MonthlyMoney {
  final int month;
  final double income;
  final double expense;

  MonthlyMoney.fromJson(Map<String, dynamic> j)
    : month = (j['month'] as num).toInt(),
      income = _num(j['income']),
      expense = _num(j['expense']);
}

/// ผลผลิตของเดือน 1 เดือน ปีนี้กับปีก่อน
class MonthlyProduction {
  final int month;
  final double kg;
  final double prevKg;

  MonthlyProduction.fromJson(Map<String, dynamic> j)
    : month = (j['month'] as num).toInt(),
      kg = _num(j['kg']),
      prevKg = _num(j['prevKg']);
}

/// ข้อมูลรายงานทั้งปี
class YearlyReport {
  final int year;
  final int? month; // null = รายงานรายปี
  final double totalKg;
  final double prevTotalKg;
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final List<GardenSummary> byGarden;
  final double commonIncome; // ส่วนกลาง (รายการเงินที่ไม่ผูกแปลง)
  final double commonExpense;
  final List<MonthlyMoney> monthly;
  final List<MonthlyProduction> production;

  YearlyReport.fromJson(Map<String, dynamic> j)
    : year = (j['year'] as num).toInt(),
      month = (j['month'] as num?)?.toInt(),
      totalKg = _num(j['totalKg']),
      prevTotalKg = _num(j['prevTotalKg']),
      totalIncome = _num(j['totalIncome']),
      totalExpense = _num(j['totalExpense']),
      profit = _num(j['profit']),
      byGarden = (j['byGarden'] as List? ?? []).map((e) => GardenSummary.fromJson(e)).toList(),
      commonIncome = _num((j['common'] as Map?)?['income']),
      commonExpense = _num((j['common'] as Map?)?['expense']),
      monthly = (j['monthly'] as List? ?? []).map((e) => MonthlyMoney.fromJson(e)).toList(),
      production = (j['production'] as List? ?? []).map((e) => MonthlyProduction.fromJson(e)).toList();
}
