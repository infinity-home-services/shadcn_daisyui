# Mockup

Browser and code window mockup frames.

## Specs

| Part | Description |
| --- | --- |
| Frame | mockup-browser or mockup-window chrome around content. |
| Toolbar | mockup-browser-toolbar with a faux URL input. |
| Code block | mockup-code listing with data-prefix gutters per line. |

| Property | Value |
| --- | --- |
| Radius | var(--radius-lg) |
| Surface | muted background, 1px border-color |
| URL field | background-colored faux input in the toolbar |

Tokens used: `muted`, `background`, `border-color`, `color-success`

## Accessibility

Role / ARIA: Presentational decorative frame; the contained content carries its own semantics.

Focus: The frame is not focusable; only real controls inside it are.

Screen reader: The chrome is decorative; ensure inner content is meaningful on its own.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
VStack(spacing: 0) {
    HStack { Circle(); Circle(); Circle() }.foregroundStyle(.secondary).padding(8)
    content
}
.background(Color(.secondarySystemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

No native window-chrome control; build a decorative frame around your content.

## Browser & code

```html
<div class="w-full space-y-6">
  <div class="mockup-browser border border-base-300">
    <div class="mockup-browser-toolbar">
      <div class="input">https://shadcn-daisyui.dev</div>
    </div>
    <div class="flex justify-center px-4 py-6 text-sm text-muted-foreground">Hello, world!</div>
  </div>
  <div class="mockup-code">
    <pre data-prefix="$"><code>mix phx.server</code></pre>
    <pre data-prefix=">" class="text-success"><code>running on :4000</code></pre>
  </div>
</div>
```
