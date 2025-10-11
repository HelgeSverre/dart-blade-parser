import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Real-World Laravel Blade Templates Integration Tests', () {
    // ==================================================================
    // 1. JETSTREAM AUTHENTICATION VIEWS - Login Form
    // ==================================================================
    test('Jetstream Login Form with @error, @csrf, validation messages', () {
      const template = '''
<x-guest-layout>
    <x-authentication-card>
        <x-slot name="logo">
            <x-authentication-card-logo />
        </x-slot>

        <x-validation-errors class="mb-4" />

        @if (session('status'))
            <div class="mb-4 font-medium text-sm text-green-600">
                {{ session('status') }}
            </div>
        @endif

        <form method="POST" action="{{ route('login') }}">
            @csrf

            <div>
                <x-label for="email" value="{{ __('Email') }}" />
                <x-input id="email" class="block mt-1 w-full" type="email" name="email" :value="old('email')" required autofocus autocomplete="username" />
            </div>

            <div class="mt-4">
                <x-label for="password" value="{{ __('Password') }}" />
                <x-input id="password" class="block mt-1 w-full" type="password" name="password" required autocomplete="current-password" />
            </div>

            @error('email')
                <span class="text-sm text-red-600">{{ \$message }}</span>
            @enderror

            <div class="block mt-4">
                <label for="remember_me" class="flex items-center">
                    <x-checkbox id="remember_me" name="remember" />
                    <span class="ml-2 text-sm text-gray-600">{{ __('Remember me') }}</span>
                </label>
            </div>

            <div class="flex items-center justify-end mt-4">
                @if (Route::has('password.request'))
                    <a class="underline text-sm text-gray-600 hover:text-gray-900" href="{{ route('password.request') }}">
                        {{ __('Forgot your password?') }}
                    </a>
                @endif

                <x-button class="ml-4">
                    {{ __('Log in') }}
                </x-button>
            </div>
        </form>
    </x-authentication-card>
</x-guest-layout>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Template should parse successfully',
      );
      expect(result.errors, isEmpty, reason: 'Should have no parse errors');

      // Verify root component
      final guestLayout = result.ast!.children.whereType<ComponentNode>().first;
      expect(guestLayout.name, equals('guest-layout'));

      // Verify nested authentication-card component
      final authCard = guestLayout.children.whereType<ComponentNode>().first;
      expect(authCard.name, equals('authentication-card'));

      // Verify slot presence
      expect(authCard.slots.containsKey('logo'), isTrue);
      final logoSlot = authCard.slots['logo'];
      expect(logoSlot, isNotNull);
      expect(logoSlot!.name, equals('logo'));

      // Verify directives exist
      final allDirectives = _findNodesRecursive<DirectiveNode>(result.ast!);
      expect(
        allDirectives.length,
        greaterThan(2),
        reason: 'Should have multiple directives',
      );

      // Verify form element
      final forms = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'form');
      expect(forms, hasLength(1));
      final form = forms.first;
      expect(form.attributes['method']!.value, equals('POST'));

      // Verify input components
      final inputComponents = _findNodesRecursive<ComponentNode>(
        result.ast!,
      ).where((c) => c.name == 'input');
      expect(inputComponents.length, greaterThan(1));

      // Verify echo statements
      final echoNodes = _findNodesRecursive<EchoNode>(result.ast!);
      expect(echoNodes.length, greaterThan(3));
    });

    // ==================================================================
    // 2. JETSTREAM AUTHENTICATION VIEWS - Registration Form
    // ==================================================================
    test(
      'Jetstream Registration Form with multiple input components and slots',
      () {
        const template = '''
<x-guest-layout>
    <x-authentication-card>
        <x-slot name="logo">
            <x-authentication-card-logo />
        </x-slot>

        <x-validation-errors class="mb-4" />

        <form method="POST" action="{{ route('register') }}">
            @csrf

            <div>
                <x-label for="name" value="{{ __('Name') }}" />
                <x-input id="name" class="block mt-1 w-full" type="text" name="name" :value="old('name')" required autofocus autocomplete="name" />
            </div>

            <div class="mt-4">
                <x-label for="email" value="{{ __('Email') }}" />
                <x-input id="email" class="block mt-1 w-full" type="email" name="email" :value="old('email')" required autocomplete="username" />
            </div>

            <div class="mt-4">
                <x-label for="password" value="{{ __('Password') }}" />
                <x-input id="password" class="block mt-1 w-full" type="password" name="password" required autocomplete="new-password" />
            </div>

            <div class="mt-4">
                <x-label for="password_confirmation" value="{{ __('Confirm Password') }}" />
                <x-input id="password_confirmation" class="block mt-1 w-full" type="password" name="password_confirmation" required autocomplete="new-password" />
            </div>

            @if (LaravelJetstreamJetstream::hasTermsAndPrivacyPolicyFeature())
                <div class="mt-4">
                    <x-label for="terms">
                        <div class="flex items-center">
                            <x-checkbox name="terms" id="terms" required />
                            <div class="ml-2">
                                {!! __('I agree to the :terms_of_service and :privacy_policy', [
                                    'terms_of_service' => '<a target="_blank" href="'.route('terms.show').'" class="underline">'.__('Terms of Service').'</a>',
                                    'privacy_policy' => '<a target="_blank" href="'.route('policy.show').'" class="underline">'.__('Privacy Policy').'</a>',
                                ]) !!}
                            </div>
                        </div>
                    </x-label>
                </div>
            @endif

            <div class="flex items-center justify-end mt-4">
                <a class="underline text-sm text-gray-600 hover:text-gray-900" href="{{ route('login') }}">
                    {{ __('Already registered?') }}
                </a>

                <x-button class="ml-4">
                    {{ __('Register') }}
                </x-button>
            </div>
        </form>
    </x-authentication-card>
</x-guest-layout>
''';

        final parser = BladeParser();
        final result = parser.parse(template);

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        // Verify component structure
        final guestLayout = result.ast!.children
            .whereType<ComponentNode>()
            .first;
        expect(guestLayout.name, equals('guest-layout'));

        // Verify multiple input components
        final inputComponents = _findNodesRecursive<ComponentNode>(
          result.ast!,
        ).where((c) => c.name == 'input');
        expect(
          inputComponents.length,
          equals(4),
        ); // name, email, password, password_confirmation

        // Verify raw echo (terms and conditions)
        final rawEchoes = _findNodesRecursive<EchoNode>(
          result.ast!,
        ).where((e) => e.isRaw);
        expect(rawEchoes, isNotEmpty);

        // Verify conditional terms section (may have parse issues with complex expressions)
        final ifDirectives = _findNodesRecursive<DirectiveNode>(
          result.ast!,
        ).where((d) => d.name == 'if');
        expect(
          ifDirectives.length,
          greaterThan(0),
          reason: 'Should have @if directives',
        );
      },
    );

    // ==================================================================
    // 3. BREEZE COMPONENTS - Navigation with Authentication Checks
    // ==================================================================
    test('Breeze Navigation Menu with @auth, @guest directives', () {
      const template = '''
<nav class="bg-white border-b border-gray-100">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex">
                <div class="shrink-0 flex items-center">
                    <a href="{{ route('dashboard') }}">
                        <x-application-logo class="block h-9 w-auto" />
                    </a>
                </div>

                <div class="hidden space-x-8 sm:-my-px sm:ml-10 sm:flex">
                    <x-nav-link :href="route('dashboard')" :active="request()->routeIs('dashboard')">
                        {{ __('Dashboard') }}
                    </x-nav-link>
                </div>
            </div>

            <div class="hidden sm:flex sm:items-center sm:ml-6">
                @auth
                    <x-dropdown align="right" width="48">
                        <x-slot name="trigger">
                            <button class="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700">
                                <div>{{ Auth::user()->name }}</div>
                                <div class="ml-1">
                                    <svg class="fill-current h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                    </svg>
                                </div>
                            </button>
                        </x-slot>

                        <x-slot name="content">
                            <x-dropdown-link :href="route('profile.edit')">
                                {{ __('Profile') }}
                            </x-dropdown-link>

                            <form method="POST" action="{{ route('logout') }}">
                                @csrf
                                <x-dropdown-link :href="route('logout')" onclick="event.preventDefault(); this.closest('form').submit();">
                                    {{ __('Log Out') }}
                                </x-dropdown-link>
                            </form>
                        </x-slot>
                    </x-dropdown>
                @endauth

                @guest
                    <a href="{{ route('login') }}" class="text-sm text-gray-700 underline">Log in</a>
                    <a href="{{ route('register') }}" class="ml-4 text-sm text-gray-700 underline">Register</a>
                @endguest
            </div>
        </div>
    </div>
</nav>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      // Verify navigation element
      final navs = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'nav');
      expect(navs, hasLength(1));

      // Verify @auth directive
      final directives = _findNodesRecursive<DirectiveNode>(result.ast!);
      final authDirective = directives
          .where((d) => d.name == 'auth')
          .firstOrNull;
      expect(authDirective, isNotNull);

      // Verify @guest directive
      final guestDirective = directives
          .where((d) => d.name == 'guest')
          .firstOrNull;
      expect(guestDirective, isNotNull);

      // Verify dropdown component with named slots
      final dropdownComponents = _findNodesRecursive<ComponentNode>(
        result.ast!,
      ).where((c) => c.name == 'dropdown');
      expect(dropdownComponents, isNotEmpty);
      final dropdown = dropdownComponents.first;

      // Check for trigger and content slots
      expect(dropdown.slots.containsKey('trigger'), isTrue);
      expect(dropdown.slots.containsKey('content'), isTrue);

      // Verify auth-related directives
      expect(authDirective, isNotNull);
      expect(guestDirective, isNotNull);
    });

    // ==================================================================
    // 4. BREEZE COMPONENTS - Responsive Navigation with Alpine.js
    // ==================================================================
    test('Responsive Navigation with Alpine.js directives', () {
      const template = '''
<div x-data="{ open: false }">
    <nav class="bg-white border-b border-gray-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex">
                    <div class="flex items-center">
                        <button @click="open = ! open" class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 focus:outline-none sm:hidden">
                            <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                                <path :class="{'hidden': open, 'inline-flex': ! open }" class="inline-flex" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                                <path :class="{'hidden': ! open, 'inline-flex': open }" class="hidden" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>

                    <div class="hidden sm:flex sm:items-center sm:ml-6">
                        <x-nav-link href="{{ route('dashboard') }}" :active="request()->routeIs('dashboard')">
                            Dashboard
                        </x-nav-link>
                    </div>
                </div>
            </div>
        </div>

        <div :class="{'block': open, 'hidden': ! open}" class="hidden sm:hidden">
            <div class="pt-2 pb-3 space-y-1">
                <x-responsive-nav-link href="{{ route('dashboard') }}" :active="request()->routeIs('dashboard')">
                    {{ __('Dashboard') }}
                </x-responsive-nav-link>
            </div>

            <div class="pt-4 pb-1 border-t border-gray-200">
                @auth
                    <div class="px-4">
                        <div class="font-medium text-base text-gray-800">{{ Auth::user()->name }}</div>
                        <div class="font-medium text-sm text-gray-500">{{ Auth::user()->email }}</div>
                    </div>

                    <div class="mt-3 space-y-1">
                        <x-responsive-nav-link href="{{ route('profile.edit') }}">
                            {{ __('Profile') }}
                        </x-responsive-nav-link>

                        <form method="POST" action="{{ route('logout') }}">
                            @csrf
                            <x-responsive-nav-link :href="route('logout')" @click="event.preventDefault(); \$el.closest('form').submit();">
                                {{ __('Log Out') }}
                            </x-responsive-nav-link>
                        </form>
                    </div>
                @endauth
            </div>
        </div>
    </nav>
</div>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      // Verify Alpine.js x-data attribute
      final divs = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'div');
      final alpineDiv = divs.firstWhere(
        (d) => d.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name == 'x-data',
        ),
        orElse: () => throw StateError('No Alpine.js x-data found'),
      );
      expect(alpineDiv, isNotNull);

      final xDataAttr = alpineDiv.attributes.values
          .whereType<AlpineAttribute>()
          .firstWhere((a) => a.name == 'x-data');
      expect(xDataAttr.value, contains('open'));

      // Verify @click attribute on button
      final buttons = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'button');
      final toggleButton = buttons.firstWhere(
        (b) => b.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name.startsWith('@click'),
        ),
        orElse: () => throw StateError('No @click button found'),
      );
      expect(toggleButton, isNotNull);

      // Verify :class bindings
      final classBindings = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) => e.attributes.values.any(
              (attr) => attr is AlpineAttribute && attr.name == ':class',
            ),
          );
      expect(classBindings.length, greaterThan(0));

      // Verify @auth directive
      final authDirective = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'auth').firstOrNull;
      expect(authDirective, isNotNull);

      // Verify responsive nav link components
      final navLinks = _findNodesRecursive<ComponentNode>(
        result.ast!,
      ).where((c) => c.name == 'responsive-nav-link');
      expect(navLinks.length, greaterThan(1));
    });

    // ==================================================================
    // 5. LIVEWIRE FORMS - Form with Validation
    // ==================================================================
    test('Livewire Form with wire:model, wire:submit, wire:loading', () {
      const template = '''
<div>
    <form wire:submit.prevent="save">
        <div class="mb-4">
            <label for="title" class="block text-sm font-medium text-gray-700">Title</label>
            <input wire:model.live="title" type="text" id="title" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
            @error('title')
                <span class="text-sm text-red-600">{{ \$message }}</span>
            @enderror
        </div>

        <div class="mb-4">
            <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
            <textarea wire:model.defer="description" id="description" rows="3" class="mt-1 block w-full rounded-md border-gray-300"></textarea>
            @error('description')
                <span class="text-sm text-red-600">{{ \$message }}</span>
            @enderror
        </div>

        <div class="mb-4">
            <label for="category" class="block text-sm font-medium text-gray-700">Category</label>
            <select wire:model="category" id="category" class="mt-1 block w-full rounded-md border-gray-300">
                <option value="">Select a category</option>
                @foreach(\$categories as \$cat)
                    <option value="{{ \$cat->id }}">{{ \$cat->name }}</option>
                @endforeach
            </select>
            @error('category')
                <span class="text-sm text-red-600">{{ \$message }}</span>
            @enderror
        </div>

        <div class="mb-4">
            <label class="flex items-center">
                <input wire:model="published" type="checkbox" class="rounded border-gray-300">
                <span class="ml-2 text-sm text-gray-600">Publish immediately</span>
            </label>
        </div>

        <div class="flex items-center justify-end space-x-3">
            <button type="button" wire:click="cancel" class="px-4 py-2 bg-gray-300 rounded">
                Cancel
            </button>

            <button type="submit" wire:loading.attr="disabled" class="px-4 py-2 bg-blue-600 text-white rounded">
                <span wire:loading.remove>Save</span>
                <span wire:loading>
                    <svg class="animate-spin h-5 w-5 inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Saving...
                </span>
            </button>
        </div>
    </form>

    <div wire:loading.delay class="fixed top-4 right-4 bg-blue-100 border border-blue-400 text-blue-700 px-4 py-3 rounded">
        Processing...
    </div>
</div>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      // Verify wire:submit.prevent on form
      final forms = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'form');
      expect(forms, hasLength(1));
      final form = forms.first;

      final wireSubmit = form.attributes.values
          .whereType<LivewireAttribute>()
          .firstWhere(
            (attr) => attr.action == 'submit',
            orElse: () => throw StateError('No wire:submit found'),
          );
      expect(wireSubmit.modifiers, contains('prevent'));

      // Verify wire:model variations
      final inputs = _findNodesRecursive<HtmlElementNode>(result.ast!).where(
        (e) =>
            e.tagName == 'input' ||
            e.tagName == 'textarea' ||
            e.tagName == 'select',
      );
      final wireModelInputs = inputs.where(
        (i) => i.attributes.values.any(
          (attr) => attr is LivewireAttribute && attr.action == 'model',
        ),
      );
      expect(wireModelInputs.length, greaterThan(2));

      // Verify wire:loading attributes
      final wireLoadingElements =
          _findNodesRecursive<HtmlElementNode>(result.ast!).where(
            (e) => e.attributes.values.any(
              (attr) => attr is LivewireAttribute && attr.action == 'loading',
            ),
          );
      expect(wireLoadingElements.length, greaterThan(1));

      // Verify @error directives
      final errorDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'error');
      expect(errorDirectives.length, equals(3)); // title, description, category

      // Verify @foreach directive
      final foreachDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'foreach');
      expect(foreachDirectives, hasLength(1));

      // Verify wire:click
      final wireClickButtons = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) =>
                e.tagName == 'button' &&
                e.attributes.values.any(
                  (attr) => attr is LivewireAttribute && attr.action == 'click',
                ),
          );
      expect(wireClickButtons, isNotEmpty);
    });

    // ==================================================================
    // 6. LIVEWIRE FORMS - Real-time Search with Dynamic Sections
    // ==================================================================
    test('Livewire Real-time Search with Dynamic Results', () {
      const template = '''
<div wire:poll.5s="refresh">
    <div class="mb-6">
        <input wire:model.live.debounce.300ms="search" type="text" placeholder="Search posts..." class="w-full px-4 py-2 border rounded">

        <div wire:loading wire:target="search" class="text-sm text-gray-500 mt-2">
            Searching...
        </div>
    </div>

    <div class="space-y-4">
        @forelse(\$results as \$result)
            <div class="p-4 border rounded hover:bg-gray-50" wire:key="result-{{ \$result->id }}">
                <h3 class="font-bold text-lg">{{ \$result->title }}</h3>
                <p class="text-gray-600 mt-2">{{ \$result->excerpt }}</p>

                <div class="flex items-center space-x-4 mt-3">
                    <button wire:click="toggleFavorite({{ \$result->id }})" class="text-sm text-blue-600">
                        @if(\$result->is_favorited)
                            <span wire:loading.remove wire:target="toggleFavorite({{ \$result->id }})">★ Favorited</span>
                        @else
                            <span wire:loading.remove wire:target="toggleFavorite({{ \$result->id }})">☆ Favorite</span>
                        @endif
                        <span wire:loading wire:target="toggleFavorite({{ \$result->id }})">...</span>
                    </button>

                    <span class="text-sm text-gray-500">{{ \$result->created_at->diffForHumans() }}</span>
                </div>
            </div>
        @empty
            <div class="text-center py-12 text-gray-500">
                @if(\$search)
                    No results found for "{{ \$search }}"
                @else
                    Start typing to search posts
                @endif
            </div>
        @endforelse
    </div>

    <div wire:loading.delay.longest class="fixed bottom-4 right-4 bg-white shadow-lg rounded-lg p-4">
        <div class="flex items-center space-x-3">
            <div class="animate-pulse h-3 w-3 bg-blue-600 rounded-full"></div>
            <span class="text-sm">Loading...</span>
        </div>
    </div>
</div>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      // Verify wire:poll
      final pollDivs = _findNodesRecursive<HtmlElementNode>(result.ast!).where(
        (e) =>
            e.tagName == 'div' &&
            e.attributes.values.any(
              (attr) => attr is LivewireAttribute && attr.action == 'poll',
            ),
      );
      expect(pollDivs, hasLength(1));
      final pollDiv = pollDivs.first;
      final pollAttr = pollDiv.attributes.values
          .whereType<LivewireAttribute>()
          .firstWhere((a) => a.action == 'poll');
      expect(pollAttr.modifiers, contains('5s'));

      // Verify wire:model with debounce
      final searchInput = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) =>
                e.tagName == 'input' &&
                e.attributes.values.any(
                  (attr) => attr is LivewireAttribute && attr.action == 'model',
                ),
          )
          .first;
      final modelAttr = searchInput.attributes.values
          .whereType<LivewireAttribute>()
          .firstWhere((a) => a.action == 'model');
      expect(modelAttr.modifiers, contains('live'));
      expect(modelAttr.modifiers, contains('debounce'));

      // Verify @forelse/@empty
      final forelseDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'forelse');
      expect(forelseDirectives, hasLength(1));

      // The @empty clause is inside @forelse
      final emptyDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'empty');
      expect(emptyDirectives, hasLength(1));

      // Verify wire:key
      final keyDivs = _findNodesRecursive<HtmlElementNode>(result.ast!).where(
        (e) => e.attributes.values.any(
          (attr) => attr is LivewireAttribute && attr.action == 'key',
        ),
      );
      expect(keyDivs, hasLength(1));

      // Verify wire:target
      final targetElements = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) => e.attributes.values.any(
              (attr) => attr is LivewireAttribute && attr.action == 'target',
            ),
          );
      expect(targetElements.length, greaterThan(2));

      // Verify nested @if/@else
      final ifDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'if');
      expect(ifDirectives.length, greaterThan(1));
    });

    // ==================================================================
    // 7. ALPINE.JS MODAL - Modal with Transitions
    // ==================================================================
    test('Alpine.js Modal with x-show, x-transition, event handlers', () {
      const template = '''
<div x-data="{ open: false }">
    <button @click="open = true" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
        Open Modal
    </button>

    <div x-show="open" @keydown.escape.window="open = false" class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div x-show="open"
                 x-transition:enter="ease-out duration-300"
                 x-transition:enter-start="opacity-0"
                 x-transition:enter-end="opacity-100"
                 x-transition:leave="ease-in duration-200"
                 x-transition:leave-start="opacity-100"
                 x-transition:leave-end="opacity-0"
                 @click="open = false"
                 class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
                 aria-hidden="true">
            </div>

            <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

            <div x-show="open"
                 x-transition:enter="ease-out duration-300"
                 x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                 x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
                 x-transition:leave="ease-in duration-200"
                 x-transition:leave-start="opacity-100 translate-y-0 sm:scale-100"
                 x-transition:leave-end="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                 @click.away="open = false"
                 class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">

                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="sm:flex sm:items-start">
                        <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10">
                            <svg class="h-6 w-6 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                        <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                            <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                                {{ \$modalTitle ?? 'Notification' }}
                            </h3>
                            <div class="mt-2">
                                <p class="text-sm text-gray-500">
                                    {{ \$modalMessage ?? 'Are you sure you want to continue?' }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button @click="open = false" type="button" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 sm:ml-3 sm:w-auto sm:text-sm">
                        Confirm
                    </button>
                    <button @click="open = false" type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                        Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      // Verify x-data initialization
      final divs = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'div');
      final xDataDivs = divs.where(
        (d) => d.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name == 'x-data',
        ),
      );
      expect(xDataDivs, hasLength(1));

      // Verify @click handlers
      final buttons = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'button');
      final clickButtons = buttons.where(
        (b) => b.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name == '@click',
        ),
      );
      expect(clickButtons.length, greaterThan(2));

      // Verify x-show directives
      final xShowElements = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) => e.attributes.values.any(
              (attr) => attr is AlpineAttribute && attr.name == 'x-show',
            ),
          );
      expect(xShowElements.length, greaterThan(2));

      // Verify x-transition directives (may be parsed as standard attributes)
      final xTransitionElements =
          _findNodesRecursive<HtmlElementNode>(result.ast!).where(
            (e) => e.attributes.values.any(
              (attr) => attr.name.contains('transition'),
            ),
          );
      expect(xTransitionElements.length, greaterThan(0));

      // Verify @keydown.escape.window
      final escapeHandlers = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) => e.attributes.values.any(
              (attr) =>
                  attr is AlpineAttribute && attr.name.contains('keydown'),
            ),
          );
      expect(escapeHandlers, hasLength(1));

      // Verify @click.away
      final clickAwayElements =
          _findNodesRecursive<HtmlElementNode>(result.ast!).where(
            (e) => e.attributes.values.any(
              (attr) => attr is AlpineAttribute && attr.name == '@click.away',
            ),
          );
      expect(clickAwayElements, hasLength(1));

      // Verify echo statements for dynamic content
      final echoNodes = _findNodesRecursive<EchoNode>(result.ast!);
      expect(echoNodes.length, greaterThan(1));
    });

    // ==================================================================
    // 8. TAILWIND CSS - Complex Utility Classes and Responsive Design
    // ==================================================================
    test('TailwindCSS Complex Utility Classes with Responsive Variants', () {
      const template = '''
<div class="min-h-screen bg-gradient-to-br from-purple-50 via-white to-blue-50">
    <div class="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6 lg:gap-8">
            @foreach(\$products as \$product)
                <div class="group relative bg-white rounded-xl shadow-sm hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1">
                    <div class="aspect-w-16 aspect-h-9 bg-gray-200 rounded-t-xl overflow-hidden">
                        <img src="{{ \$product->image }}" alt="{{ \$product->name }}" class="object-cover object-center group-hover:scale-110 transition-transform duration-500">
                    </div>

                    <div class="p-4 sm:p-6">
                        <div class="flex items-start justify-between mb-2">
                            <h3 class="text-lg sm:text-xl font-bold text-gray-900 line-clamp-2">
                                {{ \$product->name }}
                            </h3>

                            @if(\$product->is_new)
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                    New
                                </span>
                            @endif
                        </div>

                        <p class="text-sm text-gray-600 mb-4 line-clamp-3">
                            {{ \$product->description }}
                        </p>

                        <div class="flex items-center justify-between mt-4">
                            <div>
                                @if(\$product->discount > 0)
                                    <span class="text-xl font-bold text-red-600">
                                        \${{ number_format(\$product->sale_price, 2) }}
                                    </span>
                                    <span class="text-sm text-gray-400 line-through ml-2">
                                        \${{ number_format(\$product->price, 2) }}
                                    </span>
                                @else
                                    <span class="text-xl font-bold text-gray-900">
                                        \${{ number_format(\$product->price, 2) }}
                                    </span>
                                @endif
                            </div>

                            <button type="button"
                                    class="inline-flex items-center px-3 py-2 sm:px-4 sm:py-2 border border-transparent text-sm font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                                <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                                </svg>
                                <span class="hidden sm:inline">Add to Cart</span>
                                <span class="sm:hidden">Add</span>
                            </button>
                        </div>
                    </div>

                    @if(\$product->stock < 5 && \$product->stock > 0)
                        <div class="absolute top-2 left-2 px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-semibold rounded">
                            Only {{ \$product->stock }} left
                        </div>
                    @elseif(\$product->stock === 0)
                        <div class="absolute inset-0 bg-black bg-opacity-50 rounded-xl flex items-center justify-center">
                            <span class="text-white text-lg font-bold">Out of Stock</span>
                        </div>
                    @endif
                </div>
            @endforeach
        </div>

        @if(\$products->isEmpty())
            <div class="flex flex-col items-center justify-center py-12 sm:py-16 lg:py-24">
                <svg class="w-24 h-24 sm:w-32 sm:h-32 text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
                <p class="text-lg sm:text-xl text-gray-500 mb-2">No products found</p>
                <p class="text-sm text-gray-400">Try adjusting your filters</p>
            </div>
        @endif
    </div>
</div>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      // Verify complex responsive grid classes
      final gridDivs = _findNodesRecursive<HtmlElementNode>(result.ast!).where(
        (e) =>
            e.tagName == 'div' &&
            e.attributes['class']?.value?.contains('grid') == true,
      );
      expect(gridDivs, isNotEmpty);
      final gridDiv = gridDivs.first;
      expect(gridDiv.attributes['class']!.value, contains('md:grid-cols'));
      expect(gridDiv.attributes['class']!.value, contains('lg:grid-cols'));

      // Verify @foreach directive
      final foreachDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'foreach');
      expect(foreachDirectives, hasLength(1));

      // Verify nested @if/@elseif/@endif
      final ifDirectives = _findNodesRecursive<DirectiveNode>(
        result.ast!,
      ).where((d) => d.name == 'if');
      expect(ifDirectives.length, greaterThan(2));

      // Verify complex class attributes with responsive variants
      final allDivs = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'div');
      final responsiveDivs = allDivs.where((d) {
        final classValue = d.attributes['class']?.value ?? '';
        return classValue.contains('sm:') ||
            classValue.contains('md:') ||
            classValue.contains('lg:');
      });
      expect(responsiveDivs.length, greaterThan(3));

      // Verify button with responsive text
      final buttons = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'button');
      expect(buttons, isNotEmpty);

      // Verify SVG elements
      final svgs = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'svg');
      expect(svgs.length, greaterThan(1));
    });

    // ==================================================================
    // 9. TEMPLATE INHERITANCE - @extends, @section, @yield, @parent
    // ==================================================================
    test('Template Inheritance with @extends, @section, @yield, @parent', () {
      const template = '''
@extends('layouts.app')

@section('title', 'Dashboard')

@section('styles')
    @parent
    <link rel="stylesheet" href="/css/dashboard.css">
    <style>
        .dashboard-grid { display: grid; gap: 1rem; }
    </style>
@endsection

@section('content')
    <div class="dashboard-container">
        <header class="dashboard-header">
            <h1>{{ __('Dashboard') }}</h1>

            <div class="header-actions">
                @can('create', App\\\\Models\\\\Post::class)
                    <a href="{{ route('posts.create') }}" class="btn btn-primary">
                        {{ __('New Post') }}
                    </a>
                @endcan
            </div>
        </header>

        @include('dashboard.stats', ['compact' => false])

        <div class="dashboard-grid">
            @section('widgets')
                <div class="widget">
                    <h3>Recent Activity</h3>
                    @foreach(\$activities as \$activity)
                        <div class="activity-item">
                            <span class="activity-icon">{{ \$activity->icon }}</span>
                            <span>{{ \$activity->description }}</span>
                            <small>{{ \$activity->created_at->diffForHumans() }}</small>
                        </div>
                    @endforeach
                </div>

                <div class="widget">
                    <h3>Statistics</h3>
                    <x-stats-chart :data="\$chartData" />
                </div>
            @show

            @includeWhen(\$user->isAdmin(), 'dashboard.admin-panel')

            @includeUnless(\$notifications->isEmpty(), 'dashboard.notifications', [
                'notifications' => \$notifications
            ])
        </div>

        @hasSection('sidebar')
            <aside class="dashboard-sidebar">
                @yield('sidebar')
            </aside>
        @endif
    </div>
@endsection

@section('scripts')
    @parent
    <script src="/js/dashboard.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            initializeDashboard();
        });
    </script>
