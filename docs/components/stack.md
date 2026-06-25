# Stack

Overlapping, stacked elements.

## Specs

| Part | Description |
| --- | --- |
| Stack container | stack wrapper that overlaps its children. |
| Stacked items | Cards layered front-to-back with a slight offset (here three cards). |

| Property | Value |
| --- | --- |
| Layout | Children overlap in the same box with a small offset |
| Size | Sized via utilities (size-20 in the example) |
| Surfaces | Cards use primary / secondary / base-100 fills |

Tokens used: `primary`, `primary-foreground`, `secondary`, `secondary-foreground`, `color-base-200`

## Accessibility

Role / ARIA: Presentational overlap layout; only the top item is typically visible/meaningful.

Focus: Not focusable as a unit; any controls inside stacked items keep their own focus.

Screen reader: All stacked children remain in the DOM and read in order - hide non-top items if that is confusing.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
ZStack {
    CardC(); CardB().offset(y: -4); CardA().offset(y: -8)
}
```

A ZStack with small offsets reproduces the overlapped-card look.

## Default

```html
<div class="stack size-20">
  <div class="card bg-primary text-primary-foreground"><div class="card-body items-center justify-center p-0">A</div></div>
  <div class="card bg-secondary text-secondary-foreground"><div class="card-body items-center justify-center p-0">B</div></div>
  <div class="card border border-base-300 bg-base-100"><div class="card-body items-center justify-center p-0">C</div></div>
</div>
```
