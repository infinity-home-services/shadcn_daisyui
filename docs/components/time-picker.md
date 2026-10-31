# Time Picker

A field-style trigger that opens hour, minute and AM/PM columns, bound to a form as an ISO time.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

The hidden input carries a 24-hour ISO time (HH:MM, or HH:MM:SS with seconds), which an Ecto :time field casts. Every pick commits and dispatches input + change, so phx-change fires; picking a minute before an hour starts from midnight. The open popover and label survive LiveView patches; a changed server value wins. A time-change event with { value } bubbles from the root.

## Usage guidance

Use when:

- A time of day in a form: opening hours, a meeting start, a reminder
- Times on a fixed grid - set minute_step (15 for scheduling)
- Pair with <.date_picker> when a date and a time are separate fields

Don't use for:

- Durations (1h 30m) - use number inputs or a select of lengths
- Fast keyboard entry of many times - a native <input type="time"> types faster
- A handful of fixed slots - show them as a <.select> or a toggle group

Sizing: Trigger w-40 at field height; popover p-1, rounded-md, ring + shadow-md; columns 14rem tall, 2.75rem x 2rem options, 1px border between columns.

Responsive: Use full_width in compact forms and sheets: the trigger fills the row and grows to 44px on touch, and options grow to 44px.

iOS: DatePicker with displayedComponents: .hourAndMinute (.compact in forms, .wheel inline). Use a minuteInterval on a UIDatePicker for stepped minutes.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Outline field button (aria-haspopup=dialog, aria-expanded) with a clock icon and the formatted time or placeholder. |
| Popover | role=dialog panel holding the columns, floating-content styles. |
| Columns | One role=listbox per part (Hours, Minutes, Seconds, AM/PM), scrolling on their own, divided by a 1px border. |
| Option | role=option button: accent on hover, primary fill when selected, tabular numbers. |
| Hidden input | name, ISO time, synced by the hook. |

| Property | Value |
| --- | --- |
| Trigger | w-40 default, 2.25rem tall, var(--radius-md) |
| Popover | p-1, rounded-md, ring-1 ring-foreground/10, shadow-md |
| Column | max 14rem tall, 0.25rem padding, 2px gap, scrollbar hidden |
| Option | 2.75rem x 2rem (3rem x 2.75rem on touch), rounded-sm |

Tokens used: `popover`, `popover-foreground`, `primary`, `primary-foreground`, `accent`, `accent-foreground`, `border-color`, `input`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space | Open the popover; focus moves to the hours column |
| Up / Down | Pick the previous / next value in the column |
| Home / End | First / last value in the column |
| Left / Right | Move to the previous / next column |
| Tab | Move between columns |
| Enter | Close and return focus to the trigger |
| Esc | Close and return focus to the trigger |

Role / ARIA: The trigger is a button with aria-haspopup=dialog and aria-expanded; the popover is role=dialog named by the placeholder. Each column is a role=listbox named Hours, Minutes, Seconds or AM/PM; options are role=option with aria-selected. Name the control with a <label for> on the trigger (field binding sets its id to the field id), aria-label or aria-labelledby.

Focus: Each column has one tab stop, its selected value (else the first). Opening scrolls every column so its value sits at the top.

Screen reader: The trigger reads the committed time ("2:30 PM"); each column announces its name and each option its value and selected state.

Touch target: Options are 44px tall on coarse pointers; pass full_width for a 44px trigger in sheets and compact forms.

Reduced motion: The popover toggles and columns jump without animation.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
@State private var opensAt = Calendar.current.date(from: DateComponents(hour: 9))!

DatePicker("Opens at", selection: $opensAt, displayedComponents: .hourAndMinute)
    .datePickerStyle(.compact)
```

A compact hourAndMinute DatePicker is the native trigger-plus-popover equivalent and follows the device's 12/24-hour setting. SwiftUI has no minute step; wrap UIDatePicker (minuteInterval = 15) when you need one.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| field | Phoenix.HTML.FormField | nil |
| name / value | string / Time \| ISO string | nil |
| hour_cycle | 12 \| 24 | 12 |
| minute_step | integer | 1 |
| seconds | boolean | false |
| placeholder | string | "Pick a time" |
| full_width | boolean | false |
| disabled | boolean | false |
| aria-label / aria-labelledby | string | nil |

## Default (15-minute steps)

HEEx:

```heex
<.time_picker id="meeting-time" minute_step={15} aria-label="Meeting time" />
```

```html
<div id="meeting-time" data-timepicker data-hour-cycle="12" data-placeholder="Pick a time" class="relative w-40">
  <button type="button" id="meeting-time-trigger" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" aria-label="Meeting time" class="btn btn-outline w-full justify-start gap-2 font-normal">
    <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
    <span data-timepicker-label class="truncate text-muted-foreground">Pick a time</span>
  </button>
  <div data-timepicker-panel role="dialog" aria-label="Pick a time" class="popover-panel absolute z-50 mt-1 hidden p-1">
    <div class="time-columns">
        <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">12</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">1</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">2</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">3</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">4</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">5</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">6</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">7</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="8">8</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="9">9</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">10</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">11</button>
        </div>
        <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="0">00</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">15</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="30">30</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">45</button>
        </div>
        <div role="listbox" aria-label="AM/PM" class="time-col" data-time-col="p">
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="AM">AM</button>
          <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="PM">PM</button>
        </div>
    </div>
  </div>
</div>
```

## Form (24-hour, full width)

HEEx:

```heex
<.form for={@form} id="store-form" phx-change="validate" class="w-full max-w-sm space-y-2">
  <.label for={@form[:opens_at].id}>Opens at</.label>
  <.time_picker
    id="opens-at"
    field={@form[:opens_at]}
    hour_cycle={24}
    minute_step={15}
    full_width
  />
</.form>
```

```html
<form class="w-full max-w-sm space-y-2">
  <label for="store_opens_at" class="text-sm font-medium">Opens at</label>
  <div id="opens-at" data-timepicker data-value="09:00" data-hour-cycle="24" data-full-width data-placeholder="Pick a time" class="relative w-full">
    <input type="hidden" name="store[opens_at]" value="09:00" data-timepicker-input />
    <button type="button" id="store_opens_at" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
      <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
      <span data-timepicker-label class="truncate">09:00</span>
    </button>
    <div data-timepicker-panel role="dialog" aria-label="Pick a time" class="popover-panel absolute z-50 mt-1 hidden p-1">
      <div class="time-columns">
          <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="0">00</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">01</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">02</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">03</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">04</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">05</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">06</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">07</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="8">08</button>
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="9">09</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">10</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">11</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">12</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="13">13</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="14">14</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">15</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="16">16</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="17">17</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="18">18</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="19">19</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="20">20</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="21">21</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="22">22</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="23">23</button>
          </div>
          <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="0">00</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">15</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="30">30</button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">45</button>
          </div>
      </div>
    </div>
  </div>
</form>
```
