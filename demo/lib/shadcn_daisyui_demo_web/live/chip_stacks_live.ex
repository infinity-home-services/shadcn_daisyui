defmodule ShadcnDaisyuiDemoWeb.ChipStacksLive do
  @moduledoc """
  `/lab/chip-stacks` (not in the static export): stacked filter chips in a
  `<.table_toolbar>` inside a pinned `<.page_header>`'s `:below`, in a real
  `<.app_shell>` under the lab's strict CSP, with the filters in the URL
  (`ShadcnDaisyui.DataTable.State`). It re-renders twice a second, so an open
  stack has to survive patches; "Add a brand" changes a stack from the server.
  Everything is made up.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components, only: [select: 1]
  import ShadcnDaisyui.Components.DataTable
  import ShadcnDaisyuiDemoWeb.CoreComponents, only: []
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1, button: 1]
  import ShadcnDaisyuiDemoWeb.LabOrders, only: [lab_shell: 1]

  alias ShadcnDaisyui.DataTable.State

  @brands [
    {"Acme sandbox", "acme"},
    {"Northwind", "northwind"},
    {"Northwind sandbox", "northwind-sandbox"},
    {"A brand with a very long name indeed, for truncation", "long"},
    {"Northgate", "northgate"},
    {"Lakeside", "lakeside"},
    {"Summit", "summit"}
  ]
  @statuses [{"Open", "open"}, {"Paid", "paid"}, {"Overdue", "overdue"}]
  @owners [{"Pat Lee", "pat"}, {"Sam Okafor", "sam"}]
  @regions [{"North", "north"}, {"South", "south"}, {"East", "east"}, {"West", "west"}]
  @plans [{"Starter", "starter"}, {"Team", "team"}]

  @fields ~w(brand status owner region plan)
  @options %{
    "brand" => @brands,
    "status" => @statuses,
    "owner" => @owners,
    "region" => @regions,
    "plan" => @plans
  }
  @opts [filters: Map.new(@fields, &{&1, "any"})]
  @start %{
    "brand" => "acme,northwind,northwind-sandbox",
    "status" => "open,paid",
    "owner" => "pat",
    "region" => "north,south,east,west",
    "plan" => "starter,team"
  }

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(500, :tick)
    {:ok, assign(socket, page_title: "Chip stacks", state: %State{}, ticks: 0)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, state: State.from_params(params, @opts))}
  end

  @impl true
  def handle_info(:tick, socket), do: {:noreply, update(socket, :ticks, &(&1 + 1))}

  @impl true
  def handle_event("dt:filter", params, socket) do
    state =
      socket.assigns.state
      |> State.put_search(params["q"])
      |> State.put_filters(params, @fields, @opts)

    {:noreply, patch(socket, state)}
  end

  def handle_event("dt:unfilter", %{"key" => key, "value" => value}, socket) do
    {:noreply, patch(socket, State.remove_value(socket.assigns.state, key, value, @opts))}
  end

  def handle_event("dt:unfilter", %{"key" => key}, socket) do
    {:noreply, patch(socket, State.put_filters(socket.assigns.state, %{key => ""}, [key], @opts))}
  end

  def handle_event("dt:reset", _params, socket) do
    {:noreply, patch(socket, State.from_params(%{}, @opts))}
  end

  def handle_event("start", _params, socket) do
    {:noreply, patch(socket, State.from_params(@start, @opts))}
  end

  def handle_event("add_brand", _params, socket) do
    picked = State.values(socket.assigns.state.filters["brand"])
    next = Enum.find(@brands, fn {_, value} -> value not in picked end)
    brands = if next, do: picked ++ [elem(next, 1)], else: picked
    state = State.put_filters(socket.assigns.state, %{"brand" => brands}, ["brand"], @opts)
    {:noreply, patch(socket, state)}
  end

  defp patch(socket, state),
    do: push_patch(socket, to: ~p"/lab/chip-stacks?#{State.to_params(state, @opts)}")

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        options: @options,
        fields: @fields,
        chips: State.chips(assigns.state, @fields, @options)
      )

    ~H"""
    <.lab_shell active="orders">
      <.page_header crumbs={[%{label: "Lab"}, %{label: "Chip stacks"}]}>
        Chip stacks
        <:actions>
          <.button size="sm" variant="outline" phx-click="start" id="start">Filters on</.button>
          <.button size="sm" variant="outline" phx-click="add_brand" id="add-brand">
            Add a brand
          </.button>
        </:actions>
        <:below>
          <.table_toolbar id="stacks" search={@state.search} placeholder="Search" chips={@chips}>
            <:filter :for={field <- @fields} key={field} label={label(field)}>
              <.select
                id={"filter-" <> field}
                name={field}
                multiple
                full_width
                value={State.values(@state.filters[field])}
                placeholder="Any"
              >
                <:option :for={{label, value} <- @options[field]} value={value}>{label}</:option>
              </.select>
            </:filter>
          </.table_toolbar>
        </:below>
      </.page_header>
      <p class="pt-4 text-sm text-muted-foreground">
        Patches so far: <span id="ticks" class="font-semibold">{@ticks}</span>
      </p>
      <div :for={i <- 1..40} class="border-b border-border py-3 text-sm">Row {i}</div>
    </.lab_shell>
    """
  end

  defp label("brand"), do: "Brands"
  defp label(field), do: String.capitalize(field)
end
