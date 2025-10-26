import 'dart:io';
import 'package:blade_parser/blade_parser.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/format_file.dart <file> [--write]');
    exit(1);
  }

  final filePath = args[0];
  final write = args.contains('--write');

  final file = File(filePath);
  if (!file.existsSync()) {
    print('Error: File not found: $filePath');
    exit(1);
  }

  try {
    final formatter = BladeFormatter();
    final input = file.readAsStringSync();
    final output = formatter.format(input);

    if (write) {
      file.writeAsStringSync(output);
      print('Formatted: $filePath');
    } else {
      print(output);
    }
  } catch (e) {
    print('Error formatting $filePath: $e');
    exit(1);
  }
}
