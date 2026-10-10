# Progress

Displays an indicator showing completion progress.

## Specs

| Part | Description |
| --- | --- |
| Track | Rounded muted background bar. |
| Value | Primary-filled portion sized by value/max (omit value for indeterminate). |

| Property | Value |
| --- | --- |
| Radius | 9999px (rounded-full) |
| Track | var(--muted) |
| Fill | var(--primary) |
| Width | w-full by default |

Tokens used: `muted`, `primary`

## Accessibility

Role / ARIA: Native progress element (implicit role progressbar) exposing value and max. Omitting value yields an indeterminate bar.

Focus: Not focusable; it is a status indicator, not a control.

Screen reader: value/max are announced as a percentage. Add an aria-label or nearby text describing what is progressing.

Touch target: No hit area (display-only).

Reduced motion: Determinate fill is static; avoid added animation for reduced-motion users.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
ProgressView(value: 0.6)
```

ProgressView covers both determinate (value:) and indeterminate (no value) cases natively.

## Default

HEEx:

```heex
<.progress value={60} />
```

```html
<progress class="progress w-full" value="60" max="100"></progress>
```
