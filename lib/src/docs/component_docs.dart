import 'dart:io';

import 'package:blade_parser/blade_parser.dart';

/// Generates documentation for Blade components.
///
/// Scans a directory for Blade component files, extracts props and slots,
/// and generates markdown documentation.
class ComponentDocGenerator {
  /// Generate documentation for components in a directory.
  ///
  /// [componentDir] is the path to the components directory.
  /// Returns markdown documentation as a string.
  Future<String> generateDocs(
    String componentDir, {
    bool includeExamples = true,
    bool recursive = true,
  }) async {
    final dir = Directory(componentDir);
    if (!await dir.exists()) {
      throw ArgumentError('Directory does not exist: $componentDir');
    }

    final components = <ComponentInfo>[];

    // Find all Blade component files
    await for (final entity in dir.list(recursive: recursive)) {
      if (entity is File && entity.path.endsWith('.blade.php')) {
        final info = await analyzeComponent(entity);
        if (info != null) {
          components.add(info);
        }
      }
    }

    // Sort components alphabetically by name
    components.sort((a, b) => a.name.compareTo(b.name));

    return _generateMarkdown(components, includeExamples: includeExamples);
  }

  /// Analyze a single component file.
  Future<ComponentInfo?> analyzeComponent(File file) async {
    final content = await file.readAsString();
    final fileName = file.uri.pathSegments.last;
    final componentName = _fileNameToComponentName(fileName);

    // Parse the template
    final parser = BladeParser();
    final result = parser.parse(content);

    // Extract @props directive
    final props = <PropInfo>[];
    final slots = <String>{};
    String? description;

    // Visit the AST to find props directive and slots
    final visitor = _ComponentAnalyzer();
    result.ast?.accept(visitor);

    // Parse @props array if found
    if (visitor.propsContent != null) {
      props.addAll(_parsePropsArray(visitor.propsContent!));
    }

    // Add discovered slots
    slots.addAll(visitor.slots);

    // Extract description from first comment if present
    description = visitor.firstComment;

    return ComponentInfo(
      name: componentName,
      fileName: fileName,
      props: props,
      slots: slots.toList()..sort(),
      description: description,
      source: content,
    );
  }

  /// Convert filename to component name.
  ///
  /// `button.blade.php` -> `button`
  /// `alert-dialog.blade.php` -> `alert-dialog`
  String _fileNameToComponentName(String fileName) {
    return fileName.replaceAll('.blade.php', '');
  }

  /// Parse the @props array content to extract prop names and defaults.
  List<PropInfo> _parsePropsArray(String propsContent) {
    final props = <PropInfo>[];

    // Match patterns like:
    // 'propName' => 'default'
    // 'propName' => null
    // 'propName' => true
    // 'propName' => false
    // 'propName' => 123
    // "propName" => "default"
    final propPattern = RegExp(
      r'''['"](\w+)['"]\s*=>\s*(.+?)(?=,\s*['"]|\s*\]|$)''',
      multiLine: true,
    );

    for (final match in propPattern.allMatches(propsContent)) {
      final name = match.group(1)!;
      var defaultValue = match.group(2)?.trim();

      // Clean up the default value
      if (defaultValue != null) {
        // Remove trailing commas
        defaultValue = defaultValue.replaceAll(RegExp(r',\s*$'), '').trim();
      }

      props.add(PropInfo(
        name: name,
        defaultValue: defaultValue,
        type: _inferType(defaultValue),
      ));
    }

    return props;
  }

  /// Infer the type from a default value.
  String? _inferType(String? defaultValue) {
    if (defaultValue == null) return null;
    if (defaultValue == 'null') return null;
    if (defaultValue == 'true' || defaultValue == 'false') return 'bool';
    if (RegExp(r'^\d+$').hasMatch(defaultValue)) return 'int';
    if (RegExp(r'^\d+\.\d+$').hasMatch(defaultValue)) return 'float';
    if (defaultValue.startsWith("'") || defaultValue.startsWith('"')) {
      return 'string';
    }
    if (defaultValue.startsWith('[')) return 'array';
    return null;
  }

