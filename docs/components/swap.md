# Swap

An animated swap between two icons or states.

## Specs

| Part | Description |
| --- | --- |
| Swap label | A <label> wrapper (often styled as a button) toggling two states. |
| Checkbox | Hidden <input type=checkbox> that drives on/off. |
| Swap faces | swap-on / swap-off children shown for each state (swap-rotate animates between them). |

| Property | Value |
| --- | --- |
| States | Two faces: swap-on (checked) and swap-off (unchecked) |
| Animation | swap-rotate rotates between the two faces |
| Icon size | size-5 in the example |

Tokens used: `foreground`, `primary`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the swap |
| Space | Toggle between the two states |

Role / ARIA: Wraps a checkbox; give the input an aria-label describing the toggle action.

Focus: Native checkbox focus; ensure the label exposes a visible focus indicator.

Screen reader: Announced as a checkbox with its aria-label; checked state conveys which face is shown.

Touch target: Style the label to a 44pt effective tap area on touch.

Reduced motion: The rotate animation should be suppressed under prefers-reduced-motion.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
Toggle(isOn: $isDark) {
    Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
        .contentTransition(.symbolEffect(.replace))
}
.toggleStyle(.button)
```

A button-style Toggle with a symbol replace transition mirrors the icon swap.

## Default

```html
<label class="swap swap-rotate btn btn-outline btn-square">
  <input type="checkbox" aria-label="Toggle theme" />
  <span class="hero-sun swap-on size-5" aria-hidden="true"></span>
  <span class="hero-moon swap-off size-5" aria-hidden="true"></span>
</label>
```
