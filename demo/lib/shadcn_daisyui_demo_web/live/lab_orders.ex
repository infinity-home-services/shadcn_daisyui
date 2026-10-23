defmodule ShadcnDaisyuiDemoWeb.LabOrders do
  @moduledoc """
  The made-up orders behind `/lab/data-table`: 240 of them, generated the same
  way every time, plus the things the list and record pages share (the app
  shell's navigation for the lab, the table's options, the status badges).
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components.Shell, only: [app_shell: 1, app_shell_heading: 1]

  alias ShadcnDaisyui.DataTable.State

  @customers [
    "Blue Harbor Inn",
    "Maple & Co.",
    "Summit Outfitters",
    "Lakeside Clinic",
    "Copper Kettle",
    "Granite Works",
    "Orchard Lane Grocers",
    "Pine Street Bakery",
    "Riverside Dental",
    "Hillcrest Motors",
    "Willow Creek Farm",
    "Bright Path Tutoring",
    "Cedar & Stone",
    "Northgate Pharmacy",
    "Sunny Side Cafe",
    "Old Mill Hardware"
  ]

  @owners ["Pat Lee", "Sam Okafor", "Jordan Diaz", "Riley Chen"]
  @statuses [{"Open", "open"}, {"Paid", "paid"}, {"Overdue", "overdue"}, {"Refunded", "refunded"}]

  @doc "The table's URL options: its filters (and their defaults) and sort keys."
  def opts,
    do: [filters: %{"status" => "any", "owner" => "any"}, sorts: ~w(number customer placed total)]

  @doc "The filter options, `[{label, value}]` per filter."
  def options, do: %{"status" => @statuses, "owner" => Enum.map(@owners, &{&1, &1})}

  @doc "Saved views: a fixed filter each (the person's own filters go on top)."
  def views do
    [
      %{key: "all", label: "All orders", filter: nil},
      %{key: "open", label: "Open", filter: {"status", "open"}},
      %{key: "overdue", label: "Overdue", filter: {"status", "overdue"}},
      %{key: "mine", label: "Mine", filter: {"owner", "Pat Lee"}}
    ]
  end

  @doc "How State.run/3 searches, filters and sorts the orders."
  def spec do
    %{
      search: &"#{&1.number} #{&1.customer} #{&1.owner}",
      filters: %{
        "status" => &State.any_of?(&2, &1.status),
        "owner" => &State.any_of?(&2, &1.owner)
      },
      sorts: %{
        "number" => & &1.id,
        "customer" => & &1.customer,
        "placed" => & &1.placed,
        "total" => & &1.total
      }
    }
  end

  @doc "Every order, newest first."
  def all do
    for id <- 240..1//-1 do
      %{
        id: id,
        number: "##{1000 + id}",
        customer: Enum.at(@customers, rem(id * 7, length(@customers))),
        owner: Enum.at(@owners, rem(id * 3, length(@owners))),
        status: status(id),
        total: rem(id * 7919, 120_000) / 100 + 25,
        placed: Date.add(~D[2026-10-22], -div((241 - id) * 5, 3)),
        email: "orders#{id}@example.test"
      }
    end
  end

  defp status(id) do
    cond do
      rem(id, 11) == 0 -> "refunded"
      rem(id, 5) == 0 -> "overdue"
      rem(id, 3) == 0 -> "open"
      true -> "paid"
    end
  end

  @doc "One order by id, or nil."
  def get(id) do
    id = if is_binary(id), do: String.to_integer(id), else: id
    Enum.find(all(), &(&1.id == id))
  end

  @doc "A status's label."
  def status_label(status),
    do: Enum.find_value(@statuses, status, fn {l, v} -> v == status && l end)

  @doc "Money, as the table shows it."
  def money(amount) do
    [whole, cents] = :erlang.float_to_binary(amount * 1.0, decimals: 2) |> String.split(".")

    "$" <>
      (whole |> String.reverse() |> String.replace(~r/(\d{3})(?=\d)/, "\\1,") |> String.reverse()) <>
      "." <> cents
  end

  attr(:status, :string, required: true)

  @doc "A status badge."
  def status_badge(assigns) do
    ~H"""
    <span class={["badge", badge_class(@status)]}>{status_label(@status)}</span>
    """
  end

  defp badge_class("paid"), do: "badge-secondary"
  defp badge_class("overdue"), do: "badge-error"
  defp badge_class(_), do: "badge-outline"

  attr(:active, :string, required: true)
  attr(:fill, :boolean, default: false)
  slot(:inner_block, required: true)

  @doc "The lab's app shell."
  def lab_shell(assigns) do
    ~H"""
    <.app_shell
      nav={nav()}
      active={@active}
      wide={@fill}
      fill={@fill}
      environment="Lab"
      person={%{name: "Pat Lee", email: "pat@example.test"}}
    >
      <:header>
        <.app_shell_heading
          id="lab-heading"
          icon="hero-beaker"
          title="Lab"
          subtitle="LiveView demos"
          tip="Lab"
        />
      </:header>
      <:phone_header>
        <span class="app-shell-tile">
          <span class="hero-beaker size-4" aria-hidden="true"></span>
        </span>
        <span class="text-sm font-semibold">Lab</span>
      </:phone_header>
      <:account_item id="docs" icon="hero-book-open" href="/docs">Docs</:account_item>
      {render_slot(@inner_block)}
    </.app_shell>
    """
  end

  defp nav do
    [
      %{
        label: "Lab",
        items: [
          %{
            id: "orders",
            label: "Orders",
            short: "Orders",
            path: "/lab/data-table",
            icon: "hero-shopping-cart"
          },
          %{
            id: "search",
            label: "Server search",
            short: "Search",
            path: "/lab/command-search",
            icon: "hero-magnifying-glass"
          },
          %{
            id: "csp",
            label: "CSP + patches",
            short: "CSP",
            path: "/lab/csp",
            icon: "hero-shield-check"
          }
        ]
      }
    ]
  end
end
