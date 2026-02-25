# Slot Spacing & Slot Name Syntax Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add slot spacing options (newlines around slots), fix the `<x-slot name="x">` → `<x-slot:x name="x">` bug, and add a slot name syntax config option (colon vs attribute vs preserve).

**Architecture:** Three changes to the formatter: (1) a new `SlotSpacing` config enum controlling blank lines around slots, wired into `_needsSpacingBetween`; (2) a new `SlotNameStyle` config enum controlling how slot names are rendered, with a `useColonSyntax` flag on `SlotNode` to support `preserve`; (3) stripping the `name` attribute in the formatter when outputting colon syntax to fix the duplication bug.

**Tech Stack:** Dart, existing formatter/parser/AST infrastructure.

---

### Task 1: Add anonymized fixture file

**Files:**
- Create: `benchmark/fixtures/livewire/03-dashboard-page.blade.php`
- Create: `tool/playground/assets/examples/16-livewire-dashboard-page.blade.php`
- Modify: `tool/playground/lib/main.dart` (add menu entry)

**Step 1: Create the anonymized benchmark fixture**

Copy the wash-units file as `03-dashboard-page.blade.php`, replacing:
- `glitra` → generic names
- `washunit`/`wash-unit`/`vaskehall` → generic `item`/`resource` names  
- Norwegian text → English placeholder text
- Route names → generic route names
- Business-specific references → generic references

```blade
<x-slot name="scripts">
    <script src="https://maps.googleapis.com/maps/api/js?key={{ config('services.maps.api_key') }}&libraries=places"></script>
</x-slot>

<x-layouts.page>
    <x-slot name="actions">
        <x-layouts.breadcrumb-links
            :links="
                [
                    [
                        'label' => 'Resources',
                        'url' => route('resources.index'),
                    ],
                ]
            "
        />

        <x-layouts.actions>
            <x-slot name="left">
                <x-app.filters :sortings="$this->filters()" />
            </x-slot>

            <x-slot name="right">
                <x-app.search />

                <x-app.action-button
                    href="{{ route('resources.uptime') }}"
                    x-data
                    x-tooltip.raw="Show resource uptime"
                >
                    <x-lucide-history class="size-4" />
                </x-app.action-button>

                <x-app.action-button
                    href="{{ route('resources.log-table') }}"
                    x-data
                    x-tooltip.raw="Show all resource events"
                >
                    <x-lucide-logs class="size-4" />
                </x-app.action-button>

                <x-app.action-button
                    wire:click="toggleMap"
                    x-data
                    x-tooltip.raw="{{ $showMap ? 'Hide map' : 'Show resources on map'  }}"
                >
                    @if ($showMap)
                        <x-lucide-map-pin-off class="size-4" />
                    @else
                        <x-lucide-map-pin class="size-4" />
                    @endif
                </x-app.action-button>

                <x-app.action-button action="createLogEntryAction">
                    Log Event
                </x-app.action-button>

                <x-app.action-button
                    variant="primary"
                    wire:click="refresh"
                    x-data
                    x-tooltip.raw="Last updated: {{ $this->lastUpdatedAt?->diffForHumans() ?: 'unknown' }}"
                >
                    Refresh
                </x-app.action-button>

                @if (\App\Enums\Permission::manageResources->isAllowed() || Auth::user()->isSuperAdmin())
                    <x-app.action-button
                        variant="primary"
                        :href="route('resources.create')"
                        x-data
                        x-tooltip.raw="Add new resource"
                    >
                        <x-lucide-plus class="size-4" />
                    </x-app.action-button>
                @endif
            </x-slot>
        </x-layouts.actions>
    </x-slot>

    @if ($showMap)
        <div class="mb-12">
            <x-app::resource-map
                :resources="$this->resourcesWithLocation"
            />
        </div>
    @endif

    <div
        class="flex flex-col gap-12 duration-200"
        wire:target="refresh"
        wire:loading.class="opacity-50"
    >
        @if ($this->inactiveResources->isNotEmpty())
            <div>
                <div class="mb-4">
                    <h2 class="text-base font-semibold text-gray-700">
                        Inactive Resources
                    </h2>
                    <p class="text-sm text-gray-600">
                        Here you can see an overview of all currently inactive
                        resources.
                    </p>
                </div>

                <div
                    class="grid gap-2 sm:grid-cols-2 md:gap-4 xl:grid-cols-3 2xl:grid-cols-4"
                >
                    @foreach ($this->inactiveResources as $resource)
                        <x-app::resource-card
                            :resource="$resource"
                            :usagePerCycle="$this->usagePerCycleByResource[$resource->id] ?? null"
                        />
                    @endforeach
                </div>
            </div>
        @endif

        @if ($this->activeResources->isNotEmpty())
            <div>
                <div class="mb-4">
                    <h2 class="text-base font-semibold text-gray-700">
                        Active Resources
                    </h2>
                    <p class="text-sm text-gray-600">
                        Here you can see an overview of all active resources.
                    </p>
                </div>

                <div
                    class="grid gap-2 sm:grid-cols-2 md:gap-4 xl:grid-cols-3 2xl:grid-cols-4"
                >
                    @foreach ($this->activeResources as $resource)
                        <x-app::resource-card
                            :resource="$resource"
                            :usagePerCycle="$this->usagePerCycleByResource[$resource->id] ?? null"
                        />
                    @endforeach
                </div>
            </div>
        @endif
    </div>

    <x-filament-actions::modals />
</x-layouts.page>
```

