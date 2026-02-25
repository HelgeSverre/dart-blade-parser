import 'dart:convert';
import 'dart:js_interop';

import 'package:blade_parser/blade_parser.dart';

/// JS-interop bridge for the Blade formatter.
/// Compiled with: dart compile js -O2 -o blade_formatter.js tool/js_bridge.dart

@JS('__dartBladeFormatter')
external set _bladeFormatter(JSFunction fn);

void main() {
  _bladeFormatter = _format.toJS;
}

/// Format Blade template source. Called from JS with:
///   bladeFormatter(source, optionsJson)
/// Returns JSON: { "formatted": "...", "error": null }
JSString _format(JSString source, JSString optionsJson) {
  final text = source.toDart;
  final opts = jsonDecode(optionsJson.toDart) as Map<String, dynamic>;

  final config = FormatterConfig(
    indentSize: opts['tabWidth'] as int? ?? 4,
    indentStyle: (opts['useTabs'] as bool? ?? false)
        ? IndentStyle.tabs
        : IndentStyle.spaces,
    maxLineLength: opts['printWidth'] as int? ?? 120,
    quoteStyle: QuoteStyle.fromString(opts['quoteStyle'] as String?),
    directiveSpacing:
        DirectiveSpacing.fromString(opts['directiveSpacing'] as String?),
    slotFormatting:
        SlotFormatting.fromString(opts['slotFormatting'] as String?),
    wrapAttributes:
        WrapAttributes.fromString(opts['wrapAttributes'] as String?),
    attributeSort:
        AttributeSort.fromString(opts['attributeSort'] as String?),
    closingBracketStyle:
        ClosingBracketStyle.fromString(opts['closingBracketStyle'] as String?),
    selfClosingStyle:
        SelfClosingStyle.fromString(opts['selfClosingStyle'] as String?),
  );

  final formatter = BladeFormatter(config: config);

  try {
    final formatted = formatter.format(text);
    final result = {'formatted': formatted, 'error': null};
    return jsonEncode(result).toJS;
  } catch (e) {
    final result = {'formatted': text, 'error': e.toString()};
    return jsonEncode(result).toJS;
  }
}
