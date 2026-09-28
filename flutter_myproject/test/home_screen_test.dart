import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/main/HOME/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // หลังล็อกอิน HomeScreen สร้างทั้ง 5 แท็บพร้อมกัน ถ้าแท็บไหนพังตอนสร้าง แอปจะค้างหลังล็อกอิน
  // (เคยเกิดจาก setState(() => _future = ...) ที่ callback คืนค่า Future)
  testWidgets('หลังล็อกอิน สร้างหน้าหลักทั้ง 5 แท็บได้โดยไม่มี error', (tester) async {
    await initializeDateFormatting('th_TH', null);
    SharedPreferences.setMockInitialValues({'user_id': 'U999', 'access_token': 'x'});

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // ในเทสต์ http จะได้ 400 ทุกครั้ง แต่ละหน้าต้องแสดง error ของตัวเองได้ ไม่ใช่พังทั้งแอป
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
