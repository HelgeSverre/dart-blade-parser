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
  directiveEmpty,

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
  directivePrependOnce,
  directiveEndPrependOnce,

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
  directiveEntangle,
  directiveThis,
  directiveJs,

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
  error,
}
