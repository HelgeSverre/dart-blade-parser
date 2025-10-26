// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  // Path to the blade CLI executable
  late String bladePath;
  late Directory tempDir;

  setUpAll(() {
    // Get path to blade executable relative to test directory
    bladePath = path.join(
      Directory.current.path,
      'bin',
      'blade.dart',
    );

    // Verify the blade CLI exists
    if (!File(bladePath).existsSync()) {
      throw StateError('blade CLI not found at: $bladePath');
    }
  });

  setUp(() {
    // Create temp directory for test files
    tempDir = Directory.systemTemp.createTempSync('blade_cli_test_');
  });

  tearDown(() {
    // Clean up temp directory
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CLI - Version and Help', () {
    test('shows version with --version flag', () async {
      final result = await Process.run('dart', [bladePath, '--version']);
      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('blade v'));
    });

    test('shows help with --help flag', () async {
      final result = await Process.run('dart', [bladePath, '--help']);
      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('parse'));
      expect(result.stdout.toString(), contains('format'));
    });

    test('shows help when no subcommand provided', () async {
      final result = await Process.run('dart', [bladePath]);
      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Usage:'));
    });
  });

  group('CLI - Format Command - Basic Modes', () {
    test('formats file to stdout by default', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', testFile.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('{{ \$user }}'));
      expect(result.stdout.toString(), contains('---'));
      // Original file should be unchanged
      expect(testFile.readAsStringSync(), '<div>{{  \$user  }}</div>');
    });

    test('writes formatted output back to file with --write', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', testFile.path],
      );

      expect(result.exitCode, 0);
      // File should be modified
      expect(testFile.readAsStringSync(), '<div>{{ \$user }}</div>\n');
    });

    test('check mode detects files needing formatting', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--check', testFile.path],
      );

      expect(result.exitCode, 1); // Exit 1 when formatting needed
      expect(result.stdout.toString(), contains('Needs formatting'));
    });

    test('check mode returns 0 for already formatted files', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>\n');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--check', testFile.path],
      );

      expect(result.exitCode, 0);
    });

    test('formats from stdin to stdout', () async {
      final process = await Process.start(
        'dart',
        [bladePath, 'format', '--stdin'],
      );

      process.stdin.writeln('<div>{{  \$user  }}</div>');
      await process.stdin.close();

      final stdout = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0);
      expect(stdout, contains('{{ \$user }}'));
    });
  });

  group('CLI - Format Command - Exit Codes', () {
    test('exits with 0 on successful formatting', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', testFile.path],
      );

      expect(result.exitCode, 0);
    });

    test('exits with 1 when check mode finds formatting needed', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--check', testFile.path],
      );

      expect(result.exitCode, 1);
    });

    test('exits with 1 on parse errors', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('@if(\$condition)'); // Missing @endif

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', testFile.path],
      );

      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('Parse errors'));
    });

    test('exits with 2 on invalid usage (conflicting flags)', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--check', '--write', testFile.path],
      );

      expect(result.exitCode, 2);
      expect(result.stderr.toString(), contains('Cannot use'));
    });

    test('exits with 2 when no files specified', () async {
      final result = await Process.run(
        'dart',
        [bladePath, 'format'],
      );

      expect(result.exitCode, 2);
      expect(result.stderr.toString(), contains('No files'));
    });

    test('exits with 2 when no matching files found', () async {
      final result = await Process.run(
        'dart',
        [bladePath, 'format', path.join(tempDir.path, 'nonexistent/')],
      );

      expect(result.exitCode, 2);
      expect(result.stderr.toString(), contains('No .blade.php files found'));
    });
  });

  group('CLI - Format Command - File Discovery', () {
    test('formats single file by path', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', testFile.path],
      );

      expect(result.exitCode, 0);
    });

    test('formats all .blade.php files in directory', () async {
      final file1 = File(path.join(tempDir.path, 'file1.blade.php'));
      final file2 = File(path.join(tempDir.path, 'file2.blade.php'));
      file1.writeAsStringSync('<div>{{  \$a  }}</div>');
      file2.writeAsStringSync('<div>{{  \$b  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', tempDir.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Found 2 file(s)'));
      expect(file1.readAsStringSync(), '<div>{{ \$a }}</div>\n');
      expect(file2.readAsStringSync(), '<div>{{ \$b }}</div>\n');
    });

    test('ignores non-.blade.php files in directory', () async {
      final bladeFile = File(path.join(tempDir.path, 'test.blade.php'));
      final phpFile = File(path.join(tempDir.path, 'test.php'));
      bladeFile.writeAsStringSync('<div>{{ \$user }}</div>');
      phpFile.writeAsStringSync('<?php echo "test"; ?>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', tempDir.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Found 1 file(s)'));
      // PHP file should be unchanged
      expect(phpFile.readAsStringSync(), '<?php echo "test"; ?>');
    });

    test('recursively finds files in nested directories', () async {
      final subDir = Directory(path.join(tempDir.path, 'sub'));
      subDir.createSync();

      final file1 = File(path.join(tempDir.path, 'root.blade.php'));
      final file2 = File(path.join(subDir.path, 'nested.blade.php'));
      file1.writeAsStringSync('<div>{{  \$a  }}</div>');
      file2.writeAsStringSync('<div>{{  \$b  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', tempDir.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Found 2 file(s)'));
    });

    test('supports glob pattern *.blade.php', () async {
      final file1 = File(path.join(tempDir.path, 'file1.blade.php'));
      final file2 = File(path.join(tempDir.path, 'file2.blade.php'));
      file1.writeAsStringSync('<div>{{  \$a  }}</div>');
      file2.writeAsStringSync('<div>{{  \$b  }}</div>');

      final pattern = path.join(tempDir.path, '*.blade.php');
      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', pattern],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('file(s)'));
    });

    test('handles multiple file patterns', () async {
      final subDir1 = Directory(path.join(tempDir.path, 'dir1'));
      final subDir2 = Directory(path.join(tempDir.path, 'dir2'));
      subDir1.createSync();
      subDir2.createSync();

      final file1 = File(path.join(subDir1.path, 'test.blade.php'));
      final file2 = File(path.join(subDir2.path, 'test.blade.php'));
      file1.writeAsStringSync('<div>{{  \$a  }}</div>');
      file2.writeAsStringSync('<div>{{  \$b  }}</div>');

      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--write',
          '--verbose',
          subDir1.path,
          subDir2.path,
        ],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Found 2 file(s)'));
    });

    test('deduplicates files when same file matches multiple patterns', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      // Pass the same file twice
      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--write',
          '--verbose',
          testFile.path,
          testFile.path,
        ],
      );

      expect(result.exitCode, 0);
      // Should only format once
      expect(result.stdout.toString(), contains('Found 1 file(s)'));
    });
  });

  group('CLI - Format Command - Configuration', () {
    test('uses default configuration when no config file', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('@if(\$x)\n<p>test</p>\n@endif');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', testFile.path],
      );

      expect(result.exitCode, 0);
      final content = testFile.readAsStringSync();
      // Default is 4 spaces
      expect(content, contains('    <p>test</p>'));
    });

    test('loads JSON configuration file', () async {
      final configFile = File(path.join(tempDir.path, '.blade.json'));
      configFile.writeAsStringSync(jsonEncode({
        'indent_size': 2,
        'indent_style': 'spaces',
      }));

      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('@if(\$x)\n<p>test</p>\n@endif');

      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--write',
          '--config',
          configFile.path,
          testFile.path,
        ],
      );

      expect(result.exitCode, 0);
      final content = testFile.readAsStringSync();
      // Should use 2 spaces from config
      expect(content, contains('  <p>test</p>'));
    });

    test('CLI flags override configuration file', () async {
      final configFile = File(path.join(tempDir.path, '.blade.json'));
      configFile.writeAsStringSync(jsonEncode({
        'indent_size': 2,
        'indent_style': 'spaces',
      }));

      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('@if(\$x)\n<p>test</p>\n@endif');

      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--write',
          '--config',
          configFile.path,
          '--indent-size',
          '8',
          testFile.path,
        ],
      );

      expect(result.exitCode, 0);
      final content = testFile.readAsStringSync();
      // Should use 8 spaces from CLI flag, not 2 from config
      expect(content, contains('        <p>test</p>'));
    });

    test('respects --indent-style tabs flag', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('@if(\$x)\n<p>test</p>\n@endif');

      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--write',
          '--indent-style',
          'tabs',
          testFile.path,
        ],
      );

      expect(result.exitCode, 0);
      final content = testFile.readAsStringSync();
      expect(content, contains('\t<p>test</p>'));
    });

    test('exits with error when config file not found', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--config',
          '/nonexistent/config.json',
          testFile.path,
        ],
      );

      expect(result.exitCode, 2);
      expect(result.stderr.toString(), contains('Config file not found'));
    });

    test('exits with error when config file has invalid JSON', () async {
      final configFile = File(path.join(tempDir.path, '.blade.json'));
      configFile.writeAsStringSync('{invalid json}');

      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [
          bladePath,
          'format',
          '--config',
          configFile.path,
          testFile.path,
        ],
      );

      expect(result.exitCode, 2);
      expect(result.stderr.toString(), contains('Failed to parse config'));
    });
  });

  group('CLI - Format Command - Verbose Output', () {
    test('shows detailed output with --verbose', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', testFile.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Found'));
      expect(result.stdout.toString(), contains('Summary:'));
      expect(result.stdout.toString(), contains('Total files:'));
      expect(result.stdout.toString(), contains('Formatted:'));
    });

    test('shows "Already formatted" message for unchanged files with --verbose', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>\n');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', testFile.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Already formatted'));
    });

    test('shows summary in check mode even without --verbose', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{  \$user  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--check', testFile.path],
      );

      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('Summary:'));
    });

    test('shows error count in summary when errors occur', () async {
      final file1 = File(path.join(tempDir.path, 'good.blade.php'));
      final file2 = File(path.join(tempDir.path, 'bad.blade.php'));
      file1.writeAsStringSync('<div>{{ \$user }}</div>');
      file2.writeAsStringSync('@if(\$x)'); // Missing @endif

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', tempDir.path],
      );

      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('Errors: 1'));
    });
  });

  group('CLI - Format Command - Error Handling', () {
    test('reports parse errors with line and column numbers', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('@if(\$condition)\n<p>Test</p>'); // Missing @endif

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', testFile.path],
      );

      expect(result.exitCode, 1);
      final stderr = result.stderr.toString();
      expect(stderr, contains('Parse errors'));
      expect(stderr, matches(RegExp(r'\d+:\d+'))); // Line:column format
    });

    test('continues processing other files when one has errors', () async {
      final file1 = File(path.join(tempDir.path, 'good.blade.php'));
      final file2 = File(path.join(tempDir.path, 'bad.blade.php'));
      final file3 = File(path.join(tempDir.path, 'also_good.blade.php'));

      file1.writeAsStringSync('<div>{{  \$a  }}</div>');
      file2.writeAsStringSync('@if(\$x)'); // Parse error
      file3.writeAsStringSync('<div>{{  \$b  }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--write', '--verbose', tempDir.path],
      );

      expect(result.exitCode, 1);
      // Good files should still be formatted
      expect(file1.readAsStringSync(), '<div>{{ \$a }}</div>\n');
      expect(file3.readAsStringSync(), '<div>{{ \$b }}</div>\n');
      // Bad file should be unchanged
      expect(file2.readAsStringSync(), '@if(\$x)');
    });

    test('exits with error when --stdin and --check used together', () async {
      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--stdin', '--check'],
      );

      expect(result.exitCode, 2);
      expect(
        result.stderr.toString(),
        contains('Cannot use --stdin with --check'),
      );
    });

    test('exits with error when --stdin and --write used together', () async {
      final result = await Process.run(
        'dart',
        [bladePath, 'format', '--stdin', '--write'],
      );

      expect(result.exitCode, 2);
      expect(
        result.stderr.toString(),
        contains('Cannot use --stdin with'),
      );
    });
  });

  group('CLI - Parse Command', () {
    test('parses file and shows tree output by default', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'parse', testFile.path],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Document'));
    });

    test('parses file and shows JSON output with --json', () async {
      final testFile = File(path.join(tempDir.path, 'test.blade.php'));
      testFile.writeAsStringSync('<div>{{ \$user }}</div>');

      final result = await Process.run(
        'dart',
        [bladePath, 'parse', '--json', testFile.path],
      );

      expect(result.exitCode, 0);
      final output = result.stdout.toString();
      expect(output, contains('{'));
      expect(output, contains('}'));
      // Verify it's valid JSON
      expect(() => jsonDecode(output), returnsNormally);
    });

    test('parses from stdin with --stdin', () async {
      final process = await Process.start(
        'dart',
        [bladePath, 'parse', '--stdin'],
      );

      process.stdin.writeln('<div>{{ \$user }}</div>');
      await process.stdin.close();

      final stdout = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0);
      expect(stdout, contains('Document'));
    });

    test('shows parse command help with --help', () async {
      final result = await Process.run(
        'dart',
        [bladePath, 'parse', '--help'],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Parse Blade templates'));
      expect(result.stdout.toString(), contains('--json'));
      expect(result.stdout.toString(), contains('--stdin'));
    });
  });
}
