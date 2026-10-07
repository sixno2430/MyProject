// ทดสอบ AuthHttpClient: แนบ token ทุก request และพากลับหน้าล็อกอินเมื่อเซิร์ฟเวอร์ตอบ 401
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';
import 'package:flutter_myproject/services/api_client.dart';
import 'package:flutter_myproject/services/auth_server.dart';

void main() {
  test('แนบ Authorization: Bearer <token> ให้ทุก request', () async {
    SharedPreferences.setMockInitialValues({'user_id': 'U002', 'access_token': 'tok123'});
    String? sentHeader;
    final client = AuthHttpClient(MockClient((req) async {
      sentHeader = req.headers['Authorization'];
      return http.Response('{"isError":false}', 200);
    }));
    await http.runWithClient(() => http.get(Uri.parse('http://x/api/harvests')), () => client);
    expect(sentHeader, 'Bearer tok123');
  });

  test('ยังไม่ล็อกอิน (ไม่มี token) ไม่แนบ header', () async {
    SharedPreferences.setMockInitialValues({});
    String? sentHeader = 'unset';
    final client = AuthHttpClient(MockClient((req) async {
      sentHeader = req.headers['Authorization'];
      return http.Response('{}', 200);
    }));
    await http.runWithClient(() => http.post(Uri.parse('http://x/api/authen_request')), () => client);
    expect(sentHeader, isNull);
  });

  testWidgets('ได้ 401 -> ล้างการล็อกอิน แล้วกลับหน้าล็อกอิน', (tester) async {
    SharedPreferences.setMockInitialValues({'user_id': 'U002', 'access_token': 'expired'});
    final client = AuthHttpClient(MockClient((req) async => http.Response('{"isError":true}', 401)));

    await tester.pumpWidget(MaterialApp(navigatorKey: navigatorKey, home: const Scaffold(body: Text('หน้าเดิม'))));
    await tester.runAsync(() => http.runWithClient(() => http.get(Uri.parse('http://x/api/harvests')), () => client));
    await tester.pumpAndSettle();

    expect(await AuthService.getToken(), isNull);
    expect(await AuthService.getUserId(), isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('หน้าเดิม'), findsNothing);
  });
}
