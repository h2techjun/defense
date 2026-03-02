import 'dart:convert';
import 'dart:io';

/// i18n 키 동기화 검증 스크립트
/// 
/// 기준 파일(ko.json) 대비 다른 locale 파일의 누락/초과 키를 검출합니다.
/// 
/// 사용법: dart run scripts/check_i18n.dart [--dir assets/i18n]
void main(List<String> args) {
  final dir = args.isNotEmpty ? args.first.replaceAll('--dir=', '') : 'assets/i18n';
  final i18nDir = Directory(dir);
  
  if (!i18nDir.existsSync()) {
    print('❌ 디렉토리를 찾을 수 없습니다: $dir');
    exit(1);
  }

  // JSON 파일 목록
  final jsonFiles = i18nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  if (jsonFiles.isEmpty) {
    print('❌ JSON 파일이 없습니다: $dir');
    exit(1);
  }

  // 기준 파일 찾기 (ko.json)
  final baseFile = jsonFiles.firstWhere(
    (f) => f.path.contains('ko.json'),
    orElse: () => jsonFiles.first,
  );

  print('📋 기준 파일: ${baseFile.path}');
  print('━' * 50);

  final baseContent = jsonDecode(baseFile.readAsStringSync()) as Map<String, dynamic>;
  final baseKeys = _flattenKeys(baseContent);

  print('📊 기준 키 수: ${baseKeys.length}');
  print('');

  int totalMissing = 0;
  int totalExtra = 0;

  for (final file in jsonFiles) {
    if (file.path == baseFile.path) continue;

    final fileName = file.uri.pathSegments.last;
    final content = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final keys = _flattenKeys(content);

    final missing = baseKeys.where((k) => !keys.contains(k)).toList();
    final extra = keys.where((k) => !baseKeys.contains(k)).toList();

    if (missing.isEmpty && extra.isEmpty) {
      print('✅ $fileName — 동기화 완료 (${keys.length}키)');
    } else {
      if (missing.isNotEmpty) {
        print('⚠️  $fileName — 누락 ${missing.length}키:');
        for (final key in missing.take(10)) {
          print('    - $key');
        }
        if (missing.length > 10) {
          print('    ... 외 ${missing.length - 10}개');
        }
        totalMissing += missing.length;
      }
      if (extra.isNotEmpty) {
        print('🔵 $fileName — 초과 ${extra.length}키:');
        for (final key in extra.take(5)) {
          print('    + $key');
        }
        if (extra.length > 5) {
          print('    ... 외 ${extra.length - 5}개');
        }
        totalExtra += extra.length;
      }
    }
  }

  print('');
  print('━' * 50);
  print('📊 결과: 누락 $totalMissing키, 초과 $totalExtra키');
  
  if (totalMissing > 0) {
    print('🔴 누락된 키가 있습니다! 기준 파일(ko)을 참고하여 추가하세요.');
    exit(1);
  } else {
    print('🟢 모든 locale 파일이 동기화되어 있습니다.');
  }
}

/// 중첩된 JSON 키를 평탄화 (dot notation)
Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(entry.value as Map<String, dynamic>, key));
    } else {
      keys.add(key);
    }
  }
  return keys;
}
