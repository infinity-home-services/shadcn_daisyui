defmodule ShadcnDaisyuiDemoWeb.ComponentPagesTest do
  @moduledoc """
  Render-every-page smoke test: a broken example, guidance shape, or template
  reference for any of the catalog components fails CI here instead of in production.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  alias ShadcnDaisyuiDemoWeb.Catalog

  test "every component page renders 200 with its title", %{conn: conn} do
    for slug <- Catalog.slugs() do
      title = Catalog.component(slug).title
      html = conn |> get(~p"/docs/components/#{slug}") |> html_response(200)
      assert html =~ Plug.HTML.html_escape(title), "#{slug} page did not render its title"
    end
  end

  test "every component markdown export renders 200", %{conn: conn} do
    for slug <- Catalog.slugs() do
      assert conn |> get("/docs/components/#{slug}.md") |> response(200) =~ "#"
    end
  end

  test "the table card's row actions example has a ⋯ menu on every row, the last too",
       %{conn: conn} do
    html = conn |> get(~p"/docs/components/table-card") |> html_response(200)
    doc = LazyHTML.from_document(html)

    rows = LazyHTML.query(doc, ~s(#contacts [role="rowgroup"]:last-child > [role="row"]))
    menus = LazyHTML.query(rows, ".dropdown.dropdown-end")

    assert LazyHTML.attribute(rows, "id") == ["contact-1", "contact-2", "contact-3"]

    assert LazyHTML.attribute(menus, "id") == [
             "contact-1-menu",
             "contact-2-menu",
             "contact-3-menu"
           ]

    assert html =~ ~s(aria-label="Actions for Robin Park")
  end

  test "the table card's side by side example: a card with rows next to an empty one",
       %{conn: conn} do
    html = conn |> get(~p"/docs/components/table-card") |> html_response(200)
    doc = LazyHTML.from_document(html)

    rows = LazyHTML.query(doc, ~s(#crew-north [role="rowgroup"]:last-child > [role="row"]))
    menus = LazyHTML.query(rows, ".dropdown")

    assert LazyHTML.attribute(rows, "id") == ["crew-north-1", "crew-north-2", "crew-north-3"]
    # some rows with a ⋯ menu, the lead's with a badge instead
    assert LazyHTML.attribute(menus, "id") == ["crew-north-2-menu", "crew-north-3-menu"]
    assert LazyHTML.query(doc, "#crew-north-1 .badge") |> Enum.count() == 1

    assert LazyHTML.query(doc, "#crew-south .table-card-empty") |> LazyHTML.text() =~
             "No members yet."
  end

  test "the tokens reference page renders with swatches", %{conn: conn} do
    html = conn |> get(~p"/docs/tokens") |> html_response(200)
    assert html =~ "Tokens"
    assert html =~ "--background"
    assert html =~ "--primary"
  end
end
