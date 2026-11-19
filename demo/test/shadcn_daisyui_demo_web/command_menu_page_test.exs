defmodule ShadcnDaisyuiDemoWeb.CommandMenuPageTest do
  @moduledoc """
  The Command Menu gallery page (rendered from the real component, in the
  Actions group) and /lab/command-menu (a few hundred rows in a LiveView).
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ShadcnDaisyuiDemoWeb.Catalog

  test "the page shows both examples, rendered from the component", %{conn: conn} do
    html = conn |> get(~p"/docs/components/command-menu") |> html_response(200)

    for title <- ["Switch location", "From the sidebar header"] do
      assert html =~ ~r{>\s*#{title}\s*</h[23]>}, "missing example #{title}"
    end

    assert html =~ ~s(id="scope" class="command-menu" data-command-menu)
    assert html =~ ~s(id="scope-panel" popover="manual" role="dialog")
    [row] = Regex.run(~r{<a [^>]*id="loc-1-1"[^>]*>}, html)
    assert row =~ ~s(data-depth="1")
    assert row =~ ~s(data-parent="brand-1")
    # the sidebar heading as the trigger, the menu beside it
    assert html =~ ~s(<button type="button" class="app-shell-heading" id="scope-heading">)
    assert html =~ ~s(data-trigger="scope-heading" data-side="right")
    # the code tab is plain HTML: no LiveView hook attributes
    refute html =~ ~s(phx-hook="ShadcnCommandMenu")
  end

  test "it's listed under Actions" do
    actions = Enum.find(Catalog.groups(), &(&1.title == "Actions"))
    assert "command-menu" in Enum.map(actions.components, & &1.slug)
  end

  test "/lab/command-menu: picking a row moves the check and renames the trigger", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/lab/command-menu")

    assert html =~ ~s(phx-hook="ShadcnCommandMenu")
    assert html =~ "369 rows"
    assert has_element?(view, "#acme[data-current]")

    view |> element("#loc-3-2") |> render_click()

    assert has_element?(view, "#loc-3-2[data-current][aria-selected=true]")
    refute has_element?(view, "#acme[data-current]")
    assert view |> element("#scope-trigger") |> render() =~ "Cedar Home"
    assert view |> element("#chosen") |> render() =~ "Cedar Home"
  end
end
