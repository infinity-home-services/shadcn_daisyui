defmodule ShadcnDaisyuiDemoWeb.AiDocsControllerTest do
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  alias ShadcnDaisyuiDemoWeb.Catalog

  describe "GET /llms.txt" do
    test "returns the llms index as text/plain", %{conn: conn} do
      conn = get(conn, "/llms.txt")

      assert response(conn, 200) =~ "# shadcn_daisyui"
      assert response_content_type(conn, :txt) =~ "text/plain"
      assert response(conn, 200) =~ "- [Button](/docs/components/button.md)"
    end
  end

  describe "GET /llms-full.txt" do
    test "returns the full markdown for every component", %{conn: conn} do
      conn = get(conn, "/llms-full.txt")
      body = response(conn, 200)

      assert response_content_type(conn, :txt) =~ "text/plain"
      assert body =~ "# shadcn_daisyui"
      assert body =~ "# Button"
      assert body =~ "# Data Table"
      assert body =~ "```html"
    end
  end

  describe "GET /docs/components/:slug.md" do
    test "returns component markdown with the markdown content type", %{conn: conn} do
      conn = get(conn, "/docs/components/button.md")

      assert response(conn, 200) =~ "# Button"
      assert response_content_type(conn, :md) =~ "text/markdown"
    end

    test "includes props table and examples", %{conn: conn} do
      body = conn |> get(~p"/docs/components/button.md") |> response(200)

      assert body =~ "| Name | Type | Default |"
      assert body =~ "## Variants"
      assert body =~ "```html"
    end

    test "notes the JS hook requirement for hook components", %{conn: conn} do
      body = conn |> get(~p"/docs/components/combobox.md") |> response(200)
      assert body =~ "Requires a JS hook"
    end

    test "404s for an unknown component", %{conn: conn} do
      conn = get(conn, "/docs/components/not-a-component.md")
      assert response(conn, 404)
    end
  end

  describe "GET /docs/search.json" do
    test "returns a valid JSON index containing every slug", %{conn: conn} do
      conn = get(conn, "/docs/search.json")
      index = json_response(conn, 200)

      assert Enum.map(index, & &1["slug"]) == Catalog.slugs()

      for entry <- index do
        assert is_binary(entry["title"])
        assert is_binary(entry["description"])
        assert is_binary(entry["group"])
        assert entry["url"] == "/docs/components/#{entry["slug"]}"
      end
    end
  end

  describe "command palette" do
    test "the root layout renders the search dialog with component items", %{conn: conn} do
      html = conn |> get(~p"/docs/components/button") |> html_response(200)

      assert html =~ "data-command"
      assert html =~ "command-dialog"
      assert html =~ "data-command-search"
      assert html =~ "docs-search-palette"
    end
  end
end
