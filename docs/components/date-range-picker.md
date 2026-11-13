# Date Range Picker

A popover with two months and optional preset ranges, bound to a form as two ISO dates.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Hidden inputs carry ISO dates (YYYY-MM-DD) and dispatch input + change once a full range is picked (two days or a preset), so phx-change fires once per range, not per click. A half-picked range is dropped when the popover closes. The open popover and label survive LiveView patches; a changed server value wins. A range-change event with { start, end } bubbles from the root.

## Usage guidance

Use when:

- Report periods and filters where the range is one field among several
- Forms that store a start and an end date - bind start_name / end_name
- Common ranges people pick repeatedly - add :preset slots

Don't use for:

- The range is the main control of the page (booking) - use <.range_calendar> inline
- A single date - use <.date_picker>
- Dates far from today (birthdays) - typed inputs are faster than paging months

Sizing: Trigger w-64 at field height; popover p-3, rounded-md, ring + shadow-md; 32px day cells; presets column 9rem with btn-sm rows.

Responsive: Under 640px the months stack and the presets wrap into a row above them. Keep the trigger full width in compact forms.

iOS: Two DatePickers (start, end) with .compact style, plus a Menu of preset ranges; or a sheet with a .graphical DatePicker per endpoint.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Outline field button (aria-haspopup=dialog, aria-expanded) with a calendar icon and the formatted range or placeholder. |
| Popover | role=dialog panel: presets column + calendar, floating-content styles. |
| Presets | Ghost btn-sm rows; one click sets the range, closes, and emits. |
| Calendar | Two role=grid months with the range band: endpoints primary, the span accent, rounded at week edges. |
| Hidden inputs | start_name / end_name, ISO dates, synced by the hook. |

| Property | Value |
| --- | --- |
| Trigger | w-64 default, 2.25rem tall, var(--radius-md) |
| Popover | p-3, rounded-md, ring-1 ring-foreground/10, shadow-md |
| Day cell | 2rem x 2rem, rounded-md |
| Presets column | 9rem, end border, 0.75rem gap |

Tokens used: `popover`, `popover-foreground`, `primary`, `primary-foreground`, `accent`, `accent-foreground`, `muted-foreground`, `border-color`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space | Open the popover; focus moves to the calendar |
| Arrows | Move a day / week |
| Home / End | Start / end of the week |
| PageUp / PageDown | Previous / next month (Shift: year) |
| Enter / Space on a day | Pick the start, then the end |
| Tab | Reach the presets and month buttons |
| Esc | Close (drops a half-picked range) and return focus to the trigger |

Role / ARIA: The trigger is a button with aria-haspopup=dialog and aria-expanded; the popover is role=dialog named by the placeholder; each month is a role=grid of gridcells with full date labels and aria-selected on the endpoints.

Focus: Opening with the keyboard focuses the calendar's tab stop (the start date, else today). Picking a full range or a preset closes the popover and focus returns to the trigger.

Screen reader: The trigger reads the committed range ("Oct 4 – Oct 11, 2026"); day cells read their full localized date and selected state. While picking, the label shows "Oct 4 – …".

Touch target: Day cells are 32px - pad the popover or switch to <.range_calendar> in a sheet for touch-first flows. Preset rows are 32px; give them a full-width sheet on compact.

Reduced motion: The popover toggles without movement.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
@State private var from = Date.now.addingTimeInterval(-6 * 86_400)
@State private var to = Date.now

HStack {
    DatePicker("From", selection: $from, in: ...to, displayedComponents: .date)
    DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
    Menu("Presets") {
        Button("Last 7 days") { (from, to) = (.now.addingTimeInterval(-6 * 86_400), .now) }
        Button("Last 30 days") { (from, to) = (.now.addingTimeInterval(-29 * 86_400), .now) }
    }
}
.labelsHidden()
```

SwiftUI has no range DatePicker; two bounded compact pickers plus a presets Menu is the platform pattern. MultiDatePicker selects discrete days, not a span.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| start / end | Date \| ISO string | nil |
| start_name / end_name | string (form field names) | nil |
| months | integer | 2 |
| placeholder | string | "Pick a date range" |
| :preset label start end | slot | - |
| :preset label days | slot (last N days ending today) | - |

## Presets

HEEx:

```heex
<.date_range id="period">
  <:preset label="Today" days={1} />
  <:preset label="Last 7 days" days={7} />
  <:preset label="Last 30 days" days={30} />
  <:preset label="Last 90 days" days={90} />
</.date_range>
```

```html
<div id="period" data-daterange data-months="2" data-placeholder="Pick a date range" class="relative w-64">
  <button type="button" data-daterange-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
    <span class="hero-calendar size-4 opacity-70" aria-hidden="true"></span>
    <span data-daterange-label class="truncate text-muted-foreground">Pick a date range</span>
  </button>
  <div data-daterange-panel role="dialog" aria-label="Pick a date range" class="popover-panel absolute z-50 mt-1 hidden p-3">
    <div class="flex flex-col gap-3 sm:flex-row">
      <div class="flex flex-wrap gap-1 border-border sm:w-36 sm:flex-col sm:flex-nowrap sm:border-e sm:pe-3">
        <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="1">Today</button>
        <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="7">Last 7 days</button>
        <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="30">Last 30 days</button>
        <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="90">Last 90 days</button>
      </div>
      <div data-calendar-range></div>
    </div>
  </div>
</div>
```

## Form

HEEx:

```heex
<.form for={@form} id="report-form" phx-change="filter" class="space-y-2">
  <.date_range
    id="report-period"
    start_name={@form[:from].name}
    end_name={@form[:to].name}
    start={@form[:from].value}
    end={@form[:to].value}
  >
    <:preset label="Last 7 days" start={Date.add(@today, -6)} end={@today} />
    <:preset label="This month" start={Date.beginning_of_month(@today)} end={@today} />
  </.date_range>
</.form>
```

```html
<form class="space-y-2">
  <div id="report-period" data-daterange data-months="2" data-start="2026-10-01" data-end="2026-10-09" data-placeholder="Pick a date range" class="relative w-64">
    <input type="hidden" name="report[from]" value="2026-10-01" data-range-start />
    <input type="hidden" name="report[to]" value="2026-10-09" data-range-end />
    <button type="button" data-daterange-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
      <span class="hero-calendar size-4 opacity-70" aria-hidden="true"></span>
      <span data-daterange-label class="truncate">Oct 1 – Oct 9, 2026</span>
    </button>
    <div data-daterange-panel role="dialog" aria-label="Pick a date range" class="popover-panel absolute z-50 mt-1 hidden p-3">
      <div class="flex flex-col gap-3 sm:flex-row">
        <div class="flex flex-wrap gap-1 border-border sm:w-36 sm:flex-col sm:flex-nowrap sm:border-e sm:pe-3">
          <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-days="7">Last 7 days</button>
          <button type="button" class="btn btn-ghost btn-sm justify-start font-normal" data-daterange-preset data-start="2026-10-01" data-end="2026-10-09">Oct 1 – 9</button>
        </div>
        <div data-calendar-range></div>
      </div>
    </div>
  </div>
</form>
```
