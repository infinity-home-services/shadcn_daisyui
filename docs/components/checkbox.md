# Checkbox

A control that toggles between checked and unchecked.

## Specs

| Part | Description |
| --- | --- |
| Box | Square control that fills with primary and shows a checkmark when checked. |
| Label | Adjacent tappable label text wrapping the input. |

| Property | Value |
| --- | --- |
| Size | 1rem x 1rem (size-4) |
| Radius | var(--radius-sm) |
| Border | 1px var(--input) |
| Checked fill | var(--primary) |
| Padding | 2px (so the check reads at size-4) |

Tokens used: `input`, `primary`, `primary-foreground`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to / from the checkbox |
| Space | Toggle checked / unchecked |

Role / ARIA: Native checkbox input (implicit role checkbox). The form variant renders a hidden false input so an unchecked box still submits.

Focus: Shows a ring shadow on focus-visible.

Screen reader: Checked state is announced. Wrapping the input in a label row gives it an accessible name.

Touch target: Visual box is 16px; wrap it in the full label row so the effective hit area reaches 44pt on touch.

Reduced motion: Checkmark appears instantly under the theme.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Toggle("Active", isOn: $active)
    .toggleStyle(.checkbox)
```

.checkbox toggle style exists on macOS; on iOS a Toggle renders as a switch, so a checkbox there is custom.

## Default

HEEx:

```heex
<.checkbox field={@form[:terms]} label="Accept terms and conditions" />
<.checkbox field={@form[:newsletter]} label="Subscribe to newsletter" />
```

```html
<div class="space-y-3">
  <label class="flex items-center gap-2 text-sm">
    <input type="checkbox" class="checkbox" checked /> Accept terms and conditions
  </label>
  <label class="flex items-center gap-2 text-sm">
    <input type="checkbox" class="checkbox" /> Subscribe to newsletter
  </label>
  <label class="flex items-center gap-2 text-sm text-muted-foreground">
    <input type="checkbox" class="checkbox" disabled /> Disabled option
  </label>
</div>
```
