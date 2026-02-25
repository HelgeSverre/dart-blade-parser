import { describe, it } from "node:test";
import assert from "node:assert/strict";
import * as prettier from "prettier";

const pluginPath = new URL("../src/index.mjs", import.meta.url).pathname;

async function format(code, options = {}) {
  return prettier.format(code, {
    parser: "blade",
    plugins: [pluginPath],
    ...options,
  });
}

// ---------------------------------------------------------------------------
// Core formatting
// ---------------------------------------------------------------------------
describe("core formatting", () => {
  it("formats a basic template", async () => {
    const result = await format(
      "<div>@if($user) <p>Hello</p> @endif</div>",
    );
    assert.equal(
      result,
      "<div>\n    @if($user)\n        <p>Hello</p>\n    @endif\n</div>\n",
    );
  });

  it("is idempotent", async () => {
    const input =
      "<div>@if($user) <p>{{ $user->name }}</p> @else <p>Guest</p> @endif</div>";
    const first = await format(input);
    const second = await format(first);
    assert.equal(first, second);
  });

  it("idempotent on complex nested template", async () => {
    const input = `<section>
@auth
@foreach($items as $item)
<x-card title="{{ $item->title }}">
<x-slot:header><h2>{{ $item->name }}</h2></x-slot>
<p>{{ $item->body }}</p>
</x-card>
@endforeach
@endauth
</section>`;
    const first = await format(input);
    const second = await format(first);
    assert.equal(first, second);
  });

  it("outputs trailing newline", async () => {
    const result = await format("<p>Hello</p>");
    assert.ok(result.endsWith("\n"));
  });

  it("handles empty input", async () => {
    const result = await format("");
    assert.equal(result.trim(), "");
  });

  it("handles whitespace-only input", async () => {
    const result = await format("   \n\n  ");
    assert.equal(result.trim(), "");
  });
});

// ---------------------------------------------------------------------------
// Prettier standard options
// ---------------------------------------------------------------------------
describe("prettier standard options", () => {
  it("respects tabWidth", async () => {
    const result = await format(
      "<div>@if($user) <p>Hello</p> @endif</div>",
      { tabWidth: 2 },
    );
    assert.equal(
      result,
      "<div>\n  @if($user)\n    <p>Hello</p>\n  @endif\n</div>\n",
    );
  });

  it("respects useTabs", async () => {
    const result = await format(
      "<div>@if($user) <p>Hello</p> @endif</div>",
      { useTabs: true },
    );
    assert.ok(result.includes("\t@if"));
    assert.ok(!result.includes("    @if"));
  });

  it("printWidth affects attribute wrapping", async () => {
    const tag =
      '<input type="email" class="form-control very-long-class-name" id="email" name="email" placeholder="Enter email" required>';
    const narrow = await format(tag, { printWidth: 40 });
    const wide = await format(tag, { printWidth: 300 });

    const narrowLines = narrow.trim().split("\n");
    const wideLines = wide.trim().split("\n");
    assert.ok(narrowLines.length > wideLines.length);
  });

  it("infers parser from .blade.php extension", async () => {
    const result = await prettier.format(
      "<div>@if($x) <p>Y</p> @endif</div>",
      { filepath: "template.blade.php", plugins: [pluginPath] },
    );
    assert.ok(result.includes("@if"));
    assert.ok(result.includes("@endif"));
  });

  it("infers parser from nested path", async () => {
    const result = await prettier.format("<p>{{ $x }}</p>", {
      filepath: "resources/views/home.blade.php",
      plugins: [pluginPath],
    });
    assert.ok(result.includes("{{ $x }}"));
  });
});

