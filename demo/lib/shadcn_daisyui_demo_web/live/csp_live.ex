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

  The width-aware rows ride the same patches: a `<.tab_nav>` whose counts
  change width on every tick (it must re-fit without a visible jump, keep the
  `?view=` tab visible and keep its More menu open), and a `<.chip_row>` of
  the active filters inside a `<.reveal>` (removing a chip is a server event;
  focus lands on its neighbour).

  Toasts and flashes must show above an open sheet or dialog and stay
  clickable: the buttons inside them `put_flash` and `push_toast` while the
  patches keep running (the toast layer sits in the dialog's ignored
  `[data-toast-host]`, so patches must not drop it).
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components.Overlay, only: [dialog: 1, sheet: 1, show_modal: 1]
  import ShadcnDaisyui.Components, only: [select: 1, combobox: 1, date_range: 1]
  import ShadcnDaisyui.Components.Navigation, only: [tab_nav: 1]
  import ShadcnDaisyui.Components.Display, only: [chip_row: 1, reveal: 1, push_toast: 3]

  @empty %{"status" => [], "labels" => [], "from" => "", "to" => ""}
  @labels ~w(bug docs feature perf security ui)
  @views ~w(all active backlog triage review done canceled)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(500, :tick)

    {:ok,
     socket
     |> assign(ticks: 0, changes: 0, page_title: "CSP + LiveView patches", labels: @labels)
     |> assign(views: @views, view: "all")
     |> assign_filters(@empty)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, view: Map.get(params, "view", "all"))}
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    {:noreply, socket |> update(:changes, &(&1 + 1)) |> assign_filters(params)}
  end

  def handle_event("reset", _params, socket), do: {:noreply, assign_filters(socket, @empty)}

  def handle_event("flash", %{"kind" => kind}, socket) do
    msg = if kind == "info", do: "Profile saved", else: "Could not save the profile"

    {:noreply,
     put_flash(socket, String.to_existing_atom(kind), "#{msg} (tick #{socket.assigns.ticks})")}
  end

  def handle_event("toast", _params, socket) do
    {:noreply,
     push_toast(socket, "Event has been created",
       description: "Pushed from the LiveView at tick #{socket.assigns.ticks}",
       action: %{label: "Undo", event: "undo"}
     )}
  end

  def handle_event("undo", _params, socket),
    do: {:noreply, put_flash(socket, :info, "Undone from the toast")}

  def handle_event("remove_chip", %{"field" => field, "value" => value}, socket) do
    params = Map.update!(socket.assigns.params, field, &List.delete(&1, value))
    {:noreply, assign_filters(socket, params)}
  end

  defp assign_filters(socket, params) do
    params =
      Map.merge(@empty, Map.new(params, fn {k, v} -> {k, if(v == "", do: [], else: v)} end))

    params = Map.update!(params, "from", &if(&1 == [], do: "", else: &1))
    params = Map.update!(params, "to", &if(&1 == [], do: "", else: &1))
    assign(socket, params: params, form: to_form(params, as: :filters))
  end

  @impl true
  def handle_info(:tick, socket), do: {:noreply, update(socket, :ticks, &(&1 + 1))}

  # Phoenix 1.8's generated Layouts.flash_group, calling the package flash/1
  # (the demo's own CoreComponents is the stock generated one).
  defp lab_flash_group(assigns) do
    ~H"""
    <div id="flash-group" aria-live="polite">
      <ShadcnDaisyui.CoreComponents.flash kind={:info} flash={@flash} />
      <ShadcnDaisyui.CoreComponents.flash kind={:error} flash={@flash} />
      <ShadcnDaisyui.CoreComponents.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
      </ShadcnDaisyui.CoreComponents.flash>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.lab_flash_group flash={@flash} />
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
          <div class="mt-4 flex flex-wrap gap-2">
            <button
              id="sheet-flash-info"
              type="button"
              class="btn btn-outline btn-sm"
              phx-click="flash"
              phx-value-kind="info"
            >
              Flash info
            </button>
            <button
              id="sheet-flash-error"
              type="button"
              class="btn btn-outline btn-sm"
              phx-click="flash"
              phx-value-kind="error"
            >
              Flash error
            </button>
            <button id="sheet-toast" type="button" class="btn btn-outline btn-sm" phx-click="toast">
              push_toast
            </button>
          </div>
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

      <.reveal id="chips-reveal" open={chips(@params) != []} class="max-w-sm">
        <.chip_row id="lab-chips" aria-label="Active filters">
          <:chip
            :for={{field, value} <- chips(@params)}
            value={"#{field}:#{value}"}
            on_remove={JS.push("remove_chip", value: %{field: field, value: value})}
          >
            {String.capitalize(field)}: {value}
          </:chip>
          <:action>
            <button type="button" class="btn btn-ghost btn-sm" phx-click="reset">Clear all</button>
          </:action>
        </.chip_row>
      </.reveal>

      <.tab_nav id="lab-views" aria-label="Views">
        <:tab
          :for={{v, i} <- Enum.with_index(@views)}
          patch={~p"/lab/csp?view=#{v}"}
          active={@view == v}
          count={rem(@ticks * (i + 3), 1000)}
        >
          {String.capitalize(v)}
        </:tab>
        <:menu_item group="Shared" patch={~p"/lab/csp?view=bugs"} active={@view == "bugs"}>
          Open bugs
        </:menu_item>
        <:menu_item patch={~p"/lab/csp"} icon="hero-cog-6-tooth">Manage views…</:menu_item>
      </.tab_nav>
      <p class="text-sm text-muted-foreground">
        View: <span id="current-view" class="font-semibold">{@view}</span>
      </p>
    </main>
    """
  end

  defp chips(params) do
    for field <- ~w(status labels), value <- List.wrap(params[field]), do: {field, value}
  end
end
