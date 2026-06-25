# Countdown

An animated numeric odometer for countdowns.

## Specs

| Part | Description |
| --- | --- |
| Countdown span | Monospace wrapper for the animated digit(s). |
| Value span | Inner span whose --value drives the odometer roll; aria-live=polite for updates. |

| Property | Value |
| --- | --- |
| Value | --value sets the displayed number (odometer transition) |
| Font | font-mono, text-2xl in the example |
| Motion | Vertical digit roll on change |

Tokens used: `foreground`, `muted-foreground`

## Accessibility

Role / ARIA: Presentational numeric display; updates are announced via aria-live=polite.

Focus: Not focusable.

Screen reader: The polite live region announces each new value as the countdown ticks.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: The digit roll is excluded from the global transition reset; honor prefers-reduced-motion if you drive it yourself.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Text(timerInterval: Date.now...endDate, countsDown: true)
    .font(.system(.title, design: .monospaced))
```

Text(timerInterval:countsDown:) gives a self-updating monospaced countdown.

## Default

```html
<span class="countdown font-mono text-2xl">
  <span style="--value:42;" aria-live="polite">42</span>
</span>
```
