// 해원의 문 — 기본 위젯 테스트
// 앱이 정상적으로 시작되는지 확인하는 smoke test

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gateway_of_regrets/main.dart';

void main() {
  testWidgets('App smoke test — renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GatewayOfRegretsApp()),
    );

    // 앱이 크래시 없이 렌더링되는지 확인
    expect(find.byType(GatewayOfRegretsApp), findsOneWidget);
  });
}
