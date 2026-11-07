# Slider

An input for selecting a value from a range.

## Specs

| Part | Description |
| --- | --- |
| Track | Muted rail showing the selectable range. |
| Fill | Primary-colored portion left of the thumb. |
| Thumb | Round background-faced knob with a 2px primary ring. |

| Property | Value |
| --- | --- |
| Thumb size | 1rem (size-4) |
| Thumb border | 2px var(--primary), rounded-full |
| Track | var(--muted) |
| Fill | var(--primary) |

Tokens used: `muted`, `primary`, `background`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Left / Down | Decrease the value by one step |
| Right / Up | Increase the value by one step |
| Home / End | Jump to the minimum / maximum |

Role / ARIA: Native range input (implicit role slider) exposing min/max/value.

Focus: Thumb shows a ring shadow on focus-visible.

Screen reader: Current, min, and max values are announced. Add an aria-label describing what the slider controls.

Touch target: Thumb is 16px visually; the native range control provides a larger effective drag area, but verify 44pt on touch.

Reduced motion: Thumb movement tracks input directly; no decorative animation.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Slider(value: $volume, in: 0...100, step: 1)
    .accessibilityLabel("Volume")
```

Slider is the exact native equivalent, with built-in step and accessibility value reporting.

## Default

```html
<input type="range" min="0" max="100" value="50" class="range w-full" />
```
