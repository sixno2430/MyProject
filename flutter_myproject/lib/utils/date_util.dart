// ============================================================
// date_util.dart — ฟังก์ชันช่วยจัดรูปแบบวันที่ (dd-MM-yyyy)
// ============================================================

import 'package:intl/intl.dart';

/// ตัวช่วยจัดรูปแบบวันที่
class  DateUtil {
  /// แปลงวันที่เป็นข้อความ เช่น 29-09-2026
  static String getFormattedDate(DateTime dt) {
    String formattedDate = DateFormat('dd-MM-yyyy').format(dt);

    return formattedDate;
  }
}