/// NOTON Web — 통합 테스트 (flutter drive)
///
/// 실행:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_test.dart \
///     -d web-server --browser-name=chrome --driver-port=4444 \
///     --dart-define=TEST_EMAIL=e2e@noton.test \
///     --dart-define=TEST_PASSWORD=E2eTest1234!
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:noton_web/main.dart' as app;

const _email =
    String.fromEnvironment('TEST_EMAIL', defaultValue: 'e2e@noton.test');
const _password =
    String.fromEnvironment('TEST_PASSWORD', defaultValue: 'E2eTest1234!');

/// HTTP 요청 처리를 위해 짧은 간격으로 반복 pump
Future<void> _pumpFor(WidgetTester t, {int seconds = 5}) async {
  for (int i = 0; i < seconds * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 특정 텍스트가 나타날 때까지 pump (최대 timeout)
Future<bool> _waitForText(
  WidgetTester t,
  String text, {
  int timeoutSecs = 10,
}) async {
  for (int i = 0; i < timeoutSecs * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
    if (find.text(text).evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NOTON Web — 전체 플로우', (tester) async {
    app.main();

    // 인증 초기화 (_init) 대기
    await _pumpFor(tester, seconds: 4);

    // ─── 1. 로그인 (필요한 경우만) ────────────────
    if (find.text('NOTON에 로그인').evaluate().isNotEmpty) {
      debugPrint('[E2E] 로그인 화면 — 로그인 진행');
      await tester.enterText(find.byType(TextFormField).first, _email);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).last, _password);
      await tester.pump();
      await tester.tap(find.text('계속하기'));
      await _pumpFor(tester, seconds: 6);
    } else {
      debugPrint('[E2E] ℹ️ 이미 로그인 상태');
    }

    // ─── 2. 셸 화면 진입 확인 ────────────────────
    final shellLoaded = await _waitForText(
      tester,
      '사이드바에서 문서를 선택하거나 만드세요',
      timeoutSecs: 10,
    );
    expect(shellLoaded, isTrue,
        reason: '셸 화면의 홈 뷰 텍스트가 10초 내에 나타나야 합니다');
    debugPrint('[E2E] ✅ 셸(Shell) 화면 진입 확인');

    // ─── 3. 사이드바 확인 ─────────────────────────
    // 'NOTON' 텍스트 (워크스페이스 미선택 시 기본값)
    expect(find.text('NOTON'), findsWidgets);
    debugPrint('[E2E] ✅ 사이드바 로드 확인');

    // ─── 4. 워크스페이스 생성 (빈 상태인 경우) ──────
    await _pumpFor(tester, seconds: 2);
    final makeBtn = find.widgetWithText(FilledButton, '만들기');
    if (makeBtn.evaluate().isNotEmpty) {
      debugPrint('[E2E] 빈 상태 — 워크스페이스 생성');
      await tester.tap(makeBtn);
      await _pumpFor(tester, seconds: 1);

      final dialogFields = find.byType(TextField);
      if (dialogFields.evaluate().length >= 2) {
        await tester.enterText(dialogFields.first, 'E2E 워크스페이스');
        await tester.pump();
        await tester.enterText(dialogFields.at(1), 'e2e-ws');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, '만들기').last);
        await _pumpFor(tester, seconds: 3);
        debugPrint('[E2E] ✅ 워크스페이스 생성 완료');
      }
    } else {
      debugPrint('[E2E] ℹ️ 워크스페이스 이미 존재');
    }

    // ─── 5. 로그아웃 ──────────────────────────────
    if (find.text('로그아웃').evaluate().isNotEmpty) {
      await tester.tap(find.text('로그아웃'));
      await _pumpFor(tester, seconds: 3);
    }
    final backToLogin = await _waitForText(tester, 'NOTON에 로그인', timeoutSecs: 5);
    expect(backToLogin, isTrue, reason: '로그아웃 후 로그인 화면으로 이동해야 합니다');
    debugPrint('[E2E] ✅ 로그아웃 성공');

    // ─── 6. 잘못된 비밀번호 에러 ──────────────────
    await tester.enterText(find.byType(TextFormField).first, _email);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.pump();
    await tester.tap(find.text('계속하기'));
    await _pumpFor(tester, seconds: 6);
    expect(
      find.text('이메일 또는 비밀번호가 올바르지 않습니다.'),
      findsOneWidget,
    );
    debugPrint('[E2E] ✅ 잘못된 비밀번호 에러 확인');

    // ─── 7. 재로그인 ──────────────────────────────
    await tester.enterText(find.byType(TextFormField).first, _email);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, _password);
    await tester.pump();
    await tester.tap(find.text('계속하기'));
    final finalShell = await _waitForText(
      tester,
      '사이드바에서 문서를 선택하거나 만드세요',
      timeoutSecs: 10,
    );
    expect(finalShell, isTrue, reason: '재로그인 후 셸 화면으로 이동해야 합니다');
    debugPrint('[E2E] ✅ 재로그인 성공');

    // 미완료 async 작업 소진
    await _pumpFor(tester, seconds: 3);
  });
}
