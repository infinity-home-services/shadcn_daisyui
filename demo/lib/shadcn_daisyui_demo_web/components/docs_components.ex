defmodule ShadcnDaisyuiDemoWeb.DocsComponents do
  @moduledoc """
  Shared chrome for the docs site: the top nav, the footer, the two-column docs
  shell (sticky sidebar + content), and the `preview_code` helper that renders a
  single raw HTML string both as a live preview and as an escaped code block.
  """
  use ShadcnDaisyuiDemoWeb, :html

  alias ShadcnDaisyuiDemoWeb.Catalog
  alias ShadcnDaisyuiDemoWeb.Guides

  @doc """
  Top navigation bar — shared by every page. `active` highlights a primary link
  (`:docs`, `:themes`, or `nil`).
  """
  attr :active, :atom, default: nil

  def site_header(assigns) do
    ~H"""
    <header class="sticky top-0 z-40 w-full border-b border-base-300 bg-base-100/85 backdrop-blur">
      <div class="mx-auto flex h-14 max-w-7xl items-center gap-6 px-4 sm:px-6 lg:px-8">
        <a href="/" class="flex items-center gap-2">
          <span class="grid size-7 place-items-center rounded-md bg-primary text-primary-content">
            <.icon name="hero-square-3-stack-3d" class="size-4" />
          </span>
          <span class="text-sm font-semibold tracking-tight">shadcn × daisyUI</span>
        </a>

        <nav class="hidden items-center gap-5 text-sm md:flex">
          <a
            href={~p"/docs/installation"}
            class={["transition-colors hover:text-foreground", nav_class(@active == :install)]}
          >
            Installation
          </a>
          <a
            href={~p"/docs/components/button"}
            class={["transition-colors hover:text-foreground", nav_class(@active == :docs)]}
          >
            Components
          </a>
          <a
            href={~p"/docs/themes"}
            class={["transition-colors hover:text-foreground", nav_class(@active == :themes)]}
          >
            Themes
          </a>
        </nav>

        <div class="flex flex-1 items-center justify-end gap-2">
          <button
            type="button"
            class="btn btn-outline btn-sm gap-2 font-normal text-muted-foreground"
            onclick="document.getElementById('docs-search-palette').showModal()"
            aria-label="Search components"
          >
            <.icon name="hero-magnifying-glass" class="size-4" />
            <span class="hidden sm:inline">Search</span>
            <kbd class="kbd kbd-sm">⌘K</kbd>
          </button>
          <a
            href="https://github.com/N00nDay/shadcn_daisyui"
            class="btn btn-ghost btn-sm btn-square"
            aria-label="GitHub repository"
          >
            <svg viewBox="0 0 16 16" class="size-4" fill="currentColor" aria-hidden="true">
              <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
            </svg>
          </a>
          <Layouts.theme_toggle />
        </div>
      </div>
    </header>
    """
  end

  defp nav_class(true), do: "font-medium text-foreground"
  defp nav_class(false), do: "text-muted-foreground"

  @doc "Site footer — shared by every page."
  def site_footer(assigns) do
    ~H"""
    <footer class="border-t border-base-300">
      <div class="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 px-4 py-8 text-sm text-muted-foreground sm:flex-row sm:px-6 lg:px-8">
        <p>
          Built with
          <a href="https://daisyui.com" class="link link-hover font-medium text-foreground">
            daisyUI v5
          </a>
          and the
          <a
            href="https://github.com/N00nDay/shadcn_daisyui"
            class="link link-hover font-medium text-foreground"
          >
            shadcn_daisyui
          </a>
          theme.
        </p>
        <p>Components styled to match shadcn/ui — for Phoenix.</p>
      </div>
    </footer>
    """
  end

  @doc """
  The two-column docs shell: a sticky sidebar listing every component grouped by
  section (current page highlighted) and a content slot for the right pane.
  """
  attr :active, :any, default: nil, doc: "slug of the current component page"
  attr :active_guide, :any, default: nil, doc: "slug of the current guide page"
  attr :active_nav, :atom, default: :docs
  slot :inner_block, required: true

  def docs_layout(assigns) do
    assigns = assign(assigns, :groups, Catalog.groups())

    ~H"""
    <div class="flex min-h-screen flex-col bg-base-100 text-base-content lg:h-screen lg:min-h-0 lg:overflow-hidden">
      <.site_header active={@active_nav} />

      <div class="mx-auto w-full max-w-7xl flex-1 px-4 sm:px-6 lg:grid lg:min-h-0 lg:grid-cols-[15rem_minmax(0,1fr)] lg:gap-10 lg:px-8">
        <%!-- Sidebar — its own scroll pane on desktop --%>
        <aside class="hidden lg:block lg:min-h-0">
          <div data-docs-sidebar class="h-full overflow-y-auto overscroll-contain">
            <nav class="space-y-6 py-8 pr-2">
              <div class="space-y-1">
                <p class="px-2 pb-1 text-xs font-semibold tracking-wide text-foreground">
                  Guides
                </p>
                <a
                  :for={g <- guides()}
                  href={"/docs/#{g.slug}"}
                  class={[
                    "block rounded-md px-2 py-1.5 text-sm transition-colors",
                    sidebar_link_class(@active_guide == g.slug)
                  ]}
                >
                  {g.title}
                </a>
              </div>

              <div :for={group <- Guides.groups()} class="space-y-1">
                <p class="px-2 pb-1 text-xs font-semibold tracking-wide text-foreground">
                  {group.title}
                </p>
                <a
                  :for={g <- group.guides}
                  href={g.path}
                  class={[
                    "block rounded-md px-2 py-1.5 text-sm transition-colors",
                    sidebar_link_class(@active_guide == g.slug)
                  ]}
                >
                  {g.title}
                </a>
              </div>

              <div :for={group <- @groups} class="space-y-1">
                <p class="px-2 pb-1 text-xs font-semibold tracking-wide text-foreground">
                  {group.title}
                </p>
                <a
                  :for={c <- group.components}
                  href={~p"/docs/components/#{c.slug}"}
                  class={[
                    "block rounded-md px-2 py-1.5 text-sm transition-colors",
                    sidebar_link_class(@active == c.slug)
                  ]}
                >
                  {c.title}
                </a>
              </div>
            </nav>
          </div>
        </aside>

        <%!-- Content — its own scroll pane on desktop --%>
        <main
          data-docs-main
          class="flex min-w-0 flex-col lg:min-h-0 lg:overflow-y-auto lg:overscroll-contain"
        >
          <div class="flex-1 py-8 lg:py-10">
            <%!-- Mobile component picker (sidebar is hidden below lg) --%>
            <details class="dropdown mb-6 w-full lg:hidden">
              <summary class="btn btn-outline w-full justify-between font-normal">
                <span>{mobile_summary(@groups, @active, @active_guide)}</span>
                <span class="hero-chevron-down size-4" aria-hidden="true"></span>
              </summary>
              <div class="dropdown-content z-30 mt-1 max-h-[70vh] w-full overflow-y-auto">
                <div class="p-2">
                  <div class="mb-2 space-y-0.5">
                    <p class="px-2 pb-1 text-xs font-semibold tracking-wide text-foreground">
                      Guides
                    </p>
                    <a
                      :for={g <- guides()}
                      href={"/docs/#{g.slug}"}
                      class={[
                        "block rounded-md px-2 py-1.5 text-sm",
                        sidebar_link_class(@active_guide == g.slug)
                      ]}
                    >
                      {g.title}
                    </a>
                  </div>
                  <div :for={group <- Guides.groups()} class="mb-2 space-y-0.5">
                    <p class="px-2 pb-1 text-xs font-semibold tracking-wide text-foreground">
                      {group.title}
                    </p>
                    <a
                      :for={g <- group.guides}
                      href={g.path}
                      class={[
                        "block rounded-md px-2 py-1.5 text-sm",
                        sidebar_link_class(@active_guide == g.slug)
                      ]}
                    >
                      {g.title}
                    </a>
                  </div>
                  <div :for={group <- @groups} class="mb-2 space-y-0.5">
                    <p class="px-2 pb-1 text-xs font-semibold tracking-wide text-foreground">
                      {group.title}
                    </p>
                    <a
                      :for={c <- group.components}
                      href={~p"/docs/components/#{c.slug}"}
                      class={[
                        "block rounded-md px-2 py-1.5 text-sm",
                        sidebar_link_class(@active == c.slug)
                      ]}
                    >
                      {c.title}
                    </a>
                  </div>
                </div>
              </div>
            </details>

            {render_slot(@inner_block)}
          </div>

          <.site_footer />
        </main>
      </div>
    </div>
    """
  end

  @doc false
  def guides do
    [%{slug: "installation", title: "Installation"}, %{slug: "themes", title: "Themes"}]
  end

  defp sidebar_link_class(true), do: "bg-muted font-medium text-foreground"
  defp sidebar_link_class(false), do: "text-muted-foreground hover:bg-muted hover:text-foreground"

  defp mobile_summary(groups, active, active_guide) do
    cond do
      guide = Enum.find(guides(), &(&1.slug == active_guide)) ->
        guide.title

      guide = Enum.find(Guides.all(), &(&1.slug == active_guide)) ->
        guide.title

      c = groups |> Enum.flat_map(& &1.components) |> Enum.find(&(&1.slug == active)) ->
        c.title

      true ->
        "Browse components"
    end
  end

  @doc """
  A titled, escaped code block with a copy button. Pure-HTML copy (inline
  `navigator.clipboard`) — no hook required.
  """
  attr :code, :string, required: true
  attr :language, :string, default: nil

  def code_block(assigns) do
    ~H"""
    <div data-code-block class="overflow-hidden rounded-lg border border-base-300 bg-base-200">
      <div
        :if={@language}
        class="flex items-center justify-between gap-2 border-b border-base-300 py-1 pl-4 pr-1.5"
      >
        <span class="font-mono text-xs text-muted-foreground">{@language}</span>
        <.code_copy_button />
      </div>
      <div class="relative">
        <.code_copy_button :if={!@language} class="absolute right-2 top-2 z-10" />
        <pre class="overflow-x-auto p-4 text-sm leading-relaxed"><code class="font-mono">{String.trim_trailing(@code)}</code></pre>
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil

  defp code_copy_button(assigns) do
    ~H"""
    <button
      type="button"
      aria-label="Copy code"
      class={["btn btn-ghost btn-xs btn-square", @class]}
      onclick="navigator.clipboard.writeText(this.closest('[data-code-block]').querySelector('pre').innerText); this.classList.add('text-success')"
    >
      <span class="hero-clipboard-document size-4" aria-hidden="true"></span>
    </button>
    """
  end

  @doc """
  Web | iOS | All filter for guideline pages. Buttons toggle a
  `data-platform-view` attribute on `<html>` (persisted in localStorage by
  `app.js`); CSS hides blocks marked `data-platform="web"`/`"ios"` accordingly.
  """
  def platform_toggle(assigns) do
    ~H"""
    <div data-platform-toggle role="group" aria-label="Filter by platform" class="tabs tabs-box w-fit">
      <button type="button" class="tab tab-active" data-platform-choice="all">All</button>
      <button type="button" class="tab" data-platform-choice="web">Web</button>
      <button type="button" class="tab" data-platform-choice="ios">iOS</button>
    </div>
    """
  end

  @doc """
  Header block for a guideline page: heading + platform toggle + a pointer to
  the portable markdown source (the agent-facing artifact).
  """
  attr :guide, :map, required: true

  def guide_heading(assigns) do
    ~H"""
    <.doc_heading title={@guide.title} description={@guide.description} />
    <div class="mt-6 flex flex-wrap items-center justify-between gap-3">
      <.platform_toggle />
      <p class="text-sm text-muted-foreground">
        Portable source:
        <a href={"#{@guide.path}.md"} class="link link-primary font-medium">
          usage-rules/{@guide.source}
        </a>
        · <a href="/design-guidelines.md" class="link link-hover">all-in-one bundle</a>
      </p>
    </div>
    """
  end

  @doc "Page heading for a component/guide page."
  attr :title, :string, required: true
  attr :description, :string, default: nil

  def doc_heading(assigns) do
    ~H"""
    <div class="space-y-2 border-b border-base-300 pb-6">
      <h1 class="text-3xl font-bold tracking-tight">{@title}</h1>
      <p :if={@description} class="text-lg text-muted-foreground">{@description}</p>
    </div>
    """
  end

  @doc """
  Callout shown on interactive component pages — points to the JS-hook setup.
  """
  def js_hook_callout(assigns) do
    ~H"""
    <div class="mt-6 flex gap-3 rounded-lg border border-base-300 bg-muted/40 px-4 py-3 text-sm">
      <span class="hero-bolt size-4 shrink-0 translate-y-0.5 text-foreground" aria-hidden="true">
      </span>
      <div class="space-y-1">
        <p class="font-medium text-foreground">Requires JavaScript</p>
        <p class="text-muted-foreground">
          This component is interactive. Register the package hooks in your
          <code class="rounded bg-muted px-1 py-0.5 font-mono text-xs">LiveSocket</code>
          (or call
          <code class="rounded bg-muted px-1 py-0.5 font-mono text-xs">initShadcnDaisyui()</code>
          for dead views) — see <a href={~p"/docs/installation"} class="link link-primary font-medium">
            Installation → Wire the JavaScript
          </a>.
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Usage-guidance panel for a component page: when to use / when not, plus
  sizing, responsive, and iOS notes. All keys optional.
  """
  attr :guidance, :map, required: true

  def guidance_panel(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="grid gap-4 sm:grid-cols-2">
        <div :if={@guidance[:use_when]} class="rounded-lg border border-success/40 p-4">
          <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-success">Use when</p>
          <ul class="list-inside list-disc space-y-1 text-sm">
            <li :for={item <- @guidance.use_when}>{item}</li>
          </ul>
        </div>
        <div :if={@guidance[:avoid_when]} class="rounded-lg border border-destructive/40 p-4">
          <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-destructive">
            Don't use for
          </p>
          <ul class="list-inside list-disc space-y-1 text-sm text-muted-foreground">
            <li :for={item <- @guidance.avoid_when}>{item}</li>
          </ul>
        </div>
      </div>
      <dl class="space-y-2 text-sm">
        <div :if={@guidance[:sizing]} class="flex gap-2">
          <dt class="w-28 shrink-0 font-medium">Sizing</dt>
          <dd class="text-muted-foreground">{@guidance.sizing}</dd>
        </div>
        <div :if={@guidance[:responsive]} class="flex gap-2">
          <dt class="w-28 shrink-0 font-medium">Responsive</dt>
          <dd class="text-muted-foreground">{@guidance.responsive}</dd>
        </div>
        <div :if={@guidance[:ios]} class="flex gap-2" data-platform="ios">
          <dt class="w-28 shrink-0 font-medium">iOS</dt>
          <dd class="text-muted-foreground">{@guidance.ios}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  API reference table for a component's function-component props.
  """
  attr :props, :list, required: true

  def props_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-base-300">
      <table class="table">
        <thead>
          <tr>
            <th class="w-40">Prop</th>
            <th>Type</th>
            <th class="w-28">Default</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={p <- @props}>
            <td class="font-mono text-sm font-medium">{p.name}</td>
            <td class="font-mono text-xs text-muted-foreground">{p.type}</td>
            <td class="font-mono text-xs text-muted-foreground">{Map.get(p, :default) || "—"}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a single raw HTML string as both a live preview (in a bordered frame)
  and an escaped code block, switchable with pure-CSS Preview|Code tabs.

      <.preview_code id="button-variants" code={~S(<button class="btn btn-primary">Hi</button>)} />

  `id` must be unique on the page (it names the radio group). Pass `center={false}`
  for examples that should not be centered (tables, full-width layouts).

  Pass `heex` (a function-component usage snippet) to add a HEEx tab between the
  preview and the raw markup — the raw tab is then labeled "HTML" instead of
  "Code".
  """
  attr :id, :string, required: true
  attr :code, :string, required: true
  attr :heex, :string, default: nil
  attr :center, :boolean, default: true

  def preview_code(assigns) do
    ~H"""
    <div class="tabs tabs-lift" role="tablist">
      <input
        type="radio"
        name={"tab-#{@id}"}
        class="tab [--tab-bg:var(--color-base-100)]"
        aria-label="Preview"
        checked
      />
      <div class="tab-content rounded-b-lg rounded-tr-lg border-base-300 bg-base-100">
        <div class={[
          "flex min-h-[20rem] w-full gap-4 p-8",
          if(@center, do: "flex-wrap items-center justify-center", else: "flex-col")
        ]}>
          {raw(@code)}
        </div>
      </div>

      <input
        :if={@heex}
        type="radio"
        name={"tab-#{@id}"}
        class="tab [--tab-bg:var(--color-base-200)]"
        aria-label="HEEx"
      />
      <div :if={@heex} class="tab-content rounded-b-lg rounded-tr-lg border-base-300 bg-base-200">
        <div data-code-block class="relative">
          <.code_copy_button class="absolute right-2 top-2 z-10 bg-base-200" />
          <pre class="max-h-[28rem] overflow-auto p-4 text-sm leading-relaxed"><code class="font-mono">{format_code(@heex)}</code></pre>
        </div>
      </div>

      <input
        type="radio"
        name={"tab-#{@id}"}
        class="tab [--tab-bg:var(--color-base-200)]"
        aria-label={if(@heex, do: "HTML", else: "Code")}
      />
      <div class="tab-content rounded-b-lg rounded-tr-lg border-base-300 bg-base-200">
        <div data-code-block class="relative">
          <.code_copy_button class="absolute right-2 top-2 z-10 bg-base-200" />
          <pre class="max-h-[28rem] overflow-auto p-4 text-sm leading-relaxed"><code class="font-mono">{format_code(@code)}</code></pre>
        </div>
      </div>
    </div>
    """
  end

  # Trim leading/trailing blank lines and a common indent so the code reads cleanly.
  defp format_code(code) do
    code
    |> String.trim_trailing()
    |> String.replace(~r/\A\n+/, "")
  end
end