// ---------------------------------------------------------------------------
// Directives
// ---------------------------------------------------------------------------
describe("directives", () => {
  it("formats @if / @else / @endif", async () => {
    const result = await format(
      "@if($a) <p>A</p> @else <p>B</p> @endif",
    );
    assert.ok(result.includes("@if($a)"));
    assert.ok(result.includes("@else"));
    assert.ok(result.includes("@endif"));
  });

  it("formats @foreach", async () => {
    const result = await format(
      "@foreach($items as $item) <li>{{ $item }}</li> @endforeach",
    );
    assert.ok(result.includes("@foreach"));
    assert.ok(result.includes("@endforeach"));
  });

  it("formats @forelse / @empty", async () => {
    const result = await format(
      "@forelse($items as $item) <li>{{ $item }}</li> @empty <p>None</p> @endforelse",
    );
    assert.ok(result.includes("@forelse"));
    assert.ok(result.includes("@empty"));
    assert.ok(result.includes("@endforelse"));
  });

  it("formats nested directives with correct indentation", async () => {
    const result = await format(
      "@if($a) @foreach($items as $item) <p>{{ $item }}</p> @endforeach @endif",
    );
    const lines = result.split("\n");
    const foreachLine = lines.find((l) => l.includes("@foreach"));
    const pLine = lines.find((l) => l.includes("<p>"));
    assert.ok(foreachLine);
    assert.ok(pLine);
    // @foreach should be more indented than @if, <p> more than @foreach
    const foreachIndent = foreachLine.search(/\S/);
    const pIndent = pLine.search(/\S/);
    assert.ok(pIndent > foreachIndent);
  });

  it("formats @auth / @guest", async () => {
    const result = await format(
      "@auth <p>Logged in</p> @endauth @guest <p>Please log in</p> @endguest",
    );
    assert.ok(result.includes("@auth"));
    assert.ok(result.includes("@endauth"));
    assert.ok(result.includes("@guest"));
    assert.ok(result.includes("@endguest"));
  });

  it("formats @switch / @case / @default", async () => {
    const result = await format(
      "@switch($type) @case('a') <p>A</p> @break @default <p>Other</p> @break @endswitch",
    );
    assert.ok(result.includes("@switch"));
    assert.ok(result.includes("@case"));
    assert.ok(result.includes("@default"));
    assert.ok(result.includes("@endswitch"));
  });

  it("formats inline directives", async () => {
    const result = await format(
      '<form>@csrf @method("PUT") <input></form>',
    );
    assert.ok(result.includes("@csrf"));
    assert.ok(result.includes("@method"));
  });

  it("formats @section / @yield / @extends", async () => {
    const result = await format(
      "@extends('layout') @section('content') <p>Hi</p> @endsection",
    );
    assert.ok(result.includes("@extends"));
    assert.ok(result.includes("@section"));
    assert.ok(result.includes("@endsection"));
  });

  it("formats @php block", async () => {
    const result = await format("@php $x = 1; @endphp");
    assert.ok(result.includes("@php"));
    assert.ok(result.includes("@endphp"));
  });

  it("formats @push / @stack", async () => {
    const result = await format(
      "@push('scripts') <script>alert(1)</script> @endpush",
    );
    assert.ok(result.includes("@push"));
    assert.ok(result.includes("@endpush"));
  });
});

// ---------------------------------------------------------------------------
// Echo statements
// ---------------------------------------------------------------------------
describe("echo statements", () => {
  it("formats escaped echo {{ }}", async () => {
    const result = await format("<p>{{$name}}</p>");
    assert.ok(result.includes("{{ $name }}"));
  });

  it("formats raw echo {!! !!}", async () => {
    const result = await format("<p>{!!$html!!}</p>");
    assert.ok(result.includes("{!! $html !!}"));
  });

  it("formats echo with complex expression", async () => {
    const result = await format("<p>{{ $user->getFullName() }}</p>");
    assert.ok(result.includes("{{ $user->getFullName() }}"));
  });

  it("keeps inline echo within tags", async () => {
    const result = await format("<span>{{ $count }}</span>");
    // Should stay inline: <span>{{ $count }}</span>
    assert.ok(result.includes("<span>{{ $count }}</span>"));
  });
});

