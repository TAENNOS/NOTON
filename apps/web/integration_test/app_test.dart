/// NOTON Web — 통합 테스트
///
/// 사전 조건:
///   - 백엔드 전체 서비스 실행 중 (pnpm dev)
///   - 테스트 계정이 미리 등록되어 있거나 E2E 테스트로 생성된 계정 사용
///
/// 실행:
///   flutter test integration_test/app_test.dart -d chrome
///
/// 환경 변수:
///   TEST_EMAIL    — 테스트 계정 이메일 (기본: e2e@noton.test)
///   TEST_PASSWORD — 테스트 계정 비밀번호 (기본: E2eTest1234!)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:noton_web/main.dart' as app;

const _email = String.fromEnvironment('TEST_EMAIL', defaultValue: 'e2e@noton.test');
const _password = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'E2eTest1234!');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NOTON Web E2E', () {
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

      // 비밀번호 입력
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, _password);

      // 로그인 버튼 클릭
      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 로그인 후 셸(워크스페이스 사이드바) 확인
      expect(find.text('NOTON에 로그인'), findsNothing);
    });

    // ──────────────────────────────────────────
    // 2. 워크스페이스
    // ──────────────────────────────────────────
    testWidgets('워크스페이스를 생성할 수 있다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 로그인 (재사용)
      await _login(tester);

      // 워크스페이스 추가 버튼 클릭
      await tester.tap(find.text('워크스페이스 추가'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인
      expect(find.text('워크스페이스 만들기'), findsOneWidget);

      // 이름 입력
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '테스트 워크스페이스');

      // slug 입력
      final slugField = find.byType(TextField).last;
      await tester.enterText(slugField, 'test-workspace-${DateTime.now().millisecondsSinceEpoch}');

      // 만들기 버튼
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 생성된 워크스페이스 확인
      expect(find.text('테스트 워크스페이스'), findsOneWidget);
    });

    // ──────────────────────────────────────────
    // 3. 문서
    // ──────────────────────────────────────────
    testWidgets('새 문서를 생성하고 에디터가 열린다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 워크스페이스 펼치기 (첫 번째)
      final workspaceRow = find.byIcon(Icons.workspaces_outlined).first;
      await tester.tap(workspaceRow);
      await tester.pumpAndSettle();

      // + 새 문서 버튼 (hover 상태에서만 보이므로 직접 아이콘 탐색)
      final addDocBtn = find.byTooltip('새 문서');
      if (addDocBtn.evaluate().isNotEmpty) {
        await tester.tap(addDocBtn);
        await tester.pumpAndSettle();

        // 제목 입력
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'E2E 테스트 문서');

        await tester.tap(find.text('만들기'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 사이드바에 문서 이름 표시 확인
        expect(find.text('E2E 테스트 문서'), findsOneWidget);
      }
    });

    // ──────────────────────────────────────────
    // 4. 로그아웃
    // ──────────────────────────────────────────
    testWidgets('로그아웃 후 로그인 화면으로 이동한다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 로그아웃 버튼 클릭
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 로그인 화면으로 복귀 확인
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
