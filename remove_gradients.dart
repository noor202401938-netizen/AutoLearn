import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.contains('gradient_menu.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    final originalContent = content;

    while (true) {
      final idx = content.indexOf('gradient: LinearGradient(');
      if (idx == -1) break;

      final startParen = content.indexOf('(', idx);
      int parenCount = 1;
      int endIdx = startParen + 1;

      while (endIdx < content.length && parenCount > 0) {
        if (content[endIdx] == '(') {
          parenCount++;
        } else if (content[endIdx] == ')') {
          parenCount--;
        }
        endIdx++;
      }

      // Check if there is a trailing comma
      while (endIdx < content.length && (content[endIdx] == ' ' || content[endIdx] == '\n' || content[endIdx] == '\r')) {
        endIdx++;
      }
      if (endIdx < content.length && content[endIdx] == ',') {
        endIdx++;
      }

      content = content.substring(0, idx) + content.substring(endIdx);
    }

    if (content != originalContent) {
      // Clean up empty BoxDecorations
      content = content.replaceAll('decoration: BoxDecoration(\n        ),', '');
      content = content.replaceAll('decoration: const BoxDecoration(\n        ),', '');
      content = content.replaceAll(RegExp(r'decoration:\s*(const\s*)?BoxDecoration\(\s*\),?'), '');
      
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
  print('Done!');
}
