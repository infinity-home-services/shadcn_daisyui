defmodule ShadcnDaisyuiDemoWeb.OrderLive do
  @moduledoc """
  `/lab/data-table/:id` (not in the static export): a record page built from
  the package's parts in a connected LiveView. `<.record_tabs>` (Details,
  Activity), an edit form whose 11 sections a `<.section_nav>` finds (a list
  beside the cards from `lg`, a select in the page header below it, with a
  filter), `<.time_field>`s for the delivery window, `<.table_card>`s for the
  line items and the activity, and two server-opened dialogs: Cancel with
  unsaved changes asks "Discard your changes?" (`push_show_modal/2`), and
  Delete opens a confirm through `show` + `on_close`.
  """
  use ShadcnDaisyuiDemoWeb, :live_view

  import ShadcnDaisyui.Components,
    only: [select: 1, card: 1, card_body: 1, card_title: 1, card_description: 1]

  import ShadcnDaisyui.Components.Overlay, only: [dialog: 1, hide_modal: 1, push_show_modal: 2]
  import ShadcnDaisyui.Components.Record
  import ShadcnDaisyui.Components.Display, only: [push_toast: 3]
  # the package's button and input (variants, sizes) over the demo's generated ones
  import ShadcnDaisyuiDemoWeb.CoreComponents, only: []
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1, button: 1, input: 1]
  import ShadcnDaisyuiDemoWeb.LabOrders, only: [lab_shell: 1, status_badge: 1, money: 1]

  alias ShadcnDaisyuiDemoWeb.LabOrders

  @sections [
    {"customer", "Name", "Customer"},
    {"contact", "Contact", "Customer"},
    {"billing-address", "Billing address", "Addresses"},
    {"shipping-address", "Shipping address", "Addresses"},
    {"items", "Items", "Order"},
    {"discounts", "Discounts", "Order"},
    {"delivery", "Delivery window", "Delivery"},
    {"payment", "Payment", "Billing"},
    {"invoice", "Invoice", "Billing"},
    {"notes", "Notes", "Other"},
    {"files", "Files", "Other"}
  ]

  @fields ~w(customer email phone billing shipping discount opens closes method terms notes)

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    case LabOrders.get(id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/lab/data-table")}

      order ->
        saved = %{
          "customer" => order.customer,
          "email" => order.email,
          "phone" => "",
          "billing" => "12 Harbor Road",
          "shipping" => "",
          "discount" => "",
          "opens" => "09:00",
          "closes" => "17:00",
          "method" => "card",
          "terms" => "30",
          "notes" => ""
        }

        back =
          if params["back"],
            do: "/lab/data-table?" <> params["back"],
            else: ~p"/lab/data-table?#{%{opened: id}}"

        {:ok,
         assign(socket,
           page_title: order.number,
           order: order,
           saved: saved,
           form: to_form(saved, as: :order),
           dirty: false,
           tab: "details",
           confirm_delete: false,
           back: back,
           sections: @sections
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"order" => params}, socket) do
    {:noreply,
     assign(socket,
       form: to_form(params, as: :order, errors: errors(params), action: :validate),
       dirty: Map.take(params, @fields) != socket.assigns.saved
     )}
  end

  def handle_event("save", %{"order" => params}, socket) do
    case errors(params) do
      [] ->
        saved = Map.take(params, @fields)

        socket
        |> assign(saved: saved, form: to_form(saved, as: :order), dirty: false)
        |> push_toast("#{socket.assigns.order.number} saved", type: :success)
        |> then(&{:noreply, &1})

      errors ->
        {:noreply,
         assign(socket, form: to_form(params, as: :order, errors: errors, action: :validate))}
    end
  end

  def handle_event("tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, tab: tab)}

  # a decision the server makes: unsaved changes ask first
  def handle_event("cancel", _params, socket) do
    if socket.assigns.dirty,
      do: {:noreply, push_show_modal(socket, "discard")},
      else: {:noreply, push_navigate(socket, to: socket.assigns.back)}
  end

  def handle_event("discard", _params, socket),
    do: {:noreply, push_navigate(socket, to: socket.assigns.back)}

  def handle_event("delete", _params, socket),
    do: {:noreply, assign(socket, confirm_delete: true)}

  def handle_event("keep_order", _params, socket),
    do: {:noreply, assign(socket, confirm_delete: false)}

  def handle_event("confirm_delete", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "#{socket.assigns.order.number} deleted (a lab demo: nothing was)")
     |> push_navigate(to: socket.assigns.back)}
  end

  defp errors(params) do
    [
      String.trim(params["customer"] || "") == "" && {:customer, {"can't be blank", []}},
      window_backwards?(params["opens"], params["closes"]) &&
        {:closes, {"must be after the window opens", []}}
    ]
    |> Enum.filter(& &1)
  end

  defp window_backwards?(opens, closes) when opens in [nil, ""] or closes in [nil, ""], do: false
  defp window_backwards?(opens, closes), do: closes <= opens

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        items: [
          %{name: "Annual service plan", qty: 1, price: assigns.order.total * 0.6},
          %{name: "Filters, set of 4", qty: 2, price: assigns.order.total * 0.15},
          %{name: "Delivery", qty: 1, price: assigns.order.total * 0.1}
        ],
        activity: [
          %{id: 1, what: "Order placed", by: assigns.order.owner, at: assigns.order.placed},
          %{id: 2, what: "Invoice sent", by: "System", at: Date.add(assigns.order.placed, 1)},
          %{
            id: 3,
            what: "Payment reminder",
            by: assigns.order.owner,
            at: Date.add(assigns.order.placed, 14)
          },
          %{
            id: 4,
            what: "Status: #{LabOrders.status_label(assigns.order.status)}",
            by: "System",
            at: Date.add(assigns.order.placed, 15)
          }
        ]
      )

    ~H"""
    <.lab_shell active="orders">
      <.page_header
        crumbs={[%{label: "Lab"}, %{label: "Orders", path: @back}, %{label: @order.number}]}
        esc_back={!@dirty}
      >
        {@order.number}
        <:badge><.status_badge status={@order.status} /></:badge>
        <:actions>
          <.button size="sm" variant="ghost" class="hidden sm:inline-flex" phx-click="delete">
            Delete
          </.button>
          <.button size="sm" variant="outline" phx-click="cancel">Cancel</.button>
          <.button size="sm" type="submit" form="order-form" disabled={!@dirty}>Save</.button>
        </:actions>
        <:below>
          <.record_tabs
            id="order-tabs"
            tabs={[{"details", "Details"}, {"activity", "Activity", length(@activity)}]}
            active={@tab}
            aria_label="Order"
          />
          <.section_nav
            :if={@tab == "details"}
            id="order-sections-select"
            sections={@sections}
            variant="select"
          />
        </:below>
      </.page_header>

      <.form
        :if={@tab == "details"}
        for={@form}
        id="order-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.section_nav id="order-sections" sections={@sections}>
          <.card id="customer">
            <.card_body>
              <.card_title>Customer</.card_title>
              <.card_description>Who the order is for.</.card_description>
              <div class="mt-4 space-y-4"><.input field={@form[:customer]} label="Name" /></div>
            </.card_body>
          </.card>
          <.card id="contact">
            <.card_body>
              <.card_title>Contact</.card_title>
              <div class="mt-4 grid gap-4 sm:grid-cols-2">
                <.input field={@form[:email]} type="email" label="Email" />
                <.input field={@form[:phone]} type="tel" label="Phone" />
              </div>
            </.card_body>
          </.card>
          <.card id="billing-address">
            <.card_body>
              <.card_title>Billing address</.card_title>
              <div class="mt-4"><.input field={@form[:billing]} label="Street" /></div>
            </.card_body>
          </.card>
          <.card id="shipping-address">
            <.card_body>
              <.card_title>Shipping address</.card_title>
              <.card_description>Leave empty to ship to the billing address.</.card_description>
              <div class="mt-4"><.input field={@form[:shipping]} label="Street" /></div>
            </.card_body>
          </.card>
          <.table_card
            id="items"
            title="Items"
            description="What's on the order."
            rows={@items}
            grid="grid-cols-[minmax(0,1fr)_2.5rem_6rem]"
          >
            <:col :let={i} label="Item">{i.name}</:col>
            <:col :let={i} label="Qty" class="tabular-nums">{i.qty}</:col>
            <:col :let={i} label="Price" class="tabular-nums">{money(i.price)}</:col>
          </.table_card>
          <.card id="discounts">
            <.card_body>
              <.card_title>Discounts</.card_title>
              <div class="mt-4">
                <.input field={@form[:discount]} label="Code" placeholder="None" />
              </div>
            </.card_body>
          </.card>
          <.card id="delivery">
            <.card_body>
              <.card_title>Delivery window</.card_title>
              <.card_description>When someone is there to take the delivery.</.card_description>
              <div class="mt-4 grid gap-4 sm:grid-cols-2">
                <.time_field id="opens" field={@form[:opens]} label="Opens" />
                <.time_field id="closes" field={@form[:closes]} label="Closes" />
              </div>
            </.card_body>
          </.card>
          <.card id="payment">
            <.card_body>
              <.card_title>Payment</.card_title>
              <div class="mt-4 space-y-2">
                <label for="order_method" class="text-sm font-medium">Method</label>
                <.select id="method" field={@form[:method]} full_width>
                  <:option value="card">Card</:option>
                  <:option value="transfer">Bank transfer</:option>
                  <:option value="invoice">Invoice</:option>
                </.select>
              </div>
            </.card_body>
          </.card>
          <.card id="invoice">
            <.card_body>
              <.card_title>Invoice</.card_title>
              <div class="mt-4">
                <.input field={@form[:terms]} type="number" label="Payment terms (days)" />
              </div>
            </.card_body>
          </.card>
          <.card id="notes">
            <.card_body>
              <.card_title>Notes</.card_title>
              <div class="mt-4">
                <.input field={@form[:notes]} type="textarea" label="For the team" rows="4" />
              </div>
            </.card_body>
          </.card>
          <.card id="files">
            <.card_body>
              <.card_title>Files</.card_title>
              <.card_description>Nothing attached.</.card_description>
            </.card_body>
          </.card>
        </.section_nav>
      </.form>

      <.table_card
        :if={@tab == "activity"}
        id="activity"
        title="Activity"
        description={"Everything that happened to #{@order.number}."}
        rows={@activity}
        row_id={&"activity-#{&1.id}"}
      >
        <:col :let={a} label="Event" class="font-medium">{a.what}</:col>
        <:col :let={a} label="By" class="text-muted-foreground">{a.by}</:col>
        <:col :let={a} label="When">{Calendar.strftime(a.at, "%b %-d, %Y")}</:col>
      </.table_card>

      <.dialog id="discard">
        <:title>Discard your changes?</:title>
        <:description>Your edits to {@order.number} haven't been saved.</:description>
        <:actions>
          <.button variant="outline" phx-click={hide_modal("discard")}>Keep editing</.button>
          <.button variant="destructive" phx-click="discard">Discard</.button>
        </:actions>
      </.dialog>

      <.dialog id="delete-order" show={@confirm_delete} on_close="keep_order">
        <:title>Delete {@order.number}?</:title>
        <:description>The order and its activity go. This can't be undone.</:description>
        <:actions>
          <.button variant="outline" phx-click={hide_modal("delete-order")}>Keep order</.button>
          <.button variant="destructive" phx-click="confirm_delete">Delete</.button>
        </:actions>
      </.dialog>
    </.lab_shell>
    """
  end
end
