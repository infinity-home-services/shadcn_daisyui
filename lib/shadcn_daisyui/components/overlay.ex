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
      </.sheet>
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger)
  slot(:title)
  slot(:description)
  slot(:inner_block)

  def sheet(assigns) do
    ~H"""
    <span :if={@trigger != []} phx-click={show_modal(@id)}>
      {render_slot(@trigger)}
    </span>
    <dialog id={@id} class={["sheet", @class]} phx-mounted={keep_open()} {@rest}>
      <button
        type="button"
        class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
        aria-label="Close"
        phx-click={hide_modal(@id)}
      >
        <span class="hero-x-mark size-4" aria-hidden="true"></span>
      </button>
      <h3 :if={@title != []} class="text-lg font-semibold">{render_slot(@title)}</h3>
      <p :if={@description != []} class="mt-1 text-sm text-muted-foreground">
        {render_slot(@description)}
      </p>
      <div class="mt-5">{render_slot(@inner_block)}</div>
    </dialog>
    """
  end

  @doc """
  A drawer - a panel that slides up from the bottom (Vaul-style).

      <.drawer id="goal">
        <:trigger><.button variant="outline">Open drawer</.button></:trigger>
        …content…
      </.drawer>
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger)
  slot(:inner_block, required: true)

  def drawer(assigns) do
    ~H"""
    <span :if={@trigger != []} phx-click={show_modal(@id)}>
      {render_slot(@trigger)}
    </span>
    <dialog id={@id} class={["drawer-bottom", @class]} phx-mounted={keep_open()} {@rest}>
      <div class="mx-auto mb-4 h-1.5 w-12 rounded-full bg-muted"></div>
      {render_slot(@inner_block)}
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

  attr(:rest, :global)

  slot(:trigger, required: true)
  slot(:label, doc: "a non-interactive section title")

  slot :item do
    attr(:class, :any)
    attr(:"phx-click", :any)
    attr(:"phx-value-id", :any)
  end

  def dropdown_menu(assigns) do
    ~H"""
    <div class={["dropdown", @align == "end" && "dropdown-end"]} {@rest}>
      <div tabindex="0" role="button" class={@trigger_class} aria-label={assigns[:"aria-label"]}>
        {render_slot(@trigger)}
        <span :if={@chevron} class="hero-chevron-down size-4" aria-hidden="true"></span>
      </div>
      <ul tabindex="0" class={["dropdown-content menu z-50 mt-2", @class]}>
        <li :if={@label != []} class="menu-title">{render_slot(@label)}</li>
        <li :for={item <- @item}>
          <a class={item[:class]} phx-click={item[:"phx-click"]} phx-value-id={item[:"phx-value-id"]}>
            {render_slot(item)}
          </a>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  A command palette (searchable action list in a modal). Needs the
  `ShadcnCommand` hook. Also opens with ⌘K.

      <.command id="commands">
        <:trigger_label>Search commands…</:trigger_label>
        <:item group="Suggestions" icon="hero-calendar">Calendar</:item>
        <:item group="Suggestions" icon="hero-calculator">Calculator</:item>
        <:item group="Settings" icon="hero-user" shortcut="⌘P">Profile</:item>
      </.command>
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Type a command or search…")
  attr(:class, :any, default: nil)
  slot(:trigger_label, doc: "text inside the default trigger button")

  slot :item, required: true do
    attr(:group, :string)
    attr(:icon, :string, doc: "heroicon class, e.g. \"hero-calendar\"")
    attr(:shortcut, :string)
    attr(:"phx-click", :any)
  end

  def command(assigns) do
    ~H"""
    <button
      :if={@trigger_label != []}
      type="button"
      class="btn btn-outline w-64 justify-between"
      phx-click={show_modal(@id)}
    >
      <span class="text-muted-foreground">{render_slot(@trigger_label)}</span>
      <kbd class="kbd">⌘K</kbd>
    </button>
    <dialog
      id={@id}
      phx-hook="ShadcnCommand"
      phx-mounted={keep_open()}
      data-command
      class={["command-dialog", @class]}
    >
      <div class="flex items-center gap-2 border-b border-base-300 px-3">
        <span class="hero-magnifying-glass size-4 opacity-50" aria-hidden="true"></span>
        <input
          data-command-search
          class="h-11 w-full bg-transparent text-sm outline-none"
          placeholder={@placeholder}
        />
      </div>
      <ul data-command-list class="max-h-80 overflow-auto p-1">
        <%= for {group, items} <- command_groups(@item) do %>
          <li :if={group} class="command-group-label" data-group>{group}</li>
          <li :for={item <- items}>
            <button type="button" class="command-item" data-command-item phx-click={item[:"phx-click"]}>
              <span :if={item[:icon]} class={[item.icon, "size-4"]} aria-hidden="true"></span>
              {render_slot(item)}
              <span :if={item[:shortcut]} class="ml-auto text-xs text-muted-foreground">
                {item.shortcut}
              </span>
            </button>
          </li>
        <% end %>
      </ul>
      <p data-command-empty class="hidden p-6 text-center text-sm text-muted-foreground">
        No results found.
      </p>
    </dialog>
    """
  end

  # The browser owns a <dialog>'s `open` attribute (showModal/close); without
  # this a LiveView patch would strip it and close an open dialog.
  defp keep_open, do: JS.ignore_attributes(["open"])

  # Groups consecutive items by their :group attr, preserving order.
  defp command_groups(items) do
    items
    |> Enum.chunk_by(& &1[:group])
    |> Enum.map(fn [first | _] = chunk -> {first[:group], chunk} end)
  end
end
