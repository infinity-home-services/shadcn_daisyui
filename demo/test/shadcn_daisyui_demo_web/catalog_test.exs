defmodule ShadcnDaisyuiDemoWeb.CatalogTest do
  use ExUnit.Case, async: true

  alias ShadcnDaisyuiDemoWeb.Catalog

  test "every group slug resolves to a full component spec" do
    # Catalog.groups/0 raises if any sidebar slug has no component definition.
    for group <- Catalog.groups() do
      assert is_binary(group.title)

      for component <- group.components do
        assert is_binary(component.slug)
        assert is_binary(component.title)
        assert is_binary(component.description)
      end
    end
  end

  test "slugs are unique" do
    slugs = Catalog.slugs()
    assert slugs == Enum.uniq(slugs)
  end

  test "the curated visual components keep their anatomy diagrams and do/don't pairs" do
    for slug <- ~w(button input card) do
      assert is_binary(Catalog.component(slug).specs.anatomy_svg),
             "#{slug} lost its anatomy diagram"
    end

    for slug <- ~w(button input dialog) do
      assert is_map(Catalog.component(slug).do_dont), "#{slug} lost its do/don't pair"
    end
  end

  test "every design-enrichment key maps to a real component slug" do
    slugs = MapSet.new(Catalog.slugs())

    for slug <- Map.keys(ShadcnDaisyuiDemoWeb.Catalog.Enrichment.all()) do
      assert MapSet.member?(slugs, slug),
             "enrichment lists #{inspect(slug)}, which is not a component slug"
    end
  end

  test "every defined component appears in exactly one sidebar group (no orphans either way)" do
    defined = Catalog.components() |> Map.keys() |> Enum.sort()
    grouped = Catalog.slugs() |> Enum.sort()

    # A defined component missing from @groups would never show in the sidebar;
    # a grouped slug with no definition would crash component!/1. Both are drift.
    assert defined == grouped,
           "catalog/group drift - only defined: #{inspect(defined -- grouped)}; only grouped: #{inspect(grouped -- defined)}"
  end

  test "every component has at least one example and every example has :code" do
    for slug <- Catalog.slugs() do
      component = Catalog.component(slug)
      assert component.examples != [], "#{slug} has no examples"

      for example <- component.examples do
        assert is_binary(Map.get(example, :title)), "#{slug} example missing :title"
        code = Map.get(example, :code)
        assert is_binary(code) and code != "", "#{slug} example missing :code"
      end
    end
  end
end
