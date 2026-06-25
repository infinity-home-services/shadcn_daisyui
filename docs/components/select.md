# Select

Displays a list of options for the user to pick from, triggered by a button.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Outline button showing the current value and a chevron-down icon. |
| Panel | Popover listbox of option buttons positioned below the trigger. |
| Option | Each row (combo-item) with a check icon revealed on selection. |

| Property | Value |
| --- | --- |
| Trigger height | 2.25rem / 36px (btn h-9) |
| Trigger radius | var(--radius-md) |
| Panel radius | var(--radius-md) |
| Panel border | 1px var(--border-color) |
| Option padding | 0.375rem block, 0.5rem inline |
| Option radius | var(--radius-sm) |

Tokens used: `popover`, `popover-foreground`, `border-color`, `accent`, `accent-foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space | Open the listbox from the trigger |
| Up / Down | Move the active option |
| Enter | Select the active option and close |
| Esc | Close the listbox without changing the value |

Role / ARIA: Custom trigger button plus a popover list of option buttons, driven by the ShadcnSelect hook. Requires a unique id. Provide an accessible name on the trigger (the placeholder/label reads as the current value).

Focus: Trigger shows the ring on focus; the active option is highlighted with the accent background.

Screen reader: For a fully announced native experience prefer native-select; this custom control trades native semantics for shadcn visuals.

Touch target: Trigger is 36px tall (desktop-fine); options are tappable rows. Pad to 44pt on touch-primary surfaces.

Reduced motion: Panel toggles visibility without a color fade under the theme.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Picker("Fruit", selection: $fruit) {
    ForEach(fruits, id: \.self) { Text($0).tag($0) }
}
.pickerStyle(.menu)
```

A .menu Picker gives the same trigger-then-list behavior natively, with system-managed selection semantics.

## Default

HEEx:

```heex
<.select id="fruit" placeholder="Select a fruit">
  <:option value="Apple">Apple</:option>
  <:option value="Banana">Banana</:option>
  <:option value="Blueberry">Blueberry</:option>
  <:option value="Grapes">Grapes</:option>
  <:option value="Pineapple">Pineapple</:option>
</.select>
```

```html
<div data-select class="relative w-60">
  <button type="button" data-select-trigger class="btn btn-outline w-full justify-between font-normal">
    <span data-select-label class="text-muted-foreground">Select a fruit</span>
    <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
  </button>
  <div data-select-panel class="popover-panel absolute z-30 mt-1 hidden w-full p-1">
    <button type="button" class="combo-item" data-select-item data-value="Apple"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Apple</button>
    <button type="button" class="combo-item" data-select-item data-value="Banana"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Banana</button>
    <button type="button" class="combo-item" data-select-item data-value="Blueberry"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Blueberry</button>
    <button type="button" class="combo-item" data-select-item data-value="Grapes"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Grapes</button>
    <button type="button" class="combo-item" data-select-item data-value="Pineapple"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Pineapple</button>
  </div>
</div>
```
