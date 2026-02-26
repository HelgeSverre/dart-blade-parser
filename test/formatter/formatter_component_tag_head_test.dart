import 'dart:io';

import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter: Component tagHead with structural directives', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('component with @if/@endif wrapping attribute is formatted', () {
      const input = '''<x-button
    type="submit"
    @if(\$loading)
        disabled
    @endif
>
    Save
</x-button>''';

      final result = formatter.format(input);
      expect(result, contains('@if'));
      expect(result, contains('@endif'));
      expect(result, contains('disabled'));
      expect(result, contains('<x-button'));
      expect(result, contains('</x-button>'));
    });

    test('self-closing component with @if is formatted correctly', () {
      const input = '''<x-icon
    name="bell"
    @if(\$animate)
        class="animate-bounce"
    @endif
/>''';

      final result = formatter.format(input);
      expect(result, contains('@if'));
      expect(result, contains('@endif'));
      expect(result, contains('name="bell"'));
      expect(result, contains('/>'));
    });

    test('component with mixed @if and @class', () {
      const input = '''<x-button
    type="submit"
    @if(\$loading)
        wire:loading.attr="disabled"
        wire:target="save"
    @endif
    @class(['btn', 'btn-lg' => \$large])
>
    Save
</x-button>''';

      final result = formatter.format(input);
      expect(result, contains('@if'));
      expect(result, contains('@endif'));
      expect(result, contains("@class(['btn'"));
      expect(result, contains('wire:loading.attr="disabled"'));
    });

    test('idempotency: component with @if in tag head', () {
      const input = '''<x-data-table
    :columns="\$columns"
    :rows="\$rows"
    @if(\$paginated)
        :per-page="\$perPage"
    @endif
>
    <x-slot:empty>
        <p>No records found.</p>
    </x-slot>
</x-data-table>''';

      final pass1 = formatter.format(input);
      final pass2 = formatter.format(pass1);
      final pass3 = formatter.format(pass2);

      expect(pass2, equals(pass1), reason: 'Second pass should equal first');
      expect(pass3, equals(pass2), reason: 'Third pass should equal second');
    });

    test('idempotency: self-closing component with @class', () {
      const input = '''<x-dynamic-component
    :component="\$item['icon']"
    @class([
        'flex-shrink-0 -ml-1 mr-3 size-6',
        \$activeIcon => \$isActive,
        \$defaultIcon => ! \$isActive,
    ])
/>''';

      final pass1 = formatter.format(input);
      final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1), reason: 'Second pass should equal first');
    });

    test('contoso settings layout fixture parses and formats', () {
      final source = File('test/fixtures/stress/contoso/settings_layout.blade.php')
          .readAsStringSync();

      final pass1 = formatter.format(source);
      final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1),
          reason: 'Settings layout should be idempotent');
    });

    test('contoso contact show fixture parses and formats', () {
      final source = File('test/fixtures/stress/contoso/contact_show.blade.php')
          .readAsStringSync();

      final pass1 = formatter.format(source);
      final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1),
          reason: 'Contact show should be idempotent');
    });

    test('contoso ticket show fixture parses and formats', () {
      final source = File('test/fixtures/stress/contoso/ticket_show.blade.php')
          .readAsStringSync();

      final pass1 = formatter.format(source);
      final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1),
          reason: 'Ticket show should be idempotent');
    });
  });
}