**Step 2: Copy same file as playground example `16-livewire-dashboard-page.blade.php`**

Same content.

**Step 3: Add menu entry in playground**

In `tool/playground/lib/main.dart`, after line 193 (the `15-messy-components-slots` entry), add:

```dart
const PopupMenuItem(
  value: '16-livewire-dashboard-page',
  child: Text('Livewire Dashboard Page'),
),
```

**Step 4: Verify**

Run: `dart analyze`
Expected: No errors

**Step 5: Commit**

```bash
git add benchmark/fixtures/livewire/03-dashboard-page.blade.php tool/playground/assets/examples/16-livewire-dashboard-page.blade.php tool/playground/lib/main.dart
git commit -m "feat: add livewire dashboard page fixture and playground example"
```

---

### Task 2: Fix bug — `<x-slot name="x">` outputs duplicate name

The parser puts the `name` attribute in the `SlotNode.attributes` map even when the name was extracted from it. The formatter then outputs `<x-slot:actions name="actions">`.

**Files:**
- Modify: `lib/src/formatter/formatter_visitor.dart` (~line 962-975)
- Test: `test/formatter/formatter_bugfix_test.dart`

**Step 1: Write the failing test**

Add test in `test/formatter/formatter_bugfix_test.dart`:

```dart
test('does not duplicate name attribute when converting slot syntax', () {
  const input = '<x-card><x-slot name="header">Content</x-slot></x-card>';
  final result = formatter.format(input);
  // Should NOT contain name="header" when using colon syntax
  expect(result, contains('<x-slot:header>'));
  expect(result, isNot(contains('name="header"')));
});
```

**Step 2: Run test to verify it fails**

Run: `dart test test/formatter/formatter_bugfix_test.dart -N "does not duplicate name attribute"`
Expected: FAIL (currently outputs `<x-slot:header name="header">`)

**Step 3: Fix — strip `name` attribute in visitSlot**

In `lib/src/formatter/formatter_visitor.dart`, in `visitSlot`, filter out the `name` attribute when outputting colon syntax:

```dart
// Line ~962, change:
final attributes = node.attributes.values.toList();

// To:
final attributes = node.attributes.entries
    .where((e) => e.key != 'name')
    .map((e) => e.value)
    .toList();
```

**Step 4: Run test to verify it passes**

Run: `dart test test/formatter/formatter_bugfix_test.dart -N "does not duplicate name attribute"`
Expected: PASS

**Step 5: Run full test suite**

Run: `dart test`
Expected: All pass

**Step 6: Commit**

```bash
git add lib/src/formatter/formatter_visitor.dart test/formatter/formatter_bugfix_test.dart
git commit -m "fix: remove duplicate name attribute when formatting x-slot with colon syntax"
```

