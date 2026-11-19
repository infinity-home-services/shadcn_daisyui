defmodule ShadcnDaisyuiDemoWeb.CommandMenuLive do
  @moduledoc """
  `/lab/command-menu` (not in the static export): `<.command_menu>` in a
  connected LiveView, a few hundred rows long (40 brands with 8 locations
  each, the company, divisions and regions). Choosing a row pushes `pick`;
  the LiveView moves the check and renames the trigger, so the open/closed
  state, the filter and the placement survive the patch.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components.CommandMenu

  alias ShadcnDaisyuiDemoWeb.ScopeData

  @impl true
  def mount(_params, _session, socket) do
    rows = ScopeData.rows(40, 8)

    {:ok,
     assign(socket,
       page_title: "Command menu",
       rows: rows,
       current: ScopeData.find(rows, "acme")
     )}
  end

  @impl true
  def handle_event("pick", %{"id" => id}, socket),
    do: {:noreply, assign(socket, current: ScopeData.find(socket.assigns.rows, id))}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-2xl space-y-6 px-4 py-12 sm:px-6">
      <div class="space-y-1">
        <h1 class="text-3xl font-bold tracking-tight">Command menu</h1>
        <p class="text-sm text-muted-foreground">
          {length(@rows)} rows. Type a city, a store number or a brand; pick a row and the
          LiveView moves the check.
        </p>
      </div>

      <.command_menu id="scope" label="Switch location" placeholder="Search brands and locations">
        <:trigger>
          <span class="truncate">{@current.label}</span>
          <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
        </:trigger>
        <:item
          :for={row <- @rows}
          id={row.id}
          group={row.group}
          parent={row[:parent]}
          icon={row.icon}
          description={row[:description]}
          current={row.id == @current.id}
          phx-click="pick"
          values={%{id: row.id}}
        >
          {row.label}
        </:item>
        <:empty>No brand or location matches.</:empty>
      </.command_menu>

      <p id="chosen" class="text-sm text-muted-foreground">
        Showing <span class="font-medium text-foreground">{@current.label}</span>
      </p>
    </main>
    """
  end
end
