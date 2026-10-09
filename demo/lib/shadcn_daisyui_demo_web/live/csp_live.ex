defmodule ShadcnDaisyuiDemoWeb.CspLive do
  @moduledoc """
  `/lab/csp` (not in the static export): the package overlays inside a connected LiveView under
  a strict `script-src 'self' 'nonce-…'` policy. A timer re-renders the view
  (including content inside the dialogs) twice a second; an open dialog must
  stay open across those patches (`JS.ignore_attributes(["open"])`).

  The form below does the same for the hook-driven pickers: a multiple select,
  a multiple combobox whose counts change on every tick, and a date range with
  presets. Each must stay open across patches, fire `phx-change` on every
  toggle, and adopt a server-side reset.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components.Overlay, only: [dialog: 1, sheet: 1, show_modal: 1]
  import ShadcnDaisyui.Components, only: [select: 1, combobox: 1, date_range: 1]

  @empty %{"status" => [], "labels" => [], "from" => "", "to" => ""}
  @labels ~w(bug docs feature perf security ui)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(500, :tick)

    {:ok,
     socket
     |> assign(ticks: 0, changes: 0, page_title: "CSP + LiveView patches", labels: @labels)
     |> assign_filters(@empty)}
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    {:noreply, socket |> update(:changes, &(&1 + 1)) |> assign_filters(params)}
  end

  def handle_event("reset", _params, socket), do: {:noreply, assign_filters(socket, @empty)}

  defp assign_filters(socket, params) do
    params =
      Map.merge(@empty, Map.new(params, fn {k, v} -> {k, if(v == "", do: [], else: v)} end))

    params = Map.update!(params, "from", &if(&1 == [], do: "", else: &1))
    params = Map.update!(params, "to", &if(&1 == [], do: "", else: &1))
    assign(socket, params: params, form: to_form(params, as: :filters))
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

      <.form for={@form} id="filters" phx-change="filter" class="space-y-4">
        <div class="flex flex-wrap items-start gap-3">
          <.select
            id="status"
            field={@form[:status]}
            multiple
            placeholder="Status"
            aria-label="Status"
          >
            <:option value="todo" count={3}>Todo</:option>
            <:option value="in-progress" count={5}>In progress</:option>
            <:option value="done" count={8}>Done</:option>
            <:option value="canceled" count={1}>Canceled</:option>
          </.select>
          <.combobox
            id="labels"
            field={@form[:labels]}
            multiple
            placeholder="Labels"
            aria-label="Labels"
          >
            <:option :for={{l, i} <- Enum.with_index(@labels)} value={l} count={rem(@ticks + i, 10)}>
              {String.capitalize(l)}
            </:option>
          </.combobox>
          <.date_range
            id="period"
            start_name={@form[:from].name}
            end_name={@form[:to].name}
            start={@form[:from].value}
            end={@form[:to].value}
          >
            <:preset
              label="Last 7 days"
              start={Date.add(Date.utc_today(), -6)}
              end={Date.utc_today()}
            />
            <:preset
              label="Last 30 days"
              start={Date.add(Date.utc_today(), -29)}
              end={Date.utc_today()}
            />
            <:preset
              label="This month"
              start={Date.beginning_of_month(Date.utc_today())}
              end={Date.utc_today()}
            />
          </.date_range>
          <button type="button" class="btn btn-ghost" phx-click="reset">Reset</button>
        </div>
        <p class="text-sm text-muted-foreground">
          phx-change events: <span id="change-count" class="font-semibold">{@changes}</span>
        </p>
        <pre id="params" class="rounded-md bg-muted p-3 font-mono text-xs">{inspect(@params)}</pre>
      </.form>
    </main>
    """
  end
end
