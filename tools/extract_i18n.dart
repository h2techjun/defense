import 'dart:convert';
import 'dart:io';

/// i18n JSON 파일 유효성 검사 도구
/// AppStrings가 JSON 기반으로 리팩토링되었으므로, 기존 extract 로직 대신
/// assets/i18n/ 폴더의 JSON 형식을 검증합니다.
void main() {
  final dir = Directory('assets/i18n');
  if (!dir.existsSync()) {
    print('❌ assets/i18n 디렉토리가 존재하지 않습니다');
    return;
  }

  final jsonFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
  if (jsonFiles.isEmpty) {
    print('⚠️ assets/i18n에 JSON 파일이 없습니다');
    return;
  }

  for (final file in jsonFiles) {
    try {
      final content = file.readAsStringSync();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      print('✅ ${file.uri.pathSegments.last}: ${decoded.length}개 키');
    } catch (e) {
      print('❌ ${file.uri.pathSegments.last}: 파싱 실패 - $e');
    }
  }

  print('\\n🎉 i18n 검증 완료');
}
