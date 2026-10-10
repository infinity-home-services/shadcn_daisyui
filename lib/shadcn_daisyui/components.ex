defmodule ShadcnDaisyui.Components do
  @moduledoc """
  Phoenix function components styled by the shadcn-daisyui theme.

  Most components are thin wrappers over daisyUI classes (so the theme does the
  styling). The interactive ones render the markup the JS hooks expect and set
  `phx-hook="Shadcn…"` - add the hooks to your `LiveSocket` (see the README).

      use ShadcnDaisyui.Components
      # or: import ShadcnDaisyui.Components

  Anything not wrapped here is still available as plain daisyUI classes
  (`btn`, `card`, `tabs tabs-box`, …) - the theme styles them automatically.

  `use ShadcnDaisyui.Components` also imports `ShadcnDaisyui.FormComponents`
  (field-aware form controls). The generator-compatible `button`, `input`,
  `flash`, `table`, … live in `ShadcnDaisyui.CoreComponents` - apps normally get
  those through their own `CoreComponents` module.
  """
  use Phoenix.Component

  defmacro __using__(_opts) do
    quote do
      import(ShadcnDaisyui.Components)
      import(ShadcnDaisyui.Components.Overlay)
      import(ShadcnDaisyui.Components.Navigation)
      import(ShadcnDaisyui.Components.Display)
      import(ShadcnDaisyui.Components.Conversation)
      import(ShadcnDaisyui.FormComponents)
    end
  end

  # ----------------------------------------------------------------------------
  # Badge
  # ----------------------------------------------------------------------------
  @badge_variants %{
    "default" => "badge-primary",
    "secondary" => "badge-secondary",
    "outline" => "badge-outline",
    "destructive" => "badge-error"
  }

  @doc "A badge. Variants: default, secondary, outline, destructive."
  attr(:variant, :string, default: "default", values: ~w(default secondary outline destructive))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    assigns = assign(assigns, :vclass, @badge_variants[assigns.variant])

    ~H"""
    <span class={["badge", @vclass, @class]} {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  # ----------------------------------------------------------------------------
  # Alert
  # ----------------------------------------------------------------------------
  @doc """
  An alert. Variant `default` or `destructive`.

      <.alert variant="destructive">
        <:title>Error</:title>
        Your session has expired.
      </.alert>
  """
  attr(:variant, :string, default: "default", values: ~w(default destructive))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:title)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div class={["alert", @variant == "destructive" && "alert-error", @class]} role="alert" {@rest}>
      <div>
        <h3 :if={@title != []} class="text-sm font-medium">{render_slot(@title)}</h3>
        <p class="text-sm text-muted-foreground">{render_slot(@inner_block)}</p>
      </div>
    </div>
    """
  end

  # ----------------------------------------------------------------------------
  # Card (+ subcomponents)
  # ----------------------------------------------------------------------------
  @doc "A card container. Compose with the card_* helpers or just put a `.card-body` inside."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["card", @class]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card_body(assigns) do
    ~H"""
    <div class={["card-body", @class]}>{render_slot(@inner_block)}</div>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card_title(assigns) do
    ~H"""
    <h3 class={["card-title", @class]}>{render_slot(@inner_block)}</h3>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card_description(assigns) do
    ~H"""
    <p class={["text-sm text-muted-foreground", @class]}>{render_slot(@inner_block)}</p>
    """
  end

  # ----------------------------------------------------------------------------
  # Separator
  # ----------------------------------------------------------------------------
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:class, :any, default: nil)

  def separator(assigns) do
    ~H"""
    <div class={["divider", @orientation == "vertical" && "divider-horizontal", @class]}></div>
    """
  end

  # ============================================================================
  # Interactive (paired with JS hooks). Each needs an `id`.
  # ============================================================================

  @doc "An inline month calendar (single-date)."
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)

  def calendar(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnCalendar" phx-update="ignore" data-calendar class={@class}></div>
    """
  end

  @doc "A date picker button that opens a calendar popover."
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Pick a date")
  attr(:class, :any, default: "w-60")

  def date_picker(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnDatePicker" data-datepicker class={["relative", @class]}>
      <button type="button" data-datepicker-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="size-4 opacity-70 hero-calendar" aria-hidden="true"></span>
        <span data-datepicker-label class="truncate text-muted-foreground">{@placeholder}</span>
      </button>
      <div data-datepicker-panel class="popover-panel absolute z-50 mt-1 hidden p-3">
        <div id={"#{@id}-calendar"} phx-update="ignore" data-calendar></div>
      </div>
    </div>
    """
  end

  @doc """
  A date range picker: a trigger that opens two months in a popover, with the
  shadcn range band.

      <.date_range id="period" />

  Bind it to a form like `range_calendar/1`: name the two hidden inputs it
  emits (ISO `YYYY-MM-DD`; the JS hook dispatches `input` + `change` once a
  full range is picked, so `phx-change` fires):

      <.date_range
        id="report-period"
        start_name={@form[:from].name}
        end_name={@form[:to].name}
        start={@form[:from].value}
        end={@form[:to].value}
      >
        <:preset label="Last 7 days" start={Date.add(@today, -6)} end={@today} />
        <:preset label="Last 30 days" start={Date.add(@today, -29)} end={@today} />
        <:preset label="This month" start={Date.beginning_of_month(@today)} end={@today} />
      </.date_range>

  `:preset` slots render a list of one-click ranges beside the calendar
  (above it on compact screens). Give each `start` + `end`, or `days={7}` for
  "the last 7 days ending today" in the browser's time zone (handy on cached or
  static pages, where server-computed dates go stale). A half-picked range is discarded when the
  popover closes. The open popover and the label survive LiveView patches,
  and a changed server value (`start` / `end`) wins. A `range-change` event
  with `%{start, end}` bubbles from the root.
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Pick a date range")
  attr(:start, :any, default: nil, doc: "preselected start (Date or ISO string)")
  attr(:end, :any, default: nil, doc: "preselected end (Date or ISO string)")
  attr(:start_name, :string, default: nil, doc: "form name for the start date input")
  attr(:end_name, :string, default: nil, doc: "form name for the end date input")
  attr(:months, :integer, default: 2, doc: "months shown side by side (1 or 2)")
  attr(:class, :any, default: "w-64")
  attr(:rest, :global)

  slot :preset, doc: "a one-click range: `start` + `end`, or `days`" do
    attr(:label, :string, required: true)
    attr(:start, :any, doc: "Date or ISO string")
    attr(:end, :any, doc: "Date or ISO string")
    attr(:days, :integer, doc: "the last N days ending today, computed in the browser")
  end

  def date_range(assigns) do
    assigns =
      assigns
      |> assign(:start_iso, iso_date(assigns.start))
      |> assign(:end_iso, iso_date(assigns.end))
      |> assign(:range_label, range_label(assigns.start, assigns.end))

    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnDateRange"
      data-daterange
      data-months={@months}
      data-start={@start_iso}
      data-end={@end_iso}
      data-placeholder={@placeholder}
      class={["relative", @class]}
      {@rest}
    >
      <input :if={@start_name} type="hidden" name={@start_name} value={@start_iso} data-range-start />
      <input :if={@end_name} type="hidden" name={@end_name} value={@end_iso} data-range-end />
      <button
        type="button"
        data-daterange-trigger
        aria-haspopup="dialog"
        aria-expanded="false"
        class="btn btn-outline w-full justify-start gap-2 font-normal"
      >
        <span class="size-4 opacity-70 hero-calendar" aria-hidden="true"></span>
        <span data-daterange-label class={["truncate", !@range_label && "text-muted-foreground"]}>
          {@range_label || @placeholder}
        </span>
      </button>
      <div
        data-daterange-panel
        role="dialog"
        aria-label={@placeholder}
        class="popover-panel absolute z-50 mt-1 hidden p-3"
      >
        <div class={@preset != [] && "flex flex-col gap-3 sm:flex-row"}>
          <div
            :if={@preset != []}
            class="flex flex-wrap gap-1 border-border sm:w-36 sm:flex-col sm:flex-nowrap sm:border-e sm:pe-3"
          >
            <button
              :for={p <- @preset}
              type="button"
              class="btn btn-ghost btn-sm justify-start font-normal"
              data-daterange-preset
              data-start={iso_date(p[:start])}
              data-end={iso_date(p[:end])}
              data-days={p[:days]}
            >
              {p.label}
            </button>
          </div>
          <div id={"#{@id}-calendar"} phx-update="ignore" data-calendar-range></div>
        </div>
      </div>
    </div>
    """
  end

  # en-US "Oct 4 – Oct 11, 2026", matching the JS label so nothing jumps on mount.
  defp range_label(start, finish) do
    with %Date{} = s <- to_date(start), %Date{} = e <- to_date(finish) do
      Calendar.strftime(s, "%b %-d") <> " – " <> Calendar.strftime(e, "%b %-d, %Y")
    else
      _ -> nil
    end
  end

  defp to_date(%Date{} = d), do: d

  defp to_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp to_date(_), do: nil

  @doc """
  A time picker: a field-style trigger that opens scrollable hour, minute
  (optional second) and AM/PM columns in a popover.

      <.time_picker id="start-time" />

  Bind it to a form with `field` (or `name` + `value`). It emits one hidden
  input with a 24-hour ISO time (`HH:MM`, or `HH:MM:SS` with `seconds`), which
  an Ecto `:time` field casts directly. Every pick dispatches `input` +
  `change`, so `phx-change` fires:

      <.time_picker id="opens-at" field={@form[:opens_at]} minute_step={15} />

  `hour_cycle={24}` drops the AM/PM column. `value` takes a `Time` or an ISO
  string. The open popover and label survive LiveView patches, and a changed
  server value wins. A `time-change` event with `%{value}` bubbles from the
  root.
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Pick a time")
  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "form field: derives name and value")
  attr(:name, :string, default: nil, doc: "form field name; emits a hidden input when set")
  attr(:value, :any, default: nil, doc: "current/preselected time (Time or ISO string)")
  attr(:hour_cycle, :integer, default: 12, values: [12, 24])
  attr(:minute_step, :integer, default: 1, doc: "minutes between options (1, 5, 15, …)")
  attr(:seconds, :boolean, default: false, doc: "adds a seconds column; value is HH:MM:SS")
  attr(:full_width, :boolean, default: false, doc: "fill the container; 44px trigger on touch")
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "root classes; the width defaults to `w-40`")

  attr(:"aria-label", :string,
    default: nil,
    doc: "accessible name when no `<label for>` points at the trigger"
  )

  attr(:"aria-labelledby", :string, default: nil)
  attr(:rest, :global)

  def time_picker(assigns) do
    {name, value, field_id, invalid} =
      case assigns.field do
        %Phoenix.HTML.FormField{} = f ->
          {assigns.name || f.name, if(is_nil(assigns.value), do: f.value, else: assigns.value),
           f.id, f.errors != [] and Phoenix.Component.used_input?(f)}

        nil ->
          {assigns.name, assigns.value, nil, false}
      end

    time = to_time(value)
    twelve = assigns.hour_cycle == 12

    columns =
      [
        {"h", "Hours",
         if(twelve,
           do: Enum.map([12 | Enum.to_list(1..11)], &{&1, Integer.to_string(&1)}),
           else: Enum.map(0..23, &{&1, pad2(&1)})
         ), time && if(twelve, do: hour12(time.hour), else: time.hour)},
        {"m", "Minutes", Enum.map(0..59//max(assigns.minute_step, 1), &{&1, pad2(&1)}),
         time && time.minute},
        assigns.seconds &&
          {"s", "Seconds", Enum.map(0..59, &{&1, pad2(&1)}), time && time.second},
        twelve &&
          {"p", "AM/PM", [{"AM", "AM"}, {"PM", "PM"}],
           time && if(time.hour < 12, do: "AM", else: "PM")}
      ]
      |> Enum.filter(& &1)

    width =
      cond do
        assigns.full_width -> "w-full"
        is_nil(assigns.class) -> "w-40"
        true -> nil
      end

    assigns =
      assign(assigns,
        name: name,
        iso: time_iso(time, assigns.seconds),
        time_label: time_label(time, twelve, assigns.seconds),
        columns: columns,
        invalid: invalid,
        width: width,
        trigger_id:
          if(field_id && field_id != assigns.id, do: field_id, else: "#{assigns.id}-trigger")
      )

    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnTimePicker"
      data-timepicker
      data-value={@iso}
      data-hour-cycle={@hour_cycle}
      data-seconds={@seconds}
      data-full-width={@full_width}
      data-placeholder={@placeholder}
      class={["relative", @width, @class]}
      {@rest}
    >
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value={@iso || ""}
        disabled={@disabled}
        data-timepicker-input
      />
      <button
        type="button"
        id={@trigger_id}
        data-timepicker-trigger
        aria-haspopup="dialog"
        aria-expanded="false"
        aria-invalid={@invalid && "true"}
        aria-label={assigns[:"aria-label"]}
        aria-labelledby={assigns[:"aria-labelledby"]}
        disabled={@disabled}
        class="btn btn-outline w-full justify-start gap-2 font-normal"
      >
        <span class="hero-clock size-4 opacity-70" aria-hidden="true"></span>
        <span data-timepicker-label class={["truncate", !@time_label && "text-muted-foreground"]}>
          {@time_label || @placeholder}
        </span>
      </button>
      <div
        data-timepicker-panel
        role="dialog"
        aria-label={@placeholder}
        class="popover-panel absolute z-50 mt-1 hidden p-1"
      >
        <div class="time-columns">
          <div
            :for={{key, label, options, selected} <- @columns}
            role="listbox"
            aria-label={label}
            class="time-col"
            data-time-col={key}
          >
            <button
              :for={{value, text} <- options}
              type="button"
              role="option"
              tabindex="-1"
              aria-selected={to_string(value == selected)}
              class="time-option"
              data-value={value}
            >
              {text}
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp to_time(%Time{} = t), do: t

  defp to_time(value) when is_binary(value) do
    value = if Regex.match?(~r/^\d{2}:\d{2}$/, value), do: value <> ":00", else: value

    case Time.from_iso8601(value) do
      {:ok, t} -> t
      _ -> nil
    end
  end

  defp to_time(_), do: nil

  defp pad2(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  defp hour12(h), do: if(rem(h, 12) == 0, do: 12, else: rem(h, 12))

  defp time_iso(nil, _), do: nil
  defp time_iso(t, false), do: pad2(t.hour) <> ":" <> pad2(t.minute)
  defp time_iso(t, true), do: time_iso(t, false) <> ":" <> pad2(t.second)

  # "2:30 PM" / "14:30" (seconds appended), matching the JS label so nothing jumps on mount.
  defp time_label(nil, _, _), do: nil

  defp time_label(t, twelve, seconds) do
    hour = if twelve, do: Integer.to_string(hour12(t.hour)), else: pad2(t.hour)
    secs = if seconds, do: ":" <> pad2(t.second), else: ""
    period = if twelve, do: if(t.hour < 12, do: " AM", else: " PM"), else: ""
    hour <> ":" <> pad2(t.minute) <> secs <> period
  end

  @doc """
  An inline calendar for picking a date range (shadcn's Range Calendar). Click a
  start day, then an end day; the band between them is highlighted. Arrow keys,
  Home/End, and PageUp/PageDown move focus.

      <.range_calendar id="stay" months={2} class="rounded-md border border-base-300 p-3" />

  To bind it to a form, name the two hidden inputs it emits (ISO
  `YYYY-MM-DD`; the JS hook keeps them in sync and dispatches `input` +
  `change`, so `phx-change` fires):

      <.range_calendar
        id="booking-dates"
        start_name="booking[check_in]"
        end_name="booking[check_out]"
        start={@form[:check_in].value}
        end={@form[:check_out].value}
      />

  A `range-change` DOM event with `%{start, end}` also bubbles from the root.
  """
  attr(:id, :string, required: true)
  attr(:months, :integer, default: 1, doc: "months shown side by side (1 or 2)")
  attr(:start, :any, default: nil, doc: "preselected start (Date or ISO string)")
  attr(:end, :any, default: nil, doc: "preselected end (Date or ISO string)")
  attr(:start_name, :string, default: nil, doc: "form name for the start date input")
  attr(:end_name, :string, default: nil, doc: "form name for the end date input")
  attr(:class, :any, default: "w-fit")
  attr(:rest, :global)

  def range_calendar(assigns) do
    assigns =
      assigns
      |> assign(:start_iso, iso_date(assigns.start))
      |> assign(:end_iso, iso_date(assigns.end))

    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnRangeCalendar"
      data-range-calendar
      data-months={@months}
      data-start={@start_iso}
      data-end={@end_iso}
      class={@class}
      {@rest}
    >
      <input :if={@start_name} type="hidden" name={@start_name} value={@start_iso} data-range-start />
      <input :if={@end_name} type="hidden" name={@end_name} value={@end_iso} data-range-end />
      <div id={"#{@id}-grid"} phx-update="ignore" data-range-calendar-grid></div>
    </div>
    """
  end

  defp iso_date(%Date{} = date), do: Date.to_iso8601(date)
  defp iso_date(value) when is_binary(value) and value != "", do: value
  defp iso_date(_), do: nil

  # ----------------------------------------------------------------------------
  # Select / Combobox. One renderer and one JS engine (`initPicker` in
  # shadcn-daisyui.js) for both, single or `multiple`.
  # ----------------------------------------------------------------------------

  @doc """
  A combobox (searchable select). Provide options as `:option` slots.

      <.combobox id="fw" placeholder="Select framework…">
        <:option value="Next.js">Next.js</:option>
        <:option value="Phoenix">Phoenix</:option>
      </.combobox>

  Bind it to a form with `field` (or `name` + `value`) - it emits a hidden input
  the JS hook keeps in sync and dispatches `input` + `change` on, so `phx-change`
  fires:

      <.combobox id="fw" field={@form[:framework]}>
        <:option value="Next.js">Next.js</:option>
        <:option value="Phoenix">Phoenix</:option>
      </.combobox>

  `multiple` turns every option into a checkbox row (the faceted-filter
  pattern); the list stays open while toggling, the search box stays, and a
  Clear row appears once anything is selected. `value` is then a list and the
  hidden inputs are `name[]` (see `select/1` for the exact params):

      <.combobox id="labels" field={@form[:labels]} multiple placeholder="Labels">
        <:option :for={l <- @labels} value={l.id} count={l.count}>{l.name}</:option>
      </.combobox>
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Select…")

  attr(:search_placeholder, :string,
    default: nil,
    doc: "search box text (defaults to `placeholder`)"
  )

  attr(:empty, :string, default: "No results.", doc: "shown when the search matches nothing")
  attr(:class, :any, default: nil, doc: "root classes; the width defaults to `w-60`")
  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "form field: derives name and value")
  attr(:name, :string, default: nil, doc: "form field name; emits hidden input(s) when set")
  attr(:value, :any, default: nil, doc: "current/preselected value (a list when `multiple`)")
  attr(:multiple, :boolean, default: false, doc: "checkbox rows, many values")
  attr(:full_width, :boolean, default: false, doc: "fill the container; 44px trigger on touch")
  attr(:clear_label, :string, default: "Clear", doc: "the multiple-mode Clear row")
  attr(:disabled, :boolean, default: false)

  attr(:"aria-label", :string,
    default: nil,
    doc: "accessible name when no `<label for>` points at the trigger"
  )

  attr(:"aria-labelledby", :string, default: nil)
  attr(:rest, :global)

  slot :option, doc: "each option; set `value`, optionally `count`" do
    attr(:value, :any, required: true)
    attr(:count, :any, doc: "right-aligned muted number (facet count)")
  end

  def combobox(assigns), do: assigns |> assign(:kind, "combobox") |> picker()

  @doc """
  A custom select (shadcn-style trigger + listbox popover). Provide options as
  `:option` slots.

      <.select id="fruit" placeholder="Select a fruit">
        <:option value="Apple">Apple</:option>
        <:option value="Banana">Banana</:option>
      </.select>

  Bind it to a form with `field` (or `name` + `value`) - it emits a hidden input
  the JS hook keeps in sync and dispatches `input` + `change` on, so `phx-change`
  fires. A preselected value is rendered on the server:

      <.select id="fruit" field={@form[:fruit]}>
        <:option value="Apple">Apple</:option>
        <:option value="Banana">Banana</:option>
      </.select>

  ## Multiple

  `multiple` (bits-ui `Select type="multiple"`): each option becomes a checkbox
  row, the list stays open while toggling, and a Clear row appears once
  anything is selected. The trigger shows the placeholder, or up to two
  selected labels then "+N". Options take an optional `count`:

      <.select id="status" field={@form[:status]} multiple placeholder="Status">
        <:option value="todo" count={12}>Todo</:option>
        <:option value="done" count={4}>Done</:option>
      </.select>

  It emits one `name[]` hidden input per selected value, after an always-present
  `name=""` input, so params are `%{"status" => ["todo", "done"]}` and, when
  cleared, `%{"status" => ""}` (Ecto casts that to the field default, so an
  `{:array, :string}` field with `default: []` clears). Every toggle dispatches
  `input` + `change` on the form. A `select-change` event with
  `%{value: [...]}` also bubbles from the root (`combobox-change` for the
  combobox).

  The open list, the label and the checks survive LiveView patches. The
  server's value wins whenever it changes (a reset, a cap); echoes of the
  user's own changes are ignored, so fast toggling never flickers.

  For the plain HTML control use `<.native_select>` / `<select class="select">`.
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Select…")
  attr(:class, :any, default: nil, doc: "root classes; the width defaults to `w-60`")
  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "form field: derives name and value")
  attr(:name, :string, default: nil, doc: "form field name; emits hidden input(s) when set")
  attr(:value, :any, default: nil, doc: "current/preselected value (a list when `multiple`)")
  attr(:multiple, :boolean, default: false, doc: "checkbox rows, many values")
  attr(:full_width, :boolean, default: false, doc: "fill the container; 44px trigger on touch")
  attr(:clear_label, :string, default: "Clear", doc: "the multiple-mode Clear row")
  attr(:disabled, :boolean, default: false)

  attr(:"aria-label", :string,
    default: nil,
    doc: "accessible name when no `<label for>` points at the trigger"
  )

  attr(:"aria-labelledby", :string, default: nil)
  attr(:rest, :global)

  slot :option, doc: "each option; set `value`, optionally `count`" do
    attr(:value, :any, required: true)
    attr(:count, :any, doc: "right-aligned muted number (facet count)")
  end

  def select(assigns), do: assigns |> assign(:kind, "select") |> picker()

  defp picker(assigns) do
    {name, value, field_id, invalid} =
      case assigns.field do
        %Phoenix.HTML.FormField{} = f ->
          {assigns.name || f.name, if(is_nil(assigns.value), do: f.value, else: assigns.value),
           f.id, f.errors != [] and Phoenix.Component.used_input?(f)}

        nil ->
          {assigns.name, assigns.value, nil, false}
      end

    values = picker_values(value, assigns.multiple)
    name = if name && assigns.multiple, do: String.replace_suffix(name, "[]", ""), else: name

    width =
      cond do
        assigns.full_width -> "w-full"
        is_nil(assigns.class) -> "w-60"
        true -> nil
      end

    assigns =
      assign(assigns,
        name: name,
        values: values,
        selected: Enum.filter(assigns.option, &(to_string(&1.value) in values)),
        trigger_id:
          if(field_id && field_id != assigns.id, do: field_id, else: "#{assigns.id}-trigger"),
        list_id: "#{assigns.id}-list",
        invalid: invalid,
        width: width,
        search_placeholder: assigns[:search_placeholder] || assigns.placeholder
      )

    ~H"""
    <div
      id={@id}
      phx-hook={if @kind == "select", do: "ShadcnSelect", else: "ShadcnCombobox"}
      {%{"data-#{@kind}" => true}}
      data-multiple={@multiple}
      data-full-width={@full_width}
      data-placeholder={@placeholder}
      class={["relative", @width, @class]}
      {@rest}
    >
      <input
        :if={@name && !@multiple}
        type="hidden"
        name={@name}
        value={List.first(@values)}
        disabled={@disabled}
        {pd(@kind, "input")}
      />
      <input :if={@name && @multiple} type="hidden" name={@name} value="" disabled={@disabled} {pd(@kind, "sentinel")} />
      <input
        :for={v <- if(@name && @multiple, do: @values, else: [])}
        type="hidden"
        name={@name <> "[]"}
        value={v}
        disabled={@disabled}
        {pd(@kind, "value")}
      />
      <button
        type="button"
        id={@trigger_id}
        role={@kind == "select" && "combobox"}
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={@list_id}
        aria-label={assigns[:"aria-label"]}
        aria-labelledby={assigns[:"aria-labelledby"]}
        aria-invalid={@invalid && "true"}
        disabled={@disabled}
        class="btn btn-outline w-full justify-between font-normal"
        {pd(@kind, "trigger")}
      >
        <span class={["flex min-w-0 items-center gap-1", @selected == [] && "text-muted-foreground"]} {pd(@kind, "label")}>
          <%= if @selected == [] do %>
            <span class="truncate">{@placeholder}</span>
          <% else %>
            <span class="truncate"><%= for {opt, i} <- Enum.with_index(Enum.take(@selected, if(@multiple, do: 2, else: 1))) do %>{if i > 0, do: ", "}{render_slot(opt)}<% end %></span>
            <span :if={length(@selected) > 2} class="shrink-0 text-muted-foreground">+{length(@selected) - 2}<span class="sr-only"> more</span></span>
          <% end %>
        </span>
        <span
          class={["size-4 shrink-0 opacity-50", if(@kind == "select", do: "hero-chevron-down", else: "hero-chevron-up-down")]}
          aria-hidden="true"
        >
        </span>
      </button>
      <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" {pd(@kind, "panel")}>
        <%= if @kind == "combobox" do %>
          <input data-combobox-search class="input mb-1 w-full" placeholder={@search_placeholder} autocomplete="off" />
          <ul
            id={@list_id}
            role="listbox"
            aria-multiselectable={@multiple && "true"}
            class="max-h-60 overflow-auto"
            data-combobox-list
          >
            <li :for={opt <- @option}>
              <.picker_option opt={opt} kind={@kind} multiple={@multiple} values={@values} />
            </li>
          </ul>
          <p data-combobox-empty class="hidden p-2 text-center text-sm text-muted-foreground">{@empty}</p>
        <% else %>
          <div
            id={@list_id}
            role="listbox"
            aria-multiselectable={@multiple && "true"}
            class="max-h-72 overflow-auto"
            data-select-list
          >
            <.picker_option :for={opt <- @option} opt={opt} kind={@kind} multiple={@multiple} values={@values} />
          </div>
        <% end %>
        <div :if={@multiple} class={["-mx-1 mt-1 border-t border-border px-1 pt-1", @values == [] && "hidden"]} {pd(@kind, "clear")}>
          <button type="button" class="combo-item justify-center" {pd(@kind, "clear-btn")}>{@clear_label}</button>
        </div>
      </div>
    </div>
    """
  end

  attr(:opt, :map, required: true)
  attr(:kind, :string, required: true)
  attr(:multiple, :boolean, required: true)
  attr(:values, :list, required: true)

  defp picker_option(assigns) do
    assigns = assign(assigns, :on, to_string(assigns.opt.value) in assigns.values)

    ~H"""
    <button
      type="button"
      tabindex="-1"
      role="option"
      aria-selected={to_string(@on)}
      class="combo-item"
      data-select-item={@kind == "select"}
      data-value={@opt.value}
      data-selected={@on}
    >
      <span :if={@multiple} class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span>
      <span :if={!@multiple} class={["hero-check size-4 shrink-0", !@on && "opacity-0"]} aria-hidden="true"></span>
      <span data-label class="truncate">{render_slot(@opt)}</span>
      <span :if={@opt[:count] != nil} class="ml-auto font-mono text-xs text-muted-foreground">{@opt.count}</span>
    </button>
    """
  end

  defp picker_values(value, _multiple) when value in [nil, ""], do: []

  defp picker_values(values, multiple) when is_list(values) do
    values = for v <- values, v not in [nil, ""], do: to_string(v)
    if multiple, do: Enum.uniq(values), else: Enum.take(values, 1)
  end

  defp picker_values(value, _multiple), do: [to_string(value)]

  # `data-<kind>-<part>` as a dynamic attribute (select and combobox share markup)
  defp pd(kind, part), do: %{"data-#{kind}-#{part}" => true}

  @doc "A segmented one-time-code input."
  attr(:id, :string, required: true)
  attr(:length, :integer, default: 6)
  attr(:group, :integer, default: 3, doc: "insert a separator every `group` slots (0 = none)")
  attr(:class, :any, default: nil)

  def input_otp(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnOtp" data-otp class={["flex items-center gap-2", @class]}>
      <%= for i <- 0..(@length - 1) do %>
        <span :if={@group > 0 and i > 0 and rem(i, @group) == 0} class="text-muted-foreground">-</span>
        <input class="otp-slot" maxlength="1" inputmode="numeric" />
      <% end %>
    </div>
    """
  end

  @doc """
  A carousel. Provide slides as `:slide` slots.

      <.carousel id="c"><:slide>1</:slide><:slide>2</:slide></.carousel>
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: "w-full max-w-sm")
  slot(:slide, required: true)

  def carousel(assigns) do
    ~H"""
    <div class={["relative px-4", @class]}>
      <div id={@id} phx-hook="ShadcnCarousel" data-carousel class="carousel w-full rounded-lg">
        <div :for={s <- @slide} class="carousel-item w-full">{render_slot(s)}</div>
      </div>
      <button type="button" data-carousel-prev class="btn btn-outline btn-circle btn-sm absolute left-0 top-1/2 -translate-y-1/2">
        <span class="size-4 hero-chevron-left" aria-hidden="true"></span>
      </button>
      <button type="button" data-carousel-next class="btn btn-outline btn-circle btn-sm absolute right-0 top-1/2 -translate-y-1/2">
        <span class="size-4 hero-chevron-right" aria-hidden="true"></span>
      </button>
    </div>
    """
  end

  @doc "A two-pane resizable group with a draggable grip."
  attr(:id, :string, required: true)
  attr(:class, :any, default: "h-44 w-full")
  slot(:start, required: true)
  slot(:end_pane, required: true)

  def resizable(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnResizable"
      data-resizable
      class={["flex overflow-hidden rounded-lg border border-base-300 text-sm", @class]}
    >
      <div class="resizable-panel flex items-center justify-center" style="width: 50%">{render_slot(@start)}</div>
      <div class="resizable-handle" role="separator" aria-orientation="vertical" tabindex="0">
        <div class="resizable-grip"><span class="size-2.5 hero-ellipsis-vertical" aria-hidden="true"></span></div>
      </div>
      <div class="resizable-panel flex flex-1 items-center justify-center">{render_slot(@end_pane)}</div>
    </div>
    """
  end
end
