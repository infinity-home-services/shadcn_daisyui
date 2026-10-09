defmodule ShadcnDaisyuiDemoWeb.CspLive do
  @moduledoc """
  `/lab/csp` (not in the static export): the package overlays inside a connected LiveView under
  a strict `script-src 'self' 'nonce-…'` policy. A timer re-renders the view
  (including content inside the dialogs) twice a second; an open dialog must
  stay open across those patches (`JS.ignore_attributes(["open"])`).
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components.Overlay, only: [dialog: 1, sheet: 1, show_modal: 1]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(500, :tick)
    {:ok, assign(socket, ticks: 0, page_title: "CSP + LiveView patches")}
  end

  @impl true
  def handle_info(:tick, socket), do: {:noreply, update(socket, :ticks, &(&1 + 1))}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-2xl space-y-6 px-4 py-12 sm:px-6">
      <div class="space-y-1">
        <h1 class="text-3xl font-bold tracking-tight">CSP + LiveView patches</h1>
        <p class="text-sm text-muted-foreground">
          Served under <code class="rounded bg-muted px-1.5 py-0.5 font-mono text-xs">script-src 'self' 'nonce-…'</code>.
          Patches so far: <span id="tick-count" class="font-semibold">{@ticks}</span>
        </p>
      </div>

      <div class="flex flex-wrap gap-3">
        <.dialog id="live-dialog">
          <:trigger><button type="button" class="btn btn-outline">Open dialog</button></:trigger>
          <:title>Still open</:title>
          <:description>This text is patched every 500ms.</:description>
          <p class="text-sm">Patches while open: <span id="dialog-ticks">{@ticks}</span></p>
          <:actions>
            <form method="dialog"><button class="btn btn-outline">Close</button></form>
          </:actions>
        </.dialog>

        <.sheet id="live-sheet">
          <:trigger><button type="button" class="btn btn-outline">Open sheet</button></:trigger>
          <:title>Sheet</:title>
          <p class="text-sm">Patches while open: <span id="sheet-ticks">{@ticks}</span></p>
        </.sheet>

        <%!-- a custom trigger wired with the show_modal/1 JS command --%>
        <button type="button" class="btn btn-primary" phx-click={show_modal("live-dialog")}>
          show_modal("live-dialog")
        </button>
      </div>
    </main>
    """
  end
end
