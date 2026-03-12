import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// i18n JSON 파일 검증 테스트
/// AppStrings는 런타임에 JSON을 로드하므로, 여기서는 JSON 파일 존재/형식을 검증합니다.
void main() {
  test('i18n JSON 파일이 존재하고 유효한 형식인지 확인', () {
    final dir = Directory('assets/i18n');
    if (!dir.existsSync()) {
      fail('assets/i18n 디렉토리가 존재하지 않습니다');
    }

    final koFile = File('assets/i18n/ko.json');
    expect(koFile.existsSync(), isTrue, reason: 'ko.json이 존재해야 합니다');

    final content = koFile.readAsStringSync();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    expect(decoded.isNotEmpty, isTrue, reason: 'ko.json에 번역 키가 있어야 합니다');
  });
}
