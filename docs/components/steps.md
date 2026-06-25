# Steps

A horizontal stepper showing progress through a flow.

## Specs

| Part | Description |
| --- | --- |
| Steps list | Horizontal <ul> of step items. |
| Step | An <li> with a numbered node above its label; completed steps get step-primary. |

| Property | Value |
| --- | --- |
| Label font | 0.875rem |
| Default node | --step-bg muted, --step-fg muted-foreground |
| Active node | --step-bg primary, --step-fg primary-foreground |
| Connector | Track line between nodes follows the node color |

Tokens used: `muted`, `muted-foreground`, `primary`, `primary-foreground`

## Accessibility

Role / ARIA: Presentational <ul>/<li>; current/complete state is conveyed only visually by color.

Focus: Not focusable; add ARIA (aria-current) yourself if steps must be announced.

Screen reader: Step labels read as a plain list; progress is not exposed without extra ARIA.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack(spacing: 0) {
    ForEach(steps) { step in
        Circle().fill(step.done ? Color.accentColor : Color(.systemGray4))
            .frame(width: 24, height: 24)
        if step != steps.last { Rectangle().frame(height: 2) }
    }
}
```

No stock stepper; build from nodes + connectors, or use a segmented ProgressView.

## Default

```html
<ul class="steps w-full">
  <li class="step step-primary">Cart</li>
  <li class="step step-primary">Shipping</li>
  <li class="step">Payment</li>
  <li class="step">Confirm</li>
</ul>
```
