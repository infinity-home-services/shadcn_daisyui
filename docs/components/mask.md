# Mask

Clip an element to a shape.

## Specs

| Part | Description |
| --- | --- |
| Masked element | An element clipped to a shape via a mask-* utility. |

| Property | Value |
| --- | --- |
| Shapes | mask-squircle, mask-hexagon, mask-star-2, etc. |
| Size | Sized via utilities (size-14 in the example) |
| Fill | Background color shows through the clipped shape |

Tokens used: `primary`, `secondary`, `color-warning`

## Accessibility

Role / ARIA: Presentational clipping; the shape is purely decorative.

Focus: Not focusable.

Screen reader: Decorative; provide alt text if a masked image carries meaning.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
Color.accentColor
    .frame(width: 56, height: 56)
    .clipShape(.rect(cornerRadius: 16, style: .continuous)) // or a custom Shape
```

.mask(_:) or .clipShape(_:) with a custom Shape gives the same effect.

## Default

```html
<div class="flex items-center gap-4">
  <div class="mask mask-squircle size-14 bg-primary"></div>
  <div class="mask mask-hexagon size-14 bg-secondary"></div>
  <div class="mask mask-star-2 size-14 bg-warning"></div>
</div>
```
