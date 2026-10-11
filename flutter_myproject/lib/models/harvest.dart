// ============================================================
// harvest.dart — model การเก็บเกี่ยว
//
// - HarvestData   : รายการเก็บเกี่ยว 1 ล็อต (สถานะ รอขาย/ขายแล้ว, ร้าน, ราคา, เกรด)
// - HarvestSummary: สรุปผลผลิต/รายได้ของปี + ผลผลิตรายเดือน (ใช้ทำกราฟ)
// ============================================================

/// ข้อมูลการเก็บเกี่ยว 1 รายการ
class HarvestData {
  final String id;
  final String gardenId;

  /// รหัสร้านในแอป ('' = ไม่มี) รอขาย = ร้านที่จะขายให้, ขายแล้ว = ร้านที่รับซื้อ
  final String shopId;

  /// ชื่อร้านนอกระบบที่พิมพ์เอง ('' = ไม่ระบุ)
  final String buyerName;

  /// วันที่ขาย yyyy-MM-dd ('' = ยังไม่ขาย)
  final String soldDate;

  /// true = ร้านในแอปบันทึกรับซื้อแล้ว แก้/ลบเองไม่ได้
  final bool purchasedByShop;

  /// หมายเหตุที่เกษตรกรพิมพ์เอง ('' = ไม่มี)
  final String note;

  /// เกรดที่ร้านในแอปให้ตอนรับซื้อ ('' = ไม่มี)
  final String grade;

  /// ร้านล่าสุดที่ไม่รับล็อตนี้ + เหตุผล ('' = ไม่มี / เลือกร้านใหม่แล้ว)
  final String rejectedBy;
  final String rejectReason;
  final String code;
  final String plotName;
  final String buyer;
  final double quantityKg;
  final double pricePerKg;
  final double totalPrice;
  final String date;
  final String status;

  HarvestData({
    required this.id,
    this.gardenId = '',
    this.shopId = '',
    this.buyerName = '',
    this.soldDate = '',
    this.purchasedByShop = false,
    this.note = '',
    this.grade = '',
    this.rejectedBy = '',
    this.rejectReason = '',
    required this.code,
    required this.plotName,
    required this.buyer,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalPrice,
    required this.date,
    required this.status,
  });

  /// แปลง JSON จาก API เป็น HarvestData
  factory HarvestData.fromJson(Map<String, dynamic> json) {
    return HarvestData(
      id: json['id']?.toString() ?? '',
      gardenId: json['gardenId']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      soldDate: json['soldDate']?.toString() ?? '',
      // MariaDB ส่งค่า boolean มาเป็น 0/1
      purchasedByShop: json['purchasedByShop'] == true || json['purchasedByShop'] == 1,
      note: json['note']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      rejectedBy: json['rejectedBy']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString() ?? '',
      code: json['code'] ?? '',
      plotName: json['plotName'] ?? json['plot_name'] ?? '',
      buyer: json['buyer'] ?? '',
      quantityKg: (json['quantityKg'] ?? json['quantity_kg'] ?? 0).toDouble(),
      pricePerKg: (json['pricePerKg'] ?? json['price_per_kg'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? json['total_price'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      status: json['status'] ?? 'sold',
    );
  }
}

/// ข้อมูลสรุป: ผลผลิตรวม, รายได้ (เฉพาะที่ขายแล้ว), ราคาเฉลี่ย, ผลผลิตรายเดือน
class HarvestSummary {
  final double totalQuantityKg;
  final double totalRevenue;
  final double averagePrice;
  final Map<String, double> last12MonthsProduction;

  HarvestSummary({
    required this.totalQuantityKg,
    required this.totalRevenue,
    required this.averagePrice,
    required this.last12MonthsProduction,
  });

  /// แปลง JSON จาก API เป็น HarvestSummary
  factory HarvestSummary.fromJson(Map<String, dynamic> json) {
    return HarvestSummary(
      totalQuantityKg: (json['totalQuantityKg'] ?? json['total_quantity_kg'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? json['total_revenue'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? json['average_price'] ?? 0).toDouble(),
      last12MonthsProduction: Map<String, double>.from(
        (json['last12MonthsProduction'] ?? json['last6MonthsProduction'] ?? json['monthly_production'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }
}
