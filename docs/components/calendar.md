# Calendar

A date-selection calendar.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Caption | Centered month + year heading. |
| Month nav | Ghost prev/next buttons that step the visible month. |
| Weekday header | role=columnheader cells (Su-Sa) with full-day aria-labels. |
| Day grid | role=grid of role=gridcell day buttons; today is outlined, the selection filled with primary. |

| Property | Value |
| --- | --- |
| Day cell | 2rem x 2rem |
| Day radius | var(--radius-md) |
| Grid | 7 columns, 0.25rem row gap |
| Caption font | 0.875rem / weight 500 |

Tokens used: `primary`, `primary-foreground`, `accent`, `accent-foreground`, `muted-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move between the nav buttons and day cells |
| Enter / Space | Activate the focused nav button or pick the focused day (native button) |

Role / ARIA: The month is role=grid with role=columnheader weekdays and role=gridcell day buttons; each day has a full localized aria-label and aria-selected reflects the selection.

Focus: Day cells and the prev/next buttons are native buttons; the nav stops click propagation so a wrapping popover stays open across a re-render.

Screen reader: Each day reads its weekday, month, day, and year; aria-selected announces the chosen date and the grid label names the month.

Touch target: 32px day cells are below the 44pt touch minimum - size the calendar up or add padding for touch-first use.

Reduced motion: Month changes re-render the grid in place with no transition.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
DatePicker("Date", selection: $date, displayedComponents: .date)
    .datePickerStyle(.graphical)
```

The .graphical DatePicker is the native month-grid calendar. Use a range selection / two-month layout via custom views if range mode is required.

## Default

HEEx:

```heex
<.calendar id="cal" />
```

```html
<div class="card w-fit">
  <div class="card-body"><div data-calendar></div></div>
</div>
```
