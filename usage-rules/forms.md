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
`<.input_otp>` are JS-hook components. In LiveView forms:

- Give each a unique, stable `id` (LiveView requirement; never index-based ids in streams).
- They emit values via hidden inputs / events - wire to the changeset explicitly;
  they do not take `field` yet.

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
