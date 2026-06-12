defmodule ShadcnDaisyuiDemoWeb.DocsController do
  use ShadcnDaisyuiDemoWeb, :controller

  alias ShadcnDaisyuiDemoWeb.Catalog
  alias ShadcnDaisyuiDemoWeb.Guides
  alias ShadcnDaisyuiDemoWeb.Markdown

  # /docs -> first component page
  def index(conn, _params) do
    redirect(conn, to: ~p"/docs/components/#{Catalog.first_slug()}")
  end

  # /docs/components/:slug renders the HTML page; /docs/components/:slug.md
  # serves the same content as AI-consumable markdown.
  def component(conn, %{"component" => slug}) do
    case Path.extname(slug) do
      ".md" -> component_markdown(conn, Path.rootname(slug))
      _ -> component_html(conn, slug)
    end
  end

  defp component_html(conn, slug) do
    case Catalog.component(slug) do
      nil ->
        not_found(conn)

      spec ->
        conn
        |> assign(:page_title, spec.title)
        |> assign(:spec, spec)
        |> render(:component)
    end
  end

  defp component_markdown(conn, slug) do
    case Catalog.component(slug) do
      nil -> not_found(conn)
      spec -> text_response(conn, "text/markdown", Markdown.component_markdown(spec))
    end
  end

  def llms(conn, _params) do
    text_response(conn, "text/plain", Markdown.llms_txt(base_path()))
  end

  def llms_full(conn, _params) do
    text_response(conn, "text/plain", Markdown.llms_full_txt(base_path()))
  end

  def search(conn, _params) do
    json(conn, Markdown.search_index(base_path()))
  end

  # /docs/foundations/:slug and /docs/styles/:slug render the visual guideline
  # page; the .md variant serves the shipped markdown source verbatim.
  def guide(conn, %{"guide" => slug}) do
    section = Enum.at(conn.path_info, 1)

    case Path.extname(slug) do
      ".md" -> guide_markdown(conn, section, Path.rootname(slug))
      _ -> guide_html(conn, section, slug)
    end
  end

  defp guide_html(conn, section, slug) do
    case Guides.guide(section, slug) do
      nil ->
        not_found(conn)

      guide ->
        conn
        |> assign(:page_title, guide.title)
        |> assign(:guide, guide)
        |> render(guide.template)
    end
  end

  defp guide_markdown(conn, section, slug) do
    case Guides.guide(section, slug) do
      nil -> not_found(conn)
      guide -> text_response(conn, "text/markdown", guide.markdown)
    end
  end

  def design_guidelines(conn, _params) do
    text_response(conn, "text/markdown", Guides.design_guidelines_md())
  end

  def installation(conn, _params) do
    conn
    |> assign(:page_title, "Installation")
    |> render(:installation)
  end

  def themes(conn, _params) do
    conn
    |> assign(:page_title, "Themes")
    |> render(:themes)
  end

  def adopt(conn, _params) do
    conn
    |> assign(:page_title, "Adopt the design system")
    |> render(:adopt)
  end

  def tokens(conn, _params) do
    conn
    |> assign(:page_title, "Tokens")
    |> assign(:token_groups, ShadcnDaisyuiDemoWeb.Catalog.Tokens.grouped())
    |> render(:tokens)
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ShadcnDaisyuiDemoWeb.ErrorHTML)
    |> render(:"404")
  end

  defp text_response(conn, content_type, body) do
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(200, body)
  end

  # The base URL path the site is hosted under ("" unless URL_PATH is set,
  # e.g. "/shadcn_daisyui" on a GitHub Pages project site). Links inside the
  # AI documents must carry this prefix so they resolve on the static host.
  defp base_path do
    case ShadcnDaisyuiDemoWeb.Endpoint.path("") do
      "/" -> ""
      path -> String.trim_trailing(path, "/")
    end
  end
end
