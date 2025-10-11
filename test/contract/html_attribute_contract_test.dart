import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Attribute Categorization Contract Tests', () {
    test('StandardAttribute for standard HTML attributes', () {
      final classAttr = StandardAttribute(name: 'class', value: 'container');
      expect(classAttr.name, 'class');
      expect(classAttr.value, 'container');
      expect(classAttr.toJson()['type'], 'standard');

      final idAttr = StandardAttribute(name: 'id', value: 'app');
      expect(idAttr.name, 'id');
      expect(idAttr.value, 'app');
      expect(idAttr.toJson()['type'], 'standard');
    });

    test('StandardAttribute for data-* attributes', () {
      final dataAttr = StandardAttribute(name: 'data-user-id', value: '123');
      expect(dataAttr.name, 'data-user-id');
      expect(dataAttr.value, '123');
      expect(dataAttr.toJson()['type'], 'standard');
    });

    test('StandardAttribute for aria-* attributes', () {
      final ariaAttr = StandardAttribute(name: 'aria-label', value: 'Close');
      expect(ariaAttr.name, 'aria-label');
      expect(ariaAttr.value, 'Close');
      expect(ariaAttr.toJson()['type'], 'standard');
    });

    test('AlpineAttribute for x-data directive', () {
      final xData = AlpineAttribute(
        name: 'x-data',
        directive: 'data',
        value: '{count: 0}',
      );
      expect(xData.name, 'x-data');
      expect(xData.directive, 'data');
      expect(xData.value, '{count: 0}');
      expect(xData.toJson()['type'], 'alpine');
    });

    test('AlpineAttribute for @click shorthand', () {
      final onClick = AlpineAttribute(
        name: '@click',
        directive: 'on:click',
        value: 'handle',
      );
      expect(onClick.name, '@click');
      expect(onClick.directive, 'on:click');
      expect(onClick.value, 'handle');
      expect(onClick.toJson()['type'], 'alpine');
    });

    test('AlpineAttribute for :class shorthand', () {
      final bindClass = AlpineAttribute(
        name: ':class',
        directive: 'bind:class',
        value: "{'active': isActive}",
      );
      expect(bindClass.name, ':class');
      expect(bindClass.directive, 'bind:class');
      expect(bindClass.toJson()['type'], 'alpine');
    });

    test('AlpineAttribute for x-show directive', () {
      final xShow = AlpineAttribute(
        name: 'x-show',
        directive: 'show',
        value: 'open',
      );
      expect(xShow.name, 'x-show');
      expect(xShow.directive, 'show');
      expect(xShow.value, 'open');
      expect(xShow.toJson()['type'], 'alpine');
    });

    test('LivewireAttribute for wire:click directive', () {
      final wireClick = LivewireAttribute(
        name: 'wire:click',
        action: 'click',
        value: 'save',
      );
      expect(wireClick.name, 'wire:click');
      expect(wireClick.action, 'click');
      expect(wireClick.value, 'save');
      expect(wireClick.toJson()['type'], 'livewire');
    });

    test('LivewireAttribute for wire:model directive', () {
      final wireModel = LivewireAttribute(
        name: 'wire:model',
        action: 'model',
        value: 'name',
      );
      expect(wireModel.name, 'wire:model');
      expect(wireModel.action, 'model');
      expect(wireModel.value, 'name');
      expect(wireModel.toJson()['type'], 'livewire');
    });

    test('LivewireAttribute for wire:model.defer with modifier', () {
      final wireModelDefer = LivewireAttribute(
        name: 'wire:model.defer',
        action: 'model',
        modifiers: ['defer'],
        value: 'email',
      );
      expect(wireModelDefer.name, 'wire:model.defer');
      expect(wireModelDefer.action, 'model');
      expect(wireModelDefer.modifiers, ['defer']);
      expect(wireModelDefer.value, 'email');
      expect(wireModelDefer.toJson()['type'], 'livewire');
    });

    test('LivewireAttribute for wire:loading.class with modifier', () {
      final wireLoading = LivewireAttribute(
        name: 'wire:loading.class',
        action: 'loading',
        modifiers: ['class'],
        value: 'opacity-50',
      );
      expect(wireLoading.name, 'wire:loading.class');
      expect(wireLoading.action, 'loading');
      expect(wireLoading.modifiers, ['class']);
      expect(wireLoading.value, 'opacity-50');
      expect(wireLoading.toJson()['type'], 'livewire');
    });

    test('StandardAttribute boolean attributes have null value', () {
      final disabled = StandardAttribute(name: 'disabled', value: null);
      expect(disabled.name, 'disabled');
      expect(disabled.value, isNull);

      final required = StandardAttribute(name: 'required', value: null);
      expect(required.name, 'required');
      expect(required.value, isNull);

      final readonly = StandardAttribute(name: 'readonly', value: null);
      expect(readonly.name, 'readonly');
      expect(readonly.value, isNull);
    });

    test('Attributes serialize to JSON with correct type field', () {
      final standard = StandardAttribute(name: 'class', value: 'foo');
      final alpine = AlpineAttribute(
        name: 'x-data',
        directive: 'data',
        value: '{}',
      );
      final livewire = LivewireAttribute(
        name: 'wire:click',
        action: 'click',
        value: 'save',
      );

      final standardJson = standard.toJson();
      final alpineJson = alpine.toJson();
      final livewireJson = livewire.toJson();

      expect(standardJson['type'], 'standard');
      expect(standardJson['name'], 'class');
      expect(standardJson['value'], 'foo');

      expect(alpineJson['type'], 'alpine');
      expect(alpineJson['name'], 'x-data');
      expect(alpineJson['directive'], 'data');
      expect(alpineJson['value'], '{}');

      expect(livewireJson['type'], 'livewire');
      expect(livewireJson['name'], 'wire:click');
      expect(livewireJson['action'], 'click');
      expect(livewireJson['value'], 'save');
    });

    test('Boolean attributes omit value in JSON when null', () {
      final disabled = StandardAttribute(name: 'disabled', value: null);
      final json = disabled.toJson();

      expect(json['type'], 'standard');
      expect(json['name'], 'disabled');
      expect(json.containsKey('value'), false); // value not included
    });

    test('Livewire modifiers are preserved in JSON', () {
      final wireAttr = LivewireAttribute(
        name: 'wire:poll.5s.visible',
        action: 'poll',
        modifiers: ['5s', 'visible'],
        value: 'refresh',
      );

      final json = wireAttr.toJson();

      expect(json['type'], 'livewire');
      expect(json['modifiers'], isA<List>());
      expect(json['modifiers'], hasLength(2));
      expect(json['modifiers'], contains('5s'));
      expect(json['modifiers'], contains('visible'));
    });
  });
}
