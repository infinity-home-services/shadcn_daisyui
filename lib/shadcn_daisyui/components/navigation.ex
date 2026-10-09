defmodule ShadcnDaisyui.Components.Navigation do
  @moduledoc """
  Navigation components: tabs, link tabs with overflow (`tab_nav`), breadcrumb,
  pagination, and the sidebar app shell.

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Tabs with content panels (CSS-only, radio-based).

      <.tabs id="settings">
        <:tab label="Account" checked>Account settings…</:tab>
        <:tab label="Password">Password settings…</:tab>
      </.tabs>

  For tabs without panels use the raw classes:
  `<div role="tablist" class="tabs tabs-box">` + `<input type="radio" class="tab">`.
  """
  attr(:id, :string, required: true, doc: "groups the radio inputs")
  attr(:class, :any, default: nil)
  attr(:content_class, :any, default: "p-4")

  slot :tab, required: true do
    attr(:label, :string, required: true)
    attr(:checked, :boolean)
  end

  def tabs(assigns) do
    ~H"""
    <div role="tablist" class={["tabs tabs-box w-fit", @class]}>
      <%= for tab <- @tab do %>
        <input
          type="radio"
          name={@id}
          class="tab"
          aria-label={tab.label}
          checked={tab[:checked]}
        />
        <div class={["tab-content", @content_class]}>{render_slot(tab)}</div>
      <% end %>
    </div>
    """
  end

  @doc """
  A row of link tabs (views, saved filters, sections of a page) that fits its
  width. Needs the `ShadcnTabNav` hook.

  Tabs show while they fit; the ones that would be squeezed move, in order,
  into a trailing More menu, which also holds any `:menu_item`s. The `active`
  tab always stays visible (it swaps out the last visible one), and when an
  active `:menu_item` is in the menu the More trigger shows its name. When
  even the active tab and More don't fit side by side, every tab folds into
  the menu (the active one checked) and the trigger names the active tab with
  its count, truncating the label, never the count. The row re-fits on resize
  and after LiveView patches.

      <.tab_nav id="views" aria-label="Views">
        <:tab patch={~p"/issues"} active={@view == "all"} count={@counts.all}>All issues</:tab>
        <:tab patch={~p"/issues?view=active"} active={@view == "active"}>Active</:tab>
        <:tab patch={~p"/issues?view=backlog"} active={@view == "backlog"}>Backlog</:tab>
        <:menu_item group="Mine" patch={~p"/issues?view=triage"} active={@view == "triage"}>Triage</:menu_item>
        <:menu_item group="Shared" patch={~p"/issues?view=bugs"}>Open bugs</:menu_item>
        <:menu_item navigate={~p"/views"} icon="hero-cog-6-tooth">Manage views…</:menu_item>
      </.tab_nav>

  The root fills its container; inside a flex row give it `min-w-0 flex-1`.
  Consecutive `:menu_item`s with the same `group` share a labelled section.
  """
  attr(:id, :string, required: true)
  attr(:aria_label, :string, default: "Tabs", doc: "names the <nav> landmark")
  attr(:more_label, :string, default: "More")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :tab, required: true do
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
    attr(:active, :boolean)
    attr(:count, :any, doc: "a number shown in a muted pill after the label")
  end

  slot :menu_item, doc: "extra entries at the end of the More menu" do
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
    attr(:active, :boolean)
    attr(:group, :string, doc: "section label; consecutive items with the same group share it")
    attr(:icon, :string, doc: "heroicon class, e.g. \"hero-cog-6-tooth\"")
    attr(:"phx-click", :any)
  end

  def tab_nav(assigns) do
    assigns =
      assigns
      |> assign(:tabs, Enum.with_index(assigns.tab))
      |> assign(:active_item, Enum.find(assigns.menu_item, & &1[:active]))
      |> assign(:active_tab, Enum.find(assigns.tab, & &1[:active]))
      |> assign(:groups, menu_groups(assigns.menu_item))

    ~H"""
    <nav
      id={@id}
      phx-hook="ShadcnTabNav"
      phx-mounted={keep_client_attrs(["data-ready", "data-squeezed", "data-collapsed"])}
      data-tab-nav
      aria-label={@aria_label}
      class={["tab-nav", @class]}
      {@rest}
    >
      <div class="tabs tabs-box tab-nav-list">
        <div class="tab-nav-tabs" data-tab-nav-tabs>
          <.link
            :for={{tab, i} <- @tabs}
            navigate={tab[:navigate]}
            patch={tab[:patch]}
            href={tab[:href]}
            class={["tab", tab[:active] && "tab-active"]}
            aria-current={tab[:active] && "page"}
            data-tab-nav-item
            data-index={i}
            phx-mounted={keep_client_attrs(["hidden"])}
          >
            <span class="tab-nav-label">{render_slot(tab)}</span>
            <span :if={tab[:count] != nil} class="tab-count">{tab.count}</span>
          </.link>
        </div>
        <div
          class="tab-nav-more"
          data-tab-nav-more
          hidden={@menu_item == []}
          phx-mounted={keep_client_attrs(["hidden"])}
        >
          <button
            type="button"
            id={"#{@id}-more"}
            class={["tab", @active_item && "tab-active"]}
            aria-expanded="false"
            aria-controls={"#{@id}-menu"}
            data-tab-nav-trigger
            phx-mounted={keep_client_attrs(["aria-expanded"])}
          >
            <%= if @active_item do %>
              <span class="sr-only" data-tab-nav-default>{@more_label}: </span>
              <span class="tab-nav-label" data-tab-nav-default>{render_slot(@active_item)}</span>
            <% else %>
              <span class="tab-nav-label" data-tab-nav-default>{@more_label}</span>
            <% end %>
            <%!-- collapsed (every tab in the menu): the trigger names the active tab --%>
            <span :if={@active_tab} class="tab-nav-label" data-tab-nav-current>
              {render_slot(@active_tab)}
            </span>
            <span
              :if={@active_tab && @active_tab[:count] != nil}
              class="tab-count"
              data-tab-nav-current
            >
              {@active_tab.count}
            </span>
            <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
          </button>
          <div
            id={"#{@id}-menu"}
            class="popover-panel tab-nav-menu"
            data-tab-nav-menu
            hidden
            phx-mounted={keep_client_attrs(["hidden"])}
          >
            <div data-tab-nav-overflow hidden phx-mounted={keep_client_attrs(["hidden"])}>
              <.link
                :for={{tab, i} <- @tabs}
                navigate={tab[:navigate]}
                patch={tab[:patch]}
                href={tab[:href]}
                class="combo-item"
                aria-current={tab[:active] && "page"}
                tabindex="-1"
                data-tab-nav-copy
                data-index={i}
                hidden
                phx-mounted={keep_client_attrs(["hidden"])}
              >
                <span class="truncate">{render_slot(tab)}</span>
                <span :if={tab[:count] != nil} class="ml-auto font-mono text-xs text-muted-foreground">
                  {tab.count}
                </span>
                <span
                  :if={tab[:active]}
                  class={["hero-check size-4", tab[:count] == nil && "ml-auto"]}
                  aria-hidden="true"
                >
                </span>
              </.link>
            </div>
            <div
              :if={@menu_item != []}
              class="tab-nav-sep"
              data-tab-nav-sep
              hidden
              phx-mounted={keep_client_attrs(["hidden"])}
            >
            </div>
            <div
              :for={{{group, items}, gi} <- Enum.with_index(@groups)}
              role="group"
              aria-labelledby={group && "#{@id}-group-#{gi}"}
              class={gi > 0 && "tab-nav-group"}
            >
              <div :if={group} id={"#{@id}-group-#{gi}"} class="command-group-label">{group}</div>
              <.link
                :for={item <- items}
                navigate={item[:navigate]}
                patch={item[:patch]}
                href={item[:href]}
                phx-click={item[:"phx-click"]}
                class="combo-item"
                aria-current={item[:active] && "page"}
                tabindex="-1"
                data-tab-nav-entry
              >
                <span :if={item[:icon]} class={[item.icon, "size-4"]} aria-hidden="true"></span>
                <span class="truncate">{render_slot(item)}</span>
                <span :if={item[:active]} class="hero-check ml-auto size-4" aria-hidden="true"></span>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  # Attributes the hook owns (visibility, measured state, open/closed). A
  # LiveView patch would otherwise reset them to the server render for a frame.
  defp keep_client_attrs(attrs), do: JS.ignore_attributes(attrs)

  # Consecutive menu items with the same :group share a section, in order.
  defp menu_groups(items) do
    items
    |> Enum.chunk_by(& &1[:group])
    |> Enum.map(fn [first | _] = chunk -> {first[:group], chunk} end)
  end

  @doc """
  A breadcrumb trail. Items with `navigate`/`patch`/`href` render as links;
  the rest (typically the last) render as the current page.

      <.breadcrumb>
        <:item navigate={~p"/"}>Home</:item>
        <:item navigate={~p"/docs"}>Components</:item>
        <:item>Breadcrumb</:item>
      </.breadcrumb>
  """
  attr(:class, :any, default: nil)

  slot :item, required: true do
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
  end

  def breadcrumb(assigns) do
    ~H"""
    <nav class={["breadcrumbs text-sm", @class]} aria-label="Breadcrumb">
      <ul>
        <li :for={item <- @item}>
          <.link
            :if={item[:navigate] || item[:patch] || item[:href]}
            navigate={item[:navigate]}
            patch={item[:patch]}
            href={item[:href]}
          >
            {render_slot(item)}
          </.link>
          <span :if={!(item[:navigate] || item[:patch] || item[:href])} aria-current="page">
            {render_slot(item)}
          </span>
        </li>
      </ul>
    </nav>
    """
  end

  @doc ~S"""
  Pagination. Provide either `path` (a 1-arity fun returning the URL for a page,
  rendered as links) or `event` (a `phx-click` event receiving `phx-value-page`).

      <.pagination page={@page} total_pages={@total_pages} path={fn p -> ~p"/items?page=#{p}" end} />
      <.pagination page={@page} total_pages={@total_pages} event="paginate" />
  """
  attr(:page, :integer, required: true)
  attr(:total_pages, :integer, required: true)
  attr(:path, :any, default: nil, doc: "fn page -> url end; renders links")
  attr(:event, :string, default: nil, doc: "phx-click event name; sends phx-value-page")
  attr(:class, :any, default: nil)

  def pagination(assigns) do
    assigns = assign(assigns, :pages, page_window(assigns.page, assigns.total_pages))

    ~H"""
    <nav class={["flex items-center gap-1", @class]} aria-label="Pagination">
      <.page_button page={@page - 1} disabled={@page <= 1} path={@path} event={@event} class="btn btn-ghost btn-sm gap-1 px-2.5">
        <span class="hero-chevron-left size-4" aria-hidden="true"></span> Previous
      </.page_button>
      <%= for p <- @pages do %>
        <span :if={p == :gap} class="px-1.5 text-sm text-muted-foreground">…</span>
        <.page_button
          :if={p != :gap}
          page={p}
          disabled={false}
          path={@path}
          event={@event}
          current={p == @page}
          class={["btn btn-sm btn-square", (p == @page && "btn-outline") || "btn-ghost"]}
        >
          {p}
        </.page_button>
      <% end %>
      <.page_button page={@page + 1} disabled={@page >= @total_pages} path={@path} event={@event} class="btn btn-ghost btn-sm gap-1 px-2.5">
        Next <span class="hero-chevron-right size-4" aria-hidden="true"></span>
      </.page_button>
    </nav>
    """
  end

  attr(:page, :integer, required: true)
  attr(:disabled, :boolean, default: false)
  attr(:current, :boolean, default: false)
  attr(:path, :any, default: nil)
  attr(:event, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  defp page_button(%{path: path} = assigns) when is_function(path, 1) do
    ~H"""
    <.link
      navigate={!@disabled && @path.(@page)}
      class={[@class, @disabled && "btn-disabled"]}
      aria-current={@current && "page"}
      aria-disabled={@disabled && "true"}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp page_button(assigns) do
    ~H"""
    <button
      type="button"
      class={@class}
      disabled={@disabled}
      aria-current={@current && "page"}
      phx-click={@event}
      phx-value-page={@page}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  # 1 … (page-1) page (page+1) … last, degrading gracefully near the edges.
  defp page_window(_page, total) when total <= 7, do: Enum.to_list(1..max(total, 1))

  defp page_window(page, total) do
    middle = Enum.filter((page - 1)..(page + 1), &(&1 > 1 and &1 < total))

    [1] ++
      if(List.first(middle, 2) > 2, do: [:gap], else: []) ++
      middle ++
      if(List.last(middle, total - 1) < total - 1, do: [:gap], else: []) ++
      [total]
  end

  @doc """
  The sidebar app shell: a fixed-width sidebar next to the main content.

      <.sidebar_layout>
        <:sidebar>
          <.sidebar_group title="Platform">
            <:item navigate={~p"/"} active={@active == :dashboard}>Dashboard</:item>
            <:item navigate={~p"/projects"}>Projects</:item>
          </.sidebar_group>
        </:sidebar>
        {@inner_content}
      </.sidebar_layout>
  """
  attr(:class, :any, default: "h-dvh")
  attr(:sidebar_class, :any, default: "w-56")
  slot(:sidebar, required: true)
  slot(:inner_block, required: true)

  def sidebar_layout(assigns) do
    ~H"""
    <div class={["flex overflow-hidden", @class]}>
      <aside class={["shrink-0 overflow-y-auto border-r border-base-300 bg-base-100 p-2", @sidebar_class]}>
        {render_slot(@sidebar)}
      </aside>
      <main class="min-w-0 flex-1 overflow-y-auto">{render_slot(@inner_block)}</main>
    </div>
    """
  end

  @doc """
  A titled group of sidebar navigation items. Use inside `sidebar_layout`'s
  `:sidebar` slot.
  """
  attr(:title, :string, default: nil)
  attr(:class, :any, default: nil)

  slot :item, required: true do
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:href, :any)
    attr(:active, :boolean)
    attr(:"phx-click", :any)
  end

  def sidebar_group(assigns) do
    ~H"""
    <ul class={["menu w-full", @class]}>
      <li :if={@title} class="menu-title">{@title}</li>
      <li :for={item <- @item}>
        <.link
          navigate={item[:navigate]}
          patch={item[:patch]}
          href={item[:href]}
          phx-click={item[:"phx-click"]}
          class={item[:active] && "menu-active"}
        >
          {render_slot(item)}
        </.link>
      </li>
    </ul>
    """
  end
end
