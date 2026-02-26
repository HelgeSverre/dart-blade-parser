/// Token types for Blade templates.
enum TokenType {
  // Blade Directives - Control Flow
  directiveIf,
  directiveElseif,
  directiveElse,
  directiveEndif,
  directiveUnless,
  directiveEndunless,
  directiveSwitch,
  directiveCase,
  directiveDefault,
  directiveEndswitch,
  directiveIsset,
  directiveEndisset,
  directiveEmpty,
  directiveEndempty,

  // Blade Directives - Loops
  directiveFor,
  directiveEndfor,
  directiveForeach,
  directiveEndforeach,
  directiveForelse,
  directiveEndforelse,
  directiveWhile,
  directiveEndwhile,
  directiveContinue,
  directiveBreak,

  // Blade Directives - Template Inheritance
  directiveExtends,
  directiveSection,
  directiveEndsection,
  directiveYield,
  directiveParent,
  directiveShow,
  directiveOverwrite,

  // Blade Directives - Stacks
  directivePush,
  directiveEndpush,
  directivePrepend,
  directiveEndprepend,
  directiveStack,
  directivePushOnce,
  directiveEndPushOnce,
  directivePushIf,
  directiveEndPushIf,
  directivePrependOnce,
  directiveEndPrependOnce,
  directiveHasStack,

  // Blade Directives - Components
  directiveComponent,
  directiveEndcomponent,
  directiveSlot,
  directiveEndslot,
  directiveProps,
  directiveAware,

  // Blade Directives - Includes
  directiveInclude,
  directiveIncludeIf,
  directiveIncludeWhen,
  directiveIncludeUnless,
  directiveIncludeFirst,
  directiveEach,

  // Blade Directives - Section Closers
  directiveStop,
  directiveAppend,

  // Blade Directives - Special
  directiveOnce,
  directiveEndonce,
  directivePhp,
  directiveEndphp,
  directiveVerbatim,
  directiveEndverbatim,

  // Blade Directives - Authentication & Authorization
  directiveAuth,
  directiveEndauth,
  directiveGuest,
  directiveEndguest,
  directiveCan,
  directiveEndcan,
  directiveCannot,
  directiveEndcannot,
  directiveCanany,
  directiveEndcanany,

  // Blade Directives - Environment
  directiveEnv,
  directiveEndenv,
  directiveProduction,
  directiveEndproduction,
  directiveSession,
  directiveEndsession,
  directiveContext,
  directiveEndcontext,

  // Blade Directives - Debugging
  directiveDd,
  directiveDump,

  // Blade Directives - Validation
  directiveError,
  directiveEnderror,

  // Blade Directives - Section Conditionals
  directiveHasSection,
  directiveSectionMissing,

  // Blade Directives - HTML Attributes
  directiveClass,
  directiveStyle,
  directiveChecked,
  directiveSelected,
  directiveDisabled,
  directiveReadonly,
  directiveRequired,

  // Blade Directives - Assets & Data
  directiveJson,
  directiveMethod,
  directiveCsrf,
  directiveVite,

  // Blade Directives - Service Injection
  directiveInject,

  // Blade Directives - Modern Features
  directiveFragment,
  directiveEndfragment,
  directiveUse,

  // Livewire Directives
  directiveLivewire,
  directiveTeleport,
  directiveEndTeleport,
  directivePersist,
  directiveEndPersist,
  directiveEntangle,
  directiveThis,
  directiveJs,
  directiveLivewireStyles,
  directiveLivewireScripts,
  directiveLivewireScriptConfig,
  directiveScript,
  directiveEndscript,
  directiveAssets,
  directiveEndassets,

  // Volt Directives
  directiveVolt,
  directiveEndvolt,

  // Blaze Directives (Livewire Blaze - component optimization)
  directiveBlaze,
  directiveUnblaze,
  directiveEndunblaze,

  // Filament Directives
  directiveFilamentStyles,
  directiveFilamentScripts,

  // Echo Statements
  echoOpen, // {{
  echoClose, // }}
  rawEchoOpen, // {!!
  rawEchoClose, // !!}
  legacyEchoOpen, // {{{
  legacyEchoClose, // }}}
  bladeEscape, // @{{
  // Components
  componentTagOpen, // <x-
  componentTagClose, // </x-
  componentSelfClose, // />
  componentSlotOpen, // <x-slot:
  componentSlotClose, // </x-slot>
  // HTML Elements
  htmlTagOpen, // < (for HTML elements, not components)
  htmlTagName, // Tag name after <
  htmlTagClose, // >
  htmlSelfClose, // />
  htmlClosingTagStart, // </
  htmlClosingTagEnd, // > (after closing tag name)
  // Alpine.js Attributes
  alpineData,
  alpineInit,
  alpineShow,
  alpineIf,
  alpineFor,
  alpineModel,
  alpineText,
  alpineHtml,
  alpineBind,
  alpineOn,
  alpineTransition,
  alpineCloak,
  alpineIgnore,
  alpineRef,
  alpineTeleport,
  alpineShorthandBind, // :attribute
  alpineShorthandOn, // @event
  // Livewire Attributes
  livewireClick,
  livewireSubmit,
  livewireKeydown,
  livewireKeyup,
  livewireMouseenter,
  livewireMouseleave,
  livewireModel,
  livewireModelLive,
  livewireModelBlur,
  livewireModelDebounce,
  livewireModelLazy,
  livewireModelDefer,
  livewireLoading,
  livewireTarget,
  livewireLoadingClass,
  livewireLoadingRemove,
  livewireLoadingAttr,
  livewirePoll,
  livewirePollKeepAlive,
  livewirePollVisible,
  livewireIgnore,
  livewireKey,
  livewireId,
  livewireInit,
  livewireDirty,
  livewireOffline,
  livewireNavigate,
  livewireTransition,
  livewireStream,

  // Literals & Identifiers
  text,
  whitespace,
  identifier,
  expression,
  stringLiteral,
  numberLiteral,
  attributeValue, // Attribute value (without quotes)
  // Structural
  bladeComment, // {{-- --}}
  htmlComment, // <!-- -->
  eof,
  error;

  /// The set of Blade directives that are designed to be used as HTML
  /// attributes (e.g., `@class(...)`, `@checked(...)`).
  ///
  /// Single source of truth used by the lexer, parser, and formatter.
  static const Set<TokenType> attributeDirectives = {
    directiveClass,
    directiveStyle,
    directiveChecked,
    directiveSelected,
    directiveDisabled,
    directiveReadonly,
    directiveRequired,
  };

  /// Map from directive name (without @) to its [TokenType].
  /// Only covers attribute directives.
  static const Map<String, TokenType> attributeDirectivesByName = {
    'class': directiveClass,
    'style': directiveStyle,
    'checked': directiveChecked,
    'selected': directiveSelected,
    'disabled': directiveDisabled,
    'readonly': directiveReadonly,
    'required': directiveRequired,
  };

  /// Maps directive names to their correct closing tag names.
  ///
  /// Handles directives where `@end` + name doesn't match the actual syntax
  /// (e.g., `pushOnce` → `endPushOnce`, not `endpushOnce`).
  ///
  /// Single source of truth used by the parser and formatter.
  static const Map<String, String> closingDirectiveNames = {
    'pushOnce': 'endPushOnce',
    'prependOnce': 'endPrependOnce',
    'pushIf': 'endPushIf',
    'hasStack': 'endif',
    'teleport': 'endTeleport',
    'persist': 'endPersist',
  };

  /// Returns the closing directive name for a given opening directive name.
  static String closingDirectiveName(String name) {
    return closingDirectiveNames[name] ?? 'end$name';
  }
}
