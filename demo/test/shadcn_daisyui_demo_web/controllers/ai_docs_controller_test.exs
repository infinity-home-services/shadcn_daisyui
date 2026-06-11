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
    test "returns a valid JSON index containing every guide and component slug", %{conn: conn} do
      conn = get(conn, "/docs/search.json")
      index = json_response(conn, 200)

      guide_slugs = Enum.map(ShadcnDaisyuiDemoWeb.Guides.all(), & &1.slug)
      assert Enum.map(index, & &1["slug"]) == guide_slugs ++ Catalog.slugs()

      for entry <- index do
        assert is_binary(entry["title"])
        assert is_binary(entry["description"])
        assert is_binary(entry["group"])
        assert String.contains?(entry["url"], "/docs/")
      end
    end
  end

  describe "GET /docs/foundations/:guide.md and /design-guidelines.md" do
    test "serves the shipped markdown for a guide", %{conn: conn} do
      conn = get(conn, "/docs/foundations/spacing.md")

      assert response(conn, 200) =~ "# shadcn_daisyui — spacing"
      assert response_content_type(conn, :md) =~ "text/markdown"
    end

    test "404s for an unknown guide", %{conn: conn} do
      assert conn |> get("/docs/foundations/not-a-guide.md") |> response(404)
      assert conn |> get("/docs/styles/not-a-guide") |> response(404)
    end

    test "serves the aggregate bundle with every guideline file", %{conn: conn} do
      body = conn |> get("/design-guidelines.md") |> response(200)

      for guide <- ShadcnDaisyuiDemoWeb.Guides.all() do
        assert body =~ String.trim_trailing(guide.markdown)
      end
    end
  end

  describe "GET /docs/foundations/:guide (HTML)" do
    test "renders every guideline page with the platform toggle", %{conn: conn} do
      for guide <- ShadcnDaisyuiDemoWeb.Guides.all() do
        html = conn |> get(guide.path) |> html_response(200)

        assert html =~ Plug.HTML.html_escape(guide.title)
        assert html =~ "data-platform-toggle"
        assert html =~ "#{guide.path}.md"
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
