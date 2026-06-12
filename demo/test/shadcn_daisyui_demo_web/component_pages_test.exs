defmodule ShadcnDaisyuiDemoWeb.ComponentPagesTest do
  @moduledoc """
  Render-every-page smoke test: a broken example, guidance shape, or template
  reference for any of the 77 components fails CI here instead of in production.
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

  test "the tokens reference page renders with swatches", %{conn: conn} do
    html = conn |> get(~p"/docs/tokens") |> html_response(200)
    assert html =~ "Tokens"
    assert html =~ "--background"
    assert html =~ "--primary"
  end
end
