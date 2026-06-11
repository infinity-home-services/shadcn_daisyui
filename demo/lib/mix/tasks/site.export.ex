defmodule Mix.Tasks.Site.Export do
  @shortdoc "Pre-render the docs site to static HTML for static hosting"

  @moduledoc """
  Renders every route to static HTML and copies the digested assets into an
  output directory (default `_site/`) that any static host can serve.

  This works because the site has no dynamic data: every route renders the same
  HTML every time, and all interactivity is client-side JS.

      MIX_ENV=prod mix site.export            # -> _site/
      MIX_ENV=prod mix site.export out/dir    # custom output dir

  Run it after building assets (the task does this for you via `assets.deploy`).
  `SECRET_KEY_BASE`/`PHX_HOST` are only needed to boot the endpoint; throwaway
  defaults are used if unset, since nothing is signed for a static build.
  """
  use Mix.Task

  alias ShadcnDaisyuiDemoWeb.Catalog

  @endpoint ShadcnDaisyuiDemoWeb.Endpoint

  @impl Mix.Task
  def run(args) do
    out = List.first(args) || "_site"

    # The endpoint boots from prod runtime config; provide throwaway values so a
    # static build doesn't require real secrets.
    System.put_env("SECRET_KEY_BASE", System.get_env("SECRET_KEY_BASE") || String.duplicate("z", 64))
    System.put_env("PHX_HOST", System.get_env("PHX_HOST") || "localhost")

    # Build + digest assets, then start the app so the digest manifest is loaded.
    Mix.Task.run("assets.deploy")
    Mix.Task.run("app.start")

    File.rm_rf!(out)
    File.mkdir_p!(out)

    pages =
      ["/", "/docs/installation", "/docs/themes"] ++
        Enum.map(Catalog.slugs(), &"/docs/components/#{&1}")

    Enum.each(pages, fn path -> write(out, path, render(path)) end)

    # /docs is a redirect route → emit a meta-refresh to the first component.
    write(out, "/docs", redirect_html("/docs/components/#{Catalog.first_slug()}"))

    # Minimal 404 (hosts can be configured to serve it).
    File.write!(Path.join(out, "404.html"), redirect_html("/"))

    copy_static(out)
    prefix_static_assets(out)

    Mix.shell().info([:green, "✓ ", :reset, "Exported #{length(pages)} pages + assets to #{out}/"])
  end

  # Phoenix prefixes generated route links with the URL base path, but `~p` for
  # static assets (`/assets`, `/images`, …) is not prefixed. When hosting under a
  # base path (e.g. a GitHub Pages project site), rewrite those roots in the HTML
  # so they resolve under the same prefix.
  defp prefix_static_assets(out) do
    base = System.get_env("URL_PATH")

    if base && base not in ["", "/"] do
      base = String.trim_trailing(base, "/")
      roots = ShadcnDaisyuiDemoWeb.static_paths()

      for file <- Path.wildcard(Path.join(out, "**/*.html")) do
        html = File.read!(file)

        new =
          Enum.reduce(roots, html, fn root, acc ->
            String.replace(acc, ~s(="/#{root}), ~s(="#{base}/#{root}))
          end)

        File.write!(file, new)
      end
    end
  end

  defp render(path) do
    # Dispatch through the full endpoint with an https://localhost conn so prod's
    # `force_ssl` passes the request through instead of issuing a 301 redirect.
    Plug.Test.conn(:get, "https://localhost" <> path)
    |> @endpoint.call(@endpoint.init([]))
    |> Map.fetch!(:resp_body)
  end

  # "/" -> out/index.html ; "/docs/themes" -> out/docs/themes/index.html
  defp write(out, "/", html), do: File.write!(Path.join(out, "index.html"), html)

  defp write(out, path, html) do
    dir = Path.join(out, String.trim_leading(path, "/"))
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "index.html"), html)
  end

  defp copy_static(out) do
    static = "priv/static"

    for entry <- File.ls!(static) do
      File.cp_r!(Path.join(static, entry), Path.join(out, entry))
    end
  end

  defp redirect_html(to) do
    """
    <!doctype html>
    <html lang="en" data-theme="shadcn">
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="refresh" content="0; url=#{to}" />
        <link rel="canonical" href="#{to}" />
        <title>Redirecting…</title>
      </head>
      <body><a href="#{to}">#{to}</a></body>
    </html>
    """
  end
end
