# Spinner

An animated loading indicator.

## Specs

| Part | Description |
| --- | --- |
| Spinner | Animated loading glyph (loading loading-spinner) sized via class. |

| Property | Value |
| --- | --- |
| Color | var(--muted-foreground) |
| Size | loading-xs / sm / (default) / lg |

Tokens used: `muted-foreground`, `primary`

## Accessibility

Role / ARIA: Decorative animated indicator with no implicit role. Pair it with an aria-live status message (Loading…) so screen-reader users learn that something is in progress.

Focus: Not focusable.

Screen reader: The spinner itself conveys nothing; announce the loading state via accompanying live-region text.

Touch target: No hit area.

Reduced motion: Spinner is excluded from the instant-toggle rule so its rotation runs; consider pausing or simplifying it under prefers-reduced-motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
ProgressView()
    .progressViewStyle(.circular)
```

A value-less circular ProgressView is the native indeterminate spinner and handles reduced-motion automatically.

## Default

HEEx:

```heex
<.spinner />
<.spinner size="loading-sm" />
<.button><.spinner size="loading-xs" /> Please wait</.button>
```

```html
<div class="flex items-center gap-4">
  <span class="loading loading-spinner"></span>
  <span class="loading loading-spinner loading-sm"></span>
  <button class="btn btn-primary">
    <span class="loading loading-spinner loading-xs"></span> Please wait
  </button>
</div>
```