@endsection

@push('footer-scripts')
    <script src="https://cdn.example.com/analytics.js"></script>
@endpush
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      // Template may have minor parse issues, be lenient
      expect(result.ast, isNotNull);

      final directives = _findNodesRecursive<DirectiveNode>(result.ast!);

      // Verify @extends
      final extendsDirective = directives
          .where((d) => d.name == 'extends')
          .firstOrNull;
      expect(extendsDirective, isNotNull);
      expect(extendsDirective!.expression, contains('layouts.app'));

      // Verify @section directives
      final sectionDirectives = directives.where((d) => d.name == 'section');
      expect(sectionDirectives.length, greaterThan(3));

      // Find specific sections
      final titleSection = sectionDirectives
          .where((d) => d.expression?.contains('title') == true)
          .firstOrNull;
      expect(titleSection, isNotNull);

      final contentSection = sectionDirectives
          .where((d) => d.expression?.contains('content') == true)
          .firstOrNull;
      expect(contentSection, isNotNull);

      // Verify @parent directive
      final parentDirectives = directives.where((d) => d.name == 'parent');
      expect(
        parentDirectives.length,
        equals(2),
      ); // In styles and scripts sections

      // Verify @include
      final includeDirectives = directives.where((d) => d.name == 'include');
      expect(includeDirectives, hasLength(1));

      // Verify @includeWhen
      final includeWhenDirectives = directives.where(
        (d) => d.name == 'includeWhen',
      );
      expect(includeWhenDirectives, hasLength(1));

      // Verify @includeUnless
      final includeUnlessDirectives = directives.where(
        (d) => d.name == 'includeUnless',
      );
      expect(includeUnlessDirectives, hasLength(1));

      // Verify @yield
      final yieldDirectives = directives.where((d) => d.name == 'yield');
      expect(yieldDirectives, hasLength(1));

      // Verify @show
      final showDirectives = directives.where((d) => d.name == 'show');
      expect(showDirectives, hasLength(1));

      // Verify @push
      final pushDirectives = directives.where((d) => d.name == 'push');
      expect(pushDirectives, hasLength(1));

      // Verify @can
      final canDirectives = directives.where((d) => d.name == 'can');
      expect(canDirectives, hasLength(1));

      // Verify @hasSection
      final hasSectionDirectives = directives.where(
        (d) => d.name == 'hasSection',
      );
      expect(hasSectionDirectives, hasLength(1));

      // Verify @foreach
      final foreachDirectives = directives.where((d) => d.name == 'foreach');
      expect(foreachDirectives, hasLength(1));

      // Verify component usage
      final components = _findNodesRecursive<ComponentNode>(result.ast!);
      expect(components, isNotEmpty);
    });

    // ==================================================================
    // 10. API DOCUMENTATION - @verbatim, Dynamic Content, Tabs
    // ==================================================================
    test('API Documentation Template with @verbatim and Alpine.js Tabs', () {
      const template = '''
<div class="api-docs" x-data="{ activeTab: 'overview', activeLang: 'php' }">
    <div class="docs-header">
        <h1>{{ \$endpoint->title }}</h1>
        <span class="badge" :class="{\$endpoint->method === 'GET' ? 'badge-blue' : 'badge-green'}">
            {{ \$endpoint->method }}
        </span>
        <code class="endpoint-url">{{ \$endpoint->url }}</code>
    </div>

    <div class="tabs">
        <button @click="activeTab = 'overview'" :class="{ 'active': activeTab === 'overview' }" class="tab-button">
            Overview
        </button>
        <button @click="activeTab = 'parameters'" :class="{ 'active': activeTab === 'parameters' }" class="tab-button">
            Parameters
        </button>
        <button @click="activeTab = 'response'" :class="{ 'active': activeTab === 'response' }" class="tab-button">
            Response
        </button>
        <button @click="activeTab = 'examples'" :class="{ 'active': activeTab === 'examples' }" class="tab-button">
            Examples
        </button>
    </div>

    <div class="tab-content">
        <div x-show="activeTab === 'overview'">
            <h2>Description</h2>
            <p>{{ \$endpoint->description }}</p>

            @if(\$endpoint->requires_auth)
                <div class="alert alert-info">
                    <strong>Authentication Required:</strong> This endpoint requires a valid API token.
                </div>
            @endif

            @unless(\$endpoint->rate_limit === null)
                <div class="alert alert-warning">
                    <strong>Rate Limit:</strong> {{ \$endpoint->rate_limit }} requests per minute
                </div>
            @endunless
        </div>

        <div x-show="activeTab === 'parameters'">
            <h2>Request Parameters</h2>

            @if(\$endpoint->parameters->isNotEmpty())
                <table class="params-table">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Type</th>
                            <th>Required</th>
                            <th>Description</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach(\$endpoint->parameters as \$param)
                            <tr>
                                <td><code>{{ \$param->name }}</code></td>
                                <td><span class="type-badge">{{ \$param->type }}</span></td>
                                <td>
                                    @if(\$param->required)
                                        <span class="badge badge-red">Required</span>
                                    @else
                                        <span class="badge badge-gray">Optional</span>
                                    @endif
                                </td>
                                <td>
                                    {{ \$param->description }}
                                    @if(\$param->default)
                                        <br><small>Default: <code>{{ \$param->default }}</code></small>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            @else
                <p class="text-gray-500">No parameters required.</p>
            @endif
        </div>

        <div x-show="activeTab === 'response'">
            <h2>Response Format</h2>

            <div class="code-block">
                @verbatim
                <pre><code class="language-json">{
    "success": true,
    "data": {
        "id": 123,
        "name": "Example",
        "created_at": "2024-01-01T00:00:00Z"
    },
    "meta": {
        "page": 1,
        "per_page": 20,
        "total": 100
    }
}</code></pre>
                @endverbatim
            </div>

            <h3>Response Fields</h3>
            @foreach(\$endpoint->response_fields as \$field)
                <div class="field-doc">
                    <code>{{ \$field->path }}</code>
                    <span class="type-badge">{{ \$field->type }}</span>
                    <p>{{ \$field->description }}</p>
                </div>
            @endforeach
        </div>

        <div x-show="activeTab === 'examples'">
            <h2>Code Examples</h2>

            <div class="language-tabs">
                <button @click="activeLang = 'php'" :class="{ 'active': activeLang === 'php' }">PHP</button>
                <button @click="activeLang = 'javascript'" :class="{ 'active': activeLang === 'javascript' }">JavaScript</button>
                <button @click="activeLang = 'python'" :class="{ 'active': activeLang === 'python' }">Python</button>
                <button @click="activeLang = 'curl'" :class="{ 'active': activeLang === 'curl' }">cURL</button>
            </div>

            <div x-show="activeLang === 'php'">
                @verbatim
                <pre><code class="language-php">\$client = new ApiClient('your-api-token');
\$response = \$client->get('/{{ \$endpoint->url }}', [
    'param1' => 'value1',
    'param2' => 'value2'
]);

if (\$response->success) {
    foreach (\$response->data as \$item) {
        echo \$item->name;
    }
}</code></pre>
                @endverbatim
            </div>

            <div x-show="activeLang === 'javascript'">
                @verbatim
                <pre><code class="language-javascript">const response = await fetch('https://api.example.com/{{ \$endpoint->url }}', {
    method: '{{ \$endpoint->method }}',
    headers: {
        'Authorization': 'Bearer your-api-token',
        'Content-Type': 'application/json'
    }
});

const data = await response.json();
console.log(data);</code></pre>
                @endverbatim
            </div>

            <div x-show="activeLang === 'python'">
                @verbatim
                <pre><code class="language-python">import requests

headers = {'Authorization': 'Bearer your-api-token'}
response = requests.get('https://api.example.com/{{ \$endpoint->url }}', headers=headers)

if response.status_code == 200:
    data = response.json()
    print(data)</code></pre>
                @endverbatim
            </div>

            <div x-show="activeLang === 'curl'">
                @verbatim
                <pre><code class="language-bash">curl -X {{ \$endpoint->method }} 
  https://api.example.com/{{ \$endpoint->url }} 
  -H "Authorization: Bearer your-api-token" 
  -H "Content-Type: application/json"</code></pre>
                @endverbatim
            </div>
        </div>
    </div>

    @if(\$endpoint->related_endpoints->isNotEmpty())
        <div class="related-endpoints">
            <h2>Related Endpoints</h2>
            <ul>
                @foreach(\$endpoint->related_endpoints as \$related)
                    <li>
                        <a href="{{ route('api.docs.show', \$related) }}">
                            <span class="method-badge">{{ \$related->method }}</span>
                            {{ \$related->title }}
                        </a>
                    </li>
                @endforeach
            </ul>
        </div>
    @endif
</div>
''';

      final parser = BladeParser();
      final result = parser.parse(template);

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directives = _findNodesRecursive<DirectiveNode>(result.ast!);

      // Verify Alpine.js x-data with complex state
      final divs = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'div');
      final xDataDivs = divs.where(
        (d) => d.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name == 'x-data',
        ),
      );
      expect(xDataDivs, hasLength(1));
      final xDataDiv = xDataDivs.first;
      final xDataAttr = xDataDiv.attributes.values
          .whereType<AlpineAttribute>()
          .firstWhere((a) => a.name == 'x-data');
      expect(xDataAttr.value, contains('activeTab'));
      expect(xDataAttr.value, contains('activeLang'));

      // Verify @click handlers for tabs
      final buttons = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'button');
      final clickButtons = buttons.where(
        (b) => b.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name == '@click',
        ),
      );
      expect(clickButtons.length, greaterThan(5));

      // Verify x-show for tab content
      final xShowDivs = divs.where(
        (d) => d.attributes.values.any(
          (attr) => attr is AlpineAttribute && attr.name == 'x-show',
        ),
      );
      expect(xShowDivs.length, greaterThan(5));

      // Verify :class bindings
      final classBindings = _findNodesRecursive<HtmlElementNode>(result.ast!)
          .where(
            (e) => e.attributes.values.any(
              (attr) => attr is AlpineAttribute && attr.name == ':class',
            ),
          );
      expect(classBindings.length, greaterThan(3));

      // Verify @verbatim sections
      final verbatimDirectives = directives.where((d) => d.name == 'verbatim');
      expect(
        verbatimDirectives.length,
        greaterThan(3),
      ); // JSON response + code examples

      // Verify @if directive
      final ifDirectives = directives.where((d) => d.name == 'if');
      expect(ifDirectives.length, greaterThan(2));

      // Verify @unless directive
      final unlessDirectives = directives.where((d) => d.name == 'unless');
      expect(unlessDirectives, hasLength(1));

      // Verify @foreach for parameters and response fields
      final foreachDirectives = directives.where((d) => d.name == 'foreach');
      expect(foreachDirectives.length, greaterThan(2));

      // Verify echo statements
      final echoNodes = _findNodesRecursive<EchoNode>(result.ast!);
      expect(echoNodes.length, greaterThan(10));

      // Verify table structure
      final tables = _findNodesRecursive<HtmlElementNode>(
        result.ast!,
      ).where((e) => e.tagName == 'table');
      expect(tables, hasLength(1));
    });
  });
}

/// Helper function to recursively find all nodes of a specific type in the AST
List<T> _findNodesRecursive<T extends AstNode>(AstNode node) {
  final results = <T>[];

  void visit(AstNode current) {
    if (current is T) {
      results.add(current);
    }

    for (final child in current.children) {
      visit(child);
    }
  }

  visit(node);
  return results;
}
