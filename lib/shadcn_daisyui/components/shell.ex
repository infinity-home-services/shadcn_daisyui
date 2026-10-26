defmodule ShadcnDaisyui.Components.Shell do
  @moduledoc """
  The signed-in app shell: `app_shell/1`, `app_shell_heading/1` for the top
  of its sidebar, and `toggle_sidebar/1`.

  On wide screens (from 48rem) a sidebar that collapses to an icon rail; on
  phones a pinned top row, a bottom dock and a More sheet. `#main` is the
  page's one scroll region, and every page inside it starts with
  `<.page_header>` (from your app's `CoreComponents`). The theme toggle in its
  account menu is `ShadcnDaisyui.Components.theme_toggle/1`.

  The shell's behaviour lives in `shadcn-daisyui.js` (no hook needed): the
  `shadcn:toggle-sidebar` event and Cmd/Ctrl+B collapse the sidebar and
  remember it in localStorage (`shadcn:sidebar`), and the root layout's
  pre-paint script sets `data-sidebar` on `<html>` before first paint (see
  `mix shadcn_daisyui.install`). The sidebar's navigation (`#main-nav`) keeps
  its scroll position from page to page - across a LiveView navigation, which
  replaces the whole shell, and a full page load in the same tab
  (sessionStorage `shadcn:sidebar-scroll`) - restored before the new page
  paints, then scrolled just enough to show the active item if it's out of
  view.

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @bar_slots 4

  @doc """
  Returns a `Phoenix.LiveView.JS` command that collapses or expands the
  `app_shell/1` sidebar (and remembers it).

      <button phx-click={toggle_sidebar()}>Toggle sidebar</button>
  """
  def toggle_sidebar(js \\ %JS{}), do: JS.dispatch(js, "shadcn:toggle-sidebar")

  @doc ~S"""
  The app shell for a signed-in app.

      <.app_shell
        nav={@nav}
        active="orders"
        search="search"
        environment="Staging"
        person={%{name: @current_user.name, email: @current_user.email}}
      >
        <:header>
          <.app_shell_heading id="app-heading" icon="hero-cube" title="Acme" subtitle="Operations" />
        </:header>
        <:phone_header>
          <span class="app-shell-tile"><.icon name="hero-cube" /></span>
          <span class="text-sm font-semibold">Acme</span>
        </:phone_header>
        <:footer_item id="whats-new-open" icon="hero-megaphone" label="What's new" phx-click={show_modal("whats-new")} />
        <:account_item id="account" icon="hero-user-circle" navigate={~p"/account"}>Account</:account_item>
        <:account_item id="support" icon="hero-lifebuoy" soon divider>Support</:account_item>
        <:account_item
          id="sign-out"
          icon="hero-arrow-right-start-on-rectangle"
          href={~p"/sign-out"}
          method="delete"
          destructive
          divider
        >
          Sign out
        </:account_item>
        {@inner_content}
      </.app_shell>

      <.command id="search" label="Search" placeholder="Search pages">
        <:item :for={page <- pages} group="Pages" icon={page.icon} navigate={page.path}>{page.label}</:item>
      </.command>

  `nav` is the navigation as groups, in order:
  `[%{label: "Sales" | nil, items: [%{id: "orders", label: "Orders", short: "Orders", path: "/orders", icon: "hero-shopping-cart"}]}]`
  (`short` is the dock label, optional). `active` is the id of this page's
  item.

  **Wide screens**: a 16rem sidebar that collapses to a 3rem icon rail
  (`data-sidebar="collapsed"` on `<html>`; the grab strip on its edge, the
  "Collapse sidebar" row and Cmd/Ctrl+B toggle it). From the top: the
  `:header` slot (use `app_shell_heading/1`, or the `app-shell-label` class on
  what the rail should hide), the search row when `search` names a command
  dialog, the groups (small muted labels, the active item `aria-current`;
  they scroll, and keep their position from page to page), then the footer: `:footer_item`s, "Collapse sidebar", the `environment`
  badge and the account menu (opens right of the sidebar, bottom-aligned).

  **Phones**: a top row pinned while the page scrolls (`:phone_header`, then
  the search button), a bottom dock with up to four of `bar` plus More, and the
  More sheet: the `more` groups, the `:footer_item`s, then the account
  section. No hamburger.

  **Account menu**: the person's initials, name and email, then the
  `:account_item`s with the theme toggle closing their first section. An item
  is a link (`navigate` / `patch` / `href` + `method`) or a button
  (`phx-click`); `soon` marks one not built yet (muted, "Soon", no action),
  `divider` puts a line above it, `destructive` styles it destructive (sign
  out goes last). Rows are 32px in the menu, 44px in the More sheet.

  **Main**: `#main` is the one scroll region. Narrow pages keep their
  content to a reading width (48rem) and the page header still spans the
  page; `wide` uses the full width (tables), `fill` makes the content fill the
  window so a table body inside it scrolls instead. Dialogs (dialog, alert
  dialog, sheet, drawer, command) can sit anywhere in the page: the reading
  width never reaches them, so they open over the whole window.

  Ids (one shell per page): `shell`, `sidebar`, `sidebar-rail`,
  `search-open`, `main-nav`, `nav-<id>`, `sidebar-toggle`,
  `environment-badge`, `user-menu` (items `user-menu-<id>`), `main`,
  `phone-header`, `search-open-phone`, `bottom-bar`, `bar-<id>`, `bar-more`,
  `more-nav` (footer items `<id>-phone`, account items `account-phone-<id>`).
  """
  attr(:nav, :list,
    required: true,
    doc: "groups: [%{label, items: [%{id, label, short, path, icon}]}]"
  )

  attr(:bar, :list,
    default: nil,
    doc: "the phone dock's items before More (up to four); defaults to the first four of `more`"
  )

  attr(:more, :list,
    default: nil,
    doc: "the groups the phone's More sheet lists; defaults to `nav`"
  )

  attr(:active, :string, default: nil, doc: "the id of this page's navigation item")
  attr(:wide, :boolean, default: false, doc: "use the full content width (tables)")

  attr(:fill, :boolean,
    default: false,
    doc: "the content fills the window and a table body inside it scrolls"
  )

  attr(:search, :string,
    default: nil,
    doc: "the id of a `<.command>` dialog, or nil for no search"
  )

  attr(:search_shortcut, :any, default: "k", doc: "the search's Cmd/Ctrl letter (a hint), or nil")

  attr(:environment, :string,
    default: nil,
    doc: "badge text in the sidebar footer, e.g. \"Staging\""
  )

  attr(:person, :map, required: true, doc: "the signed-in person: %{name, email}")
  attr(:light_theme, :string, default: "shadcn", doc: "the theme toggle's light theme")
  attr(:dark_theme, :string, default: "shadcn-dark", doc: "the theme toggle's dark theme")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:header, doc: "the top of the sidebar; must read in the 3rem rail")
  slot(:phone_header, doc: "phones: the pinned top row, left of the search button")

  slot :footer_item, doc: "a row in the sidebar footer and in the More sheet" do
    attr(:id, :string, doc: "the sidebar row's id; the More sheet row gets `<id>-phone`")
    attr(:icon, :string, required: true)
    attr(:label, :string, required: true)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
    attr(:method, :string)
    attr(:"phx-click", :any)
  end

  slot :account_item, doc: "a row in the account menu and the More sheet's account section" do
    attr(:id, :string, doc: "ids `user-menu-<id>` (menu) and `account-phone-<id>` (sheet)")
    attr(:icon, :string)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
    attr(:method, :string)
    attr(:"phx-click", :any)
    attr(:soon, :boolean, doc: "not built yet: muted, marked Soon, no action")
    attr(:divider, :boolean, doc: "a line above this item")
    attr(:destructive, :boolean, doc: "destructive styling (sign out)")
  end

  slot(:inner_block, required: true)

  def app_shell(assigns) do
    more = assigns.more || assigns.nav

    bar =
      (assigns.bar || Enum.flat_map(more, & &1.items))
      |> Enum.take(@bar_slots)

    assigns =
      assign(assigns,
        more_groups: more,
        bar_items: bar,
        sections: account_sections(assigns.account_item),
        kbd:
          assigns.search_shortcut not in [nil, ""] &&
            "⌘" <> String.upcase(assigns.search_shortcut)
      )

    ~H"""
    <div id="shell" class={["app-shell", @class]} {@rest}>
      <aside id="sidebar" class="app-shell-sidebar">
        <button
          type="button"
          id="sidebar-rail"
          class="app-shell-rail"
          tabindex="-1"
          title="Collapse or expand the sidebar (Ctrl+B)"
          aria-label="Collapse or expand the sidebar"
          phx-click={toggle_sidebar()}
        >
        </button>
        <div class="app-shell-top">
          {render_slot(@header)}
          <button
            :if={@search}
            type="button"
            id="search-open"
            class="btn btn-outline btn-sm tooltip tooltip-right app-shell-search"
            data-tip={if @kbd, do: "Search (#{@kbd})", else: "Search"}
            aria-label="Search"
            phx-click={JS.dispatch("shadcn:show-dialog", to: "##{@search}")}
          >
            <span class="hero-magnifying-glass size-4 shrink-0" aria-hidden="true"></span>
            <span class="app-shell-label app-shell-grow">Search</span>
            <kbd :if={@kbd} class="kbd kbd-sm app-shell-label">{@kbd}</kbd>
          </button>
        </div>

        <nav id="main-nav" aria-label="Main" class="app-shell-nav">
          <div :for={group <- @nav}>
            <div :if={group[:label]} class="app-shell-group-label">{group.label}</div>
            <ul>
              <li :for={item <- group.items}>
                <.link
                  id={"nav-" <> item.id}
                  navigate={item.path}
                  data-tip={item.label}
                  aria-current={item.id == @active && "page"}
                  class="tooltip tooltip-right app-shell-item"
                >
                  <span class={[item.icon, "size-4 shrink-0"]} aria-hidden="true"></span>
                  <span class="app-shell-label">{item.label}</span>
                </.link>
              </li>
            </ul>
          </div>
        </nav>

        <div class="app-shell-footer">
          <.shell_action
            :for={item <- @footer_item}
            item={item}
            id={item[:id]}
            data-tip={item.label}
            class="tooltip tooltip-right app-shell-item"
          >
            <span class={[item.icon, "size-4 shrink-0"]} aria-hidden="true"></span>
            <span class="app-shell-label">{item.label}</span>
          </.shell_action>
          <button
            type="button"
            id="sidebar-toggle"
            data-tip="Expand sidebar (⌘B)"
            class="tooltip tooltip-right app-shell-item"
            phx-click={toggle_sidebar()}
          >
            <.sidebar_icon />
            <span class="app-shell-label app-shell-grow">Collapse sidebar</span>
            <kbd class="kbd kbd-sm app-shell-label">⌘B</kbd>
          </button>
          <span
            :if={@environment}
            id="environment-badge"
            class="badge badge-secondary app-shell-label app-shell-badge"
          >
            {@environment}
          </span>
          <div id="user-menu" class="dropdown dropdown-right dropdown-end app-shell-account">
            <div tabindex="0" role="button" aria-label="Account menu" class="app-shell-account-trigger">
              <.initials name={@person[:name]} />
              <.person name={@person[:name]} email={@person[:email]} class="app-shell-label" />
              <span
                class="hero-chevron-up-down size-4 shrink-0 app-shell-label app-shell-muted"
                aria-hidden="true"
              >
              </span>
            </div>
            <div tabindex="0" class="dropdown-content app-shell-menu">
              <div class="app-shell-person-heading">
                <.initials name={@person[:name]} />
                <.person name={@person[:name]} email={@person[:email]} />
              </div>
              <div class="app-shell-sep"></div>
              <.account_rows
                sections={@sections}
                prefix="user-menu-"
                light={@light_theme}
                dark={@dark_theme}
              />
            </div>
          </div>
        </div>
      </aside>

      <div class="app-shell-content">
        <main id="main" class="app-shell-main">
          <div id="phone-header" class="app-shell-phone-header">
            {render_slot(@phone_header)}
            <button
              :if={@search}
              type="button"
              id="search-open-phone"
              aria-label="Search"
              class="btn btn-outline btn-sm btn-circle app-shell-phone-search"
              phx-click={JS.dispatch("shadcn:show-dialog", to: "##{@search}")}
            >
              <span class="hero-magnifying-glass size-4" aria-hidden="true"></span>
            </button>
          </div>
          <div class="app-shell-page" data-wide={@wide} data-fill={@fill}>
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <nav id="bottom-bar" aria-label="Main" class="dock app-shell-dock">
        <.link
          :for={item <- @bar_items}
          id={"bar-" <> item.id}
          navigate={item.path}
          aria-current={item.id == @active && "page"}
          class={item.id == @active && "dock-active"}
        >
          <span class={[item.icon, "size-5"]} aria-hidden="true"></span>
          <span class="dock-label">{item[:short] || item.label}</span>
        </.link>
        <button
          type="button"
          id="bar-more"
          aria-haspopup="dialog"
          phx-click={JS.dispatch("shadcn:show-dialog", to: "#more-nav")}
        >
          <span class="hero-ellipsis-horizontal size-5" aria-hidden="true"></span>
          <span class="dock-label">More</span>
        </button>
      </nav>

      <dialog
        id="more-nav"
        class="drawer-bottom app-shell-more"
        aria-label="More"
        phx-mounted={JS.ignore_attributes(["open"])}
      >
        <div class="app-shell-handle" aria-hidden="true"></div>
        <div class="app-shell-more-body">
          <div :for={group <- @more_groups}>
            <div :if={group[:label]} class="app-shell-more-label">{group.label}</div>
            <.link
              :for={item <- group.items}
              navigate={item.path}
              aria-current={item.id == @active && "page"}
              class="app-shell-sheet-row"
            >
              <span class={[item.icon, "size-5"]} aria-hidden="true"></span> {item.label}
            </.link>
          </div>
          <.shell_action
            :for={item <- @footer_item}
            item={item}
            id={item[:id] && item[:id] <> "-phone"}
            class="app-shell-sheet-row"
          >
            <span class={[item.icon, "size-5"]} aria-hidden="true"></span> {item.label}
          </.shell_action>
          <div id="account-phone" class="app-shell-more-account">
            <div class="app-shell-person-heading">
              <.initials name={@person[:name]} />
              <.person name={@person[:name]} email={@person[:email]} />
            </div>
            <div class="app-shell-sep"></div>
            <.account_rows
              sections={@sections}
              prefix="account-phone-"
              light={@light_theme}
              dark={@dark_theme}
            />
          </div>
        </div>
      </dialog>
    </div>
    """
  end

  # Account items split into sections at each `divider` (a leading divider is
  # ignored: the person heading already has a line under it).
  defp account_sections(items) do
    Enum.chunk_while(
      items,
      [],
      fn item, acc ->
        if item[:divider] && acc != [],
          do: {:cont, Enum.reverse(acc), [item]},
          else: {:cont, [item | acc]}
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, Enum.reverse(acc), []}
      end
    )
  end

  attr(:sections, :list, required: true)
  attr(:prefix, :string, required: true)
  attr(:light, :string, required: true)
  attr(:dark, :string, required: true)

  # The account items, with the theme row closing the first section.
  defp account_rows(assigns) do
    assigns =
      assign(assigns,
        first: List.first(assigns.sections, []),
        rest: Enum.drop(assigns.sections, 1)
      )

    ~H"""
    <.account_row :for={item <- @first} item={item} prefix={@prefix} />
    <div class="app-shell-menu-row app-shell-theme-row">
      <span class="app-shell-theme-label">
        <span class="hero-swatch size-4" aria-hidden="true"></span> Theme
      </span>
      <ShadcnDaisyui.Components.theme_toggle light={@light} dark={@dark} />
    </div>
    <%= for section <- @rest do %>
      <div class="app-shell-sep"></div>
      <.account_row :for={item <- section} item={item} prefix={@prefix} />
    <% end %>
    """
  end

  attr(:item, :map, required: true)
  attr(:prefix, :string, required: true)

  defp account_row(%{item: %{soon: true}} = assigns) do
    ~H"""
    <div id={@item[:id] && @prefix <> @item.id} class="app-shell-menu-row" data-soon>
      <span :if={@item[:icon]} class={[@item.icon, "size-4 shrink-0"]} aria-hidden="true"></span>
      <span class="app-shell-grow">{render_slot(@item)}</span>
      <span class="badge badge-outline">Soon</span>
    </div>
    """
  end

  defp account_row(assigns) do
    ~H"""
    <.shell_action
      item={@item}
      id={@item[:id] && @prefix <> @item.id}
      class="app-shell-menu-row"
      data-variant={@item[:destructive] && "destructive"}
    >
      <span :if={@item[:icon]} class={[@item.icon, "size-4 shrink-0"]} aria-hidden="true"></span>
      {render_slot(@item)}
    </.shell_action>
    """
  end

  attr(:item, :map, required: true, doc: "a slot entry with navigate/patch/href/method/phx-click")
  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  # A footer or account row: a link when it goes somewhere, else a button.
  defp shell_action(assigns) do
    assigns = assign(assigns, :link, link_attrs(assigns.item))

    ~H"""
    <.link :if={@link != []} id={@id} class={@class} {@link} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={@link == []}
      type="button"
      id={@id}
      class={@class}
      phx-click={@item[:"phx-click"]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp link_attrs(item) do
    attrs =
      for key <- [:navigate, :patch, :href],
          value = item[key],
          value not in [nil, false],
          do: {key, value}

    cond do
      attrs == [] -> []
      item[:method] -> attrs ++ [method: item.method]
      true -> attrs
    end
  end

  attr(:name, :string, default: nil)

  defp initials(assigns) do
    ~H"""
    <span class="app-shell-avatar">{initials_of(@name)}</span>
    """
  end

  defp initials_of(nil), do: "?"

  defp initials_of(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
    |> case do
      "" -> "?"
      initials -> initials
    end
  end

  attr(:name, :string, default: nil)
  attr(:email, :string, default: nil)
  attr(:class, :any, default: nil)

  # Name over email (the email alone when there is no name).
  defp person(assigns) do
    ~H"""
    <span class={["app-shell-person", @class]}>
      <span class="app-shell-name">{@name || @email}</span>
      <span :if={@name && @email} class="app-shell-email">{@email}</span>
    </span>
    """
  end

  # A panel with its left side split off. Heroicons has no sidebar icon; this
  # matches its outline style.
  defp sidebar_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class="size-4 shrink-0"
    >
      <rect x="3" y="4.5" width="18" height="15" rx="2.25" />
      <path d="M9 4.5v15" />
    </svg>
    """
  end

  @doc ~S"""
  The heading at the top of the `app_shell/1` sidebar: a tile, a title and a
  subtitle, bordered like shadcn's team switcher. In the collapsed rail only
  the tile shows, and `tip` becomes its tooltip.

      <:header>
        <.app_shell_heading id="app-heading" icon="hero-cube" title="Acme" subtitle="Operations" tip="Acme · Operations" />
      </:header>

  As a menu trigger (a switcher), pass `chevron` and the trigger attributes,
  inside your own `dropdown`:

      <div class="dropdown dropdown-right w-full">
        <.app_shell_heading tabindex="0" role="button" icon="hero-building-office-2"
          title={@team.name} subtitle={@location} tip={@label} chevron />
        <div tabindex="0" class="dropdown-content app-shell-menu w-64">…</div>
      </div>
  """
  attr(:icon, :string, required: true, doc: "heroicon in the tile, e.g. \"hero-cube\"")
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:tip, :string, default: nil, doc: "tooltip in the collapsed rail")
  attr(:chevron, :boolean, default: false, doc: "a trailing up/down chevron (a menu trigger)")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(tabindex role))

  def app_shell_heading(assigns) do
    ~H"""
    <div
      class={["app-shell-heading", @tip && "tooltip tooltip-right", @class]}
      data-tip={@tip}
      {@rest}
    >
      <span class="app-shell-tile"><span class={[@icon, "size-4"]} aria-hidden="true"></span></span>
      <span class="app-shell-label app-shell-heading-text">
        <span class="app-shell-heading-title">{@title}</span>
        <span :if={@subtitle} class="app-shell-heading-subtitle">{@subtitle}</span>
      </span>
      <span
        :if={@chevron}
        class="hero-chevron-up-down size-4 shrink-0 app-shell-label app-shell-muted"
        aria-hidden="true"
      >
      </span>
    </div>
    """
  end
end
