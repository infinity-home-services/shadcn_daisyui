defmodule ShadcnDaisyui.Components.Navigation do
  @moduledoc """
  Navigation components: tabs, breadcrumb, pagination, and the sidebar app shell.

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

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
