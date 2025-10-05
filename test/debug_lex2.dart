import 'package:blade_parser/blade_parser.dart';

void main() {
  final template = '<x-dropdown x-data="{ open: false }" wire:submit="save">';

  print('Tokenizing: $template');
  final lexer = BladeLexer(template);
  final tokens = lexer.tokenize();

  for (final token in tokens) {
    print('${token.type}: "${token.value}"');
  }
}
