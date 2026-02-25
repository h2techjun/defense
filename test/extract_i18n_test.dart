import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_of_regrets/l10n/app_strings.dart';

void main() {
  test('extract i18n', () {
    final dir = Directory('assets/i18n');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    AppStrings.translations.forEach((lang, map) {
      final file = File('assets/i18n/\${lang.name}.json');
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map));
      print('Generated \${file.path}');
    });
  });
}
