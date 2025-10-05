import 'package:blade_parser/blade_parser.dart';

void main() {
  final template = '<x-card wire:loading.delay>';

  print('Tokenizing: $template');
  final lexer = BladeLexer(template);
  final tokens = lexer.tokenize();

  for (final token in tokens) {
    print('${token.type}: "${token.value}"');
  }
}
