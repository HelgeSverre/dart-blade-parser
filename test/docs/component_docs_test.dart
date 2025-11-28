import 'dart:io';

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentDocGenerator', () {
    late ComponentDocGenerator generator;

    setUp(() {
      generator = ComponentDocGenerator();
    });

    group('analyzeComponent', () {
      test('extracts @props from component', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final file = File('${tempDir.path}/button.blade.php');
        await file.writeAsString('''
@props([
    'type' => 'button',
    'variant' => 'primary',
    'disabled' => false,
])

<button type="{{ \$type }}">{{ \$slot }}</button>
''');

        final info = await generator.analyzeComponent(file);

        expect(info, isNotNull);
        expect(info!.name, equals('button'));
        expect(info.props.length, equals(3));
        expect(info.props[0].name, equals('type'));
        expect(info.props[0].defaultValue, equals("'button'"));
        expect(info.props[0].type, equals('string'));
        expect(info.props[1].name, equals('variant'));
        expect(info.props[2].name, equals('disabled'));
        expect(info.props[2].type, equals('bool'));
        expect(info.slots, contains('default'));

        await tempDir.delete(recursive: true);
      });

      test('extracts named slots', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final file = File('${tempDir.path}/card.blade.php');
        await file.writeAsString('''
@props(['padding' => true])

<div>
    {{ \$header }}
    {{ \$slot }}
    {{ \$footer }}
</div>
''');

        final info = await generator.analyzeComponent(file);

        expect(info, isNotNull);
        expect(info!.slots, containsAll(['default', 'header', 'footer']));

        await tempDir.delete(recursive: true);
      });

      test('extracts description from first comment', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final file = File('${tempDir.path}/alert.blade.php');
        await file.writeAsString('''
{{-- Alert component for displaying messages --}}
@props(['type' => 'info'])

<div class="alert alert-{{ \$type }}">{{ \$slot }}</div>
''');

        final info = await generator.analyzeComponent(file);

        expect(info, isNotNull);
        expect(info!.description, equals('Alert component for displaying messages'));

        await tempDir.delete(recursive: true);
      });

      test('handles component without @props', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final file = File('${tempDir.path}/divider.blade.php');
        await file.writeAsString('<hr class="divider" />');

        final info = await generator.analyzeComponent(file);

        expect(info, isNotNull);
        expect(info!.name, equals('divider'));
        expect(info.props, isEmpty);

        await tempDir.delete(recursive: true);
      });

      test('infers types from defaults', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final file = File('${tempDir.path}/test.blade.php');
        await file.writeAsString('''
@props([
    'count' => 5,
    'price' => 19.99,
    'active' => true,
    'label' => "Hello",
    'items' => [],
    'data' => null,
])

{{ \$slot }}
''');

        final info = await generator.analyzeComponent(file);

        expect(info, isNotNull);
        expect(info!.props[0].type, equals('int'));
        expect(info.props[1].type, equals('float'));
        expect(info.props[2].type, equals('bool'));
        expect(info.props[3].type, equals('string'));
        expect(info.props[4].type, equals('array'));
        expect(info.props[5].type, isNull); // null doesn't have a type

        await tempDir.delete(recursive: true);
      });
    });

    group('generateDocs', () {
      test('generates markdown with table of contents', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');

        // Create test components
        await File('${tempDir.path}/button.blade.php').writeAsString('''
@props(['type' => 'button'])
<button>{{ \$slot }}</button>
''');

        await File('${tempDir.path}/card.blade.php').writeAsString('''
@props(['padding' => true])
<div>{{ \$slot }}</div>
''');

        final markdown = await generator.generateDocs(tempDir.path);

        expect(markdown, contains('# Component Reference'));
        expect(markdown, contains('## Table of Contents'));
        expect(markdown, contains('- [button](#button)'));
        expect(markdown, contains('- [card](#card)'));
        expect(markdown, contains('## button'));
        expect(markdown, contains('## card'));

        await tempDir.delete(recursive: true);
      });

      test('generates props table', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        await File('${tempDir.path}/button.blade.php').writeAsString('''
@props(['type' => 'submit', 'disabled' => false])
<button>{{ \$slot }}</button>
''');

        final markdown = await generator.generateDocs(tempDir.path);

        expect(markdown, contains('### Props'));
        expect(markdown, contains('| Name | Type | Default | Description |'));
        expect(markdown, contains('| `type` | string | `\'submit\'` | |'));
        expect(markdown, contains('| `disabled` | bool | `false` | |'));

        await tempDir.delete(recursive: true);
      });

      test('generates slots section', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        await File('${tempDir.path}/card.blade.php').writeAsString('''
<div>
    {{ \$header }}
    {{ \$slot }}
</div>
''');

        final markdown = await generator.generateDocs(tempDir.path);

        expect(markdown, contains('### Slots'));
        expect(markdown, contains('- **default**: The main content slot'));
        expect(markdown, contains('- **header**: Named slot'));

        await tempDir.delete(recursive: true);
      });

      test('generates usage example', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        await File('${tempDir.path}/button.blade.php').writeAsString('''
@props(['label' => null])
<button>{{ \$slot }}</button>
''');

        final markdown = await generator.generateDocs(tempDir.path);

        expect(markdown, contains('### Usage'));
        expect(markdown, contains('```blade'));
        expect(markdown, contains('<x-button'));

        await tempDir.delete(recursive: true);
      });

      test('scans recursively by default', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final subDir = Directory('${tempDir.path}/sub');
        await subDir.create();

        await File('${tempDir.path}/top.blade.php').writeAsString(
          '<div>{{ \$slot }}</div>',
        );
        await File('${subDir.path}/nested.blade.php').writeAsString(
          '<span>{{ \$slot }}</span>',
        );

        final markdown = await generator.generateDocs(tempDir.path);

        expect(markdown, contains('## top'));
        expect(markdown, contains('## nested'));

        await tempDir.delete(recursive: true);
      });

      test('respects non-recursive flag', () async {
        final tempDir = await Directory.systemTemp.createTemp('blade_test_');
        final subDir = Directory('${tempDir.path}/sub');
        await subDir.create();

        await File('${tempDir.path}/top.blade.php').writeAsString(
          '<div>{{ \$slot }}</div>',
        );
        await File('${subDir.path}/nested.blade.php').writeAsString(
          '<span>{{ \$slot }}</span>',
        );

        final markdown = await generator.generateDocs(
          tempDir.path,
          recursive: false,
        );

        expect(markdown, contains('## top'));
        expect(markdown, isNot(contains('## nested')));

        await tempDir.delete(recursive: true);
      });

      test('throws for non-existent directory', () async {
        expect(
          () => generator.generateDocs('/nonexistent/path'),
          throwsArgumentError,
        );
      });
    });
  });

  group('PropInfo', () {
    test('stores prop information', () {
      final prop = PropInfo(
        name: 'type',
        defaultValue: "'button'",
        type: 'string',
        description: 'The button type',
      );

      expect(prop.name, equals('type'));
      expect(prop.defaultValue, equals("'button'"));
      expect(prop.type, equals('string'));
      expect(prop.description, equals('The button type'));
    });
  });

  group('ComponentInfo', () {
    test('stores component information', () {
      final component = ComponentInfo(
        name: 'button',
        fileName: 'button.blade.php',
        props: [PropInfo(name: 'type', defaultValue: "'button'")],
        slots: ['default'],
        description: 'A button component',
        source: '<button>{{ \$slot }}</button>',
      );

      expect(component.name, equals('button'));
      expect(component.fileName, equals('button.blade.php'));
      expect(component.props.length, equals(1));
      expect(component.slots, equals(['default']));
      expect(component.description, equals('A button component'));
    });
  });
}
