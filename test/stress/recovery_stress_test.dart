import 'dart:io';

import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/node.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../utils/recovery_nodes.dart';

/// Count TagHeadRecovery items by walking the AST directly.
int countTagHeadRecoveries(AstNode node) {
  var count = 0;

  void visit(AstNode current) {
    if (current is HtmlElementNode) {
      count += current.tagHead.whereType<TagHeadRecovery>().length;
    } else if (current is ComponentNode) {
      count += current.tagHead.whereType<TagHeadRecovery>().length;
    }

    for (final child in current.children) {
      visit(child);
    }

    if (current is ComponentNode) {
      for (final slot in current.slots.values) {
        visit(slot);
      }
    }
  }

  visit(node);
  return count;
}

void main() {
  final formatter = BladeFormatter();
  final fixturesDir = Directory('test/fixtures/stress/recovery');
  final fixtures = fixturesDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.blade.php'))
      .toList();

  test('recovery fixtures exist', () {
    expect(fixtures, isNotEmpty,
        reason: 'Add malformed templates under test/fixtures/stress/recovery');
  });

  for (final fixture in fixtures) {
    final name = p.basename(fixture.path);
    test('formatter handles $name', () {
      final source = fixture.readAsStringSync();
      final result = formatter.formatWithResult(source);

      expect(result.ast, isNotNull);
      expect(result.hasErrors, isTrue);

      final recoveries = collectRecoveryNodes(result.ast!);
      expect(recoveries, isNotEmpty,
          reason: 'Expected recovery nodes in $name');
      final hasHighConfidence = recoveries.any(
        (node) => node.confidence == RecoveryConfidence.high,
      );
      final hasLowConfidence = recoveries.any(
        (node) => node.confidence == RecoveryConfidence.low,
      );
      expect(
        hasHighConfidence,
        isTrue,
        reason: 'Fixture $name should register at least one high-confidence recovery',
      );
      expect(
        hasLowConfidence,
        isTrue,
        reason: 'Fixture $name should register at least one low-confidence recovery',
      );
    });
  }

  group('tag-head recovery coverage', () {
    test('collectRecoveryNodes finds TagHeadRecovery items', () {
      // attribute_mess.blade.php has ???? and mixed_adjacent.blade.php has ???
      // which should trigger tag-head recovery
      final tagHeadFixtures = fixtures.where((f) {
        final name = p.basename(f.path);
        return name == 'attribute_mess.blade.php' ||
            name == 'mixed_adjacent.blade.php';
      });

      for (final fixture in tagHeadFixtures) {
        final source = fixture.readAsStringSync();
        final result = formatter.formatWithResult(source);
        expect(result.ast, isNotNull);

        final tagHeadCount = countTagHeadRecoveries(result.ast!);
        final recoveries = collectRecoveryNodes(result.ast!);

        // The helper must find at least as many as the direct count
        // (it also finds non-tag-head RecoveryNodes)
        expect(recoveries.length, greaterThanOrEqualTo(tagHeadCount),
            reason:
                '${p.basename(fixture.path)}: collectRecoveryNodes must include tag-head recoveries');
        expect(tagHeadCount, greaterThan(0),
            reason:
                '${p.basename(fixture.path)}: expected tag-head recovery items');
      }
    });
  });
}
