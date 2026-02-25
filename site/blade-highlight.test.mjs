import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

// Load the highlighter (it sets globalThis.BladeHighlight)
const code = readFileSync(new URL('./blade-highlight.js', import.meta.url), 'utf8');
new Function(code)();
const { tokenizeBlade, highlightBlade } = globalThis.BladeHighlight;

/**
 * Helper: run tokenizer with a timeout to catch infinite loops.
 * Returns tokens or throws if it takes too long.
 */
function tokenizeWithTimeout(input, ms = 500) {
  // tokenizeBlade is synchronous, so we can't truly timeout,
  // but we can guard against obvious hangs by checking it finishes.
  const start = performance.now();
  const tokens = tokenizeBlade(input);
  const elapsed = performance.now() - start;
  assert.ok(elapsed < ms, `Tokenization took ${elapsed.toFixed(0)}ms (>${ms}ms) — possible infinite loop for input: ${JSON.stringify(input)}`);
  return tokens;
}

function highlightWithTimeout(input, ms = 500) {
  const start = performance.now();
  const result = highlightBlade(input);
  const elapsed = performance.now() - start;
  assert.ok(elapsed < ms, `Highlighting took ${elapsed.toFixed(0)}ms (>${ms}ms) — possible infinite loop for input: ${JSON.stringify(input)}`);
  return result;
}

