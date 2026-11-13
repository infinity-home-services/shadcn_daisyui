# Indicator

A corner badge overlaid on another element.

## Specs

| Part | Description |
| --- | --- |
| Indicator wrapper | Positioning context for the overlaid item. |
| Indicator item | A badge pinned to a corner (here badge-error) over the anchor element. |
| Anchor | The element the badge sits on, e.g. a button. |

| Property | Value |
| --- | --- |
| Placement | Absolutely positioned to a corner of the wrapper |
| Badge | Inherits daisyUI badge sizing/colors |
| Color | badge-error uses destructive for the count dot |

Tokens used: `destructive`, `destructive-foreground`, `primary`

## Accessibility

Role / ARIA: Presentational overlay; the badge is decorative unless its count carries meaning via the anchor's label.

Focus: The badge itself is not focusable; focus belongs to the anchor control.

Screen reader: Surface the count in the anchor's accessible name; the badge is not announced on its own.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Image(systemName: "bell")
    .overlay(alignment: .topTrailing) {
        Text("9").font(.caption2).padding(4)
            .background(.red, in: Circle()).foregroundStyle(.white)
    }
// or, in a TabView / List: .badge(9)
```

Native .badge(_:) covers tab/list counts; .overlay places a custom corner badge anywhere.

## Default

```html
<div class="indicator">
  <span class="indicator-item badge badge-error">9</span>
  <button class="btn btn-outline">
    <span class="hero-bell size-4" aria-hidden="true"></span> Inbox
  </button>
</div>
```
