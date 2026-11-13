# Range Calendar

A calendar component that allows users to select a range of dates.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Emits ISO dates (YYYY-MM-DD) into hidden inputs when start_name / end_name are set, dispatching input + change so phx-change fires. A range-change DOM event with { start, end } bubbles from the root.

## Usage guidance

Use when:

- Picking a start and end date in place, where the calendar is the main control (booking, reporting periods)
- Forms that store two date fields (check-in / check-out) - bind start_name / end_name

Don't use for:

- Space is tight or the range is secondary - use <.date_range> (a popover)
- A single date - use <.calendar> or <.date_picker>

Sizing: 32px day cells, 12px padding; one month by default, months={2} side by side on medium screens and up.

Responsive: Two months stack vertically under 640px. Keep the calendar inside a card or bordered box so it reads as one control.

iOS: MultiDatePicker covers discrete days; for a true range, two DatePickers (.graphical) bound to start/end, or a custom grid.

## Specs

| Part | Description |
| --- | --- |
| Root | data-range-calendar wrapper with optional hidden start/end inputs. |
| Navigation | Previous / next month ghost buttons in the top corners. |
| Month grid | Caption, weekday header, and day buttons (role=gridcell). |
| Range band | Endpoints in primary; days between on an accent band. |

| Property | Value |
| --- | --- |
| Day cell | 32px square, var(--radius-md) |
| Endpoints | primary / primary-foreground |
| Band | accent, square inside, rounded at the range ends and week edges |
| Today | 1px border-color ring |
| Months | 1 by default; 2 side by side at ≥ 640px, stacked below |

Tokens used: `primary`, `primary-foreground`, `accent`, `accent-foreground`, `muted-foreground`, `border-color`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus into the grid (one tab stop) and to the month buttons |
| Arrow keys | Move one day / one week; previews the band while picking the end |
| Home / End | Start / end of the week |
| PageUp / PageDown | Previous / next month (Shift: year) |
| Enter / Space | Set the start, then the end |

Role / ARIA: Each month is role=grid labeled with its month and year; days are buttons (role=gridcell) with full-date labels and aria-selected on the endpoints.

Focus: Roving tabindex: the focused, selected, or today's date is the single tab stop; the view follows focus across months.

Screen reader: Day buttons announce the full date and whether they're selected. Echo the chosen range in nearby text (or the form's labels) so it's confirmed after selection.

Touch target: Day cells are 32px; on touch-first layouts scale the grid up (e.g. [--cell:2.75rem]) or use the native date inputs.

Reduced motion: No animation; month changes swap instantly.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
@State private var start = Date()
@State private var end = Date().addingTimeInterval(7 * 86_400)

Form {
    DatePicker("Check-in", selection: $start, displayedComponents: .date)
    DatePicker("Check-out", selection: $end, in: start..., displayedComponents: .date)
}
```

SwiftUI has no range-band calendar. Two bound DatePickers (or MultiDatePicker for discrete days) cover the data; a custom LazyVGrid is needed for the visual band.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| months | integer | 1 |
| start / end | Date \| ISO string | nil |
| start_name / end_name | string (form field names) | nil |

## Default

HEEx:

```heex
<.range_calendar id="range-calendar" class="w-fit rounded-md border border-base-300 p-3" />
```

```html
<div data-range-calendar data-months="1" class="w-fit rounded-md border border-base-300 p-3">
  <div data-range-calendar-grid></div>
</div>
```

## Two months

HEEx:

```heex
<.range_calendar id="report-period" months={2} class="w-fit rounded-md border border-base-300 p-3" />
```

```html
<div data-range-calendar data-months="2" class="w-fit rounded-md border border-base-300 p-3">
  <div data-range-calendar-grid></div>
</div>
```

## Form

HEEx:

```heex
<.form for={@form} id="booking-form" phx-change="validate" phx-submit="save">
  <.range_calendar
    id="booking-dates"
    start_name={@form[:check_in].name}
    end_name={@form[:check_out].name}
    start={@form[:check_in].value}
    end={@form[:check_out].value}
    class="w-fit rounded-md border border-base-300 p-3"
  />
  <.button>Book</.button>
</.form>
```

```html
<form class="flex flex-col items-start gap-3" data-demo-booking>
  <div data-range-calendar data-months="1" class="w-fit rounded-md border border-base-300 p-3">
    <input type="hidden" name="booking[check_in]" data-range-start />
    <input type="hidden" name="booking[check_out]" data-range-end />
    <div data-range-calendar-grid></div>
  </div>
  <button class="btn btn-primary">Book</button>
</form>
```
