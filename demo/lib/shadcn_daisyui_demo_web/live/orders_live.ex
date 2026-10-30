defmodule ShadcnDaisyuiDemoWeb.OrdersLive do
  @moduledoc """
  `/lab/data-table` (not in the static export): a list page built from the
  package's parts in a connected LiveView. `<.table_toolbar>` (saved views,
  search, a filters sheet, chips) over a `<.data_table>` that fills the
  window: sortable columns, rows that open the record, ticked rows with bulk
  actions, 40 rows at a time as the end comes into view, and the scroll
  position kept when you come back. Sort, search and filters live in the URL
  (`ShadcnDaisyui.DataTable.State`), so Back restores a view; the ticks live
  on the page.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components, only: [select: 1, combobox: 1]
  import ShadcnDaisyui.Components.DataTable
  import ShadcnDaisyui.Components.Display, only: [push_toast: 3]
  # the package's button (variants, sizes) over the demo's generated one
  import ShadcnDaisyuiDemoWeb.CoreComponents, only: []
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1, button: 1]
  import ShadcnDaisyuiDemoWeb.LabOrders, only: [lab_shell: 1, status_badge: 1, money: 1]

  alias ShadcnDaisyui.DataTable.State
  alias ShadcnDaisyuiDemoWeb.LabOrders

  @page 40

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Orders",
       orders: LabOrders.all(),
       state: %State{},
       all_matching: false,
       limit: @page
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    previous = socket.assigns.state
    state = State.from_params(params, LabOrders.opts())
    view = Enum.find(LabOrders.views(), hd(LabOrders.views()), &(&1.key == params["view"]))
    # a new sort, search or filter starts from the top
    limit = if same_view?(previous, state, socket), do: socket.assigns.limit, else: @page

    socket
    |> assign(view: view, opened: params["opened"], limit: limit)
    |> assign_rows(%{state | selected: previous.selected, anchor: previous.anchor})
    |> then(&{:noreply, &1})
  end

  defp same_view?(previous, state, socket) do
    socket.assigns[:rows] != nil and State.sort_value(previous) == State.sort_value(state) and
      previous.search == state.search and previous.filters == state.filters
  end

  # The rows shown (the first `limit` matching), and the ticks still among them
  defp assign_rows(socket, state) do
    %{orders: orders, view: view, limit: limit} = socket.assigns

    matching =
      orders
      |> Enum.filter(&in_view?(&1, view))
      |> State.run(state, LabOrders.spec())

    rows = Enum.take(matching, limit)
    state = if socket.assigns.all_matching, do: state, else: State.keep_visible(state, ids(rows))

    assign(socket,
      state: state,
      rows: rows,
      matching: length(matching),
      matching_ids: Enum.map(matching, & &1.id),
      total: Enum.count(orders, &in_view?(&1, view))
    )
  end

  defp in_view?(_order, %{filter: nil}), do: true
  defp in_view?(order, %{filter: {"status", s}}), do: order.status == s
  defp in_view?(order, %{filter: {"owner", o}}), do: order.owner == o

  defp ids(rows), do: Enum.map(rows, & &1.id)

  # sort, search and filters go in the URL (and Back restores them)
  defp patch(socket, state, extra \\ %{}) do
    params =
      state
      |> State.to_params(LabOrders.opts())
      |> Map.merge(
        if socket.assigns.view.key == "all", do: %{}, else: %{"view" => socket.assigns.view.key}
      )
      |> Map.merge(extra)

    push_patch(socket, to: ~p"/lab/data-table?#{params}")
  end

  @impl true
  def handle_event("dt:sort", %{"key" => key}, socket),
    do: {:noreply, patch(socket, State.toggle_sort(socket.assigns.state, key))}

  def handle_event("dt:filter", params, socket) do
    state =
      socket.assigns.state
      |> State.put_search(params["q"])
      |> State.put_filters(params, ["status", "owner"], LabOrders.opts())

    {:noreply, patch(socket, State.parse_sort(params["sort"], state, LabOrders.opts()))}
  end

  def handle_event("dt:unfilter", %{"key" => key, "value" => value}, socket) do
    {:noreply,
     patch(socket, State.remove_value(socket.assigns.state, key, value, LabOrders.opts()))}
  end

  def handle_event("dt:unfilter", %{"key" => key}, socket) do
    state = State.put_filters(socket.assigns.state, %{key => ""}, [key], LabOrders.opts())
    {:noreply, patch(socket, state)}
  end

  def handle_event("dt:reset", _params, socket) do
    state = %{
      State.from_params(%{}, LabOrders.opts())
      | sort: socket.assigns.state.sort,
        dir: socket.assigns.state.dir
    }

    {:noreply, patch(socket, state)}
  end

  def handle_event("dt:open", %{"id" => id}, socket) do
    back = URI.encode_query(Map.put(back_params(socket), "opened", id))
    {:noreply, push_navigate(socket, to: ~p"/lab/data-table/#{id}?#{%{back: back}}")}
  end

  def handle_event("dt:select", %{"id" => id} = params, socket) do
    state =
      State.select(socket.assigns.state, id, params["shift"] == true, ids(socket.assigns.rows))

    {:noreply, assign(socket, state: state, all_matching: false)}
  end

  def handle_event("dt:select_all", _params, socket) do
    state = State.select_all(socket.assigns.state, ids(socket.assigns.rows))
    {:noreply, assign(socket, state: state, all_matching: false)}
  end

  def handle_event("dt:select_matching", _params, socket) do
    state = %{
      socket.assigns.state
      | selected: MapSet.new(socket.assigns.matching_ids, &to_string/1)
    }

    {:noreply, assign(socket, state: state, all_matching: true)}
  end

  def handle_event("dt:clear", _params, socket),
    do: {:noreply, assign(socket, state: State.clear(socket.assigns.state), all_matching: false)}

  def handle_event("dt:more", _params, socket) do
    socket = assign(socket, limit: socket.assigns.limit + @page)
    {:noreply, assign_rows(socket, socket.assigns.state)}
  end

  def handle_event("mark_paid", _params, socket) do
    picked = socket.assigns.state.selected

    orders =
      Enum.map(socket.assigns.orders, fn o ->
        if MapSet.member?(picked, to_string(o.id)), do: %{o | status: "paid"}, else: o
      end)

    n = MapSet.size(picked)

    socket
    |> assign(orders: orders, all_matching: false)
    |> assign_rows(State.clear(socket.assigns.state))
    |> push_toast("#{n} #{if n == 1, do: "order", else: "orders"} marked paid", type: :success)
    |> then(&{:noreply, &1})
  end

  def handle_event("export", _params, socket) do
    n =
      if socket.assigns.all_matching,
        do: socket.assigns.matching,
        else: MapSet.size(socket.assigns.state.selected)

    {:noreply,
     push_toast(socket, "Exported #{n} orders", description: "A lab demo: nothing was written.")}
  end

  def handle_event("save_view", _params, socket),
    do: {:noreply, push_toast(socket, "Saved views are a lab demo", type: :info)}

  defp back_params(socket) do
    socket.assigns.state
    |> State.to_params(LabOrders.opts())
    |> Map.merge(
      if socket.assigns.view.key == "all", do: %{}, else: %{"view" => socket.assigns.view.key}
    )
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        chips:
          fixed_chip(assigns.view) ++
            (State.chips(assigns.state, ["status", "owner"], LabOrders.options())
             |> Enum.map(&chip_with_label/1)),
        views:
          for v <- LabOrders.views() do
            %{
              key: v.key,
              label: v.label,
              count: Enum.count(assigns.orders, &in_view?(&1, v)),
              path: ~p"/lab/data-table?#{if v.key == "all", do: %{}, else: %{view: v.key}}",
              active: v.key == assigns.view.key,
              edited:
                v.key == assigns.view.key and State.filtered?(assigns.state, LabOrders.opts())
            }
          end
      )

    ~H"""
    <.lab_shell active="orders" fill>
      <.page_header crumbs={[%{label: "Lab"}, %{label: "Orders"}]}>
        Orders
        <:actions>
          <.button size="sm" phx-click="export" variant="outline" class="hidden sm:inline-flex">
            Export
          </.button>
        </:actions>
      </.page_header>

      <.table_toolbar
        id="orders-toolbar"
        search={@state.search}
        placeholder="Search orders"
        shown={@matching}
        total={@total}
        noun={{"order", "orders"}}
        views={@views}
        menu={[%{key: "manage", label: "Manage views…", icon: "hero-cog-6-tooth", click: "save_view"}]}
        chips={@chips}
        sort={State.sort_value(@state)}
        sorts={[
          {"Newest first", "placed:desc"},
          {"Oldest first", "placed:asc"},
          {"Customer A–Z", "customer:asc"},
          {"Largest total", "total:desc"}
        ]}
      >
        <:filter key="status" label="Status">
          <.select
            id="filter-status"
            name="status"
            multiple
            full_width
            value={State.values(@state.filters["status"])}
            placeholder="Any status"
          >
            <:option :for={{label, value} <- LabOrders.options()["status"]} value={value}>
              {label}
            </:option>
          </.select>
        </:filter>
        <:filter key="owner" label="Owner">
          <.combobox
            id="filter-owner"
            name="owner"
            multiple
            full_width
            value={State.values(@state.filters["owner"])}
            placeholder="Anyone"
          >
            <:option :for={{label, value} <- LabOrders.options()["owner"]} value={value}>
              {label}
            </:option>
          </.combobox>
        </:filter>
        <:save>
          <.button size="sm" variant="outline" phx-click="save_view">Save view</.button>
        </:save>
      </.table_toolbar>

      <.data_table
        id="orders"
        rows={@rows}
        row_href={&~p"/lab/data-table/#{&1.id}"}
        state={@state}
        selectable
        more={@matching > length(@rows)}
        matching={@matching}
        all_matching={@all_matching}
        noun={{"order", "orders"}}
        active_id={@opened}
        scroll_key="lab-orders"
        edge
      >
        <:col :let={o} label="Order" sort="number" class="w-24 font-medium">{o.number}</:col>
        <:col :let={o} label="Customer" sort="customer">{o.customer}</:col>
        <:col :let={o} label="Owner" hide_below="lg" class="w-36">{o.owner}</:col>
        <:col :let={o} label="Status" hide_below="sm" class="w-28">
          <.status_badge status={o.status} />
        </:col>
        <:col :let={o} label="Placed" sort="placed" hide_below="md" class="w-32">
          {Calendar.strftime(o.placed, "%b %-d, %Y")}
        </:col>
        <:col :let={o} label="Total" sort="total" class="w-28 tabular-nums">{money(o.total)}</:col>
        <:bulk>
          <.button size="sm" variant="outline" phx-click="mark_paid">Mark paid</.button>
          <.button size="sm" variant="ghost" phx-click="export">Export</.button>
        </:bulk>
        <:empty title="No orders match" icon="hero-funnel">
          Try another search, view or filter.
        </:empty>
        <:empty_action>
          <.button size="sm" variant="outline" phx-click="dt:reset">Clear filters</.button>
        </:empty_action>
      </.data_table>
    </.lab_shell>
    """
  end

  defp fixed_chip(%{filter: nil}), do: []

  defp fixed_chip(%{filter: {"status", s}}),
    do: [{"view", "Status: " <> LabOrders.status_label(s), :fixed}]

  defp fixed_chip(%{filter: {"owner", o}}), do: [{"view", "Owner: " <> o, :fixed}]

  # one value reads "Status: Open"; several are a stack named after the filter
  defp chip_with_label({_key, values} = chip) when is_list(values), do: chip
  defp chip_with_label({key, label}), do: {key, chip_label(key) <> ": " <> label}

  defp chip_label("status"), do: "Status"
  defp chip_label("owner"), do: "Owner"
end
