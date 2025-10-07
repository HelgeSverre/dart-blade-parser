import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Mixed Blade/HTML Integration Tests', () {
    // Quickstart scenario #7
    test('Parse HTML containing Blade directives', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          @if(\$show)
            <p>{{\$message}}</p>
          @endif
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(div.tagName, 'div');
      expect(div.children.whereType<DirectiveNode>(), hasLength(1));

      final ifDirective = div.children.whereType<DirectiveNode>().first;
      expect(ifDirective.name, 'if');
      expect(ifDirective.children.whereType<HtmlElementNode>(), hasLength(1));

      final p = ifDirective.children.whereType<HtmlElementNode>().first;
      expect(p.tagName, 'p');
      expect(p.children.whereType<EchoNode>(), hasLength(1));
    });

    test('Parse Blade directive containing HTML elements', () {
      final parser = BladeParser();
      final result = parser.parse('''
        @if(\$isActive)
          <div class="active">
            <span>Active</span>
          </div>
        @endif
      ''');

      expect(result.isSuccess, isTrue);
      final ifDirective = result.ast!.children.whereType<DirectiveNode>().first;

      expect(ifDirective.name, 'if');
      final div = ifDirective.children.whereType<HtmlElementNode>().first;

      expect(div.tagName, 'div');
      expect(div.attributes['class']!.value, 'active');

      final span = div.children.whereType<HtmlElementNode>().first;
      expect(span.tagName, 'span');
    });

    test('Parse nested Blade directives within HTML', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <ul>
          @foreach(\$items as \$item)
            <li>
              @if(\$item->active)
                <span class="active">{{\$item->name}}</span>
              @else
                <span class="inactive">{{\$item->name}}</span>
              @endif
            </li>
          @endforeach
        </ul>
      ''');

      expect(result.isSuccess, isTrue);
      final ul = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(ul.tagName, 'ul');
      expect(ul.children.whereType<DirectiveNode>(), hasLength(1));

      final foreach = ul.children.whereType<DirectiveNode>().first;
      expect(foreach.name, 'foreach');
    });

    test('Parse HTML with Blade echo statements', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          <h1>{{\$title}}</h1>
          <p>{{\$description}}</p>
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children.whereType<HtmlElementNode>().first;

      final h1 = div.children.whereType<HtmlElementNode>().first;
      expect(h1.tagName, 'h1');
      expect(h1.children.whereType<EchoNode>(), hasLength(1));

      final p = div.children.whereType<HtmlElementNode>().skip(1).first;
      expect(p.tagName, 'p');
      expect(p.children.whereType<EchoNode>(), hasLength(1));
    });

    test('Parse HTML with raw Blade echo', () {
      final parser = BladeParser();
      final result = parser.parse('<div>{!! \$html !!}</div>');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(div.children.whereType<EchoNode>(), hasLength(1));
      final echo = div.children.whereType<EchoNode>().first;
      expect(echo.isRaw, isTrue);
    });

    test('Parse Blade components alongside HTML elements', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          <x-alert type="success">
            <p>Operation successful!</p>
          </x-alert>
          <div class="footer">
            <x-button>OK</x-button>
          </div>
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(div.children.whereType<ComponentNode>(), hasLength(1));
      expect(div.children.whereType<HtmlElementNode>(), hasLength(1));

      final alert = div.children.whereType<ComponentNode>().first;
      expect(alert.name, 'alert');
      expect(alert.children.whereType<HtmlElementNode>(), hasLength(1));
    });

    test('Parse deeply nested Blade and HTML structure', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div class="container">
          @section('content')
            <div class="wrapper">
              @foreach(\$users as \$user)
                <div class="user">
                  <h2>{{\$user->name}}</h2>
                  @if(\$user->isAdmin)
                    <span class="badge">Admin</span>
                  @endif
                </div>
              @endforeach
            </div>
          @endsection
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final outerDiv = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(outerDiv.tagName, 'div');
      expect(outerDiv.attributes['class']!.value, 'container');
      expect(outerDiv.children.whereType<DirectiveNode>(), hasLength(1));
    });

    test('Parse HTML table with Blade directives', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
            </tr>
          </thead>
          <tbody>
            @foreach(\$users as \$user)
              <tr>
                <td>{{\$user->name}}</td>
                <td>{{\$user->email}}</td>
              </tr>
            @endforeach
          </tbody>
        </table>
      ''');

      expect(result.isSuccess, isTrue);
      final table = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(table.tagName, 'table');
      expect(table.children.whereType<HtmlElementNode>(),
          hasLength(2)); // thead, tbody

      final tbody = table.children.whereType<HtmlElementNode>().skip(1).first;
      expect(tbody.tagName, 'tbody');
      expect(tbody.children.whereType<DirectiveNode>(), hasLength(1));
    });

    test('Parse form with Blade CSRF directive and HTML inputs', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <form method="POST" action="/submit">
          @csrf
          <input type="text" name="name" required>
          <button type="submit">Submit</button>
        </form>
      ''');

      expect(result.isSuccess, isTrue);
      final form = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(form.tagName, 'form');
      expect(form.attributes['method']!.value, 'POST');
      expect(form.children.whereType<DirectiveNode>(), hasLength(1));
      expect(form.children.whereType<HtmlElementNode>(),
          hasLength(2)); // input, button

      final csrf = form.children.whereType<DirectiveNode>().first;
      expect(csrf.name, 'csrf');
    });

    test('Parse HTML with Blade comments', () {
      final parser = BladeParser();
      final result = parser.parse('''
        <div>
          {{-- This is a comment --}}
          <p>Visible content</p>
        </div>
      ''');

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children.whereType<HtmlElementNode>().first;

      expect(div.children.whereType<CommentNode>(), hasLength(1));
      expect(div.children.whereType<HtmlElementNode>(), hasLength(1));

      final comment = div.children.whereType<CommentNode>().first;
      expect(comment.isBladeComment, isTrue);
    });
  });
}
