defmodule ShadcnDaisyui.Components.DataTable do
  @moduledoc ~S"""
  A list page's table and its toolbar: `data_table/1` (a body that scrolls
  under a header that stays put, rows that open the record, ticked rows for
  bulk actions) and `table_toolbar/1` (views, search, filters and the active
  filter chips, as one form).

  What the table shows lives in a `ShadcnDaisyui.DataTable.State`: sort,
  search and filters in the URL, the ticked rows on the page. Both components
  send their events to the LiveView (or to `phx-target`):

  | Event | Payload | From |
  |---|---|---|
  | `dt:sort` | `%{"key" => key}` | a sortable column header |
  | `dt:open` | `%{"id" => id}` | a row (click or Enter) |
  | `dt:select` | `%{"id" => id, "shift" => bool}` | a row's checkbox |
  | `dt:select_all` | `%{}` | the header checkbox |
  | `dt:select_matching` | `%{}` | "Select all M rows" in the bulk bar |
  | `dt:clear` | `%{}` | Clear in the bulk bar |
  | `dt:more` | `%{}` | scrolling near the end (with `more`) |
  | `dt:filter` | the form's params (`q`, each filter, `sort`) | the toolbar, on change and submit |
  | `dt:unfilter` | `%{"key" => key}` | a filter chip's remove button |
  | `dt:unfilter` | `%{"key" => key, "value" => value}` | one value's remove button in a stacked chip |
  | `dt:reset` | `%{}` | "Clear all" |

  Every payload also carries `"table" => id` (the component's id), for a
  page with more than one table.

      <.table_toolbar
        id="orders-toolbar"
        search={@state.search}
        shown={length(@rows)}
        total={@total}
        noun={{"order", "orders"}}
        chips={State.chips(@state, ["status"], %{"status" => @statuses})}
        sort={State.sort_value(@state)}
        sorts={[{"Newest first", "placed:desc"}, {"Customer", "customer:asc"}]}
      >
        <:filter key="status" label="Status">
          <.select id="filter-status" name="status" multiple value={State.values(@state.filters["status"])} full_width>
            <:option :for={{label, value} <- @statuses} value={value}>{label}</:option>
          </.select>
        </:filter>
      </.table_toolbar>

      <.data_table
        id="orders"
        rows={@rows}
        row_href={&~p"/orders/#{&1.id}"}
        state={@state}
        selectable
        noun={{"order", "orders"}}
        active_id={@last_opened}
        scroll_key="orders"
      >
        <:col :let={o} label="Order" sort="number" class="w-32">#{o.number}</:col>
        <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
        <:col :let={o} label="Status" hide_below="md" class="w-32"><.badge variant="outline">{o.status}</.badge></:col>
        <:col :let={o} label="Total" sort="total" class="w-32">{o.total}</:col>
        <:bulk><.button size="sm" variant="outline" phx-click="export">Export</.button></:bulk>
        <:empty title="No orders match" icon="hero-funnel">Try another filter.</:empty>
      </.data_table>

  Put both in an `<.app_shell fill>` page (or any flex column that fills
  the window) so the table takes the space left and only its body scrolls.

  The data table needs the `ShadcnDataTable` hook (in `Hooks`).

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components, only: [select: 1]
  import ShadcnDaisyui.Components.Display, only: [chip_row: 1, reveal: 1, empty: 1]
  import ShadcnDaisyui.Components.Navigation, only: [tab_nav: 1]
  import ShadcnDaisyui.Components.Overlay, only: [sheet: 1, show_modal: 1, hide_modal: 1]

  alias Phoenix.LiveView.JS
  alias ShadcnDaisyui.DataTable.State

  # Tailwind's breakpoints, smallest first: a column with `hide_below="md"`
  # shows from md up.
  @breakpoints ~w(base sm md lg xl)

  @doc ~S"""
  A table whose body scrolls while its header stays put. Clicking a row (or
  Enter on it) opens the record; rows can be ticked for bulk actions. See the
  module doc for the events and a full list page.

  ## Columns

  `:col` takes `label`, `sort` (the key `dt:sort` sends; the header becomes
  a button with an arrow, and `aria-sort`), `class` (its width, e.g. `w-32`:
  the table is `table-fixed`), `align` (`left` or `right`) and `hide_below`
  (`sm`, `md`, `lg` or `xl`: hidden under that width). Cells truncate with
  "…". The rightmost column shown is right-aligned at every width, header
  and cells, unless `align="left"` (the first column never is).

  ## Rows

  A click on a row sends `dt:open` with its id, except on links, buttons,
  inputs, labels, anything marked `data-row-ignore`, or a click that ends with
  text selected. Cmd/Ctrl-click and middle click open `row_href` in a new
  tab. `active_id` (the row last opened) is highlighted and scrolled into
  view.

  ## Ticking rows

  `selectable` adds a checkbox column (from `md`; ticking is a desktop job).
  A row's checkbox sends `dt:select` (`"shift" => true` with Shift: tick the
  range since the last one ticked); the header checkbox sends
  `dt:select_all` and shows ticked, half-ticked or not from the rows. While
  rows are ticked a bulk bar replaces the column labels, so nothing below it
  moves: "N selected" (or "All M selected" with `all_matching`), then
  "Select all M rows" when every loaded row is ticked and `matching` says
  more match, then `:bulk`, then Clear.

  ## Scrolling

  A new sort, search or filter (from `state`) starts the body at the top.
  `scroll_key` keeps the body's scroll position in `sessionStorage`, so
  coming back to the list lands where the person left off. `more` sends
  `dt:more` as the end comes within about 200px, once until the reply.
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "fn row -> id (default: `row.id`)")
  attr(:row_href, :any, default: nil, doc: "fn row -> path, for Cmd/Ctrl-click and middle click")
  attr(:state, State, default: nil, doc: "the sort and the ticked rows")
  attr(:selectable, :boolean, default: false, doc: "a checkbox column and the bulk bar")
  attr(:more, :boolean, default: false, doc: "more rows to load (sends `dt:more`)")
  attr(:matching, :integer, default: nil, doc: "how many rows match in all")
  attr(:all_matching, :boolean, default: false, doc: "every matching row is selected")
  attr(:edge, :boolean, default: false, doc: "phones: edge to edge, no side borders or rounding")
  attr(:noun, :any, default: {"row", "rows"}, doc: "{singular, plural}")

  attr(:active_id, :any,
    default: nil,
    doc: "the row last opened: highlighted, scrolled into view"
  )

  attr(:scroll_key, :string, default: nil, doc: "keeps the scroll position under this key")
  attr(:target, :any, default: nil, doc: "phx-target for every event (a LiveComponent)")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :col, required: true do
    attr(:label, :string)
    attr(:sort, :string, doc: "the sort key `dt:sort` sends")
    attr(:class, :any, doc: "the column's width (`w-32`) and cell classes")
    attr(:align, :string, values: ~w(left right))
    attr(:hide_below, :string, values: ~w(sm md lg xl))
  end

  slot(:bulk, doc: "actions on the ticked rows (`size=\"sm\"` buttons)")

  slot :empty, doc: "no rows: `<.empty>`'s in-table layout" do
    attr(:title, :string)
    attr(:icon, :string)
  end

  slot(:empty_action, doc: "an action under the empty state")

  def data_table(assigns) do
    state = assigns.state || %State{}
    row_id = assigns.row_id || (& &1.id)
    {singular, plural} = assigns.noun
    row_list = Enum.map(assigns.rows, &{to_string(row_id.(&1)), &1})
    ids = Enum.map(row_list, &elem(&1, 0))
    ticked = Enum.count(ids, &MapSet.member?(state.selected, &1))
    count = if assigns.all_matching, do: assigns.matching, else: MapSet.size(state.selected)
    all_loaded = ids != [] and ticked == length(ids)

    assigns =
      assign(assigns,
        cols: columns(assigns.col),
        sort: state.sort,
        dir: state.dir,
        selected: state.selected,
        row_list: row_list,
        dom: &"#{assigns.id}-row-#{&1}",
        active: assigns.active_id && to_string(assigns.active_id),
        count: count || 0,
        all_loaded: all_loaded,
        some: ticked > 0 and not all_loaded,
        offer_all:
          all_loaded and not assigns.all_matching and is_integer(assigns.matching) and
            assigns.matching > length(ids),
        singular: singular,
        plural: plural,
        # what the rows are (sort, search, filters): when it changes, the body
        # goes back to the top
        view:
          assigns.state && :erlang.phash2({state.sort, state.dir, state.search, state.filters})
      )

    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnDataTable"
      data-data-table
      data-selectable={@selectable}
      data-ticked={@count > 0}
      data-edge={@edge}
      data-more={@more}
      data-view={@view}
      data-scroll-key={@scroll_key}
      phx-target={@target}
      class={["card data-table", @class]}
      {@rest}
    >
      <div class="data-table-scroll" data-dt-scroll>
        <table class="table data-table-table">
          <thead>
            <tr>
              <th :if={@selectable} scope="col" class="data-table-check">
                <input
                  type="checkbox"
                  class="checkbox"
                  aria-label={"Select all " <> @plural}
                  checked={@all_loaded}
                  data-indeterminate={@some}
                  disabled={@rows == []}
                  data-dt-select-all
                  phx-click={dt_push("dt:select_all", %{}, @id, @target)}
                />
              </th>
              <th
                :for={col <- @cols}
                scope="col"
                class={col.class}
                data-hide-below={col.hide_below}
                data-align={col.align}
                data-end={col.ends}
                aria-sort={col.sort && sort_state(col.sort, @sort, @dir)}
              >
                <button
                  :if={col.sort}
                  type="button"
                  class="data-table-sort"
                  data-sorted={col.sort == @sort && to_string(@dir)}
                  phx-click={dt_push("dt:sort", %{key: col.sort}, @id, @target)}
                >
                  <span class="data-table-sort-label">{col.label}</span>
                  <span class={["data-table-sort-icon", sort_icon(col.sort, @sort, @dir)]} aria-hidden="true"></span>
                </button>
                <span :if={!col.sort} class="data-table-label">{col.label}</span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={{id, row} <- @row_list}
              id={@dom.(id)}
              tabindex="0"
              data-dt-row
              data-id={id}
              data-href={@row_href && @row_href.(row)}
              data-selected={MapSet.member?(@selected, id)}
              data-active={@active == id}
            >
              <td :if={@selectable} class="data-table-check">
                <input
                  type="checkbox"
                  id={@dom.(id) <> "-check"}
                  class="checkbox"
                  aria-label="Select"
                  aria-labelledby={@dom.(id) <> "-check " <> @dom.(id) <> "-c0"}
                  checked={MapSet.member?(@selected, id)}
                  data-dt-select
                />
              </td>
              <td
                :for={col <- @cols}
                id={col.index == 0 && @dom.(id) <> "-c0"}
                class={col.class}
                data-hide-below={col.hide_below}
                data-align={col.align}
                data-end={col.ends}
              >
                {render_slot(col.slot, row)}
              </td>
            </tr>
          </tbody>
        </table>
        <div :if={@rows == []} class="data-table-empty">
          <%= cond do %>
            <% @empty != [] -> %>
              <.empty
                variant="plain"
                icon={empty_attr(@empty, :icon)}
                title={empty_attr(@empty, :title) || "No " <> @plural}
              >
                {render_slot(@empty)}
                <:actions :if={@empty_action != []}>{render_slot(@empty_action)}</:actions>
              </.empty>
            <% @empty_action != [] -> %>
              <.empty variant="plain" title={"No " <> @plural}>
                <:actions>{render_slot(@empty_action)}</:actions>
              </.empty>
            <% true -> %>
              <.empty variant="plain" title={"No " <> @plural} />
          <% end %>
        </div>
        <div :if={@more} class="data-table-more" data-dt-more>
          <span class="data-table-sentinel" data-dt-sentinel aria-hidden="true"></span>
          <span class="loading loading-spinner loading-sm" aria-hidden="true"></span>
          <span class="sr-only">Loading more {@plural}</span>
        </div>
      </div>
      <div :if={@selectable} class="data-table-bulk" data-dt-bulk hidden={@count == 0}>
        <span class="data-table-bulk-count" aria-live="polite">
          {if @all_matching, do: "All #{@count} selected", else: "#{@count} selected"}
        </span>
        <button
          :if={@offer_all}
          type="button"
          class="btn btn-ghost btn-sm"
          data-dt-select-matching
          phx-click={dt_push("dt:select_matching", %{}, @id, @target)}
        >
          Select all {@matching} {@plural}
        </button>
        <div :if={@bulk != []} class="data-table-bulk-actions">{render_slot(@bulk)}</div>
        <button
          type="button"
          class="btn btn-ghost btn-sm data-table-bulk-clear"
          data-dt-clear
          phx-click={dt_push("dt:clear", %{}, @id, @target)}
        >
          Clear
        </button>
      </div>
    </div>
    """
  end

  # Each column with its index, and the breakpoints where it is the
  # rightmost one shown (right-aligned there): `data-end="base sm"`. The
  # first column never is, and an explicit `align` wins at every width.
  defp columns(cols) do
    shown_at = fn col, bp ->
      rank(col[:hide_below] || "base") <= rank(bp)
    end

    last =
      Map.new(@breakpoints, fn bp ->
        {bp, cols |> Enum.with_index() |> Enum.filter(&shown_at.(elem(&1, 0), bp)) |> List.last()}
      end)

    cols
    |> Enum.with_index()
    |> Enum.map(fn {col, i} ->
      ends =
        if i > 0 and is_nil(col[:align]) do
          for bp <- @breakpoints, match?({_, ^i}, last[bp]), do: bp
        else
          []
        end

      %{
        slot: col,
        index: i,
        label: col[:label],
        sort: col[:sort],
        class: col[:class],
        align: col[:align],
        hide_below: col[:hide_below],
        ends: ends != [] && Enum.join(ends, " ")
      }
    end)
  end

  defp rank(bp), do: Enum.find_index(@breakpoints, &(&1 == bp)) || 0

  defp sort_state(key, key, :desc), do: "descending"
  defp sort_state(key, key, _dir), do: "ascending"
  defp sort_state(_col, _sort, _dir), do: "none"

  # literal class names, so Tailwind's heroicons plugin generates them
  defp sort_icon(key, key, :desc), do: "hero-arrow-down"
  defp sort_icon(key, key, _dir), do: "hero-arrow-up"
  defp sort_icon(_col, _sort, _dir), do: "hero-chevron-up-down"

  defp empty_attr([entry | _], key), do: entry[key]

  # Every event carries the table's id; `target` sends it to a LiveComponent.
  defp dt_push(event, value, id, target) do
    opts = [value: Map.put(value, :table, id)]
    JS.push(event, if(target, do: [{:target, target} | opts], else: opts))
  end

  @doc ~S"""
  The one toolbar row above a data table, as a form that sends `dt:filter`
  (on change, and on submit) with its params: `q` (the search, debounced
  200ms), each `:filter`'s value, and `sort`.

      <.table_toolbar
        id="orders-toolbar"
        search={@state.search}
        shown={length(@rows)}
        total={@total}
        noun={{"order", "orders"}}
        views={for v <- @views, do: %{key: v.key, label: v.label, count: v.count, path: ~p"/orders?view=#{v.key}", active: v.key == @view}}
        menu={[%{key: "manage", label: "Manage views…", icon: "hero-cog-6-tooth", path: ~p"/views"}]}
        chips={State.chips(@state, ["status", "owner"], @options)}
        sort={State.sort_value(@state)}
        sorts={[{"Newest first", "placed:desc"}, {"Oldest first", "placed:asc"}, {"Customer", "customer:asc"}]}
      >
        <:filter key="status" label="Status">
          <.select id="filter-status" name="status" multiple value={State.values(@state.filters["status"])} full_width>
            <:option :for={{label, value} <- @options["status"]} value={value}>{label}</:option>
          </.select>
        </:filter>
        <:more><.button size="sm" variant="outline">Export</.button></:more>
      </.table_toolbar>

  **The row**: `views` as a `<.tab_nav>` (a patch link per view, with its
  count; an `edited` view shows a dot; the overflow menu, "Views", holds the
  `menu` entries, each a `path` or a `click`), or, without views, "N orders"
  ("N of M" while filtered). Then the search (it takes the row on phones
  without views), a Filters button with the number of filters on, and
  `:more` (hidden on phones).

  **The chips row**: the filters that are on as a `<.chip_row>` that slides
  open with the first and closed with the last: `{key, label}`, or
  `{key, label, :fixed}` for one that can't be removed; a filter with several
  values is `{key, [{value, label}, ...]}` or `{key, [{value, label}, ...], :fixed}`,
  a stacked chip (a one-item list is a normal chip) named after its `:filter`'s
  `label`. A chip's × sends `dt:unfilter` with `%{"key" => key}`; a value's × in
  a stack sends `%{"key" => key, "value" => value}`. The row ends with `:save`
  (a "Save view" button), then "Clear all" (`dt:reset`) while a filter is on.

  **The filters sheet**: each `:filter` under its label (one `<.select>` or
  `<.combobox>` named after its `key`; it applies as it changes and the
  sheet stays open), on phones a "Sort by" select named `sort` (from
  `sorts`; the first is the default order, `""`; "As the table is sorted"
  when the current `sort` isn't one of them), and a footer with "Clear all"
  and "Show N orders", which closes the sheet.
  """
  attr(:id, :string, required: true)
  attr(:search, :string, default: "", doc: "the search text (`q`)")
  attr(:placeholder, :string, default: "Search…")
  attr(:shown, :integer, default: nil, doc: "rows matching")
  attr(:total, :integer, default: nil, doc: "rows unfiltered")
  attr(:noun, :any, default: {"row", "rows"}, doc: "{singular, plural}")

  attr(:views, :list,
    default: [],
    doc: "[%{key, label, count, path, active, edited}]: a tab nav of saved views"
  )

  attr(:menu, :list,
    default: [],
    doc: "[%{key, label, group, icon, active, path | click}]: the Views menu's entries"
  )

  attr(:chips, :list,
    default: [],
    doc:
      "[{key, label} | {key, label, :fixed} | {key, [{value, label}]} | {key, [{value, label}], :fixed}]: filters on"
  )

  attr(:sort, :string, default: "", doc: "\"key:dir\", or \"\" for the default order")
  attr(:sorts, :list, default: [], doc: "[{label, \"key:dir\"}], the first being the default")
  attr(:target, :any, default: nil, doc: "phx-target for every event (a LiveComponent)")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :filter, doc: "one select or combobox named after `key`, in the filters sheet" do
    attr(:key, :string, required: true)
    attr(:label, :string, required: true)
  end

  slot(:more, doc: "trailing controls (Export, Columns); hidden on phones")
  slot(:save, doc: "at the end of the chips row, before Clear all (\"Save view\")")

  def table_toolbar(assigns) do
    {singular, plural} = assigns.noun
    names = Map.new(assigns.filter, &{to_string(&1.key), &1.label})
    chips = Enum.flat_map(assigns.chips, &chip(&1, names))
    removable = Enum.count(chips, &(!&1.fixed))
    search = assigns.search || ""

    assigns =
      assign(assigns,
        chip_list: chips,
        on: removable,
        filtered: search != "" or removable > 0,
        search: search,
        noun_for: fn n -> if n == 1, do: singular, else: plural end,
        sheet: "#{assigns.id}-filters",
        sort_options: sort_options(assigns.sorts, assigns.sort),
        sort_value: sort_selected(assigns.sorts, assigns.sort)
      )

    ~H"""
    <div id={@id} class={["table-toolbar", @class]} data-views={@views != []} {@rest}>
      <form
        id={@id <> "-form"}
        class="table-toolbar-form"
        phx-change="dt:filter"
        phx-submit="dt:filter"
        phx-target={@target}
      >
        <input type="hidden" name="table" value={@id} />
        <div class="table-toolbar-row">
          <.tab_nav
            :if={@views != []}
            id={@id <> "-views"}
            aria_label="Views"
            more_label="Views"
            class="table-toolbar-views"
          >
            <:tab :for={view <- @views} patch={view.path} active={view[:active]} count={view[:count]}>
              {view.label}<span :if={view[:edited]} class="table-toolbar-edited"><span class="sr-only">(edited)</span></span>
            </:tab>
            <:menu_item
              :for={item <- @menu}
              group={item[:group]}
              icon={item[:icon]}
              active={item[:active]}
              patch={item[:path]}
              phx-click={item[:click]}
            >
              {item.label}
            </:menu_item>
          </.tab_nav>
          <p :if={@views == [] && @shown} class="table-toolbar-count">
            <%= if @filtered && @total do %>
              {@shown} of {@total}
            <% else %>
              {@shown} {@noun_for.(@shown)}
            <% end %>
          </p>
          <label class="input table-toolbar-search">
            <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
            <input
              type="search"
              name="q"
              value={@search}
              placeholder={@placeholder}
              aria-label={@placeholder}
              autocomplete="off"
              phx-debounce="200"
            />
          </label>
          <button
            :if={@filter != [] or @sorts != []}
            type="button"
            class="btn btn-outline table-toolbar-filters"
            aria-haspopup="dialog"
            aria-controls={@sheet}
            phx-click={show_modal(@sheet)}
          >
            <span class="hero-funnel size-4" aria-hidden="true"></span>
            <span class="table-toolbar-filters-label">Filters</span>
            <span :if={@on > 0} class="table-toolbar-filters-count">
              {@on}<span class="sr-only"> on</span>
            </span>
          </button>
          <div :if={@more != []} class="table-toolbar-more">{render_slot(@more)}</div>
        </div>
        <.reveal open={@chip_list != []} class="table-toolbar-chips">
          <.chip_row id={@id <> "-chips"} aria_label="Active filters">
            <:chip
              :for={chip <- @chip_list}
              value={chip.key}
              removable={!chip.fixed}
              remove_label={"Remove filter: " <> chip.label}
              on_remove={dt_push("dt:unfilter", %{key: chip.key}, @id, @target)}
              items={chip_items(chip, @id, @target)}
            >
              {chip.label}
            </:chip>
            <:action>
              {render_slot(@save)}
              <button
                :if={@on > 0}
                type="button"
                class="btn btn-ghost btn-sm"
                phx-click={dt_push("dt:reset", %{}, @id, @target)}
              >
                Clear all
              </button>
            </:action>
          </.chip_row>
        </.reveal>
        <.sheet :if={@filter != [] or @sorts != []} id={@sheet}>
          <:title>Filters</:title>
          <div class="table-toolbar-fields">
            <label :for={filter <- @filter} class="table-toolbar-field" data-filter={filter.key}>
              <span class="table-toolbar-field-label">{filter.label}</span>
              {render_slot(filter)}
            </label>
            <label :if={@sorts != []} class="table-toolbar-field table-toolbar-sort">
              <span class="table-toolbar-field-label">Sort by</span>
              <.select id={@id <> "-sort"} name="sort" value={@sort_value} full_width>
                <:option :for={{label, value} <- @sort_options} value={value}>{label}</:option>
              </.select>
            </label>
          </div>
          <:footer>
            <button type="button" class="btn btn-ghost" phx-click={dt_push("dt:reset", %{}, @id, @target)}>
              Clear all
            </button>
            <button
              type="button"
              class="btn btn-primary ml-auto grow sm:grow-0"
              phx-click={hide_modal(@sheet)}
            >
              <%= if @shown do %>
                Show {@shown} {@noun_for.(@shown)}
              <% else %>
                Show results
              <% end %>
            </button>
          </:footer>
        </.sheet>
      </form>
    </div>
    """
  end

  defp chip({key, items}, names) when is_list(items), do: chip_values(key, items, false, names)

  defp chip({key, items, :fixed}, names) when is_list(items),
    do: chip_values(key, items, true, names)

  defp chip({key, label}, _names), do: [plain_chip(key, label, false)]
  defp chip({key, label, :fixed}, _names), do: [plain_chip(key, label, true)]

  defp plain_chip(key, label, fixed),
    do: %{key: to_string(key), label: label, fixed: fixed, values: []}

  # Several values: a stack, named after its filter. One: a normal chip.
  defp chip_values(key, items, fixed, names) do
    key = to_string(key)

    case items
         |> Enum.map(fn {v, l} -> {to_string(v), to_string(l)} end)
         |> Enum.uniq_by(&elem(&1, 0)) do
      [] ->
        []

      [{_value, label}] ->
        [plain_chip(key, label, fixed)]

      values ->
        name = names[key] || Phoenix.Naming.humanize(key)
        [%{key: key, label: name, fixed: fixed, values: values}]
    end
  end

  # A fixed filter can't lose a value either.
  defp chip_items(chip, id, target) do
    for {value, label} <- chip.values do
      %{
        value: value,
        label: label,
        removable: !chip.fixed,
        on_remove: dt_push("dt:unfilter", %{key: chip.key, value: value}, id, target)
      }
    end
  end

  # The first sort is the default order, posted as "" (State.parse_sort/3
  # resets to it; a single select chooses a "" option while its value is
  # blank); a current sort none of them names gets its own option.
  defp sort_options([], _sort), do: []

  defp sort_options([{first, _} | rest] = sorts, sort) do
    known = sort in ["" | Enum.map(sorts, &elem(&1, 1))]
    current = if known or sort in [nil, ""], do: [], else: [{"As the table is sorted", sort}]
    [{first, ""} | rest] ++ current
  end

  defp sort_selected([{_, default} | _], sort) when sort == default, do: ""
  defp sort_selected(_sorts, sort), do: sort || ""
end
