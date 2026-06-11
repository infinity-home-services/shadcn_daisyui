defmodule ShadcnDaisyuiDemoWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ShadcnDaisyuiDemoWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Cmd+K search palette over the component catalog.

  Rendered once from the root layout so it is available on every page. Uses the
  design system's command-dialog markup: the bundled `shadcn-daisyui.js` already
  opens any `[data-command]` dialog on Cmd/Ctrl+K and filters its items, so all
  this has to do is render the items (one link per component, grouped like the
  sidebar). The header's Search button opens it; Cmd/Ctrl+K works everywhere.
  """
  def command_palette(assigns) do
    assigns = assign(assigns, :groups, ShadcnDaisyuiDemoWeb.Catalog.groups())

    ~H"""
    <dialog id="docs-search-palette" data-command class="command-dialog">
      <div class="flex items-center gap-2 border-b border-base-300 px-3">
        <.icon name="hero-magnifying-glass" class="size-4 opacity-50" />
        <input
          data-command-search
          class="h-11 w-full bg-transparent text-sm outline-none"
          placeholder="Search components…"
          aria-label="Search components"
        />
      </div>
      <ul data-command-list class="max-h-80 overflow-auto p-1">
        <li class="command-group-label" data-group>Guides</li>
        <li>
          <a class="command-item" data-command-item href={~p"/docs/installation"}>
            <.icon name="hero-book-open" class="size-4" /> Installation
          </a>
        </li>
        <li>
          <a class="command-item" data-command-item href={~p"/docs/themes"}>
            <.icon name="hero-swatch" class="size-4" /> Themes
          </a>
        </li>
        <%= for group <- ShadcnDaisyuiDemoWeb.Guides.groups() do %>
          <li class="command-group-label" data-group>{group.title}</li>
          <li :for={guide <- group.guides}>
            <a class="command-item" data-command-item href={guide.path}>
              {guide.title}
              <span class="ml-auto truncate text-xs text-muted-foreground">
                {guide.description}
              </span>
            </a>
          </li>
        <% end %>
        <%= for group <- @groups do %>
          <li class="command-group-label" data-group>{group.title}</li>
          <li :for={component <- group.components}>
            <a class="command-item" data-command-item href={~p"/docs/components/#{component.slug}"}>
              {component.title}
              <span class="ml-auto truncate text-xs text-muted-foreground">
                {component.description}
              </span>
            </a>
          </li>
        <% end %>
      </ul>
      <p data-command-empty class="hidden p-6 text-center text-sm text-muted-foreground">
        No results found.
      </p>
    </dialog>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div
      class="relative flex flex-row items-center border border-base-300 bg-base-200 rounded-full"
      role="group"
      aria-label="Theme"
    >
      <div class="absolute w-1/2 h-full rounded-full border border-base-300 bg-base-100 left-0 [[data-theme=shadcn-dark]_&]:left-1/2 transition-[left]" />

      <button
        class="relative flex p-2 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="shadcn"
        aria-label="Light theme"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="relative flex p-2 cursor-pointer w-1/2 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="shadcn-dark"
        aria-label="Dark theme"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
