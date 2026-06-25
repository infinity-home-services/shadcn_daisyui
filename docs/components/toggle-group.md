# Toggle Group

A set of two-state buttons that can be toggled together.

## Specs

| Part | Description |
| --- | --- |
| Group | A `.join` container holding the toggle buttons as one control. |
| Item | Each `.join-item .btn` label wrapping a hidden checkbox with `has-[:checked]` styling. |

| Property | Value |
| --- | --- |
| Group corners | var(--radius-md) on the outer corners only |
| Item height | 2.25rem (btn default) |
| Internal seams | shared 1px border (border-inline-start-width: 0 after the first item) |
| Pressed fill | var(--accent) / var(--accent-foreground) on checked items |

Tokens used: `background`, `foreground`, `border-color`, `accent`, `accent-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus into and across the items |
| Space / Enter | Toggle the focused item |

Role / ARIA: A grouped set of two-state buttons; for single-select use radio inputs, for multi-select use checkboxes.

Focus: Each item shows the ring-shadow outline when focused.

Screen reader: Each item is announced by its aria-label and pressed/checked state.

Touch target: 2.25rem items; size up to 2.75rem effective area on touch.

Reduced motion: Pressed state is an instant color change; no animation.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Picker("Format", selection: $alignment) {
  Image(systemName: "bold").tag(Format.bold)
  Image(systemName: "italic").tag(Format.italic)
  Image(systemName: "underline").tag(Format.underline)
}
.pickerStyle(.segmented)
```

Single-select toggle groups map to a segmented Picker; multi-select needs an HStack of .button-style Toggles.

## Default

```html
<div class="join">
  <label class="join-item btn btn-outline btn-square has-[:checked]:bg-accent has-[:checked]:text-accent-foreground">
    <input type="checkbox" class="hidden" aria-label="Bold" />
    <span class="font-bold">B</span>
  </label>
  <label class="join-item btn btn-outline btn-square has-[:checked]:bg-accent has-[:checked]:text-accent-foreground">
    <input type="checkbox" class="hidden" aria-label="Italic" checked />
    <span class="italic">I</span>
  </label>
  <label class="join-item btn btn-outline btn-square has-[:checked]:bg-accent has-[:checked]:text-accent-foreground">
    <input type="checkbox" class="hidden" aria-label="Underline" />
    <span class="underline">U</span>
  </label>
</div>
```
