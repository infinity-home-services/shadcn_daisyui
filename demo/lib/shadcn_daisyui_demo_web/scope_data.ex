defmodule ShadcnDaisyuiDemoWeb.ScopeData do
  @moduledoc """
  A made-up company for the `<.command_menu>` docs: the company, divisions
  with their regions, and brands with their locations, as the flat list of
  rows the menu takes (each child right after its parent).
  """

  @divisions [
    {"east", "East", ["Northeast", "Mid-Atlantic", "Southeast"]},
    {"west", "West", ["Mountain", "Pacific", "Southwest"]}
  ]

  @brands ~w(Alder Birch Cedar Dogwood Elm Fir Hawthorn Juniper Linden Maple Oak Pine
             Quince Rowan Spruce Sycamore Tamarack Walnut Willow Yew)

  @cities ~w(Albany Boston Charlotte Denver Fresno Hartford Mesa Omaha Portland Reno
             Raleigh Richmond Sacramento Tampa Tucson Tulsa)

  @doc """
  The rows for `brands` brands with `locations` locations each:
  `%{id, group, label, icon}` plus `parent` and `description` where they apply.
  """
  def rows(brands \\ 6, locations \\ 3) do
    company = [
      %{id: "acme", group: "Company", label: "All of Acme", icon: "hero-building-office-2"}
    ]

    divisions =
      Enum.flat_map(@divisions, fn {id, name, regions} ->
        [
          %{
            id: "div-" <> id,
            group: "Divisions",
            label: name <> " division",
            icon: "hero-squares-2x2"
          }
          | for region <- regions do
              %{
                id: "reg-" <> slug(region),
                group: "Divisions",
                parent: "div-" <> id,
                label: region,
                icon: "hero-map"
              }
            end
        ]
      end)

    brand_rows =
      for b <- 1..brands,
          name = brand_name(b),
          row <- [
            %{
              id: "brand-#{b}",
              group: "Brands",
              label: name,
              description: "#{locations} locations",
              icon: "hero-tag"
            }
            | for l <- 1..locations do
                city = Enum.at(@cities, rem(b * 7 + l * 3, length(@cities)))

                %{
                  id: "loc-#{b}-#{l}",
                  group: "Brands",
                  parent: "brand-#{b}",
                  label: "#{name} #{city}",
                  description: "Store #{b * 100 + l}",
                  icon: "hero-map-pin"
                }
              end
          ],
          do: row

    company ++ divisions ++ brand_rows
  end

  @doc "The row with this id (its label names the trigger), or nil."
  def find(rows, id), do: Enum.find(rows, &(&1.id == id))

  defp brand_name(b) do
    base = Enum.at(@brands, rem(b - 1, length(@brands)))
    lap = div(b - 1, length(@brands))
    if lap == 0, do: base <> " Home", else: "#{base} Home #{lap + 1}"
  end

  defp slug(name), do: name |> String.downcase() |> String.replace(~r/[^a-z]+/, "-")
end
