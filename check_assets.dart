import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  final libFiles = await libDir.list(recursive: true).where((e) => e.path.endsWith('.dart')).toList();
  
  final assetRegex = RegExp(r"['""](assets/[^'""]+)['""]");
  final referencedAssets = <String>{};

  for (final file in libFiles) {
    if (file is File) {
      final content = await file.readAsString();
      final matches = assetRegex.allMatches(content);
      for (final match in matches) {
        final path = match.group(1)!;
        if (!path.contains('\$')) {
          referencedAssets.add(path);
        }
      }
    }
  }

  int missingCount = 0;
  final outLines = <String>[];
  for (final assetPath in referencedAssets) {
    if (!File(assetPath).existsSync()) {
      outLines.add('MISSING ASSET: $assetPath');
      missingCount++;
    }
  }

  if (missingCount == 0) {
    outLines.add('SUCCESS: All referenced assets exist!');
  } else {
    outLines.add('FAILED: Found $missingCount missing assets.');
  }
  File('missing_assets_utf8.txt').writeAsStringSync(outLines.join('\n'));
}