  /// Generate markdown documentation.
  String _generateMarkdown(
    List<ComponentInfo> components, {
    bool includeExamples = true,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('# Component Reference');
    buffer.writeln();
    buffer.writeln(
        'This document provides a reference for all Blade components.');
    buffer.writeln();

    // Table of contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    for (final component in components) {
      buffer.writeln('- [${component.name}](#${component.name})');
    }
    buffer.writeln();

    // Component documentation
    for (final component in components) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## ${component.name}');
      buffer.writeln();

      // Description
      if (component.description != null) {
        buffer.writeln(component.description);
        buffer.writeln();
      }

      // Props table
      if (component.props.isNotEmpty) {
        buffer.writeln('### Props');
        buffer.writeln();
        buffer.writeln('| Name | Type | Default | Description |');
        buffer.writeln('|------|------|---------|-------------|');
        for (final prop in component.props) {
          final type = prop.type ?? '-';
          final defaultVal = prop.defaultValue ?? '-';
          buffer.writeln('| `${prop.name}` | $type | `$defaultVal` | |');
        }
        buffer.writeln();
      }

      // Slots
      if (component.slots.isNotEmpty) {
        buffer.writeln('### Slots');
        buffer.writeln();
        for (final slot in component.slots) {
          if (slot == 'default') {
            buffer.writeln('- **default**: The main content slot');
          } else {
            buffer.writeln('- **$slot**: Named slot');
          }
        }
        buffer.writeln();
      }

      // Usage example
      buffer.writeln('### Usage');
      buffer.writeln();
      buffer.writeln('```blade');
      buffer.writeln(_generateUsageExample(component));
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate a usage example for a component.
  String _generateUsageExample(ComponentInfo component) {
    final buffer = StringBuffer();
    final tagName = 'x-${component.name}';

    // Start tag
    buffer.write('<$tagName');

    // Add required props (those without defaults or with null default)
    final requiredProps =
        component.props.where((p) => p.defaultValue == 'null').toList();
    for (final prop in requiredProps.take(3)) {
      buffer.write(' ${prop.name}="value"');
    }

    // Check if we need named slots
    final namedSlots =
        component.slots.where((s) => s != 'default' && s != 'slot').toList();

    if (namedSlots.isEmpty && component.slots.contains('default')) {
      // Simple component with just default slot
      buffer.writeln('>');
      buffer.writeln('    Content goes here');
      buffer.writeln('</$tagName>');
    } else if (namedSlots.isNotEmpty) {
      // Component with named slots
      buffer.writeln('>');
      for (final slot in namedSlots.take(2)) {
        buffer.writeln('    <x-slot:$slot>');
        buffer.writeln('        $slot content');
        buffer.writeln('    </x-slot:$slot>');
        buffer.writeln();
      }
      buffer.writeln('    Main content');
      buffer.writeln('</$tagName>');
    } else {
      // Self-closing or empty
      buffer.writeln(' />');
    }

    return buffer.toString().trim();
  }
}

/// Information about a Blade component.
class ComponentInfo {
  /// The component name (e.g., 'button', 'alert').
  final String name;

  /// The source filename.
  final String fileName;

  /// Props defined with @props directive.
  final List<PropInfo> props;

  /// Slot names used by the component.
  final List<String> slots;

  /// Description extracted from comments.
  final String? description;

  /// The raw source code.
  final String source;

  ComponentInfo({
    required this.name,
    required this.fileName,
    required this.props,
    required this.slots,
    this.description,
    required this.source,
  });
}

/// Information about a component prop.
class PropInfo {
  /// The prop name.
  final String name;

  /// The default value as a string.
  final String? defaultValue;

  /// The inferred type.
  final String? type;

  /// Optional description from doc comments.
  final String? description;

  PropInfo({
    required this.name,
    this.defaultValue,
    this.type,
    this.description,
  });
}

/// Visitor to extract component information from AST.
class _ComponentAnalyzer extends RecursiveAstVisitor<void> {
  String? propsContent;
  final Set<String> slots = {};
  String? firstComment;

  @override
  void get defaultValue {}

  @override
  void visitDirective(DirectiveNode node) {
    // Extract @props content
    if (node.name == 'props' && node.expression != null) {
      propsContent = node.expression;
    }

    super.visitDirective(node);
  }

  @override
  void visitEcho(EchoNode node) {
    // Look for slot usage: {{ $slot }}, {{ $header }}, etc.
    final expr = node.expression.trim();
    if (expr.startsWith(r'$')) {
      final varName = expr.substring(1).split(RegExp(r'[^\w]')).first;
      if (varName == 'slot') {
        slots.add('default');
      } else if (_isSlotName(varName)) {
        slots.add(varName);
      }
    }
    super.visitEcho(node);
  }

  @override
  void visitComment(CommentNode node) {
    // Capture first Blade comment as description
    if (firstComment == null && node.isBladeComment) {
      var content = node.content.trim();
      // Strip blade comment markers if present
      if (content.startsWith('{{--')) {
        content = content.substring(4);
      }
      if (content.endsWith('--}}')) {
        content = content.substring(0, content.length - 4);
      }
      content = content.trim();
      // Skip comments that look like section markers
      if (content.isNotEmpty &&
          !content.startsWith('Component Usage') &&
          !content.startsWith('Example') &&
          !content.contains('Definition:')) {
        firstComment = content;
      }
    }
    super.visitComment(node);
  }

  bool _isSlotName(String name) {
    // Common slot names
    const commonSlots = {
      'header',
      'footer',
      'title',
      'content',
      'actions',
      'icon',
      'trigger',
      'body',
      'sidebar',
      'nav',
      'menu',
      'meta',
      'leading',
      'trailing',
      'prefix',
      'suffix',
      'label',
      'description',
    };
    return commonSlots.contains(name);
  }
}
