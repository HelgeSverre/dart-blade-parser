@Tags(['livewire'])
library;

import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Livewire Detection Tests', () {
    test('parses Livewire attributes without relying on toString', () {
      final parser = BladeParser();
      final result =
          parser.parse('<div wire:click="handleClick">Content</div>');
      expect(result.isSuccess, isTrue);
      final element = result.ast!.children.whereType<HtmlElementNode>().first;
      expect(element.attributes.containsKey('wire:click'), isTrue);
      final attr = element.attributes['wire:click'];
      expect(attr, isA<LivewireAttribute>());
    });
  });
}
