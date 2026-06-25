# Date Picker

A popover calendar for picking a single date or a range.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Specs

| Part | Description |
| --- | --- |
| Trigger | An outline button (aria-haspopup=dialog) showing the formatted date or placeholder. |
| Popover | Panel containing the calendar grid. |
| Calendar | The same role=grid day picker; choosing a day fills the label and closes the popover. |

| Property | Value |
| --- | --- |
| Popover radius | var(--radius-md) |
| Day cell | 2rem x 2rem |
| Trigger | field height, var(--radius-md) |
| Border | 1px var(--border-color) |

Tokens used: `popover`, `popover-foreground`, `primary`, `primary-foreground`, `accent`, `muted-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move into the popover and across the calendar controls |
| Enter / Space | Pick the focused day (closes the popover) or step months via the nav buttons |
| Esc | Dismiss via outside-click; clicking away closes the popover |

Role / ARIA: Trigger is a button with aria-haspopup=dialog and aria-expanded; the popover holds the calendar role=grid described under Calendar.

Focus: Opening reveals the calendar; selecting a day or an outside click closes the popover. aria-expanded on the trigger stays in sync.

Screen reader: Trigger announces the current date; inside, day cells read their full localized date label.

Touch target: The trigger is a full field; the 32px day cells need extra padding to meet the touch minimum.

Reduced motion: The popover toggles a hidden class with no movement.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
DatePicker("Pick a date", selection: $date, displayedComponents: .date)
    .datePickerStyle(.compact)   // .graphical for an inline calendar
```

A compact DatePicker is the native trigger-plus-popover equivalent; switch to .graphical when you want the calendar always visible.

## Single & range

HEEx:

```heex
<.date_picker id="date" placeholder="Pick a date" />
<.date_range id="range" placeholder="Pick a date range" />
```

```html
<div class="flex flex-col gap-4">
  <div class="space-y-2">
    <p class="text-sm text-muted-foreground">Date picker</p>
    <div data-datepicker class="relative w-64">
      <button type="button" data-datepicker-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="hero-calendar size-4 opacity-70" aria-hidden="true"></span>
        <span data-datepicker-label class="text-muted-foreground">Pick a date</span>
      </button>
      <div data-datepicker-panel class="popover-panel absolute z-30 mt-1 hidden p-3">
        <div data-calendar></div>
      </div>
    </div>
  </div>
  <div class="space-y-2">
    <p class="text-sm text-muted-foreground">Date range picker</p>
    <div data-daterange class="relative w-64">
      <button type="button" data-daterange-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="hero-calendar size-4 opacity-70" aria-hidden="true"></span>
        <span data-daterange-label class="text-muted-foreground">Pick a date range</span>
      </button>
      <div data-daterange-panel class="popover-panel absolute z-30 mt-1 hidden p-3">
        <div data-calendar-range></div>
      </div>
    </div>
  </div>
</div>
```