---

### Task 3: Add `SlotNameStyle` config option

**Files:**
- Modify: `lib/src/ast/node.dart` (add `useColonSyntax` to `SlotNode`)
- Modify: `lib/src/parser/parser.dart` (set `useColonSyntax` flag)
- Modify: `lib/src/formatter/formatter_config.dart` (add `SlotNameStyle` enum + field)
- Modify: `lib/src/formatter/formatter_visitor.dart` (respect the option)
- Test: `test/formatter/formatter_test.dart` or new file

**Step 1: Add `useColonSyntax` field to `SlotNode`**

In `lib/src/ast/node.dart`, add a field to `SlotNode`:

```dart
/// Whether the original source used colon syntax (x-slot:name) vs attribute syntax (x-slot name="...").
final bool useColonSyntax;
```

Add to constructor with default `true`:

```dart
SlotNode({
  required this.startPosition,
  required this.endPosition,
  required this.name,
  this.useColonSyntax = true,
  this.attributes = const {},
  required this.children,
});
```

Add to `toJson()`:
```dart
'useColonSyntax': useColonSyntax,
```

**Step 2: Set `useColonSyntax` in parser**

In `lib/src/parser/parser.dart`, in `_parseSlot` (~line 660-674), pass the flag:

```dart
final isColonSyntax = componentName.startsWith('slot:');
```

Then at the `SlotNode` constructor call (~line 727):

```dart
return SlotNode(
  startPosition: startToken.startPosition,
  endPosition: _previous().endPosition,
  name: slotName,
  useColonSyntax: isColonSyntax,
  attributes: attributes,
  children: children,
);
```

**Step 3: Add `SlotNameStyle` enum**

In `lib/src/formatter/formatter_config.dart`, add after `SlotFormatting` enum:

```dart
/// Controls how slot names are rendered in the output.
enum SlotNameStyle {
  /// Always use colon syntax: `<x-slot:header>`
  ///
  /// This is the most concise syntax and is the Laravel convention.
  colon('colon'),

  /// Always use attribute syntax: `<x-slot name="header">`
  ///
  /// Some teams prefer this for explicitness.
  attribute('attribute'),

  /// Preserve the original syntax from the source.
  ///
  /// If the source used `<x-slot:header>`, output colon syntax.
  /// If the source used `<x-slot name="header">`, output attribute syntax.
  preserve('preserve');

  final String value;
  const SlotNameStyle(this.value);

  static SlotNameStyle fromString(String? s) => switch (s) {
        'colon' => colon,
        'attribute' => attribute,
        'preserve' => preserve,
        _ => colon,
      };
}
```

Add field to `FormatterConfig`:

```dart
/// Controls how slot names are rendered (colon vs attribute syntax).
final SlotNameStyle slotNameStyle;
```

Add to constructor with default `SlotNameStyle.colon`.

Add to `fromMap`:
```dart
slotNameStyle: SlotNameStyle.fromString(map['slot_name_style'] as String?),
```

Add to `toMap`:
```dart
'slot_name_style': slotNameStyle.value,
```

Add to `toString`.

**Step 4: Update formatter to respect `SlotNameStyle`**

In `lib/src/formatter/formatter_visitor.dart`, in `visitSlot`, replace the hardcoded colon syntax line:

```dart
_output.write('<x-slot:${node.name}');
```

With logic that checks the config:

```dart
final useColon = switch (config.slotNameStyle) {
  SlotNameStyle.colon => true,
  SlotNameStyle.attribute => false,
  SlotNameStyle.preserve => node.useColonSyntax,
};

if (useColon) {
  _output.write('<x-slot:${node.name}');
  // Filter out 'name' attribute to avoid duplication
  final attributes = node.attributes.entries
      .where((e) => e.key != 'name')
      .map((e) => e.value)
      .toList();
} else {
  _output.write('<x-slot');
  // Include name as attribute; build attribute list with name first
  final nameAttr = AttributeNode(
    startPosition: node.startPosition,
    endPosition: node.startPosition,
    name: 'name',
    value: node.name,
    quoteChar: '"',
  );
  final attributes = [
    nameAttr,
    ...node.attributes.entries
        .where((e) => e.key != 'name')
        .map((e) => e.value),
  ];
}
```

