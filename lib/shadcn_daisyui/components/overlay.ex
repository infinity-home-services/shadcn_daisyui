defmodule ShadcnDaisyui.Components.Overlay do
  @moduledoc """
  Overlay components: dialog, sheet, drawer, popover, tooltip, dropdown menu,
  and the command palette.

  The modal family (`dialog`, `sheet`, `drawer`, `command`) renders native
  `<dialog>` elements animated by the theme. Open them three ways:

    * the `:trigger` slot (wired automatically),
    * `show_modal/2` / `hide_modal/2` from LiveView (`phx-click={show_modal("confirm")}`),
    * plain JS: `document.getElementById("confirm").showModal()`.

  No component renders an inline event handler, so they all work under a
  strict `script-src 'self' 'nonce-…'` Content-Security-Policy. Open/close is a
  `Phoenix.LiveView.JS` dispatch handled by `shadcn-daisyui.js`; that needs
  `liveSocket.connect()` on the page (LiveView >= 1.1 also runs JS commands on
  dead views). Esc closes natively, backdrop clicks are handled by the package
  JS, and each `<dialog>` ignores the browser-owned `open` attribute so an open
  dialog survives LiveView patches.

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Returns a `Phoenix.LiveView.JS` command that opens a modal component
  (`dialog`, `sheet`, `drawer`, `command`) by id.

      <.button phx-click={show_modal("confirm")}>Delete…</.button>
  """
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "shadcn:show-modal", to: "##{id}")
  end

  @doc "Returns a JS command that closes a modal component by id."
  def hide_modal(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "shadcn:hide-modal", to: "##{id}")
  end

  @doc """
  A modal dialog (native `<dialog>`, themed and animated).

      <.dialog id="confirm">
        <:trigger><.button variant="outline">Open dialog</.button></:trigger>
        <:title>Are you absolutely sure?</:title>
        <:description>This action cannot be undone.</:description>
        <:actions>
          <form method="dialog"><.button variant="outline">Cancel</.button></form>
          <.button variant="destructive" phx-click="delete">Delete</.button>
        </:actions>
      </.dialog>

  Clicking the backdrop closes it. Open from LiveView with
  `phx-click={show_modal("confirm")}`.
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger, doc: "optional trigger; clicking it opens the dialog")
  slot(:title)
  slot(:description)
  slot(:inner_block)
  slot(:actions, doc: "footer actions, right-aligned")

  def dialog(assigns) do
    ~H"""
    <span :if={@trigger != []} phx-click={show_modal(@id)}>
      {render_slot(@trigger)}
    </span>
    <dialog id={@id} class={["modal", @class]} phx-mounted={keep_open()} {@rest}>
      <div class="modal-box space-y-2">
        <h3 :if={@title != []} class="text-lg font-semibold">{render_slot(@title)}</h3>
        <p :if={@description != []} class="text-sm text-muted-foreground">
          {render_slot(@description)}
        </p>
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="modal-action">
          <div class="flex gap-3">{render_slot(@actions)}</div>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop"><button>close</button></form>
      <div id={"#{@id}-toasts"} data-toast-host phx-update="ignore"></div>
    </dialog>
    """
  end

  @doc """
  A sheet - a panel that slides in from the right edge.

      <.sheet id="edit-profile">
        <:trigger><.button variant="outline">Open sheet</.button></:trigger>
        <:title>Edit profile</:title>
        <:description>Make changes to your profile here.</:description>
        …form…
        <:footer>
          <.button variant="outline" phx-click={hide_modal("edit-profile")}>Cancel</.button>
          <.button class="ml-auto">Save changes</.button>
        </:footer>
      </.sheet>

  The sheet is a full-height column, like shadcn's `SheetHeader` /
  `SheetFooter`: the header (`:title`, `:description`, the close button and an
  optional `:header` slot, e.g. a search box) stays at the top, `:footer` stays
  at the bottom, and only the body between them scrolls. A 1px border separates
  the body from the header / footer only while content is scrolled under it.
  With a short body the footer still sits at the bottom of the sheet.

  The footer is a row (`flex items-center gap-2`) with safe-area padding on
  phones. A typical one: a ghost "Clear all" on the left and the primary action
  on the right (`ml-auto`); on compact screens let the primary action take the
  remaining width with `grow sm:grow-0`.

      <:footer>
        <.button variant="ghost" phx-click="clear_filters">Clear all</.button>
        <.button class="ml-auto grow sm:grow-0" phx-click={hide_modal("filters")}>
          Show 24 results
        </.button>
      </:footer>

  Width matches shadcn: 75% on phones, then `size` from `sm` (`sm` 20rem,
  `default` 24rem, `lg` 32rem, `xl` 40rem), capped at 90vw. A width class
  (`class="sm:w-[28rem]"`) or `class="[--sheet-width:28rem]"` also works.

      <.sheet id="filters" size="lg">…</.sheet>
  """
  @sheet_sizes %{"sm" => "sheet-sm", "default" => nil, "lg" => "sheet-lg", "xl" => "sheet-xl"}

  attr(:id, :string, required: true)
  attr(:size, :string, default: "default", values: Map.keys(@sheet_sizes))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger)
  slot(:title)
  slot(:description)
  slot(:header, doc: "content under the description that stays put (e.g. a search box)")
  slot(:inner_block)
  slot(:footer, doc: "pinned to the bottom; a row of actions (`ml-auto` on the primary one)")

  def sheet(assigns) do
    assigns = assign(assigns, :size_class, @sheet_sizes[assigns.size])

    ~H"""
    <span :if={@trigger != []} phx-click={show_modal(@id)}>
      {render_slot(@trigger)}
    </span>
    <dialog id={@id} class={["sheet", @size_class, @class]} phx-mounted={keep_open_scrolled()} {@rest}>
      <div class="sheet-header">
        <button
          type="button"
          class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
          aria-label="Close"
          phx-click={hide_modal(@id)}
        >
          <span class="hero-x-mark size-4" aria-hidden="true"></span>
        </button>
        <h3 :if={@title != []} class="sheet-title text-lg font-semibold">{render_slot(@title)}</h3>
        <p :if={@description != []} class="sheet-description text-sm text-muted-foreground">{render_slot(@description)}</p>
        <div :if={@header != []} class="sheet-header-content">{render_slot(@header)}</div>
      </div>
      <div class="sheet-body">
        <div>{render_slot(@inner_block)}</div>
      </div>
      <div :if={@footer != []} class="sheet-footer">{render_slot(@footer)}</div>
      <div id={"#{@id}-toasts"} data-toast-host phx-update="ignore"></div>
    </dialog>
    """
  end

  @doc """
  A drawer - a panel that slides up from the bottom (Vaul-style).

      <.drawer id="goal">
        <:trigger><.button variant="outline">Open drawer</.button></:trigger>
        <:title>Move goal</:title>
        <:description>Set your daily activity goal.</:description>
        …content…
        <:footer>
          <.button class="w-full">Submit</.button>
        </:footer>
      </.drawer>

  Same layout as `sheet/1`: the header (`:title`, `:description`, optional
  `:header`) and `:footer` stay put and only the body scrolls once the drawer
  reaches its max height (85vh), with a border shown only while content is
  scrolled under the header or footer. The footer gets safe-area padding.
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger)
  slot(:title)
  slot(:description)
  slot(:header, doc: "content under the description that stays put")
  slot(:inner_block, required: true)
  slot(:footer, doc: "pinned to the bottom; a row of actions")

  def drawer(assigns) do
    ~H"""
    <span :if={@trigger != []} phx-click={show_modal(@id)}>
      {render_slot(@trigger)}
    </span>
    <dialog id={@id} class={["drawer-bottom", @class]} phx-mounted={keep_open_scrolled()} {@rest}>
      <div class="drawer-handle" aria-hidden="true"></div>
      <div :if={@title != [] or @description != [] or @header != []} class="drawer-header">
        <h3 :if={@title != []} class="drawer-title text-lg font-semibold">{render_slot(@title)}</h3>
        <p :if={@description != []} class="drawer-description text-sm text-muted-foreground">{render_slot(@description)}</p>
        <div :if={@header != []} class="drawer-header-content">{render_slot(@header)}</div>
      </div>
      <div class="drawer-body">
        <div>{render_slot(@inner_block)}</div>
      </div>
      <div :if={@footer != []} class="drawer-footer">{render_slot(@footer)}</div>
      <div id={"#{@id}-toasts"} data-toast-host phx-update="ignore"></div>
    </dialog>
    """
  end

  @doc """
  A popover - rich floating content on click (CSS-only, daisyUI dropdown).

      <.popover>
        <:trigger>Open popover</:trigger>
        …content…
      </.popover>

  The trigger renders as an outline button by default; pass `trigger_class` to
  restyle it.
  """
  attr(:class, :any, default: "w-72", doc: "panel classes (width, padding overrides)")
  attr(:trigger_class, :any, default: "btn btn-outline")
  attr(:rest, :global)
  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def popover(assigns) do
    ~H"""
    <div class="dropdown" {@rest}>
      <div tabindex="0" role="button" class={@trigger_class}>{render_slot(@trigger)}</div>
      <div tabindex="0" class={["dropdown-content z-50 mt-2 p-4", @class]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  A tooltip shown on hover/focus.

      <.tooltip tip="Add to library"><.button variant="secondary">Hover me</.button></.tooltip>
  """
  attr(:tip, :string, required: true)
  attr(:position, :string, default: "top", values: ~w(top bottom left right))
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  # literal class names so the Tailwind scanner can see them
  @tooltip_positions %{
    "top" => nil,
    "bottom" => "tooltip-bottom",
    "left" => "tooltip-left",
    "right" => "tooltip-right"
  }

  def tooltip(assigns) do
    assigns = assign(assigns, :pclass, @tooltip_positions[assigns.position])

    ~H"""
    <div class={["tooltip", @pclass, @class]} data-tip={@tip}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A dropdown menu of actions or links.

      <.dropdown_menu>
        <:trigger>Open menu</:trigger>
        <:label>My Account</:label>
        <:item><.link navigate={~p"/profile"}>Profile</.link></:item>
        <:item phx-click="logout" class="text-destructive">Log out</:item>
      </.dropdown_menu>

  Items containing a link/button render it as-is; plain content gets wrapped in
  an `<a>` so the menu styling applies.

  An icon-only trigger (a ⋯ row-actions menu) drops the chevron and needs an
  accessible name:

      <.dropdown_menu
        trigger_class="btn btn-ghost btn-square btn-sm"
        chevron={false}
        aria-label="More actions"
        align="end"
      >
        <:trigger><.icon name="hero-ellipsis-horizontal" class="size-4" /></:trigger>
        <:item phx-click="edit" phx-value-id={@row.id}>Edit</:item>
        <:item phx-click="delete" phx-value-id={@row.id} class="text-destructive">Delete</:item>
      </.dropdown_menu>

  The menu is floating content (`z-50`), so it opens above sticky table
  headers and toolbars (`z-10`).

  ## Opt-in item attributes

  Items without these render exactly as before.

    * `variant="destructive"` - `text-destructive`, hover/focus fill tinted
      destructive (10%, 20% in dark), like shadcn's `DropdownMenuItem
      variant="destructive"`.
    * `confirm` - renders `data-confirm`, so the browser asks before
      `phx-click` is sent (handled by `phoenix_html`, imported in a stock
      Phoenix `app.js`). Name the object: "Remove Acme Marketing from Pat?",
      not "Are you sure?".
    * `values` - a map, one `phx-value-<key>` per entry, for events that need
      more than an id. `phx-value-id` still works; when both are given,
      `values` wins for its own keys only.
    * `id` - on the item, for tests and focus.
    * `disabled` - `aria-disabled="true"`, no `phx-click` / `data-confirm`, the
      variant's colors at 50% opacity, no pointer events.

  `close_on_select` on the menu closes it once an item is chosen (default:
  focus keeps it open until it blurs). One delegated listener in
  `shadcn-daisyui.js`, no inline handlers.

      <.dropdown_menu
        trigger_class="btn btn-ghost btn-square btn-sm"
        chevron={false}
        aria-label={"Actions for \#{@member.name}"}
        align="end"
        close_on_select
      >
        <:trigger><.icon name="hero-ellipsis-horizontal" class="size-4" /></:trigger>
        <:item phx-click="edit" phx-value-id={@member.id}>Edit</:item>
        <:item
          phx-click="remove"
          values={%{user_id: @member.id, team_id: @team.id}}
          variant="destructive"
          confirm={"Remove \#{@team.name} from \#{@member.name}?"}
        >
          Remove
        </:item>
      </.dropdown_menu>
  """
  attr(:class, :any, default: "w-48", doc: "menu panel classes")
  attr(:trigger_class, :any, default: "btn btn-outline")
  attr(:align, :string, default: "start", values: ~w(start end))

  attr(:chevron, :boolean,
    default: true,
    doc: "false drops the trailing chevron (icon-only triggers)"
  )

  attr(:"aria-label", :string,
    default: nil,
    doc: "names the trigger; required when it shows only an icon"
  )

  attr(:close_on_select, :boolean,
    default: false,
    doc: "close the menu once an item is chosen (default: stays open until blur)"
  )

  attr(:rest, :global)

  slot(:trigger, required: true)
  slot(:label, doc: "a non-interactive section title")

  slot :item do
    attr(:class, :any)
    attr(:"phx-click", :any)
    attr(:"phx-value-id", :any)
    attr(:id, :string, doc: "on the item, for tests and focus")
    attr(:variant, :string, values: ~w(destructive), doc: "opt in: destructive text + tint")
    attr(:confirm, :string, doc: "data-confirm; name the object (\"Remove X from Pat?\")")
    attr(:values, :map, doc: "one phx-value-<key> per entry; wins over phx-value-id")
    attr(:disabled, :boolean, doc: "aria-disabled, no phx-click, 50% opacity")
  end

  def dropdown_menu(assigns) do
    ~H"""
    <div
      class={["dropdown", @align == "end" && "dropdown-end"]}
      data-close-on-select={@close_on_select}
      {@rest}
    >
      <div tabindex="0" role="button" class={@trigger_class} aria-label={assigns[:"aria-label"]}>
        {render_slot(@trigger)}
        <span :if={@chevron} class="hero-chevron-down size-4" aria-hidden="true"></span>
      </div>
      <ul tabindex="0" class={["dropdown-content menu z-50 mt-2", @class]}>
        <li :if={@label != []} class="menu-title">{render_slot(@label)}</li>
        <li :for={item <- @item}>
          <a
            class={dropdown_item_class(item)}
            phx-click={!item[:disabled] && item[:"phx-click"]}
            phx-value-id={dropdown_item_value_id(item)}
            {dropdown_item_attrs(item)}
          >
            {render_slot(item)}
          </a>
        </li>
      </ul>
    </div>
    """
  end

  # Opt-in item attributes. With none of them set, the item keeps its old
  # markup exactly: `class={item[:class]}`, phx-click, phx-value-id, nothing else.
  @dropdown_item_variants %{"destructive" => "text-destructive"}

  defp dropdown_item_class(%{variant: variant} = item) when is_binary(variant),
    do: [@dropdown_item_variants[variant], item[:class]]

  defp dropdown_item_class(item), do: item[:class]

  defp dropdown_item_value_id(item) do
    values = item[:values] || %{}

    cond do
      Map.has_key?(values, :id) -> values[:id]
      Map.has_key?(values, "id") -> values["id"]
      true -> item[:"phx-value-id"]
    end
  end

  defp dropdown_item_attrs(item) do
    values =
      for {key, value} <- item[:values] || %{}, to_string(key) != "id" do
        {:"phx-value-#{key}", value}
      end

    [
      id: item[:id],
      "data-variant": item[:variant],
      "data-confirm": !item[:disabled] && item[:confirm],
      "aria-disabled": item[:disabled] && "true"
    ]
    |> Enum.filter(fn {_, v} -> v not in [nil, false] end)
    |> Kernel.++(values)
  end

  @doc ~S"""
  A command palette (searchable action list in a modal). Needs the
  `ShadcnCommand` hook. Opens with ⌘K (Ctrl+K) unless `shortcut` says
  otherwise.

      <.command id="commands">
        <:trigger_label>Search commands…</:trigger_label>
        <:item group="Suggestions" icon="hero-calendar">Calendar</:item>
        <:item group="Suggestions" icon="hero-calculator">Calculator</:item>
        <:item group="Settings" icon="hero-user" shortcut="⌘P">Profile</:item>
      </.command>

  Items run `phx-click`, or go somewhere: `navigate` / `patch` (a LiveView
  link), `href` (a full page load), or `form` + `name` + `value` (submits that
  form, e.g. a "switch location" form elsewhere on the page). Consecutive
  items with the same `group` share a label.

      <.command id="search" label="Search" placeholder="Search pages, teams">
        <:item :for={page <- @pages} id={"search-" <> page.id} group="Pages" icon={page.icon} navigate={page.path}>
          {page.label}
        </:item>
        <:item :for={team <- @teams} group="Teams" icon="hero-users" form="team-form" name="team" value={team.id}>
          {team.name}
        </:item>
      </.command>

  `shortcut` is the letter that opens (and closes) it with Cmd/Ctrl - `"k"`
  by default, `nil` for none (a second palette on the page). Opening it closes
  any other open dialog. Open it from a button with `show_modal(id)` or
  `JS.dispatch("shadcn:show-dialog", to: "#id")`; the hook drops its key
  listener when LiveView removes it.

  ## Server search

  By default the hook filters the items in the browser. For something only
  the server can search (a directory, a remote API, a table too big to send),
  set `on_search`: the hook stops filtering and pushes what's typed to the
  LiveView as that event, `%{"id" => id, "query" => text}` (trimmed, after
  `search_debounce` ms, 250 by default). The LiveView renders its results as
  the `<:item>`s and echoes the text they answer as `query`. Results count
  only while `query` matches the input, so a reply to older text never shows
  as current.

      <.command
        id="find-person"
        label="Add person"
        placeholder="Name or email"
        shortcut={nil}
        on_search="search_people"
        query={@query}
      >
        <:hint>Type a name or email.</:hint>
        <:empty>No one matches "{@query}".</:empty>
        <:item
          :for={person <- @results}
          id={"person-#{person.id}"}
          description={person.email}
          phx-click="add"
          values={%{id: person.id}}
          confirm={person.removed && "Add #{person.name} back? They start with no roles."}
        >
          {person.name}
        </:item>
      </.command>

      def handle_event("search_people", %{"query" => query}, socket) do
        {:noreply, assign(socket, query: query, results: Directory.search(query))}
      end

  The palette always says something: `<:hint>` before anything is typed, a
  spinner (and `aria-busy` on the list, the last results dimmed) while the
  reply is pending, `<:empty>` (default "No results found.") once the server
  has answered the current text with no items, else the items with the first
  one active. Each search's result count is announced in a polite live region.
  Opening the palette clears the input and pushes an empty search, so the
  server can drop the last results.

  A slow search can run in `start_async/3` (a new search replaces the
  pending one, so only the latest answer lands): assign `query` with the
  results, not when the event arrives. Inside a LiveComponent pass
  `phx-target={@myself}`; the search and the items' `phx-click` go there. In
  a dead view the palette dispatches `shadcn:command-search` (`detail` is
  `{id, query}`) instead; answer it by rendering the items into the list,
  then setting `data-query` on the dialog.

  ## Opt-in item attributes

  Items without these render exactly as before.

    * `description` - a muted second line under the label (an email under a
      name).
    * `confirm` - renders `data-confirm`, so the browser asks before
      `phx-click` runs (`phoenix_html`); the palette closes only when the
      person accepts, and cancelling keeps it open with the same results.
    * `values` - a map, one `phx-value-<key>` per entry.
    * `disabled` - `aria-disabled="true"`, no click (a link or form item
      renders as an inert button), skipped by the arrow keys, 50% opacity.
  """
  attr(:id, :string, required: true)
  attr(:label, :string, default: nil, doc: "the dialog's accessible name, e.g. \"Search\"")
  attr(:placeholder, :string, default: "Type a command or search…")

  attr(:shortcut, :any,
    default: "k",
    doc: "a letter that toggles it with Cmd/Ctrl, or nil for none"
  )

  attr(:on_search, :string,
    default: nil,
    doc:
      "server search: the event the typed text is pushed as, " <>
        "`%{\"id\" => id, \"query\" => text}`; the hook stops filtering"
  )

  attr(:query, :string,
    doc:
      "required with `on_search`: the text the rendered items answer " <>
        "(echo the event's \"query\"; nil before the first search)"
  )

  attr(:search_debounce, :integer,
    default: 250,
    doc: "with `on_search`: milliseconds to wait after the last keystroke"
  )

  attr(:"phx-target", :any,
    default: nil,
    doc: "where `on_search` and the items' `phx-click` go, e.g. `@myself`"
  )

  attr(:class, :any, default: nil)
  slot(:trigger_label, doc: "text inside the default trigger button")
  slot(:hint, doc: "with `on_search`: shown before anything is typed")
  slot(:empty, doc: "shown when nothing matches (default \"No results found.\")")

  slot :item, required: true do
    attr(:id, :string)
    attr(:group, :string)
    attr(:icon, :string, doc: "heroicon class, e.g. \"hero-calendar\"")
    attr(:shortcut, :string, doc: "a hint shown on the right, e.g. \"⌘P\"")
    attr(:"phx-click", :any)
    attr(:navigate, :any, doc: "a page in this LiveView session")
    attr(:patch, :any)
    attr(:href, :any, doc: "any other address (a full page load)")
    attr(:form, :string, doc: "the id of a form this item submits, with `name` and `value`")
    attr(:name, :string)
    attr(:value, :string)
    attr(:description, :string, doc: "opt in: a muted second line under the label")
    attr(:confirm, :string, doc: "opt in: data-confirm; the palette closes once it's accepted")
    attr(:values, :map, doc: "opt in: one phx-value-<key> per entry")
    attr(:disabled, :boolean, doc: "opt in: aria-disabled, no click, 50% opacity")
  end

  def command(assigns) do
    if assigns.on_search && !Map.has_key?(assigns, :query) do
      raise ArgumentError,
            "<.command id=#{inspect(assigns.id)} on_search=…> needs query={…}: " <>
              "the text the rendered items answer (nil before the first search)"
    end

    ~H"""
    <button
      :if={@trigger_label != []}
      type="button"
      class="btn btn-outline w-64 justify-between"
      phx-click={show_modal(@id)}
    >
      <span class="text-muted-foreground">{render_slot(@trigger_label)}</span>
      <kbd :if={@shortcut not in [nil, ""]} class="kbd">⌘{String.upcase(@shortcut)}</kbd>
    </button>
    <dialog
      id={@id}
      phx-hook="ShadcnCommand"
      phx-mounted={keep_open()}
      data-command
      data-shortcut={@shortcut || ""}
      aria-label={@label}
      class={["command-dialog", @class]}
      {command_search_attrs(assigns)}
    >
      <div class="flex items-center gap-2 border-b border-base-300 px-3">
        <span class="hero-magnifying-glass size-4 opacity-50" aria-hidden="true"></span>
        <input
          id={"#{@id}-search"}
          data-command-search
          autocomplete="off"
          aria-label={@placeholder}
          class="h-11 w-full bg-transparent text-sm outline-none"
          placeholder={@placeholder}
        />
        <span
          :if={@on_search}
          data-command-spinner
          class="loading loading-spinner loading-xs hidden shrink-0 opacity-50"
          aria-hidden="true"
        >
        </span>
      </div>
      <ul id={"#{@id}-list"} data-command-list class="max-h-80 overflow-auto p-1">
        <%= for {group, items} <- command_groups(@item) do %>
          <li :if={group} class="command-group-label" data-group>{group}</li>
          <li :for={item <- items}>
            <.command_item item={item} target={assigns[:"phx-target"]} />
          </li>
        <% end %>
      </ul>
      <p
        :if={@on_search && @hint != []}
        data-command-hint
        class="p-6 text-center text-sm text-muted-foreground"
      >
        {render_slot(@hint)}
      </p>
      <p data-command-empty class="hidden p-6 text-center text-sm text-muted-foreground">
        {if @empty == [], do: "No results found.", else: render_slot(@empty)}
      </p>
      <div
        :if={@on_search}
        id={"#{@id}-status"}
        data-command-status
        role="status"
        class="sr-only"
        phx-update="ignore"
      >
      </div>
      <div id={"#{@id}-toasts"} data-toast-host phx-update="ignore"></div>
    </dialog>
    """
  end

  # Server search: the event, the debounce, the text the items answer (absent
  # until there is one) and the target. None of it without `on_search`.
  defp command_search_attrs(%{on_search: nil}), do: []

  defp command_search_attrs(assigns) do
    [
      "data-on-search": assigns.on_search,
      "data-search-debounce": assigns.search_debounce,
      "data-query": assigns.query,
      "phx-target": assigns[:"phx-target"]
    ]
    |> Enum.reject(&is_nil(elem(&1, 1)))
  end

  attr(:item, :map, required: true)
  attr(:target, :any, default: nil)

  # A link when the item goes somewhere, a submit button for a form, else a
  # button running its phx-click. A disabled item is always an inert button.
  defp command_item(assigns) do
    item = assigns.item

    kind =
      cond do
        item[:disabled] -> :button
        item[:navigate] || item[:patch] || item[:href] -> :link
        item[:form] -> :submit
        true -> :button
      end

    assigns = assign(assigns, kind: kind, extra: command_item_attrs(item, assigns.target))

    ~H"""
    <.link
      :if={@kind == :link}
      id={@item[:id]}
      navigate={@item[:navigate]}
      patch={@item[:patch]}
      href={@item[:href]}
      class="command-item"
      data-command-item
      {@extra}
    >
      <.command_item_label item={@item} />
    </.link>
    <button
      :if={@kind == :submit}
      type="submit"
      id={@item[:id]}
      form={@item.form}
      name={@item[:name]}
      value={@item[:value]}
      class="command-item"
      data-command-item
      {@extra}
    >
      <.command_item_label item={@item} />
    </button>
    <button
      :if={@kind == :button}
      type="button"
      id={@item[:id]}
      class="command-item"
      data-command-item
      phx-click={!@item[:disabled] && @item[:"phx-click"]}
      {@extra}
    >
      <.command_item_label item={@item} />
    </button>
    """
  end

  # Opt-in item attributes. With none of them set (and no phx-target on the
  # palette) an item keeps its old markup exactly.
  defp command_item_attrs(item, target) do
    clickable = !item[:disabled]

    values =
      if clickable,
        do: for({key, value} <- item[:values] || %{}, do: {:"phx-value-#{key}", value}),
        else: []

    [
      "phx-target": clickable && item[:"phx-click"] && target,
      "data-confirm": clickable && item[:confirm],
      "aria-disabled": item[:disabled] && "true"
    ]
    |> Enum.filter(fn {_, v} -> v not in [nil, false] end)
    |> Kernel.++(values)
  end

  attr(:item, :map, required: true)

  # With a description, the label and a muted second line stack
  defp command_item_label(%{item: %{description: description}} = assigns)
       when is_binary(description) do
    ~H"""
    <span :if={@item[:icon]} class={[@item.icon, "size-4"]} aria-hidden="true"></span>
    <span class="command-item-text">
      <span class="command-item-title">{render_slot(@item)}</span>
      <span class="command-item-description">{@item.description}</span>
    </span>
    <span :if={@item[:shortcut]} class="ml-auto text-xs text-muted-foreground">
      {@item.shortcut}
    </span>
    """
  end

  defp command_item_label(assigns) do
    ~H"""
    <span :if={@item[:icon]} class={[@item.icon, "size-4"]} aria-hidden="true"></span>
    {render_slot(@item)}
    <span :if={@item[:shortcut]} class="ml-auto text-xs text-muted-foreground">
      {@item.shortcut}
    </span>
    """
  end

  # The browser owns a <dialog>'s `open` attribute (showModal/close); without
  # this a LiveView patch would strip it and close an open dialog.
  defp keep_open, do: JS.ignore_attributes(["open"])

  # Sheet / drawer: also keep the scroll-edge state the package JS sets on the
  # dialog (`data-scroll-top` / `data-scroll-bottom`, see shadcn-daisyui.js).
  defp keep_open_scrolled,
    do: JS.ignore_attributes(["open", "data-scroll-top", "data-scroll-bottom"])

  # Groups consecutive items by their :group attr, preserving order.
  defp command_groups(items) do
    items
    |> Enum.chunk_by(& &1[:group])
    |> Enum.map(fn [first | _] = chunk -> {first[:group], chunk} end)
  end
end
