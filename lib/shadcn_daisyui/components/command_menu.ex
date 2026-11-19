defmodule ShadcnDaisyui.Components.CommandMenu do
  @moduledoc """
  `command_menu/1`: a searchable dropdown for long grouped lists - shadcn's
  Popover + Command combobox. Needs the `ShadcnCommandMenu` hook (in `Hooks`).

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @max_depth 4

  @doc ~S"""
  A searchable dropdown anchored to its trigger: a search box (focused when
  it opens) over grouped rows, some nested under others, filtered as you
  type. Rows navigate, link, submit a form or run `phx-click`, like
  `<.command>` items. Below `md` (48rem) it opens as a drawer from the bottom
  instead. Needs `id` and the `ShadcnCommandMenu` hook.

      <.command_menu id="scope" label="Switch location" placeholder="Search brands and locations">
        <:trigger>
          <span class="truncate">{@scope.name}</span>
          <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
        </:trigger>
        <:item
          :for={row <- @scope_rows}
          id={row.id}
          group={row.group}
          parent={row[:parent]}
          icon={row.icon}
          description={row[:description]}
          current={row.id == @scope.id}
          patch={~p"/?scope=#{row.id}"}
        >
          {row.label}
        </:item>
      </.command_menu>

  Build the rows in Elixir, in order, each child after its parent, and
  render them with one `:for` (a slot entry can't sit inside a `for` block):

      scope_rows =
        [%{id: "org", group: "Company", label: "All of Acme", icon: "hero-building-office-2"}] ++
          Enum.flat_map(brands, fn brand ->
            [%{id: "brand-#{brand.id}", group: "Brands", label: brand.name, icon: "hero-tag"} |
               for loc <- brand.locations do
                 %{id: "loc-#{loc.id}", group: "Brands", parent: "brand-#{brand.id}",
                   label: loc.name, description: loc.city, icon: "hero-map-pin"}
               end]
          end)

  ## Rows

  Consecutive items with the same `group` share a heading. `parent` (another
  item's `id`, listed before it) nests a row under that item, indented a
  step per level (up to four). `current` marks the row that's chosen now: a
  check at its end and `aria-selected`, and it's the active row when the menu
  opens (scrolled into view). `description` is a muted second line,
  `keywords` extra words that find the row ("DAL Texas"), `icon` a heroicon
  class. A row runs `phx-click` (with `values`, `phx-value-*`), goes somewhere
  (`navigate` / `patch` / `href`), or submits a form (`form` + `name` +
  `value`). `confirm` asks first (`data-confirm`; the menu closes once it's
  accepted) and `disabled` makes it inert. Choosing a row closes the menu.

  ## Search

  Typing filters every level at once: a row shows when all the words typed
  are in its own text (label, description, keywords) or its parents'. So a
  location's name finds it, shown under its brand (muted: there for
  context, and still a row you can choose), and a brand's name shows the
  brand with all its locations. The first match is active. Accents and case
  don't matter. When nothing matches, `<:empty>` shows (default "No results
  found."), and the number of results is announced politely.

  ## Trigger

  `<:trigger>` is the inside of the menu's own button (`trigger_class`,
  default an outline button). Or point the id of an element
  elsewhere that opens it with `trigger_id`, e.g. the app shell's heading:

      <:header>
        <.app_shell_heading id="scope-trigger" as="button" icon="hero-building-office-2"
          title={@scope.name} subtitle={@scope.kind} tip={@scope.name} chevron />
      </:header>
      …
      <.command_menu id="scope" trigger_id="scope-trigger" side="right" label="Switch location">…</.command_menu>

  ## Placement and keys

  Desktop: in the top layer (nothing clips it, no z-index), below the
  trigger and start-aligned (`side="right"`: beside it, top-aligned;
  `align="end"`: end-aligned), at least the trigger's width; it flips above
  (or to the left) when there's more room there, keeps inside the window,
  follows the trigger as the page scrolls and closes when it scrolls out of
  view. Phones: a bottom drawer up to 85% of the screen, 44px rows, the
  search box at the top (not focused, so the keyboard doesn't cover the
  list until it's tapped).

  Keys: Enter, Space, Arrow Down / Up on the trigger open it; in the search
  box Arrow Down / Up move through the rows, Page Down / Up by ten, Enter
  chooses, Esc closes (focus goes back to the trigger), Tab closes and moves
  on. A press outside closes it. ARIA: the trigger has
  `aria-haspopup="dialog"` and `aria-expanded`; the panel is a labelled
  dialog with a combobox (the search box, `aria-activedescendant`) over a
  listbox of options in groups.
  """
  attr(:id, :string, required: true)

  attr(:label, :string,
    required: true,
    doc: "the menu's accessible name, e.g. \"Switch location\""
  )

  attr(:placeholder, :string, default: "Search…")

  attr(:trigger_id, :string,
    default: nil,
    doc: "the id of an element elsewhere that opens it (instead of `<:trigger>`)"
  )

  attr(:trigger_class, :any, default: "btn btn-outline w-64 justify-between font-normal")
  attr(:side, :string, default: "bottom", values: ~w(bottom right))
  attr(:align, :string, default: "start", values: ~w(start end))
  attr(:class, :any, default: "w-72", doc: "the panel's classes (its width)")

  attr(:"phx-target", :any,
    default: nil,
    doc: "where the rows' `phx-click` go, e.g. `@myself`"
  )

  attr(:rest, :global)

  slot(:trigger, doc: "the inside of the menu's trigger button")
  slot(:empty, doc: "shown when nothing matches (default \"No results found.\")")

  slot :item, required: true do
    attr(:id, :string, doc: "the row's id; a child's `parent` names it")
    attr(:group, :string, doc: "a heading shared by consecutive rows")
    attr(:parent, :string, doc: "the id of the row this one nests under")
    attr(:icon, :string, doc: "heroicon class, e.g. \"hero-map-pin\"")
    attr(:description, :string, doc: "a muted second line")
    attr(:keywords, :string, doc: "extra words that find the row")
    attr(:current, :boolean, doc: "the row chosen now: a check, aria-selected")
    attr(:"phx-click", :any)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
    attr(:method, :string)
    attr(:form, :string, doc: "the id of a form this row submits, with `name` and `value`")
    attr(:name, :string)
    attr(:value, :string)
    attr(:values, :map, doc: "one phx-value-<key> per entry")
    attr(:confirm, :string, doc: "data-confirm; the menu closes once it's accepted")
    attr(:disabled, :boolean, doc: "aria-disabled, no click, 50% opacity")
  end

  def command_menu(assigns) do
    if assigns.trigger_id == nil and assigns.trigger == [] do
      raise ArgumentError,
            "<.command_menu id=#{inspect(assigns.id)}> needs a <:trigger> " <>
              "or trigger_id={…} (the id of the element that opens it)"
    end

    depths = depths(assigns.item)

    assigns =
      assign(assigns,
        groups: groups(assigns.item),
        depths: depths,
        panel_id: assigns.id <> "-panel",
        list_id: assigns.id <> "-list",
        target: assigns[:"phx-target"]
      )

    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnCommandMenu"
      class="command-menu"
      data-command-menu
      data-trigger={@trigger_id}
      data-side={@side}
      data-align={@align}
      {@rest}
    >
      <button
        :if={@trigger_id == nil}
        type="button"
        id={@id <> "-trigger"}
        class={@trigger_class}
        data-command-menu-trigger
        aria-haspopup="dialog"
        aria-expanded="false"
        aria-controls={@panel_id}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
      >
        {render_slot(@trigger)}
      </button>
      <div
        id={@panel_id}
        popover="manual"
        role="dialog"
        aria-label={@label}
        tabindex="-1"
        class={["command-menu-panel", @class]}
        data-command-menu-panel
        phx-mounted={JS.ignore_attributes(["style", "data-mode", "data-placement"])}
      >
        <div class="command-menu-handle" aria-hidden="true"></div>
        <div class="command-menu-search">
          <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
          <input
            id={@id <> "-search"}
            type="text"
            data-command-menu-search
            role="combobox"
            aria-expanded="true"
            aria-controls={@list_id}
            aria-autocomplete="list"
            aria-label={@placeholder}
            autocomplete="off"
            autocapitalize="off"
            spellcheck="false"
            placeholder={@placeholder}
          />
        </div>
        <div id={@list_id} role="listbox" aria-label={@label} class="command-menu-list">
          <div
            :for={{{group, items}, g} <- Enum.with_index(@groups)}
            role="group"
            aria-labelledby={group && "#{@id}-group-#{g}"}
            data-command-menu-group
          >
            <div :if={group} id={"#{@id}-group-#{g}"} class="command-group-label">{group}</div>
            <.menu_row
              :for={{item, i} <- items}
              item={item}
              dom_id={item[:id] || "#{@id}-row-#{g}-#{i}"}
              depth={@depths[item[:id]] || 0}
              target={@target}
            />
          </div>
        </div>
        <p data-command-menu-empty hidden class="command-menu-empty">
          {if @empty == [], do: "No results found.", else: render_slot(@empty)}
        </p>
        <div
          id={@id <> "-status"}
          role="status"
          class="sr-only"
          data-command-menu-status
          phx-update="ignore"
        >
        </div>
      </div>
    </div>
    """
  end

  attr(:item, :map, required: true)
  attr(:dom_id, :string, required: true)
  attr(:depth, :integer, required: true)
  attr(:target, :any, default: nil)

  # A link when the row goes somewhere, a submit button for a form, else a
  # button running its phx-click. A disabled row is always an inert button.
  defp menu_row(assigns) do
    item = assigns.item

    kind =
      cond do
        item[:disabled] -> :button
        item[:navigate] || item[:patch] || item[:href] -> :link
        item[:form] -> :submit
        true -> :button
      end

    assigns = assign(assigns, kind: kind, extra: row_attrs(item, assigns))

    ~H"""
    <.link
      :if={@kind == :link}
      id={@dom_id}
      navigate={@item[:navigate]}
      patch={@item[:patch]}
      href={@item[:href]}
      method={@item[:method]}
      {@extra}
    >
      <.row_content item={@item} />
    </.link>
    <button
      :if={@kind == :submit}
      type="submit"
      id={@dom_id}
      form={@item.form}
      name={@item[:name]}
      value={@item[:value]}
      {@extra}
    >
      <.row_content item={@item} />
    </button>
    <button
      :if={@kind == :button}
      type="button"
      id={@dom_id}
      phx-click={!@item[:disabled] && @item[:"phx-click"]}
      {@extra}
    >
      <.row_content item={@item} />
    </button>
    """
  end

  defp row_attrs(item, assigns) do
    clickable = !item[:disabled]

    values =
      if clickable,
        do: for({key, value} <- item[:values] || %{}, do: {:"phx-value-#{key}", value}),
        else: []

    [
      class: "command-item command-menu-item",
      role: "option",
      tabindex: "-1",
      "aria-selected": if(item[:current], do: "true", else: "false"),
      "data-command-menu-item": true,
      "data-depth": assigns.depth > 0 && assigns.depth,
      "data-parent": item[:parent],
      "data-keywords": item[:keywords],
      "data-current": item[:current] == true,
      "phx-target": clickable && item[:"phx-click"] && assigns.target,
      "data-confirm": clickable && item[:confirm],
      "aria-disabled": item[:disabled] && "true"
    ]
    |> Enum.filter(fn {_, v} -> v not in [nil, false] end)
    |> Kernel.++(values)
  end

  attr(:item, :map, required: true)

  defp row_content(assigns) do
    ~H"""
    <span :if={@item[:icon]} class={[@item.icon, "size-4 shrink-0"]} aria-hidden="true"></span>
    <span class="command-item-text">
      <span class="command-item-title">{render_slot(@item)}</span>
      <span :if={@item[:description]} class="command-item-description">{@item.description}</span>
    </span>
    <span :if={@item[:current]} class="hero-check command-menu-check" aria-hidden="true"></span>
    """
  end

  # Consecutive items with the same group, each with its index in the group.
  defp groups(items) do
    items
    |> Enum.chunk_by(& &1[:group])
    |> Enum.map(fn [first | _] = chunk -> {first[:group], Enum.with_index(chunk)} end)
  end

  # Each item's nesting depth from its parent chain (an unknown parent or a
  # cycle stops it; capped at four levels).
  defp depths(items) do
    parents = for item <- items, item[:id], into: %{}, do: {item[:id], item[:parent]}

    Map.new(parents, fn {id, _} -> {id, depth(parents, id, 0, MapSet.new())} end)
  end

  defp depth(parents, id, acc, seen) do
    parent = parents[id]

    cond do
      acc >= @max_depth -> acc
      parent == nil or not Map.has_key?(parents, parent) -> acc
      MapSet.member?(seen, parent) -> acc
      true -> depth(parents, parent, acc + 1, MapSet.put(seen, id))
    end
  end
end