Note: the attribute list variable needs to be hoisted before the `_writeAttributes` call. Restructure so `attributes` is defined before the `_shouldWrapAttributes` / `_writeAttributes` calls.

**Step 5: Write tests**

Add tests for all three modes — colon, attribute, preserve.

**Step 6: Run full test suite**

Run: `dart test`
Expected: All pass

**Step 7: Commit**

```bash
git add lib/src/ast/node.dart lib/src/parser/parser.dart lib/src/formatter/formatter_config.dart lib/src/formatter/formatter_visitor.dart test/formatter/...
git commit -m "feat: add slot_name_style config option (colon, attribute, preserve)"
```

---

### Task 4: Add `SlotSpacing` config option

**Files:**
- Modify: `lib/src/formatter/formatter_config.dart` (add `SlotSpacing` enum + field)
- Modify: `lib/src/formatter/formatter_visitor.dart` (`_needsSpacingBetween` and `visitSlot`)
- Test: new or existing test file

**Step 1: Add `SlotSpacing` enum**

In `lib/src/formatter/formatter_config.dart`, add:

```dart
/// Controls spacing (blank lines) around slot elements.
enum SlotSpacing {
  /// No extra blank lines around slots.
  none('none'),

  /// Add a blank line after each slot's closing tag.
  ///
  /// This visually separates slots from subsequent content.
  /// Example:
  /// ```blade
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  ///
  /// <p>Content after slot</p>
  /// ```
  after('after'),

  /// Add a blank line before each slot's opening tag.
  ///
  /// Example:
  /// ```blade
  /// <p>Content before slot</p>
  ///
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  /// ```
  before('before'),

  /// Add blank lines both before and after slots.
  ///
  /// Example:
  /// ```blade
  /// <p>Content before</p>
  ///
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  ///
  /// <p>Content after</p>
  /// ```
  around('around'),

  /// Preserve spacing as written in source.
  preserve('preserve');

  final String value;
  const SlotSpacing(this.value);

  static SlotSpacing fromString(String? s) => switch (s) {
        'none' => none,
        'after' => after,
        'before' => before,
        'around' => around,
        'preserve' => preserve,
        _ => after,
      };
}
```

Add field `slotSpacing` to `FormatterConfig` with default `SlotSpacing.after`.

Wire into `fromMap`, `toMap`, `toString`.

**Step 2: Wire into `_needsSpacingBetween`**

In `lib/src/formatter/formatter_visitor.dart`, add cases to `_needsSpacingBetween`:

```dart
// Spacing after a slot (slot followed by any node)
if (current is SlotNode) {
  return config.slotSpacing == SlotSpacing.after ||
         config.slotSpacing == SlotSpacing.around;
}

// Spacing before a slot (any node followed by slot)
if (next is SlotNode) {
  return config.slotSpacing == SlotSpacing.before ||
         config.slotSpacing == SlotSpacing.around;
}
```

Add these before the `return false;` at the end of the method. The slot checks should go early (before the directive-specific checks that return false), but after the whitespace check.

**Step 3: Write tests**

Test each variant: none, after, before, around. Test slot-slot, slot-element, element-slot, slot-directive combinations.

**Step 4: Run full test suite**

Run: `dart test`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/src/formatter/formatter_config.dart lib/src/formatter/formatter_visitor.dart test/formatter/...
git commit -m "feat: add slot_spacing config option (none, after, before, around, preserve)"
```

---

### Task 5: Final verification and idempotency

**Step 1: Run the formatter on the new fixture and verify output**

Run: `dart run bin/format.dart benchmark/fixtures/livewire/03-dashboard-page.blade.php`

Verify output is correct — slots properly formatted, no duplicate name attributes, spacing looks right.

**Step 2: Run full test suite**

Run: `dart test`
Expected: All pass

**Step 3: Run formatter twice to verify idempotency**

Format the fixture, then format again — output should be identical.

**Step 4: Commit any remaining changes**

```bash
git commit -m "test: verify slot spacing and name style idempotency"
```
