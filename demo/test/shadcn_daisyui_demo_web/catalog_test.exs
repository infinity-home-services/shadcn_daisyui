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
