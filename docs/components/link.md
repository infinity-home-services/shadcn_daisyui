# Link

A styled inline anchor.

## Specs

| Part | Description |
| --- | --- |
| Anchor | Styled <a> with link styling. |
| Variant | link-primary tints it; link-hover defers the underline to hover. |

| Property | Value |
| --- | --- |
| Underline | Underlined by default; link-hover underlines on hover only |
| Color | Inherits text; link-primary uses primary |
| Font | text-sm in the example |

Tokens used: `primary`, `foreground`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the link |
| Enter | Follow the link |

Role / ARIA: Native <a>; give it an href so it is a real, focusable link.

Focus: Native focus ring (var(--ring)) on :focus-visible.

Screen reader: Announced as a link with its text; ensure the text is descriptive on its own.

Touch target: Inline links should still offer a comfortable tap area on touch.

Reduced motion: Color/underline transitions only; nothing moves.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Link("Primary link", destination: URL(string: "https://example.com")!)
    .tint(.accentColor)
```

SwiftUI Link maps directly; tint controls the accent color.

## Default

```html
<div class="flex flex-wrap gap-4 text-sm">
  <a class="link link-primary">Primary link</a>
  <a class="link">Default link</a>
  <a class="link link-hover">Hover link</a>
</div>
```
