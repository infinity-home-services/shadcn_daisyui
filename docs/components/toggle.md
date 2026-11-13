# Toggle

A two-state button that can be on or off.

## Specs

| Part | Description |
| --- | --- |
| Control | A bordered `.btn` (often `.btn-square`) wrapping a hidden checkbox input. |
| Label | Icon and/or text inside the button that conveys the toggled state. |

| Property | Value |
| --- | --- |
| Height | 2.25rem (btn default) |
| Corner radius | var(--radius-md) |
| Border | 1px var(--border-color) (btn-outline) |
| Pressed fill | var(--accent) background with var(--accent-foreground) text when checked |

Tokens used: `background`, `foreground`, `border-color`, `accent`, `accent-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to the toggle |
| Space / Enter | Flip the on/off state |

Role / ARIA: A two-state button; the hidden checkbox carries the on/off state and aria-label.

Focus: Focus shows the ring-shadow outline on the button.

Screen reader: Announced via the input's aria-label plus its checked/unchecked state.

Touch target: 2.25rem square; pad to 2.75rem effective area on touch surfaces.

Reduced motion: State change is an instant color swap; no transition to suppress.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Toggle(isOn: $isBold) {
  Image(systemName: "bold")
}
.toggleStyle(.button)
```

A single pressed-state button maps to a .button-style Toggle; a daisyUI switch maps to the default Toggle.

## Default

```html
<div class="flex flex-wrap items-center gap-3">
  <label class="btn btn-outline btn-square">
    <input type="checkbox" class="hidden" aria-label="Bold" /><span class="font-bold">B</span>
  </label>
  <label class="btn btn-outline gap-2">
    <input type="checkbox" class="hidden" aria-label="Bookmark" />
    <span class="hero-star size-4" aria-hidden="true"></span> Bookmark
  </label>
</div>
```
