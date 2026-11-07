# Button Group

A set of buttons joined into a single segmented control.

## Specs

| Part | Description |
| --- | --- |
| Group | A `.join` container that fuses children into one segmented control. |
| Item | Each `.join-item .btn` button; only the outer corners round. |

| Property | Value |
| --- | --- |
| Group corners | var(--radius-md) on the first/last item only (join-ss/se/es/ee vars) |
| Item height | 2.25rem (btn default), btn-sm/btn-lg scale together |
| Internal seams | border-inline-start-width: 0 on every item after the first (shared 1px border) |
| Item shadow | none (`.join .btn` clears box-shadow so seams stay flat) |

Tokens used: `background`, `foreground`, `border-color`, `accent`, `accent-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus to and between the buttons |
| Enter / Space | Activate the focused button |

Role / ARIA: A row of native buttons; add role=group with an aria-label when the buttons form one logical control.

Focus: Each button shows the standard ring-shadow focus outline; seams do not clip the ring.

Screen reader: Buttons are announced individually by their label; a group label gives shared context.

Touch target: Default 2.25rem buttons read as desktop-sized; use btn-lg for primary actions on touch.

Reduced motion: No motion; hover/press are instant color changes only.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Picker("View", selection: $range) {
  Text("Years").tag(Range.years)
  Text("Months").tag(Range.months)
  Text("Days").tag(Range.days)
}
.pickerStyle(.segmented)
```

A non-exclusive button group maps to an HStack of bordered Buttons; an exclusive one maps to a segmented Picker.

## Default

```html
<div class="join">
  <button class="join-item btn btn-outline">Years</button>
  <button class="join-item btn btn-outline">Months</button>
  <button class="join-item btn btn-outline">Days</button>
</div>
```
