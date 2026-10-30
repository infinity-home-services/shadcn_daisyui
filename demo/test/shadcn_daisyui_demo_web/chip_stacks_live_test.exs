defmodule ShadcnDaisyuiDemoWeb.ChipStacksLiveTest do
  @moduledoc """
  `/lab/chip-stacks`: stacked chips in a toolbar inside a pinned page header,
  with the filters in the URL. One value's × takes off that value, the stack's
  × the whole filter; down to one value the stack is a normal chip.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @stack "#stacks-chips-chip-v-brand"
  @start "/lab/chip-stacks?brand=acme,northwind,northwind-sandbox&status=open,paid&owner=pat"

  test "a filter with several values is a stack in the header's :below", %{conn: conn} do
    {:ok, view, _html} = live(conn, @start)

    assert has_element?(view, ".sticky-top #{@stack}[data-chip-stack][data-edges='2']")
    assert has_element?(view, "#{@stack}-open[aria-expanded=false]")
    assert has_element?(view, "#{@stack} [data-chip-stack-name]", "Acme sandbox")
    assert has_element?(view, "#{@stack} [data-chip-stack-count]", "+2")
    # named after its :filter
    assert render(view) =~
             ~r/Brands<\/span>: <span data-chip-stack-values[^>]*>Acme sandbox, Northwind, Northwind sandbox/

    # one value: a normal chip
    refute has_element?(view, "#stacks-chips-chip-v-owner[data-chip-stack]")
    assert has_element?(view, "#stacks-chips-chip-v-owner", "Pat Lee")
  end

  test "a value's × takes off that value, then the stack is a chip, then it's gone", %{conn: conn} do
    {:ok, view, _html} = live(conn, @start)

    view |> element("#{@stack}-value-v-acme-remove") |> render_click()
    path = assert_patch(view)
    assert path =~ "brand=northwind%2Cnorthwind-sandbox"
    assert has_element?(view, "#{@stack}[data-edges='1']")
    assert has_element?(view, "#{@stack} [data-chip-stack-count]", "+1")
    refute has_element?(view, "#{@stack}-value-v-acme")

    view |> element("#{@stack}-value-v-northwind-remove") |> render_click()
    assert_patch(view) =~ "brand=northwind-sandbox"
    refute has_element?(view, "#{@stack}[data-chip-stack]")
    assert has_element?(view, @stack, "Northwind sandbox")

    view |> element("#{@stack}-remove") |> render_click()
    refute assert_patch(view) =~ "brand="
    refute has_element?(view, @stack)
  end

  test "the stack's × clears the whole filter, in one click", %{conn: conn} do
    {:ok, view, _html} = live(conn, @start)

    view |> element("#{@stack}-remove") |> render_click()
    refute assert_patch(view) =~ "brand="
    refute has_element?(view, @stack)
    assert has_element?(view, "#stacks-chips-chip-v-status[data-chip-stack]")
  end

  test "the server can change a stack", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/chip-stacks?brand=acme,northwind")
    assert has_element?(view, "#{@stack} [data-chip-stack-count]", "+1")

    view |> element("#add-brand") |> render_click()
    assert_patch(view)
    assert has_element?(view, "#{@stack} [data-chip-stack-count]", "+2")
    assert has_element?(view, "#{@stack}[data-edges='2']")
  end
end
