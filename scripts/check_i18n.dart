import 'dart:convert';
import 'dart:io';

void main() async {
  final dir = Directory('assets/i18n');
  if (!await dir.exists()) {
    print('오류: assets/i18n 폴더가 존재하지 않습니다.');
    exit(1);
  }

  final files = await dir.list().where((e) => e.path.endsWith('.json')).toList();
  final koFile = files.firstWhere((e) => e.path.endsWith('ko.json'), orElse: () => File(''));

  if (koFile.path.isEmpty) {
    print('오류: 기준 파일인 ko.json을 찾을 수 없습니다.');
    exit(1);
  }

  final koContent = await File(koFile.path).readAsString();
  final Map<String, dynamic> koKeys = jsonDecode(koContent);

  bool allPassed = true;

  for (final file in files) {
    if (file.path == koFile.path) continue;

    final lang = file.path.split(Platform.pathSeparator).last;
    final content = await File(file.path).readAsString();
    final Map<String, dynamic> langKeys = jsonDecode(content);

    final missingKeys = <String>[];
    for (final key in koKeys.keys) {
      if (!langKeys.containsKey(key)) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      print('[$lang] 파일에 다음 키가 누락되었습니다:');
      for (final k in missingKeys) {
        print('  - $k');
      }
      allPassed = false;
    } else {
      print('[$lang] 모든 키가 존재합니다.');
    }
  }

  if (allPassed) {
    print('✅ i18n 검증 완료: 모든 언어 파일이 최신 상태입니다.');
  } else {
    print('❌ i18n 검증 실패: 누락된 번역 키가 존재합니다.');
    exit(1);
  }
}
