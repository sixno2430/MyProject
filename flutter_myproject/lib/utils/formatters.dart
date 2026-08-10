String formatNumber(num value) {
  final str = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i != 0 && (str.length - i) % 3 == 0 && str[i - 1] != '-') {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return 'วันนี้';
  if (diff == 1) return 'เมื่อวาน';

  const thaiMonths = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];
  return '${date.day} ${thaiMonths[date.month]}';
}

String formatThaiDate(DateTime date) {
  const thaiMonths = [
    '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];
  const thaiWeekdays = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
  final buddhistYear = date.year + 543;
  final weekday = thaiWeekdays[date.weekday - 1];
  return '$weekday, ${date.day} ${thaiMonths[date.month]} $buddhistYear';
}
