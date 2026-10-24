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
  polymorphic `<.input>`. They follow the field on every re-render (a `phx-change`
  that flips a boolean re-checks the switch); an explicit `checked` / `value` attr
  wins over the field. `<.radio_group>` rows are 44px tall on touch already - don't
  add `min-h-11` / `py-2` to its labels.
- `<.error>` - render a translated error string manually (rare).

## Interactive pickers in forms

`<.combobox>`, `<.select>` (custom listbox), `<.date_picker>`, `<.date_range>`,
`<.time_picker>`, `<.input_otp>` are JS-hook components. In LiveView forms:

- Give each a unique, stable `id` (LiveView requirement; never index-based ids in streams).
- `<.select>` and `<.combobox>` take `field` like `<.input>` (or `name` + `value`).
  The hidden input(s) dispatch `input` + `change`, so `phx-change` fires on every pick.
- A list people may need to extend on the spot (insurers, lead sources, tags) is a
  `<.combobox create on_create="add_…">`. The added text posts like any value; the
  `on_create` handler saves the new option and adds it to the slots:

  ```heex
  <.combobox id="lead-insurer" field={@form[:insurer]} create on_create="add_insurer">
    <:option :for={i <- @insurers} value={i}>{i}</:option>
  </.combobox>
  ```

  ```elixir
  def handle_event("add_insurer", %{"value" => name}, socket) do
    {:ok, _} = Insurers.create(name)
    {:noreply, assign(socket, insurers: Insurers.names())}
  end
  ```
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
  In an edit form use `<.time_field id field label>`: the label above, the picker
  full width ("Not set"), 15-minute steps, and the field's errors under it once
  it was used or the form submitted.
- A single `<.select>` / `<.combobox>` with a `value=""` option ("Default order",
  "Any") shows that option as chosen while the value is blank, and posts `""`.
- Label a picker with `<.label for={@form[:x].id}>` (the trigger takes the field id)
  or `aria-label`. Errors are not rendered by the picker - wrap it in `<.field>`.
- Open lists, labels and values survive LiveView re-renders; if the server changes
  the value (reset, cap) the server wins. `<.date_picker>` is not form-bound yet.

## File uploads

A file upload is `<.dropzone>` on the LiveView upload: a dashed area people drop
files on, or click / tap (Enter, Space) to choose. Picked files show under it as
`<.attachment>` tiles - uploading with progress, done, or the error - and
`on_cancel` gives each one a remove button:

```elixir
socket |> allow_upload(:people_csv, accept: ~w(.csv), max_entries: 1, max_file_size: 1_000_000)

def handle_event("import:cancel", %{"ref" => ref}, socket),
  do: {:noreply, cancel_upload(socket, :people_csv, ref)}
```

```heex
<.form for={@form} id="import" phx-change="validate" phx-submit="import">
  <.dropzone id="import-file" upload={@uploads.people_csv} on_cancel="import:cancel" />
</.form>
```

- Leave out the slots: the title ("Drop a file here, or choose one"; "Choose a
  file" on touch screens) and the description ("One .csv file, up to 1 MB.") come
  from the upload. Word your own with `<:title touch="…">` and `<:description>`.
- In tight forms (a row in a sheet, a settings field) use `size="compact"`: one
  input-height row, labelled like any input (`<.label for={@uploads.logo.ref}>`).
- Errors are built in: each file's on its tile, the upload's (too many files)
  under the zone, all tied to the input. `error_text={fn error -> … end}` rewords
  them (`nil` keeps the default).
- `<:entry :let={entry}>` for a different tile; keep it an `<.attachment>`.
- A plain (non-LiveView) multipart form passes `name` instead of `upload`
  (`accept`, `multiple`).
- Never hand-roll a drop area (`phx-drop-target` on your own div), show a bare
  `<.live_file_input>`, or list picked files as plain text.

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
- A bare `<.live_file_input>` or a hand-rolled drop area - use `<.dropzone>`.
- `Phoenix.HTML.Form.input_value/2` plumbing by hand - pass the `field`.
- Custom error markup - `<.input>`/`<.field>`/`<.error>` already render
  `text-sm text-error` messages tied to the control via aria.
