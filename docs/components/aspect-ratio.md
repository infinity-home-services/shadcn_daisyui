# Aspect Ratio

Constrains content to a fixed width/height ratio.

## Specs

| Part | Description |
| --- | --- |
| Container | A box constrained to a fixed width/height ratio (e.g. aspect-video). |
| Content | The media or placeholder filling the constrained box. |

| Property | Value |
| --- | --- |
| Ratio | 16/9 via aspect-video (any aspect-* utility works) |
| Corner radius | var(--radius-lg) (rounded-lg) in the example |
| Placeholder fill | var(--muted) / var(--muted-foreground) |
| Width | fills its container (max-w-sm in the demo) |

Tokens used: `muted`, `muted-foreground`, `border-color`

## Accessibility

Role / ARIA: A purely structural layout wrapper with no role; semantics come from the content it holds.

Focus: Not focusable itself; any interactive child manages its own focus.

Screen reader: Transparent to assistive tech; describe the contained media (alt text) instead.

Touch target: No interaction; any actionable child is responsible for its own hit area.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Image("cover")
  .resizable()
  .aspectRatio(16 / 9, contentMode: .fit)
```

Maps directly to the .aspectRatio modifier on the contained view.

## 16 / 9

```html
<div class="w-full max-w-sm space-y-1.5">
  <p class="text-sm font-medium">Aspect ratio (16:9)</p>
  <div class="flex aspect-video items-center justify-center rounded-lg bg-muted text-sm text-muted-foreground">
    16 / 9
  </div>
</div>
```
