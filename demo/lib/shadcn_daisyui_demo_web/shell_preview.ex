defmodule ShadcnDaisyuiDemoWeb.ShellPreview do
  @moduledoc """
  The pretend app shown in the iframes on /docs/app-shell: its navigation (the
  shape `<.app_shell nav>` takes) and the pages behind it, one static page per
  item plus a record page, so the static export can serve every one.
  """
  use ShadcnDaisyuiDemoWeb, :verified_routes

  @groups [
    {nil, [{"home", "Home", "Home", "hero-home"}]},
    {"Sales",
     [
       {"orders", "Orders", "Orders", "hero-shopping-cart"},
       {"customers", "Customers", "People", "hero-users"},
       {"quotes", "Quotes", "Quotes", "hero-document-text"}
     ]},
    {"Catalog",
     [
       {"products", "Products", "Products", "hero-cube"},
       {"price-lists", "Price lists", "Prices", "hero-currency-dollar"}
     ]},
    {"Settings",
     [
       {"team", "Team", "Team", "hero-user-group"},
       {"billing", "Billing", "Billing", "hero-credit-card"}
     ]}
  ]

  @orders [
    {"1042", "Riverside Dental", "Paid", "$4,120.00"},
    {"1041", "Northgate Pharmacy", "Open", "$980.50"},
    {"1040", "Blue Harbor Inn", "Paid", "$12,400.00"},
    {"1039", "Maple & Co.", "Refunded", "$215.00"},
    {"1038", "Summit Outfitters", "Paid", "$3,310.75"},
    {"1037", "Lakeside Clinic", "Open", "$640.00"},
    {"1036", "Copper Kettle", "Paid", "$1,875.20"},
    {"1035", "Granite Works", "Paid", "$7,060.00"},
    {"1034", "Orchard Lane", "Open", "$420.00"},
    {"1033", "Old Mill Hardware", "Paid", "$2,945.10"},
    {"1032", "Pine Street Bakery", "Paid", "$318.40"},
    {"1031", "Hillcrest Motors", "Open", "$15,200.00"}
  ]

  @doc "The navigation, as `<.app_shell nav>` takes it."
  def nav do
    for {label, items} <- @groups do
      %{
        label: label,
        items:
          for {id, item_label, short, icon} <- items do
            %{id: id, label: item_label, short: short, path: path(id), icon: icon}
          end
      }
    end
  end

  @doc "Every preview page's slug, for the static export."
  def pages, do: Enum.map(items(), & &1.id) ++ ["order"]

  @doc "The page with this slug, or nil."
  def page("order") do
    %{
      id: "order",
      active: "orders",
      title: "#1042",
      crumbs: [%{label: "Sales"}, %{label: "Orders", path: path("orders")}, %{label: "#1042"}],
      kind: :record
    }
  end

  def page(slug) do
    nav()
    |> Enum.find_value(fn group ->
      item = Enum.find(group.items, &(&1.id == slug))

      item &&
        %{
          id: item.id,
          active: item.id,
          title: item.label,
          crumbs: crumbs(group.label, item.label),
          kind: kind(item.id)
        }
    end)
  end

  @doc "The orders table's rows."
  def orders,
    do: Enum.map(@orders, fn {n, c, s, t} -> %{number: n, customer: c, status: s, total: t} end)

  @doc "The order record's sections, as `<.section_nav sections>` takes them."
  def sections do
    [
      {"details", "Details", "Order"},
      {"items", "Items", "Order"},
      {"shipping", "Shipping", "Delivery"},
      {"payment", "Payment", "Billing"},
      {"activity", "Activity", "History"}
    ]
  end

  @doc "The preview page's address."
  def path(slug), do: ~p"/docs/app-shell/preview/#{slug}"

  defp items, do: Enum.flat_map(nav(), & &1.items)

  # A group named like its page shows once
  defp crumbs(nil, label), do: [%{label: label}]
  defp crumbs(label, label), do: [%{label: label}]
  defp crumbs(group, label), do: [%{label: group}, %{label: label}]

  defp kind("home"), do: :home
  defp kind("orders"), do: :table
  defp kind(_), do: :empty
end
