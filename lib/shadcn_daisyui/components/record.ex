defmodule ShadcnDaisyui.Components.Record do
  @moduledoc ~S"""
  The parts of a record page: `record_tabs/1` (a tab row inside a record),
  `table_card/1` (a card of rows, such as a record's activity),
  `section_nav/1` (where an edit form's sections are) and `time_field/1` (a
  labelled time picker bound to a form field).

      <.page_header crumbs={@crumbs}>
        {@order.number}
        <:below><.section_nav id="order-sections-select" sections={@sections} variant="select" /></:below>
      </.page_header>

      <.section_nav id="order-sections" sections={@sections}>
        <.card id="customer">…</.card>
        <.card id="items">…</.card>
      </.section_nav>

  `section_nav` needs the `ShadcnSectionNav` hook (in `Hooks`).

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components, only: [time_picker: 1]

  alias Phoenix.LiveView.JS

  # ----------------------------------------------------------------------------
  # Record tabs
  # ----------------------------------------------------------------------------
  @doc ~S"""
  A tab row inside a record (Details, Activity, Files): the active tab is
  underlined. Each tab sends `"tab"` with `%{"tab" => key}`, so the server
  owns which one shows (keep it in the URL with `push_patch/2` if people
  link to it).

      <.record_tabs id="order-tabs" tabs={[{"details", "Details"}, {"activity", "Activity", 12}]} active={@tab} />

      def handle_event("tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, tab: tab)}

  `role="tablist"`, each tab a `role="tab"` button with `aria-selected`. One
  tab stop: Left/Right (and Home/End) move between tabs, Enter or Space
  picks one. A third tuple element is a count shown after the label.
  """
  attr(:id, :string, required: true)
  attr(:tabs, :list, required: true, doc: "[{key, label}] or [{key, label, count}]")
  attr(:active, :any, default: nil, doc: "the active tab's key")
  attr(:event, :string, default: "tab", doc: "the event each tab sends")
  attr(:target, :any, default: nil, doc: "phx-target (a LiveComponent)")
  attr(:aria_label, :string, default: nil, doc: "names the tablist")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def record_tabs(assigns) do
    tabs =
      Enum.map(assigns.tabs, fn
        {key, label} -> {to_string(key), label, nil}
        {key, label, count} -> {to_string(key), label, count}
      end)

    active = assigns.active && to_string(assigns.active)

    active =
      if Enum.any?(tabs, &(elem(&1, 0) == active)),
        do: active,
        else: tabs |> List.first({nil}) |> elem(0)

    assigns = assign(assigns, tab_list: tabs, current: active)

    ~H"""
    <div
      id={@id}
      role="tablist"
      aria-label={@aria_label}
      class={["record-tabs", @class]}
      data-record-tabs
      {@rest}
    >
      <button
        :for={{key, label, count} <- @tab_list}
        type="button"
        role="tab"
        id={"#{@id}-#{key}"}
        class="record-tab"
        aria-selected={to_string(key == @current)}
        tabindex={if key == @current, do: "0", else: "-1"}
        phx-click={tab_push(@event, key, @target)}
      >
        <span class="record-tab-label">{label}</span>
        <span :if={count != nil} class="tab-count">{count}</span>
      </button>
    </div>
    """
  end

  defp tab_push(event, key, nil), do: JS.push(event, value: %{tab: key})
  defp tab_push(event, key, target), do: JS.push(event, value: %{tab: key}, target: target)

  # ----------------------------------------------------------------------------
  # Table card
  # ----------------------------------------------------------------------------
  @doc ~S"""
  A card with a title, a description and rows: a record's activity, its
  line items, its contacts.

      <.table_card id="activity" title="Activity" description="Everything that happened to this order." rows={@events} row_id={&"event-#{&1.id}"}>
        <:col :let={e} label="Event">{e.text}</:col>
        <:col :let={e} label="By" class="text-muted-foreground">{e.by}</:col>
        <:col :let={e} label="When">{e.at}</:col>
        <:empty>Nothing has happened yet.</:empty>
      </.table_card>

  Row separators run edge to edge, and the space under the last row is the
  row's own padding. Column labels show as a header row from `sm`; on phones
  the rows stack their cells, unless `grid` (the rows' grid columns, a
  Tailwind class such as `grid-cols-[minmax(0,1fr)_auto]`) keeps them side by
  side at every width. The rightmost column is right-aligned unless
  `align="left"`. `row_class` (fn row -> classes) styles a row; `:actions`
  sits right of the title.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "fn row -> DOM id")
  attr(:row_class, :any, default: nil, doc: "fn row -> classes")

  attr(:grid, :string,
    default: nil,
    doc:
      "the rows' grid columns, e.g. \"grid-cols-[minmax(0,1fr)_auto]\"; side by side on phones too"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :col, required: true do
    attr(:label, :string)
    attr(:class, :any)
    attr(:align, :string, values: ~w(left right))
  end

  slot(:empty, doc: "shown as the only row when there are none")
  slot(:actions, doc: "right of the title (a link, a small button)")

  def table_card(assigns) do
    last = length(assigns.col) - 1

    assigns =
      assign(assigns,
        cols:
          assigns.col
          |> Enum.with_index()
          |> Enum.map(fn {col, i} ->
            align =
              cond do
                col[:align] -> col[:align]
                i == last and i > 0 -> "right"
                true -> nil
              end

            {col, align}
          end),
        labels: Enum.any?(assigns.col, & &1[:label]),
        count: if(assigns.grid, do: nil, else: min(length(assigns.col), 6))
      )

    ~H"""
    <section id={@id} class={["card table-card", @class]} data-layout={(@grid && "grid") || "stack"} {@rest}>
      <div :if={@title || @description || @actions != []} class="table-card-header">
        <div class="table-card-heading">
          <h3 :if={@title} class="card-title">{@title}</h3>
          <p :if={@description} class="text-sm text-muted-foreground">{@description}</p>
        </div>
        <div :if={@actions != []} class="table-card-actions">{render_slot(@actions)}</div>
      </div>
      <div role="table" aria-label={@title} class="table-card-table">
        <div :if={@labels} role="rowgroup">
          <div role="row" class={["table-card-row table-card-head", @grid]} data-cols={@count}>
            <div :for={{col, align} <- @cols} role="columnheader" class={["table-card-cell", col[:class]]} data-align={align}>
              {col[:label]}
            </div>
          </div>
        </div>
        <div role="rowgroup">
          <div
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            role="row"
            class={["table-card-row", @grid, @row_class && @row_class.(row)]}
            data-cols={@count}
          >
            <div :for={{col, align} <- @cols} role="cell" class={["table-card-cell", col[:class]]} data-align={align}>
              {render_slot(col, row)}
            </div>
          </div>
          <div :if={@rows == [] and @empty != []} role="row" class="table-card-empty">
            <div role="cell">{render_slot(@empty)}</div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # ----------------------------------------------------------------------------
  # Section nav
  # ----------------------------------------------------------------------------
  @doc ~S"""
  Where an edit form's sections are, so a person always finds a detail the
  same way. Each section is an element (a card) with that id. Needs the
  `ShadcnSectionNav` hook.

  `variant="side"` (the default) is a list beside the cards from `lg`,
  pinned just under the page's pinned header and level with the first card;
  it scrolls on its own when taller than the window, and over 10 sections it
  gets a "Filter sections" input (matching section and group names). Give it
  the cards as its inner block and it lays them out beside it:

      <.section_nav id="order-sections" sections={[{"customer", "Customer"}, {"items", "Items", "Order"}]}>
        <.card id="customer">…</.card>
        <.card id="items">…</.card>
      </.section_nav>

  `variant="select"` is the same for narrow screens (below `lg`): a full-width
  dropdown that names the section in view ("Group, Section" when grouped),
  options at least 44px tall with a tick on the current one. Put it in the
  page header, so it pins with it:

      <.page_header>
        Edit order
        <:below><.section_nav id="order-sections-select" sections={@sections} variant="select" /></:below>
      </.page_header>

  Both mark the section in view (`aria-current`), measured against the
  bottom of the pinned header; at the bottom of the page it is the last one.
  Choosing one scrolls there (smoothly, or at once under reduced motion),
  keeps it marked until the scroll settles, moves focus to it and closes the
  select. `sections` is `[{id, label}]` or `[{id, label, group}]`;
  consecutive sections with the same group share a heading.
  """
  attr(:id, :string, required: true)
  attr(:sections, :list, required: true, doc: "[{id, label}] or [{id, label, group}]")
  attr(:variant, :string, default: "side", values: ~w(side select))
  attr(:aria_label, :string, default: "Sections")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, doc: "side: the sections, laid out beside the list")

  def section_nav(assigns) do
    sections =
      Enum.map(assigns.sections, fn
        {id, label} -> %{id: to_string(id), label: label, group: nil}
        {id, label, group} -> %{id: to_string(id), label: label, group: group}
      end)

    groups =
      sections
      |> Enum.chunk_by(& &1.group)
      |> Enum.with_index()
      |> Enum.map(fn {[first | _] = items, i} ->
        %{group: first.group, index: i, items: items}
      end)

    current = List.first(sections)

    assigns =
      assign(assigns,
        groups: groups,
        current: current && current.id,
        current_label: current && section_label(current),
        filter: length(sections) > 10
      )

    ~H"""
    <%= if @variant == "select" do %>
      <div
        id={@id}
        phx-hook="ShadcnSectionNav"
        phx-mounted={JS.ignore_attributes(["data-ready"])}
        data-section-nav
        data-variant="select"
        class={["section-nav section-nav-select", @class]}
        {@rest}
      >
        <button
          type="button"
          id={@id <> "-trigger"}
          class="btn btn-outline section-nav-trigger"
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={@id <> "-list"}
          aria-label={@aria_label}
          data-section-trigger
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        >
          <span class="section-nav-current" data-section-current>{@current_label}</span>
          <span class="hero-chevron-down size-4 shrink-0 opacity-50" aria-hidden="true"></span>
        </button>
        <div
          id={@id <> "-list"}
          role="listbox"
          aria-label={@aria_label}
          class="popover-panel section-nav-panel"
          data-section-panel
          hidden
          phx-mounted={JS.ignore_attributes(["hidden", "data-align"])}
        >
          <div
            :for={g <- @groups}
            role="group"
            aria-labelledby={g.group && "#{@id}-group-#{g.index}"}
            class={g.index > 0 && "section-nav-panel-group"}
          >
            <div :if={g.group} id={"#{@id}-group-#{g.index}"} class="command-group-label">{g.group}</div>
            <button
              :for={s <- g.items}
              type="button"
              role="option"
              tabindex="-1"
              id={"#{@id}-option-#{s.id}"}
              class="section-nav-option"
              aria-selected={to_string(s.id == @current)}
              data-section={s.id}
              data-label={section_label(s)}
            >
              <span class="section-nav-option-label">{s.label}</span>
              <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
            </button>
          </div>
        </div>
      </div>
    <% else %>
      <div :if={@inner_block != []} class="section-nav-layout">
        <.section_list id={@id} groups={@groups} current={@current} filter={@filter} aria_label={@aria_label} class={@class} rest={@rest} />
        <div class="section-nav-content">{render_slot(@inner_block)}</div>
      </div>
      <.section_list
        :if={@inner_block == []}
        id={@id}
        groups={@groups}
        current={@current}
        filter={@filter}
        aria_label={@aria_label}
        class={@class}
        rest={@rest}
      />
    <% end %>
    """
  end

  attr(:id, :string, required: true)
  attr(:groups, :list, required: true)
  attr(:current, :string, default: nil)
  attr(:filter, :boolean, required: true)
  attr(:aria_label, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :map, default: %{})

  defp section_list(assigns) do
    ~H"""
    <nav
      id={@id}
      phx-hook="ShadcnSectionNav"
      phx-mounted={JS.ignore_attributes(["style", "data-ready"])}
      data-section-nav
      data-variant="side"
      aria-label={@aria_label}
      class={["section-nav section-nav-side", @class]}
      {@rest}
    >
      <label :if={@filter} class="input section-nav-filter">
        <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
        <input
          type="search"
          placeholder="Filter sections"
          aria-label="Filter sections"
          autocomplete="off"
          data-section-filter
        />
      </label>
      <div :for={g <- @groups} class="section-nav-group" data-group-label={g.group}>
        <div :if={g.group} class="section-nav-group-label">{g.group}</div>
        <a
          :for={s <- g.items}
          href={"#" <> s.id}
          class="section-nav-item"
          aria-current={s.id == @current && "true"}
          data-section={s.id}
          data-label={s.label}
          phx-mounted={JS.ignore_attributes(["aria-current", "hidden"])}
        >
          {s.label}
        </a>
      </div>
      <p :if={@filter} class="section-nav-none" data-section-none hidden>No sections match.</p>
    </nav>
    """
  end

  # "Group, Section"; a section named like its group reads once
  defp section_label(%{group: nil, label: label}), do: label
  defp section_label(%{group: label, label: label}), do: label
  defp section_label(%{group: group, label: label}), do: "#{group}, #{label}"

  # ----------------------------------------------------------------------------
  # Time field
  # ----------------------------------------------------------------------------
  @doc ~S"""
  A labelled `<.time_picker>` bound to a form field: the label above, the
  picker full width with "Not set" as its placeholder, and the field's
  errors under it once it was used or the form submitted.

      <.time_field id="opens-at" field={@form[:opens_at]} label="Opens at" />

  Posts a 24-hour `HH:MM`, which an Ecto `:time` field casts. Needs the
  `ShadcnTimePicker` hook.
  """
  attr(:id, :string, required: true)
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:minute_step, :integer, default: 15)
  attr(:hour_cycle, :integer, default: 12, values: [12, 24])
  attr(:placeholder, :string, default: "Not set")
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)

  def time_field(assigns) do
    field = assigns.field

    errors =
      if Phoenix.Component.used_input?(field),
        do: Enum.map(field.errors, &ShadcnDaisyui.Translate.translate_error/1),
        else: []

    assigns =
      assign(assigns,
        errors: errors,
        trigger_id: if(field.id != assigns.id, do: field.id, else: "#{assigns.id}-trigger")
      )

    ~H"""
    <div class={["time-field", @class]}>
      <label for={@trigger_id} class="time-field-label">{@label}</label>
      <.time_picker
        id={@id}
        field={@field}
        placeholder={@placeholder}
        minute_step={@minute_step}
        hour_cycle={@hour_cycle}
        disabled={@disabled}
        full_width
      />
      <ShadcnDaisyui.CoreComponents.error :for={msg <- @errors}>{msg}</ShadcnDaisyui.CoreComponents.error>
    </div>
    """
  end
end
