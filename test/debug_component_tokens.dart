import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  test('Debug component tokens', () {
    final lexer = BladeLexer('<x-alert type="error" dismissible>Content</x-alert>');
    final tokens = lexer.tokenize();

    print('\n=== TOKENS ===');
    for (var i = 0; i < tokens.length; i++) {
      print('$i: ${tokens[i].type} = "${tokens[i].value}"');
    }
  });
}