describe('blade-highlight.js — infinite loop prevention', () => {
  describe('bare special characters', () => {
    it('handles bare <', () => {
      const tokens = tokenizeWithTimeout('<');
      assert.ok(tokens.length > 0);
      assert.equal(tokens[0].type, 'text');
      assert.equal(tokens[0].text, '<');
    });

    it('handles bare @', () => {
      const tokens = tokenizeWithTimeout('@');
      assert.ok(tokens.length > 0);
      assert.equal(tokens[0].type, 'text');
    });

    it('handles bare {', () => {
      const tokens = tokenizeWithTimeout('{');
      assert.ok(tokens.length > 0);
    });

    it('handles bare {{', () => {
      // Unclosed echo — should not hang
      const tokens = tokenizeWithTimeout('{{');
      assert.ok(tokens.length > 0);
    });

    it('handles bare {!!', () => {
      const tokens = tokenizeWithTimeout('{!!');
      assert.ok(tokens.length > 0);
    });

    it('handles bare {{{', () => {
      const tokens = tokenizeWithTimeout('{{{');
      assert.ok(tokens.length > 0);
    });

    it('handles bare {{--', () => {
      // Unclosed comment
      const tokens = tokenizeWithTimeout('{{--');
      assert.ok(tokens.length > 0);
    });
  });

  describe('< not followed by valid tag start', () => {
    it('handles < followed by space', () => {
      const tokens = tokenizeWithTimeout('< div>');
      assert.ok(tokens.some(t => t.type === 'text'));
    });

    it('handles < followed by digit (comparison operator)', () => {
      const tokens = tokenizeWithTimeout('a < 3');
      assert.equal(tokens.length, 1);
      assert.equal(tokens[0].text, 'a < 3');
    });

    it('handles < at end of input', () => {
      const tokens = tokenizeWithTimeout('hello <');
      assert.ok(tokens.length > 0);
    });

    it('handles multiple bare < in sequence', () => {
      const tokens = tokenizeWithTimeout('a < b < c');
      assert.ok(tokens.length > 0);
    });

    it('handles << (shift operator)', () => {
      const tokens = tokenizeWithTimeout('x << 2');
      assert.ok(tokens.length > 0);
    });

    it('handles <= (comparison)', () => {
      const tokens = tokenizeWithTimeout('x <= 10');
      assert.ok(tokens.length > 0);
    });

    it('handles <> (not equal)', () => {
      const tokens = tokenizeWithTimeout('a <> b');
      assert.ok(tokens.length > 0);
    });

    it('handles < followed by special chars', () => {
      const tokens = tokenizeWithTimeout('< $ % ^ & *');
      assert.ok(tokens.length > 0);
    });
  });

  describe('@ not followed by valid directive', () => {
    it('handles @ followed by digit', () => {
      const tokens = tokenizeWithTimeout('@123');
      assert.ok(tokens.length > 0);
      assert.equal(tokens[0].type, 'text');
    });

    it('handles @ followed by space', () => {
      const tokens = tokenizeWithTimeout('@ hello');
      assert.ok(tokens.length > 0);
    });

    it('handles @ at end of input', () => {
      const tokens = tokenizeWithTimeout('hello @');
      assert.ok(tokens.length > 0);
    });

    it('handles email address', () => {
      const tokens = tokenizeWithTimeout('user@example.com');
      assert.ok(tokens.length > 0);
      // Should be treated as text, not a directive
      const allText = tokens.map(t => t.text).join('');
      assert.ok(allText.includes('user@example.com'));
    });

    it('handles multiple @ signs', () => {
      const tokens = tokenizeWithTimeout('@@@');
      assert.ok(tokens.length > 0);
    });

    it('handles @@ (escaped @)', () => {
      const tokens = tokenizeWithTimeout('@@if');
      assert.ok(tokens.length > 0);
    });
  });

  describe('unclosed constructs', () => {
    it('handles unclosed HTML tag', () => {
      const tokens = tokenizeWithTimeout('<div class="foo');
      assert.ok(tokens.length > 0);
    });

    it('handles unclosed echo {{ without }}', () => {
      const tokens = tokenizeWithTimeout('{{ $var');
      assert.ok(tokens.length > 0);
    });

    it('handles unclosed raw echo {!! without !!}', () => {
      const tokens = tokenizeWithTimeout('{!! $var');
      assert.ok(tokens.length > 0);
    });

    it('handles unclosed comment {{-- without --}}', () => {
      const tokens = tokenizeWithTimeout('{{-- comment');
      assert.ok(tokens.length > 0);
    });

    it('handles unclosed directive parentheses', () => {
      const tokens = tokenizeWithTimeout('@if($x');
      assert.ok(tokens.length > 0);
    });

    it('handles unclosed attribute quote in tag', () => {
      const tokens = tokenizeWithTimeout('<div class="unclosed');
      assert.ok(tokens.length > 0);
    });
  });

  describe('mixed problematic inputs', () => {
    it('handles Blade mixed with comparisons', () => {
      const tokens = tokenizeWithTimeout('@if($a < $b)');
      assert.ok(tokens.some(t => t.type === 'directive'));
    });

    it('handles JS template literal with < in Blade', () => {
      const tokens = tokenizeWithTimeout('{{ $a < $b ? "yes" : "no" }}');
      assert.ok(tokens.some(t => t.type === 'echo'));
    });

    it('handles PHP arrow syntax', () => {
      const tokens = tokenizeWithTimeout('{{ $user->name }}');
      assert.ok(tokens.some(t => t.type === 'echo'));
    });

    it('handles lone < between Blade directives', () => {
      const tokens = tokenizeWithTimeout('@if(true) < @endif');
      assert.ok(tokens.length > 0);
    });

    it('handles < inside text between tags', () => {
      const tokens = tokenizeWithTimeout('<p>a < b</p>');
      assert.ok(tokens.length > 0);
    });

    it('handles rapid partial typing: <', () => {
      tokenizeWithTimeout('<');
    });

    it('handles rapid partial typing: <d', () => {
      tokenizeWithTimeout('<d');
    });

    it('handles rapid partial typing: <di', () => {
      tokenizeWithTimeout('<di');
    });

    it('handles rapid partial typing: <div', () => {
      tokenizeWithTimeout('<div');
    });

    it('handles rapid partial typing: <div>', () => {
      tokenizeWithTimeout('<div>');
    });

    it('handles rapid partial typing: @', () => {
      tokenizeWithTimeout('@');
    });

    it('handles rapid partial typing: @i', () => {
      tokenizeWithTimeout('@i');
    });

    it('handles rapid partial typing: @if', () => {
      tokenizeWithTimeout('@if');
    });

    it('handles rapid partial typing: @if(', () => {
      tokenizeWithTimeout('@if(');
    });

    it('handles rapid partial typing: {{', () => {
      tokenizeWithTimeout('{{');
    });

    it('handles rapid partial typing: {{ $', () => {
      tokenizeWithTimeout('{{ $');
    });

    it('handles rapid partial typing: {!', () => {
      tokenizeWithTimeout('{!');
    });

    it('handles rapid partial typing: {!!', () => {
      tokenizeWithTimeout('{!!');
    });
  });

  describe('highlightBlade end-to-end (no infinite loop)', () => {
    it('highlights empty string', () => {
      const html = highlightWithTimeout('');
      assert.equal(html, '\n');
    });

    it('highlights bare <', () => {
      const html = highlightWithTimeout('<');
      assert.ok(html.includes('&lt;'));
    });

    it('highlights bare @', () => {
      const html = highlightWithTimeout('@');
      assert.ok(html.includes('@'));
    });

    it('highlights a real template with < in text', () => {
      const html = highlightWithTimeout('<p>x < y and a > b</p>');
      assert.ok(html.length > 0);
    });

    it('highlights complex real-world template', () => {
      const input = `@extends('layouts.app')
@section('content')
<div class="container" x-data="{ count: 0 }">
    @foreach($items as $item)
        <p>{{ $item->name }}</p>
        @if($item->price < 100)
            <span class="cheap">Affordable</span>
        @endif
    @endforeach
</div>
@endsection`;
      const html = highlightWithTimeout(input);
      assert.ok(html.includes('hl-directive'));
      assert.ok(html.includes('hl-echo'));
      assert.ok(html.includes('hl-tag'));
    });

    it('highlights all problematic chars in one input', () => {
      const html = highlightWithTimeout('< @ { {{ {!! <3 @123 user@test.com');
      assert.ok(html.length > 0);
    });
  });

  describe('correctness (tokens are accurate)', () => {
    it('valid tag is parsed as tag', () => {
      const tokens = tokenizeWithTimeout('<div>');
      assert.ok(tokens.some(t => t.type === 'tag' && t.text.includes('div')));
    });

    it('valid directive is parsed as directive', () => {
      const tokens = tokenizeWithTimeout('@foreach($items as $item)');
      assert.ok(tokens.some(t => t.type === 'directive' && t.text === '@foreach'));
    });

    it('echo is parsed as echo', () => {
      const tokens = tokenizeWithTimeout('{{ $name }}');
      assert.ok(tokens.some(t => t.type === 'echo'));
    });

    it('raw echo is parsed as echo', () => {
      const tokens = tokenizeWithTimeout('{!! $html !!}');
      assert.ok(tokens.some(t => t.type === 'echo'));
    });

    it('comment is parsed as comment', () => {
      const tokens = tokenizeWithTimeout('{{-- note --}}');
      assert.ok(tokens.some(t => t.type === 'comment'));
    });

    it('bare < does not consume following valid tags', () => {
      const tokens = tokenizeWithTimeout('a < b <div>c</div>');
      assert.ok(tokens.some(t => t.type === 'text' && t.text.includes('a < b ')));
      assert.ok(tokens.some(t => t.type === 'tag' && t.text.includes('div')));
    });

    it('bare @ does not consume following valid directives', () => {
      const tokens = tokenizeWithTimeout('@ @if(true)');
      assert.ok(tokens.some(t => t.type === 'text' && t.text.includes('@')));
      assert.ok(tokens.some(t => t.type === 'directive' && t.text === '@if'));
    });
  });

  describe('HTML constructs and tag edge cases', () => {
    it('handles HTML comment <!-- -->', () => {
      const tokens = tokenizeWithTimeout('<!-- a comment -->');
      assert.ok(tokens.length > 0);
    });

    it('handles unclosed HTML comment <!--', () => {
      const tokens = tokenizeWithTimeout('<!--');
      assert.ok(tokens.length > 0);
    });

    it('handles HTML comment with dashes <!-- -->', () => {
      const tokens = tokenizeWithTimeout('<!-- has -- dashes -->');
      assert.ok(tokens.length > 0);
    });

    it('handles <!DOCTYPE html>', () => {
      const tokens = tokenizeWithTimeout('<!DOCTYPE html>');
      assert.ok(tokens.length > 0);
    });

    it('handles incomplete <!DOCTYPE', () => {
      const tokens = tokenizeWithTimeout('<!DOCTYPE');
      assert.ok(tokens.length > 0);
    });

    it('handles <?php processing instruction', () => {
      // < followed by ? is not a valid tag start, should be text
      const tokens = tokenizeWithTimeout('<?php echo "hi"; ?>');
      assert.ok(tokens.length > 0);
    });

    it('handles bare </', () => {
      const tokens = tokenizeWithTimeout('</');
      assert.ok(tokens.length > 0);
    });

    it('handles bare <!', () => {
      const tokens = tokenizeWithTimeout('<!');
      assert.ok(tokens.length > 0);
    });

    it('handles <x- (partial component tag)', () => {
      const tokens = tokenizeWithTimeout('<x-');
      assert.ok(tokens.length > 0);
    });

    it('handles <x-component (no closing >)', () => {
      const tokens = tokenizeWithTimeout('<x-component');
      assert.ok(tokens.length > 0);
    });

    it('handles self-closing tag <br />', () => {
      const tokens = tokenizeWithTimeout('<br />');
      assert.ok(tokens.some(t => t.type === 'tag'));
    });

    it('handles self-closing component <x-icon />', () => {
      const tokens = tokenizeWithTimeout('<x-icon name="check" />');
      assert.ok(tokens.some(t => t.type === 'tag'));
    });

    it('handles tag with unexpected chars <div $attr>', () => {
      const tokens = tokenizeWithTimeout('<div $attr>');
      assert.ok(tokens.some(t => t.type === 'tag'));
    });

    it('handles tag with hash <div #id>', () => {
      const tokens = tokenizeWithTimeout('<div #id>');
      assert.ok(tokens.some(t => t.type === 'tag'));
    });

    it('handles closing tag </div>', () => {
      const tokens = tokenizeWithTimeout('</div>');
      assert.ok(tokens.some(t => t.type === 'tag' && t.text.includes('div')));
    });

    it('handles nested tags', () => {
      const tokens = tokenizeWithTimeout('<div><span><a href="#">link</a></span></div>');
      assert.ok(tokens.filter(t => t.type === 'tag').length >= 6);
    });
  });

  describe('tokenizeTag internals and attribute edge cases', () => {
    it('handles Blade echo in attribute value', () => {
      const tokens = tokenizeWithTimeout('<div class="{{ $class }}">');
      assert.ok(tokens.some(t => t.type === 'echo'));
      assert.ok(tokens.some(t => t.type === 'attr' && t.text === 'class'));
    });

    it('handles raw echo in attribute value', () => {
      const tokens = tokenizeWithTimeout('<div title="{!! $html !!}">');
      assert.ok(tokens.some(t => t.type === 'echo'));
    });

    it('handles multiple Blade echoes in one attribute', () => {
      const tokens = tokenizeWithTimeout('<div class="{{ $a }} {{ $b }}">');
      const echos = tokens.filter(t => t.type === 'echo');
      assert.ok(echos.length >= 2);
    });

    it('handles unclosed echo inside attribute value', () => {
      // {{ without }} inside attribute — attribute quote scanning finds the quote first
      const tokens = tokenizeWithTimeout('<div class="{{ $x">');
      assert.ok(tokens.length > 0);
    });

    it('handles Alpine.js attributes', () => {
      const tokens = tokenizeWithTimeout('<div x-data="{ open: false }" @click="open = true">');
      assert.ok(tokens.some(t => t.type === 'attr' && t.text === 'x-data'));
    });

    it('handles Livewire attributes', () => {
      const tokens = tokenizeWithTimeout('<div wire:click="save" wire:model.live="name">');
      assert.ok(tokens.some(t => t.type === 'attr' && t.text.startsWith('wire:')));
    });

    it('handles attribute without value', () => {
      const tokens = tokenizeWithTimeout('<input disabled required>');
      assert.ok(tokens.some(t => t.type === 'attr' && t.text === 'disabled'));
      assert.ok(tokens.some(t => t.type === 'attr' && t.text === 'required'));
    });

    it('handles attribute with single-quoted value', () => {
      const tokens = tokenizeWithTimeout("<div class='foo'>");
      assert.ok(tokens.some(t => t.type === 'string'));
    });

    it('handles attribute with empty value', () => {
      const tokens = tokenizeWithTimeout('<div class="">');
      assert.ok(tokens.some(t => t.type === 'attr' && t.text === 'class'));
    });

    it('handles attribute with escaped quote', () => {
      const tokens = tokenizeWithTimeout('<div title="it\\"s">');
      assert.ok(tokens.length > 0);
    });
  });

  describe('directive expression edge cases', () => {
    it('handles deeply nested parentheses @if(fn(fn(fn())))', () => {
      const tokens = tokenizeWithTimeout("@if(fn(fn(fn('x'))))");
      assert.ok(tokens.some(t => t.type === 'directive' && t.text === '@if'));
      assert.ok(tokens.some(t => t.type === 'directive-expr'));
    });

    it('handles string with parens inside directive @if("(test)")', () => {
      const tokens = tokenizeWithTimeout('@if("(test)")');
      assert.ok(tokens.some(t => t.type === 'directive'));
    });

    it('handles escaped quote in directive expression', () => {
      const tokens = tokenizeWithTimeout("@if(\\'hello\\')");
      assert.ok(tokens.some(t => t.type === 'directive'));
    });

    it('handles directive with array argument', () => {
      const tokens = tokenizeWithTimeout("@foreach(['a', 'b', 'c'] as $item)");
      assert.ok(tokens.some(t => t.type === 'directive' && t.text === '@foreach'));
    });

    it('handles directive with arrow function', () => {
      const tokens = tokenizeWithTimeout("@if($items->filter(fn($i) => $i->active)->count())");
      assert.ok(tokens.some(t => t.type === 'directive'));
    });

    it('handles directive with no args followed by text', () => {
      const tokens = tokenizeWithTimeout('@csrf');
      assert.ok(tokens.some(t => t.type === 'directive' && t.text === '@csrf'));
    });

    it('handles consecutive directives', () => {
      const tokens = tokenizeWithTimeout('@csrf\n@method("PUT")');
      const directives = tokens.filter(t => t.type === 'directive');
      assert.ok(directives.length >= 2);
    });
  });

  describe('unicode, whitespace, and encoding edge cases', () => {
    it('handles emoji in content', () => {
      const tokens = tokenizeWithTimeout('<p>Hello 🌍 World 🎉</p>');
      assert.ok(tokens.length > 0);
      const allText = tokens.map(t => t.text).join('');
      assert.ok(allText.includes('🌍'));
    });

    it('handles emoji in attribute value', () => {
      const tokens = tokenizeWithTimeout('<div title="🎨 Colors">');
      assert.ok(tokens.length > 0);
    });

    it('handles CJK characters', () => {
      const tokens = tokenizeWithTimeout('<p>日本語テスト</p>');
      assert.ok(tokens.length > 0);
    });

    it('handles RTL text', () => {
      const tokens = tokenizeWithTimeout('<p>مرحبا بالعالم</p>');
      assert.ok(tokens.length > 0);
    });

    it('handles zero-width characters', () => {
      const tokens = tokenizeWithTimeout('<p>test\u200B\u200Cword</p>');
      assert.ok(tokens.length > 0);
    });

    it('handles Windows line endings \\r\\n', () => {
      const tokens = tokenizeWithTimeout('@if(true)\r\n<p>hi</p>\r\n@endif');
      assert.ok(tokens.some(t => t.type === 'directive'));
    });

    it('handles only whitespace', () => {
      const tokens = tokenizeWithTimeout('   \n\t  \n  ');
      assert.ok(tokens.length > 0);
      assert.ok(tokens.every(t => t.type === 'text'));
    });

    it('handles only newlines', () => {
      const tokens = tokenizeWithTimeout('\n\n\n');
      assert.ok(tokens.length > 0);
    });

    it('handles null-ish content in template', () => {
      const tokens = tokenizeWithTimeout('{{ null }}');
      assert.ok(tokens.some(t => t.type === 'echo'));
    });

    it('handles very long single line', () => {
      const long = '<div class="' + 'a'.repeat(10000) + '">';
      const tokens = tokenizeWithTimeout(long, 1000);
      assert.ok(tokens.some(t => t.type === 'tag'));
    });

    it('handles many short lines', () => {
      const lines = Array.from({ length: 1000 }, (_, i) => `<p>{{ $item${i} }}</p>`).join('\n');
      const tokens = tokenizeWithTimeout(lines, 1000);
      assert.ok(tokens.length > 1000);
    });
  });

  describe('stress: every char as sole input', () => {
    const problematic = '< > @ { } ( ) [ ] ! # $ % ^ & * = + - _ ~ ` \\ | / ? , . ; : \' "';
    for (const ch of problematic.split(' ')) {
      it(`does not hang on sole input: ${JSON.stringify(ch)}`, () => {
        tokenizeWithTimeout(ch);
      });
    }
  });
});
