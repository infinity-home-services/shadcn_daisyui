# Status

A tiny status dot for online/offline state.

## Specs

| Part | Description |
| --- | --- |
| Status dot | A tiny inline circle colored by state. |
| Label | Adjacent text describing the state (Online / Offline). |

| Property | Value |
| --- | --- |
| Shape | Small circular dot |
| Online | status-success → color-success |
| Offline | status-error → destructive |
| Label font | text-sm |

Tokens used: `color-success`, `destructive`, `muted-foreground`

## Accessibility

Role / ARIA: Presentational dot; meaning lives in the adjacent text label.

Focus: Not focusable.

Screen reader: The dot is decorative; only the text label conveys state.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack(spacing: 6) {
    Circle().fill(isOnline ? .green : .red).frame(width: 8, height: 8)
    Text(isOnline ? "Online" : "Offline")
}
```

A small colored Circle plus a Text label; pair the color with words for accessibility.

## Default

```html
<div class="flex items-center gap-6">
  <span class="inline-flex items-center gap-2 text-sm">
    <span class="status status-success"></span> Online
  </span>
  <span class="inline-flex items-center gap-2 text-sm">
    <span class="status status-error"></span> Offline
  </span>
</div>
```
