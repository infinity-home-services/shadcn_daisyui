# Radio Group

A set of checkable buttons where only one can be selected at a time.

## Specs

| Part | Description |
| --- | --- |
| Group | Fieldset grouping the radios with an optional legend label. |
| Radio | Circular control selected one-at-a-time, sharing a name. |
| Label | Tappable text label per option. |

| Property | Value |
| --- | --- |
| Size | 1rem x 1rem (radio radio-sm) |
| Border | 1px var(--input) |
| Checked | border + dot use var(--primary) |
| Row gap | 0.5rem (gap-2) |

Tokens used: `input`, `primary`, `ring`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus into / out of the group (to the checked radio) |
| Arrow keys | Move selection between radios in the group |
| Space | Select the focused radio |

Role / ARIA: fieldset + legend grouping native radio inputs that share a name (implicit radiogroup / radio roles). The legend names the group.

Focus: Focused radio shows a ring shadow; arrow keys move both focus and selection.

Screen reader: Legend is announced as the group name; each radio announces its label and position in the set.

Touch target: Each option is a full label row, giving a 44pt-friendly hit area.

Reduced motion: Selection dot appears instantly under the theme.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Picker("Plan", selection: $plan) {
    Text("Free").tag("free")
    Text("Pro").tag("pro")
}
.pickerStyle(.inline)
```

An inline Picker is the idiomatic single-select group; on macOS .radioGroup style maps even more directly.

## Default

HEEx:

```heex
<.radio_group field={@form[:plan]} label="Plan">
  <:radio value="free">Free</:radio>
  <:radio value="pro">Pro</:radio>
  <:radio value="enterprise">Enterprise</:radio>
</.radio_group>
```

```html
<div class="space-y-3">
  <label class="flex items-center gap-2 text-sm">
    <input type="radio" name="plan" class="radio" checked /> Free
  </label>
  <label class="flex items-center gap-2 text-sm">
    <input type="radio" name="plan" class="radio" /> Pro
  </label>
  <label class="flex items-center gap-2 text-sm">
    <input type="radio" name="plan" class="radio" /> Enterprise
  </label>
</div>
```