// ---------------------------------------------------------------------------
// HTML elements
// ---------------------------------------------------------------------------
describe("html elements", () => {
  it("handles void elements", async () => {
    const result = await format('<img src="photo.jpg" alt="Photo">');
    assert.ok(result.includes("<img"));
    assert.ok(!result.includes("</img>"));
  });

  it("handles self-closing elements", async () => {
    const result = await format("<div />");
    assert.ok(result.includes("<div"));
  });

  it("keeps inline content on one line", async () => {
    const result = await format("<p>Hello world</p>");
    assert.ok(result.includes("<p>Hello world</p>"));
  });

  it("formats block-level children", async () => {
    const result = await format(
      "<div><p>First</p><p>Second</p></div>",
    );
    const lines = result.trim().split("\n");
    assert.ok(lines.length > 1);
  });

  it("handles nested elements", async () => {
    const result = await format(
      "<div><section><article><p>Deep</p></article></section></div>",
    );
    const pLine = result.split("\n").find((l) => l.includes("<p>"));
    assert.ok(pLine);
    // Should be indented 3 levels
    const indent = pLine.search(/\S/);
    assert.ok(indent >= 12); // 3 * 4 spaces
  });
});

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------
describe("components", () => {
  it("formats basic component", async () => {
    const result = await format(
      '<x-alert type="error"><p>Oops</p></x-alert>',
    );
    assert.ok(result.includes("<x-alert"));
    assert.ok(result.includes("</x-alert>"));
  });

  it("formats self-closing component", async () => {
    const result = await format('<x-icon name="check" />');
    assert.ok(result.includes("<x-icon"));
  });

  it("formats component with slots", async () => {
    const result = await format(
      '<x-card><x-slot:header><h2>Title</h2></x-slot><p>Body</p></x-card>',
    );
    assert.ok(result.includes("<x-card>"));
    assert.ok(result.includes("<x-slot:header>"));
    assert.ok(result.includes("</x-slot>"));
    assert.ok(result.includes("</x-card>"));
  });

  it("formats namespaced component", async () => {
    const result = await format(
      '<x-ui.button type="submit">Save</x-ui.button>',
    );
    assert.ok(result.includes("<x-ui.button"));
    assert.ok(result.includes("</x-ui.button>"));
  });
});

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------
describe("comments", () => {
  it("formats blade comments", async () => {
    const result = await format("{{-- This is a comment --}}");
    assert.ok(result.includes("{{-- This is a comment --}}"));
  });

  it("formats html comments", async () => {
    const result = await format("<!-- HTML comment -->");
    assert.ok(result.includes("<!-- HTML comment -->"));
  });
});

// ---------------------------------------------------------------------------
// Blade-specific options
// ---------------------------------------------------------------------------
describe("bladeQuoteStyle", () => {
  it("preserves quotes by default", async () => {
    const result = await format("<div class=\"foo\"></div>");
    assert.ok(result.includes('"foo"'));
  });

  it("converts to single quotes", async () => {
    const result = await format("<div class=\"foo\"></div>", {
      bladeQuoteStyle: "single",
    });
    assert.ok(result.includes("'foo'"));
  });

  it("converts to double quotes", async () => {
    const result = await format("<div class='foo'></div>", {
      bladeQuoteStyle: "double",
    });
    assert.ok(result.includes('"foo"'));
  });
});

describe("bladeDirectiveSpacing", () => {
  it("adds blank line between blocks by default", async () => {
    const result = await format(
      "@if($a) <p>A</p> @endif @if($b) <p>B</p> @endif",
    );
    // Should have a blank line between @endif and @if
    assert.ok(result.includes("@endif\n\n"));
  });

  it("no spacing with 'none'", async () => {
    const result = await format(
      "@if($a) <p>A</p> @endif @if($b) <p>B</p> @endif",
      { bladeDirectiveSpacing: "none" },
    );
    assert.ok(!result.includes("@endif\n\n@if"));
  });
});

describe("bladeWrapAttributes", () => {
  it("auto wraps based on printWidth", async () => {
    const short = '<div class="a" id="b"></div>';
    const result = await format(short, { printWidth: 200 });
    // Short enough to stay inline
    const lines = result.trim().split("\n");
    assert.equal(lines.length, 1);
  });

  it("always wraps with multiple attributes", async () => {
    const result = await format('<div class="a" id="b"></div>', {
      bladeWrapAttributes: "always",
    });
    const lines = result.trim().split("\n");
    assert.ok(lines.length > 1);
  });

  it("never wraps even with many attributes", async () => {
    const result = await format(
      '<div class="a" id="b" data-x="1" data-y="2" data-z="3"></div>',
      { bladeWrapAttributes: "never", printWidth: 20 },
    );
    // All on one line
    assert.ok(result.includes('class="a" id="b"'));
  });
});

