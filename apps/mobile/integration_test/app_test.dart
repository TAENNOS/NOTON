/// NOTON Mobile — 통합 테스트
///
/// 사전 조건:
///   - 백엔드 전체 서비스 실행 중 (pnpm dev)
///   - 실기기 또는 에뮬레이터 연결
///
/// 실행:
///   flutter test integration_test/app_test.dart -d <device_id>
///
/// 환경 변수:
///   TEST_EMAIL    — 테스트 계정 이메일 (기본: e2e@noton.test)
///   TEST_PASSWORD — 테스트 계정 비밀번호 (기본: E2eTest1234!)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:noton_mobile/main.dart' as app;

const _email = String.fromEnvironment('TEST_EMAIL', defaultValue: 'e2e@noton.test');
const _password = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'E2eTest1234!');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NOTON Mobile E2E', () {
    // ──────────────────────────────────────────
    // 1. 로그인
    // ──────────────────────────────────────────
    testWidgets('로그인 화면이 표시되고 정상 로그인된다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 로그인 화면 확인
      expect(find.text('NOTON에 로그인'), findsOneWidget);

      // 이메일 입력
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, _email);
      await tester.pumpAndSettle();

      // 비밀번호 입력
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, _password);
      await tester.pumpAndSettle();

      // 키보드 닫기
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 로그인 버튼 클릭
      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 로그인 화면 사라짐 확인
      expect(find.text('NOTON에 로그인'), findsNothing);
    });

    // ──────────────────────────────────────────
    // 2. 홈 화면 (Shell)
    // ──────────────────────────────────────────
    testWidgets('로그인 후 워크스페이스 목록이 표시된다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 셸 화면 진입 확인 — NOTON 로고 또는 워크스페이스 관련 위젯
      expect(find.byIcon(Icons.workspaces_outlined), findsWidgets);
    });

    // ──────────────────────────────────────────
    // 3. 잘못된 비밀번호
    // ──────────────────────────────────────────
    testWidgets('잘못된 비밀번호로 로그인 시 에러 메시지가 표시된다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, _email);

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'wrong-password');

      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 에러 메시지 확인
      expect(
        find.text('이메일 또는 비밀번호가 올바르지 않습니다.'),
        findsOneWidget,
      );
    });

    // ──────────────────────────────────────────
    // 4. 로그아웃
    // ──────────────────────────────────────────
    testWidgets('로그아웃 후 로그인 화면으로 이동한다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 로그아웃 버튼
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('NOTON에 로그인'), findsOneWidget);
    });
  });
}

/// 공통 로그인 헬퍼
Future<void> _login(WidgetTester tester) async {
  if (find.text('NOTON에 로그인').evaluate().isEmpty) return;

  final emailField = find.byType(TextFormField).first;
  await tester.enterText(emailField, _email);

  final passwordField = find.byType(TextFormField).last;
  await tester.enterText(passwordField, _password);

  await tester.tap(find.text('계속하기'));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}
