# Tooltip

A floating label shown on hover or focus.

## Specs

| Part | Description |
| --- | --- |
| Wrapper | Element carrying the tooltip class and data-tip text around the trigger. |
| Bubble | CSS ::before bubble in primary, positioned top/bottom/left/right. |

| Property | Value |
| --- | --- |
| Bubble bg | var(--primary) |
| Bubble text | var(--primary-foreground), 0.75rem |
| Bubble radius | var(--radius-md) |
| Position | top (default) / bottom / left / right |

Tokens used: `primary`, `primary-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus the wrapped trigger to reveal the tooltip |
| Esc | Dismiss the tooltip (when scripted) while keeping focus |

Role / ARIA: CSS tooltip driven by data-tip; appears on hover and focus of the wrapped trigger. The trigger should still carry its own accessible name (the tip is supplementary, not a label substitute).

Focus: Shows on focus as well as hover, so keyboard users see it; hover alone is never required.

Screen reader: The CSS ::before text is not in the accessibility tree, so duplicate the tip in aria-label / aria-describedby for non-visual users.

Touch target: Hover tooltips do not appear on touch; do not hide essential information behind a tooltip.

Reduced motion: Tooltip is excluded from the instant-toggle rule, keeping its own gentle fade; respect reduced motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
Button("Hover me") { }
    .help("Add to library")
```

.help(_:) provides hover tooltips on macOS; iOS has no hover tooltip, so surface the text another way there.

## Default

HEEx:

```heex
<.tooltip tip="Tooltip text">
  <.button variant="secondary">Hover me</.button>
</.tooltip>
```

```html
<div class="tooltip" data-tip="Tooltip text">
  <button class="btn btn-secondary">Hover me</button>
</div>
```