describe("bladeAttributeSort", () => {
  it("preserves order with 'none'", async () => {
    const result = await format(
      '<div id="b" class="a" type="text"></div>',
      { bladeAttributeSort: "none" },
    );
    const idPos = result.indexOf("id=");
    const classPos = result.indexOf("class=");
    assert.ok(idPos < classPos);
  });

  it("sorts alphabetically", async () => {
    const result = await format(
      '<div type="text" class="a" id="b"></div>',
      { bladeAttributeSort: "alphabetical" },
    );
    const classPos = result.indexOf("class=");
    const idPos = result.indexOf("id=");
    const typePos = result.indexOf("type=");
    assert.ok(classPos < idPos);
    assert.ok(idPos < typePos);
  });

  it("sorts by type (HTML > data > Alpine > Livewire)", async () => {
    const result = await format(
      '<input wire:model="email" x-on:blur="validate" data-testid="email" type="email" class="form-input">',
      { bladeAttributeSort: "by_type", bladeWrapAttributes: "always" },
    );
    const classPos = result.indexOf("class=");
    const dataPos = result.indexOf("data-testid=");
    const alpinePos = result.indexOf("x-on:");
    const wirePos = result.indexOf("wire:");
    assert.ok(classPos < dataPos, "HTML attrs before data-*");
    assert.ok(dataPos < alpinePos, "data-* before Alpine");
    assert.ok(alpinePos < wirePos, "Alpine before Livewire");
  });
});

describe("bladeClosingBracketStyle", () => {
  it("same_line keeps bracket with last attribute", async () => {
    const result = await format(
      '<div class="container" id="main" data-x="1" data-y="2" data-z="3"></div>',
      { bladeWrapAttributes: "always", bladeClosingBracketStyle: "same_line" },
    );
    // Last attribute line should end with >
    const lines = result.trim().split("\n");
    const lastAttrLine = lines.find((l) => l.includes("data-z="));
    assert.ok(lastAttrLine?.trimEnd().endsWith(">"));
  });

  it("new_line puts bracket on its own line", async () => {
    const result = await format(
      '<div class="container" id="main" data-x="1" data-y="2" data-z="3"></div>',
      { bladeWrapAttributes: "always", bladeClosingBracketStyle: "new_line" },
    );
    const lines = result.trim().split("\n");
    // Last attribute should NOT end with >
    const lastAttrLine = lines.find((l) => l.includes("data-z="));
    assert.ok(lastAttrLine);
    assert.ok(!lastAttrLine.trimEnd().endsWith(">"), "Last attr should not have bracket");
    // A separate line should contain just the closing bracket
    const bracketLine = lines.find((l) => /^>\s*<\/div>/.test(l.trim()));
    assert.ok(bracketLine, "Closing bracket should be on its own line");
  });
});

describe("bladeSelfClosingStyle", () => {
  it("preserves original by default", async () => {
    const selfClosing = await format("<div />");
    assert.ok(selfClosing.includes("/>"));

    const explicit = await format("<div></div>");
    assert.ok(explicit.includes("</div>"));
  });

  it("converts to self-closing with 'always'", async () => {
    const result = await format("<div></div>", {
      bladeSelfClosingStyle: "always",
    });
    assert.ok(result.includes("/>"));
  });

  it("converts to explicit close with 'never'", async () => {
    const result = await format("<div />", {
      bladeSelfClosingStyle: "never",
    });
    assert.ok(result.includes("</div>"));
  });
});

describe("bladeSlotFormatting", () => {
  it("compact for simple slots", async () => {
    const result = await format(
      "<x-card><x-slot:header><h2>Title</h2></x-slot><p>Body</p></x-card>",
      { bladeSlotFormatting: "compact" },
    );
    // Compact: no extra blank lines around slot content
    assert.ok(!result.includes("<x-slot:header>\n\n"));
  });
});

// ---------------------------------------------------------------------------
// Error handling
// ---------------------------------------------------------------------------
describe("error handling", () => {
  it("throws on unclosed directive", async () => {
    await assert.rejects(
      () => format("@if($user) <p>Hello</p>"),
      (err) => {
        assert.ok(err.message.includes("blade-formatter:"));
        return true;
      },
    );
  });

  it("error message is descriptive", async () => {
    await assert.rejects(
      () => format("@if($user) <p>Hello</p>"),
      (err) => {
        assert.ok(err.message.length > 20);
        return true;
      },
    );
  });
});

