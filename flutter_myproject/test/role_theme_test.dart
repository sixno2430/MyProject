import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:flutter_myproject/screens/auth/register_screen.dart';
import 'package:flutter_myproject/theme/role_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RoleTheme.ofRole: R003 = ส้ม (ร้านรับซื้อ), อื่นๆ = เขียว', () {
    expect(RoleTheme.ofRole('R003'), same(RoleTheme.shop));
    expect(RoleTheme.ofRole('R002'), same(RoleTheme.farmer));
    expect(RoleTheme.ofRole(null), same(RoleTheme.farmer));
  });

  test('RoleTheme.lerp: t=0 ได้ชุดแรก, t=1 ได้ชุดที่สอง', () {
    expect(RoleTheme.lerp(RoleTheme.farmer, RoleTheme.shop, 0).primary, RoleTheme.farmer.primary);
    expect(RoleTheme.lerp(RoleTheme.farmer, RoleTheme.shop, 1).primary, RoleTheme.shop.primary);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('หน้าล็อกอิน: กด "ร้านค้า" แล้วเปลี่ยนเป็นโทนร้านรับซื้อ @ $width', (tester) async {
      tester.view.physicalSize = Size(width * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      expect(find.text('ระบบจัดการสวนปาล์มน้ำมัน'), findsOneWidget);

      await tester.tap(find.text('ร้านค้า'));
      await tester.pumpAndSettle();
      expect(find.text('ระบบสำหรับร้านรับซื้อปาล์ม'), findsOneWidget);

      await tester.tap(find.text('เกษตรกร'));
      await tester.pumpAndSettle();
      expect(find.text('ระบบจัดการสวนปาล์มน้ำมัน'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('หน้าสมัคร: เปิดแบบร้านรับซื้อได้ และสลับบทบาทได้ @ $width', (tester) async {
      tester.view.physicalSize = Size(width * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen(initialRole: 1)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เกษตรกร'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
