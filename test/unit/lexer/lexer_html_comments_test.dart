import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for HTML comments (<!-- -->)
/// These tests EXPOSE bugs - HTML comments not lexed, treated as text
void main() {
  group('HTML Comments Lexer Tests (EXPECTED TO FAIL)', () {
    late BladeLexer lexer;

    test('Simple HTML comment should be tokenized', () {
      lexer = BladeLexer('<!-- This is a comment -->');
      final tokens = lexer.tokenize();

      // Expected: htmlComment token
      // Current bug: Treated as text
      final commentTokens =
          tokens.where((t) => t.type == TokenType.htmlComment).toList();

      expect(
        commentTokens.length,
        equals(1),
        reason: '<!-- --> should produce htmlComment token',
      );

      expect(commentTokens.first.value, contains('This is a comment'));
    });

    test('HTML comment with special characters', () {
      lexer = BladeLexer('<!-- TODO: Fix <div> and @if -->');
      final tokens = lexer.tokenize();

      final commentTokens =
          tokens.where((t) => t.type == TokenType.htmlComment).toList();

      expect(commentTokens.length, equals(1));

      final commentContent = commentTokens.first.value;
      expect(commentContent, contains('TODO'));
      expect(commentContent, contains('<div>'));
      expect(
        commentContent,
        contains('@if'),
        reason: 'Comment should preserve special chars literally',
      );
    });

    test('Multi-line HTML comment', () {
      lexer = BladeLexer('''
        <!--
          Multi-line
          comment
        -->
      ''');

      final tokens = lexer.tokenize();

      final commentTokens =
          tokens.where((t) => t.type == TokenType.htmlComment).toList();

      expect(
        commentTokens.length,
        equals(1),
        reason: 'Multi-line comment should be single token',
      );

      final content = commentTokens.first.value;
      expect(content, contains('Multi-line'));
      expect(content, contains('comment'));
    });

    test('Multiple HTML comments', () {
      lexer = BladeLexer('<!-- First --> text <!-- Second -->');
      final tokens = lexer.tokenize();

      final commentTokens =
          tokens.where((t) => t.type == TokenType.htmlComment).toList();

      expect(
        commentTokens.length,
        equals(2),
        reason: 'Should recognize both comments',
      );

      expect(commentTokens[0].value, contains('First'));
      expect(commentTokens[1].value, contains('Second'));

      // Should also have text token between them
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.any((t) => t.value.trim() == 'text'), isTrue);
    });

    test('Empty HTML comment', () {
      lexer = BladeLexer('<!---->');
      final tokens = lexer.tokenize();

      final commentTokens =
          tokens.where((t) => t.type == TokenType.htmlComment).toList();

      expect(commentTokens.length, equals(1));
      expect(
        commentTokens.first.value,
        isEmpty,
        reason: 'Empty comment should have empty value',
      );
    });

    test('HTML comment with -- inside (edge case)', () {
      // HTML spec doesn't allow -- inside comments, but parser should handle
      lexer = BladeLexer('<!-- Comment with -- double dash -->');
      final tokens = lexer.tokenize();

      final commentTokens =
          tokens.where((t) => t.type == TokenType.htmlComment).toList();

      // Should still parse (even if technically invalid HTML)
      expect(commentTokens, isNotEmpty);
    });
  });

  group('HTML Comments Parser Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('HTML comment in structure should create CommentNode', () {
      final result = parser.parse('''
        <div>
          <!-- This is a comment -->
          <p>Text</p>
        </div>
      ''');

      expect(result.isSuccess, isTrue);

      final div = result.ast!.children.whereType<HtmlElementNode>().firstWhere(
            (e) => e.tagName == 'div',
          );

      // Should have CommentNode child
      final comments = div.children.whereType<CommentNode>();
      expect(
        comments,
        isNotEmpty,
        reason: 'HTML comment should create CommentNode',
      );

      final comment = comments.first;
      expect(
        comment.isBladeComment,
        isFalse,
        reason: 'HTML comment should be marked as non-Blade',
      );
      expect(comment.content, contains('This is a comment'));
    });

    test('HTML comment vs Blade comment distinction', () {
      final result = parser.parse('''
        <!-- HTML comment -->
        {{-- Blade comment --}}
      ''');

      expect(result.isSuccess, isTrue);

      final comments = result.ast!.children.whereType<CommentNode>().toList();
      expect(
        comments.length,
        equals(2),
        reason: 'Should have both HTML and Blade comments',
      );

      // Find HTML comment
      final htmlComment = comments.firstWhere(
        (c) => !c.isBladeComment,
        orElse: () => throw Exception('HTML comment not found'),
      );
      expect(htmlComment.content, contains('HTML comment'));

      // Find Blade comment
      final bladeComment = comments.firstWhere((c) => c.isBladeComment);
      expect(bladeComment.content, contains('Blade comment'));
    });

    test('HTML comment preserves content without parsing', () {
      final result = parser.parse('''
        <!-- <div>This should not be parsed as HTML</div> -->
      ''');

      expect(result.isSuccess, isTrue);

      // Should be a comment, not nested HTML
      final comments = result.ast!.children.whereType<CommentNode>();
      expect(comments, isNotEmpty);

      final comment = comments.first;
      expect(comment.content, contains('<div>'));

      // Should NOT have parsed a div element
      final divs = result.ast!.children.whereType<HtmlElementNode>();
      expect(divs, isEmpty, reason: 'HTML inside comment should not be parsed');
    });

    test('Conditional comments (IE legacy)', () {
      final result = parser.parse('''
        <!--[if IE]>
          <p>You are using Internet Explorer</p>
        <![endif]-->
      ''');

      // Conditional comments are a special case
      // At minimum, should parse without error
      expect(
        result.errors,
        isEmpty,
        reason: 'Should handle conditional comments gracefully',
      );
    });

    test('HTML comment in various positions', () {
      final result = parser.parse('''
        <!-- Before -->
        <div>
          <!-- Inside -->
          <p>Text</p>
          <!-- Between -->
          <span>More</span>
          <!-- End of div -->
        </div>
        <!-- After -->
      ''');

      expect(result.isSuccess, isTrue);

      final allComments = result.ast!.children.whereType<CommentNode>();

      // Should find all comments
      expect(
        allComments.length,
        greaterThanOrEqualTo(2),
        reason: 'Should recognize multiple comments',
      );
    });
  });
}
