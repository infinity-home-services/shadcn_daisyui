# Time Field

A labelled time picker bound to a form field: the label above, the picker full width, the field's errors under it.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Posts a 24-hour HH:MM, which an Ecto :time field casts. Errors show under the picker once the field was used or the form submitted (Phoenix's used_input?/1), translated like <.input>'s. The label points at the picker's trigger (the field's id), so clicking it opens the picker and screen readers name it. Needs the ShadcnTimePicker hook. The record page on the dev server (`/lab/data-table/:id`) validates a delivery window with two of them.

## Usage guidance

Use when:

- A time of day in a form backed by a changeset (opening hours, a delivery window)
- Pairs such as Opens / Closes, side by side from sm

Don't use for:

- A time outside a form (a filter, a toolbar) - use <.time_picker> with aria-label
- Durations - use a number input or a select of lengths
- Date and time together - a date picker and a time field side by side

Sizing: A column: text-sm medium label, 8px, the full-width h-9 picker (44px on touch), then any error. Fields 16px apart, like the rest of the form.

Responsive: Full width of its column; pairs go in a grid that stacks on phones (grid gap-4 sm:grid-cols-2).

iOS: DatePicker("Opens", selection:, displayedComponents: .hourAndMinute) in a Form row.

## Specs

| Part | Description |
| --- | --- |
| Label | label for the trigger: text-sm, 500. |
| Picker | <.time_picker full_width>: trigger, popover of columns, hidden input. |
| Error | <.error> per message, under the picker. |

| Property | Value |
| --- | --- |
| Gap | 0.5rem between label, picker and error |
| Trigger | full width, 2.25rem (2.75rem on touch), var(--radius-md) |
| Minute step | 15 by default |

Tokens used: `foreground`, `input`, `border-color`, `popover`, `primary`, `destructive`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space | Open the picker; focus moves to the hours |
| Up / Down | Previous / next value in the column |
| Left / Right / Tab | Move between columns |
| Enter / Esc | Close and return focus to the trigger |

Role / ARIA: A label for the trigger button (aria-haspopup=dialog); the popover holds a role=listbox per column (Hours, Minutes, AM/PM). An invalid field marks the trigger aria-invalid.

Focus: The 3px ring on the trigger; the field's error doesn't take focus.

Screen reader: The trigger reads the label and the time ("Opens, 9:00 AM"), or "Not set"; the error text follows it.

Touch target: The trigger and options are 44px tall on touch.

Reduced motion: The popover toggles without movement.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Form {
    DatePicker("Opens", selection: $opens, displayedComponents: .hourAndMinute)
    DatePicker("Closes", selection: $closes, displayedComponents: .hourAndMinute)
    if closes <= opens {
        Text("Closes must be after it opens").font(.footnote).foregroundStyle(.red)
    }
}
```

A DatePicker row in a Form is the native labelled time field; show validation as footnote text under it. SwiftUI has no minute step; wrap UIDatePicker (minuteInterval = 15) when you need one.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| field | Phoenix.HTML.FormField (required) | - |
| label | string (required) | - |
| minute_step | integer | 15 |
| hour_cycle | 12 \| 24 | 12 |
| placeholder | string | "Not set" |
| disabled | boolean | false |
| class | any | nil |

## Bound to a form field

HEEx:

```heex
<%!-- @form = to_form(%{"opens" => "09:00"}, as: :store) --%>
<.form for={@form} id="store-form" phx-change="validate">
  <.time_field id="opens" field={@form[:opens]} label="Opens" />
</.form>
```

```html
<div class="w-full max-w-xs">
  <div class="time-field">
    <label for="store_opens" class="time-field-label">Opens</label>
    <div id="opens" data-timepicker data-value="09:00" data-hour-cycle="12" data-full-width data-placeholder="Not set" class="relative w-full">
      <input type="hidden" name="store[opens]" value="09:00" data-timepicker-input>
      <button type="button" id="store_opens" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
        <span data-timepicker-label class="truncate">
          9:00 AM
        </span>
      </button>
      <div data-timepicker-panel role="dialog" aria-label="Not set" class="popover-panel absolute z-50 mt-1 hidden p-1">
        <div class="time-columns">
          <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">
              12
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">
              1
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">
              2
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">
              3
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">
              4
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">
              5
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">
              6
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">
              7
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="8">
              8
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="9">
              9
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">
              10
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">
              11
            </button>
          </div>
          <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="0">
              00
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">
              15
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="30">
              30
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">
              45
            </button>
          </div>
          <div role="listbox" aria-label="AM/PM" class="time-col" data-time-col="p">
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="AM">
              AM
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="PM">
              PM
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

## With an error

HEEx:

```heex
<.form for={@form} id="window-form" phx-change="validate">
  <div class="grid gap-4 sm:grid-cols-2">
    <.time_field id="window-opens" field={@form[:opens]} label="Opens" />
    <.time_field id="window-closes" field={@form[:closes]} label="Closes" />
  </div>
</.form>

def handle_event("validate", %{"window" => params}, socket) do
  {:noreply, assign(socket, form: to_form(params, as: :window, errors: errors(params), action: :validate))}
end
```

```html
<div class="grid w-full max-w-md gap-4 sm:grid-cols-2">
  <div class="time-field">
    <label for="window_opens" class="time-field-label">Opens</label>
    <div id="window-opens" data-timepicker data-value="09:00" data-hour-cycle="12" data-full-width data-placeholder="Not set" class="relative w-full">
      <input type="hidden" name="window[opens]" value="09:00" data-timepicker-input>
      <button type="button" id="window_opens" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
        <span data-timepicker-label class="truncate">
          9:00 AM
        </span>
      </button>
      <div data-timepicker-panel role="dialog" aria-label="Not set" class="popover-panel absolute z-50 mt-1 hidden p-1">
        <div class="time-columns">
          <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">
              12
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">
              1
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">
              2
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">
              3
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">
              4
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">
              5
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">
              6
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">
              7
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="8">
              8
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="9">
              9
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">
              10
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">
              11
            </button>
          </div>
          <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="0">
              00
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">
              15
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="30">
              30
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">
              45
            </button>
          </div>
          <div role="listbox" aria-label="AM/PM" class="time-col" data-time-col="p">
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="AM">
              AM
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="PM">
              PM
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="time-field">
    <label for="window_closes" class="time-field-label">Closes</label>
    <div id="window-closes" data-timepicker data-value="08:30" data-hour-cycle="12" data-full-width data-placeholder="Not set" class="relative w-full">
      <input type="hidden" name="window[closes]" value="08:30" data-timepicker-input>
      <button type="button" id="window_closes" data-timepicker-trigger aria-haspopup="dialog" aria-expanded="false" aria-invalid="true" class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
        <span data-timepicker-label class="truncate">
          8:30 AM
        </span>
      </button>
      <div data-timepicker-panel role="dialog" aria-label="Not set" class="popover-panel absolute z-50 mt-1 hidden p-1">
        <div class="time-columns">
          <div role="listbox" aria-label="Hours" class="time-col" data-time-col="h">
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="12">
              12
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="1">
              1
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="2">
              2
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="3">
              3
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="4">
              4
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="5">
              5
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="6">
              6
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="7">
              7
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="8">
              8
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="9">
              9
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="10">
              10
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="11">
              11
            </button>
          </div>
          <div role="listbox" aria-label="Minutes" class="time-col" data-time-col="m">
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="0">
              00
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="15">
              15
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="30">
              30
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="45">
              45
            </button>
          </div>
          <div role="listbox" aria-label="AM/PM" class="time-col" data-time-col="p">
            <button type="button" role="option" tabindex="-1" aria-selected="true" class="time-option" data-value="AM">
              AM
            </button>
            <button type="button" role="option" tabindex="-1" aria-selected="false" class="time-option" data-value="PM">
              PM
            </button>
          </div>
        </div>
      </div>
    </div>
    <p class="mt-1.5 flex items-center gap-1.5 text-sm text-error">
      <span class="hero-exclamation-circle size-4 shrink-0" aria-hidden="true"></span>
      must be after it opens
    </p>
  </div>
</div>
```