// ---------------------------------------------------------------------------
// Real-world patterns
// ---------------------------------------------------------------------------
describe("real-world patterns", () => {
  it("formats a login form", async () => {
    const input = `<form method="POST" action="/login">
@csrf
<div><label for="email">Email</label><input type="email" id="email" name="email" required></div>
<div><label for="password">Password</label><input type="password" id="password" name="password" required></div>
<button type="submit">Login</button>
</form>`;
    const result = await format(input);
    const second = await format(result);
    assert.equal(result, second);
    assert.ok(result.includes("@csrf"));
    assert.ok(result.includes('<form method="POST"'));
  });

  it("formats a navigation with auth guards", async () => {
    const input = `<nav>
<ul>
@auth
<li><a href="/dashboard">Dashboard</a></li>
<li><a href="/profile">{{ Auth::user()->name }}</a></li>
@endauth
@guest
<li><a href="/login">Login</a></li>
<li><a href="/register">Register</a></li>
@endguest
</ul>
</nav>`;
    const result = await format(input);
    const second = await format(result);
    assert.equal(result, second);
  });

  it("formats a component-heavy layout", async () => {
    const input = `<x-app-layout>
<x-slot:header><h2>Dashboard</h2></x-slot>
<div>
<x-card>
<x-slot:header><h3>Stats</h3></x-slot>
<p>{{ $stats->total }}</p>
</x-card>
</div>
</x-app-layout>`;
    const result = await format(input);
    const second = await format(result);
    assert.equal(result, second);
  });

  it("formats a table with @foreach", async () => {
    const input = `<table>
<thead><tr><th>Name</th><th>Email</th></tr></thead>
<tbody>
@foreach($users as $user)
<tr><td>{{ $user->name }}</td><td>{{ $user->email }}</td></tr>
@endforeach
</tbody>
</table>`;
    const result = await format(input);
    const second = await format(result);
    assert.equal(result, second);
    assert.ok(result.includes("@foreach"));
  });

  it("formats Alpine.js attributes", async () => {
    const input = `<div x-data="{ open: false }">
<button @click="open = !open">Toggle</button>
<div x-show="open" x-transition>
<p>Content</p>
</div>
</div>`;
    const result = await format(input);
    assert.ok(result.includes("x-data="));
    assert.ok(result.includes("x-show="));
  });

  it("formats Livewire attributes", async () => {
    const input = `<div>
<input wire:model="email" type="email">
<button wire:click="submit">Send</button>
</div>`;
    const result = await format(input);
    assert.ok(result.includes("wire:model="));
    assert.ok(result.includes("wire:click="));
  });

  it("handles mixed echo and text inline", async () => {
    const result = await format(
      "<p>Hello, {{ $user->name }}! You have {{ $count }} messages.</p>",
    );
    assert.ok(result.includes("Hello, {{ $user->name }}"));
  });
});

// ---------------------------------------------------------------------------
// Prettier API integration
// ---------------------------------------------------------------------------
describe("prettier API", () => {
  it("check() returns false for unformatted code", async () => {
    const result = await prettier.check(
      "<div>@if($x)   <p>Y</p>   @endif</div>",
      { parser: "blade", plugins: [pluginPath] },
    );
    assert.equal(result, false);
  });

  it("check() returns true for formatted code", async () => {
    const formatted = await format("<div>@if($x) <p>Y</p> @endif</div>");
    const result = await prettier.check(formatted, {
      parser: "blade",
      plugins: [pluginPath],
    });
    assert.equal(result, true);
  });

  it("getFileInfo recognizes .blade.php files", async () => {
    const info = await prettier.getFileInfo("test.blade.php", {
      plugins: [pluginPath],
    });
    assert.equal(info.inferredParser, "blade");
  });

  it("getSupportInfo includes blade options", async () => {
    const support = await prettier.getSupportInfo({
      plugins: [pluginPath],
    });
    const bladeOpts = support.options.filter(
      (o) => o.category === "Blade",
    );
    assert.ok(bladeOpts.length >= 7, "Should have at least 7 blade options");
  });
});
