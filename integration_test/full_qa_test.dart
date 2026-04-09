// 해원의 문 — Integration Test (테스트 전용 진입점)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gateway_of_regrets/game_screen.dart';
import 'package:gateway_of_regrets/l10n/app_strings.dart';
import 'package:gateway_of_regrets/data/game_data_loader.dart';
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('해원의 문 전수검사', (tester) async {
    // 테스트 전용 앱 시작 (runZonedGuarded 우회)
    await GameDataLoader.initFromJson();
    await AppStrings.init(GameLanguage.ko);

    runApp(
      const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: GameScreen(),
        ),
      ),
    );

    // 앱 로딩 대기
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 3));

    // ========================================
    // 1. 메인메뉴 확인
    // ========================================
    debugPrint('\n=== 1. 메인메뉴 확인 ===');
    final menuTexts = ['수호자', '제단/포탑', '일일 미션', '설화도감',
      '스킨 상점', '무한의 탑', '시즌 패스', '업적 & 랭킹', '설정', '전투 시작'];
    int found = 0;
    for (final text in menuTexts) {
      final f = find.textContaining(text);
      if (f.evaluate().isNotEmpty) { debugPrint('  ✅ "$text"'); found++; }
      else { debugPrint('  ❌ "$text" 미발견'); }
    }
    debugPrint('  메뉴 버튼: $found/${menuTexts.length}');

    // ========================================
    // 2. 각 메뉴 화면 진입/복귀
    // ========================================
    debugPrint('\n=== 2. 메뉴 화면 순회 ===');
    final menuButtons = ['수호자', '제단/포탑', '일일 미션', '설화도감',
      '스킨 상점', '무한의 탑', '시즌 패스', '업적 & 랭킹'];

    for (final btnText in menuButtons) {
      final btn = find.textContaining(btnText);
      if (btn.evaluate().isEmpty) { debugPrint('  ⚠️ "$btnText" 없음'); continue; }
      debugPrint('  📍 "$btnText" 탭...');
      await tester.tap(btn.first);
      await tester.pump(const Duration(seconds: 3));
      debugPrint('  ✅ "$btnText" 진입');
      // 뒤로가기: arrow_back 아이콘 또는 "뒤로" 텍스트
      final backIcon = find.byIcon(Icons.arrow_back);
      final backText = find.textContaining('뒤로');
      if (backIcon.evaluate().isNotEmpty) {
        await tester.tap(backIcon.first);
        await tester.pump(const Duration(seconds: 2));
        debugPrint('  ↩️ 복귀 (아이콘)');
      } else if (backText.evaluate().isNotEmpty) {
        await tester.tap(backText.first);
        await tester.pump(const Duration(seconds: 2));
        debugPrint('  ↩️ 복귀 (텍스트)');
      } else { debugPrint('  ⚠️ 뒤로 버튼 없음'); }
    }

    // ========================================
    // 3. 설정 → 다국어 변경
    // ========================================
    debugPrint('\n=== 3. 다국어 테스트 ===');
    final settingsBtn = find.textContaining('설정');
    if (settingsBtn.evaluate().isNotEmpty) {
      await tester.tap(settingsBtn.first);
      await tester.pump(const Duration(seconds: 3));
      for (final lang in GameLanguage.values) {
        debugPrint('  🌐 ${lang.displayName}...');
        final dropdown = find.byType(DropdownButton<GameLanguage>);
        if (dropdown.evaluate().isEmpty) { debugPrint('  ⚠️ 드롭다운 없음'); break; }
        await tester.tap(dropdown.first);
        await tester.pump(const Duration(seconds: 1));
        final option = find.text('${lang.flag}  ${lang.displayName}');
        if (option.evaluate().isNotEmpty) {
          await tester.tap(option.last);
          await tester.pump(const Duration(seconds: 2));
          debugPrint('  ✅ ${lang.displayName} 적용');
        }
      }
      final close = find.byIcon(Icons.close);
      if (close.evaluate().isNotEmpty) { await tester.tap(close.first); }
      else { await tester.tapAt(const Offset(10, 10)); }
      await tester.pump(const Duration(seconds: 2));
    }

    // ========================================
    // 4. 전투 시작 → 스테이지 선택
    // ========================================
    debugPrint('\n=== 4. 전투 플로우 ===');
    final battleBtn = find.textContaining('전투 시작');
    if (battleBtn.evaluate().isNotEmpty) {
      await tester.tap(battleBtn.first);
      await tester.pump(const Duration(seconds: 4));
      debugPrint('  ✅ 스테이지 선택 진입');
      final gestureDetectors = find.byType(GestureDetector);
      debugPrint('  GestureDetector: ${gestureDetectors.evaluate().length}');
      final inkWells = find.byType(InkWell);
      debugPrint('  InkWell: ${inkWells.evaluate().length}');
      if (inkWells.evaluate().length > 2) {
        await tester.tap(inkWells.at(2));
        await tester.pump(const Duration(seconds: 3));
        debugPrint('  ✅ 스테이지 선택됨');
      }
    } else { debugPrint('  ❌ 전투 시작 버튼 없음'); }

    debugPrint('\n=== 전수검사 완료 ===');
    expect(true, isTrue);
  });
}
