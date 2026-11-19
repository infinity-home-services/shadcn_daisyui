# Radial Progress

A circular percentage progress ring.

## Specs

| Part | Description |
| --- | --- |
| Ring | Circular track driven by the --value custom property (0-100). |
| Center label | Percentage text centered inside the ring. |

| Property | Value |
| --- | --- |
| Value | --value:0-100 sets the swept arc |
| Color | primary by default; recolor with text-* utilities |
| Label font | text-sm in the examples |
| ARIA | role=progressbar with aria-valuenow/min/max |

Tokens used: `primary`, `muted`, `foreground`

## Accessibility

Role / ARIA: role=progressbar with aria-valuenow, aria-valuemin, aria-valuemax and an aria-label.

Focus: Not focusable; it is a status readout, not a control.

Screen reader: Announced as a progress bar reporting the current percentage.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static at render; the arc does not animate unless you animate --value.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Gauge(value: 0.7) { Text("70%") }
    .gaugeStyle(.accessoryCircularCapacity)
    .tint(.accentColor)
```

A circular Gauge maps cleanly; ProgressView(value:).progressViewStyle(.circular) also works.

## Default

```html
<div class="flex items-center gap-6">
  <div class="radial-progress text-sm" style="--value:70;" role="progressbar" aria-valuenow="70" aria-valuemin="0" aria-valuemax="100" aria-label="70%">70%</div>
  <div class="radial-progress text-sm" style="--value:40;" role="progressbar" aria-valuenow="40" aria-valuemin="0" aria-valuemax="100" aria-label="40%">40%</div>
  <div class="radial-progress text-primary text-sm" style="--value:90;" role="progressbar" aria-valuenow="90" aria-valuemin="0" aria-valuemax="100" aria-label="90%">90%</div>
</div>
```
