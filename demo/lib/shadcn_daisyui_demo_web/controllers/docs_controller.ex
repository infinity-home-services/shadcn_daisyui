defmodule ShadcnDaisyuiDemoWeb.DocsController do
  use ShadcnDaisyuiDemoWeb, :controller

  alias ShadcnDaisyuiDemoWeb.Catalog

  # /docs -> first component page
  def index(conn, _params) do
    redirect(conn, to: ~p"/docs/components/#{Catalog.first_slug()}")
  end

  def component(conn, %{"component" => slug}) do
    case Catalog.component(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(ShadcnDaisyuiDemoWeb.ErrorHTML)
        |> render(:"404")

      spec ->
        conn
        |> assign(:page_title, spec.title)
        |> assign(:spec, spec)
        |> render(:component)
    end
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
end
