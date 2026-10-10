# shadcn_daisyui - form rules

All forms bind to `Phoenix.HTML.FormField` via `ShadcnDaisyui.CoreComponents.input/1`
(or the dedicated controls in `ShadcnDaisyui.FormComponents`).

## The one true input

```heex
<.input field={@form[:name]} type="text" label="Name" />
<.input field={@form[:bio]} type="textarea" label="Bio" />
<.input field={@form[:role]} type="select" label="Role" prompt="Pick one" options={["admin", "member"]} />
<.input field={@form[:active]} type="checkbox" label="Active" />
```

- `field` derives `id`, `name`, `value`, and `errors` automatically. Don't pass them
  manually unless there is no form (rare).
- Supported types: all HTML input types plus `"textarea"`, `"select"`, `"checkbox"`.
- Errors display only after the user interacted with the input
  (`Phoenix.Component.used_input?/1`) - same behavior as stock Phoenix 1.8.
- For multi-select pass `multiple`; for select always consider a `prompt`.

## Richer controls (`ShadcnDaisyui.FormComponents`)

- `<.field>` - shadcn Form pattern: wraps label + control + description + errors with
  correct `for` / `aria-describedby` / `aria-invalid` wiring. Use when a control needs
  a description line.
- `<.checkbox>`, `<.switch>`, `<.radio_group>`, `<.textarea>`, `<.native_select>` -
  FormField-aware dedicated controls when you need more layout control than the
  polymorphic `<.input>`.
- `<.error>` - render a translated error string manually (rare).

## Interactive pickers in forms

`<.combobox>`, `<.select>` (custom listbox), `<.date_picker>`, `<.date_range>`,
`<.time_picker>`, `<.input_otp>` are JS-hook components. In LiveView forms:

- Give each a unique, stable `id` (LiveView requirement; never index-based ids in streams).
- `<.select>` and `<.combobox>` take `field` like `<.input>` (or `name` + `value`).
  The hidden input(s) dispatch `input` + `change`, so `phx-change` fires on every pick.
- `multiple` posts a list: `name=""` plus one `name[]` per value. Use an
  `{:array, :string}` field with `default: []` - a cleared picker posts `""`, which
  Ecto casts to the default:

  ```heex
  <.select id="task-status" field={@form[:status]} multiple placeholder="Status">
    <:option :for={s <- @statuses} value={s.id} count={s.count}>{s.name}</:option>
  </.select>
  ```

- `<.date_range>` / `<.range_calendar>` bind two fields with `start_name` / `end_name`
  (+ `start` / `end`); values are ISO `YYYY-MM-DD` strings that cast to `:date`.
  `<.date_range>` emits once per complete range, not per click.
- `<.time_picker>` takes `field` (or `name` + `value`) and posts a 24-hour ISO
  time (`HH:MM`, or `HH:MM:SS` with `seconds`) that casts to `:time`, whatever
  `hour_cycle` the trigger shows. Every pick emits. Use `minute_step` for slots.
- Label a picker with `<.label for={@form[:x].id}>` (the trigger takes the field id)
  or `aria-label`. Errors are not rendered by the picker - wrap it in `<.field>`.
- Open lists, labels and values survive LiveView re-renders; if the server changes
  the value (reset, cap) the server wins. `<.date_picker>` is not form-bound yet.

## Error translation

The package translates errors via the configured MFA:

```elixir
# config/config.exs (the installer writes this)
config :shadcn_daisyui, :translate_error, {MyAppWeb.CoreComponents, :translate_error}
```

Without config it falls back to interpolating `%{count}`-style bindings directly.
Keep Gettext-based translation in the app and point this config at it.

## Never do

- Raw `<input>`/`<select>`/`<textarea>` inside `<.form>`.
- `Phoenix.HTML.Form.input_value/2` plumbing by hand - pass the `field`.
- Custom error markup - `<.input>`/`<.field>`/`<.error>` already render
  `text-sm text-error` messages tied to the control via aria.
