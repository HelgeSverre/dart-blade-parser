# Blade Parser

A pure Dart parser for Laravel Blade templates.

## Features

- Complete Blade directive syntax support (@if, @foreach, @section, etc.)
- Component parsing with slots and attributes
- Alpine.js and Livewire attribute parsing
- Error recovery with descriptive messages
- Streaming mode for large files
- JSON serialization of AST
- CLI and programmatic API

## Installation

```yaml
dependencies:
  blade_parser: ^1.0.0
```

## Usage

```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();
  final result = parser.parse('{{ \$user->name }}');

  if (result.isSuccess) {
    print('Parsed successfully!');
    print(result.ast!.toJson());
  }
}
```

## Documentation

See the [API documentation](https://pub.dev/documentation/blade_parser/latest/) for complete details.

## License

MIT
