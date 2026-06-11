defmodule Mix.Tasks.ShadcnDaisyui.Gen.Theme do
  @shortdoc "Generates a brand theme that overrides the shadcn-daisyui tokens"
  @moduledoc """
  Generates a brand theme as `[data-theme]` token overrides.

      mix shadcn_daisyui.gen.theme acme --primary "oklch(0.55 0.2 250)" --radius 0.5rem

  Writes `assets/css/themes/acme.css` containing `[data-theme="acme"]` (sparse —
  everything not overridden inherits the base light theme) and
  `[data-theme="acme-dark"]` (complete — copied from the base dark theme with
  your overrides applied), then wires it into `assets/css/app.css` (import +
  dark variant) and switches the root layout to `data-theme="acme"`.

  Tune the rest of the brand by editing the generated file — every token is
  listed. You can also build values visually in the docs site's theme creator
  and paste them in.

  ## Options

    * `--primary` — brand color, e.g. `"oklch(0.55 0.2 250)"` (any CSS color works)
    * `--primary-foreground` — text color on primary (default near-white)
    * `--radius` — base radius, e.g. `0.5rem` (sm/md/lg/xl derive from it)
    * `--dark-primary` — primary for the dark theme (defaults to `--primary`)
    * `--dark-primary-foreground` — defaults to `--primary-foreground`
  """
  use Mix.Task

  alias ShadcnDaisyui.Install.Patcher

  @impl true
  def run(args) do
    {opts, argv} =
      OptionParser.parse!(args,
        strict: [
          primary: :string,
          primary_foreground: :string,
          radius: :string,
          dark_primary: :string,
          dark_primary_foreground: :string
        ]
      )

    name =
      case argv do
        [name] when name != "" ->
          unless name =~ ~r/^[a-z][a-z0-9-]*$/ do
            Mix.raise("theme name must be lowercase letters/digits/dashes, got: #{name}")
          end

          name

        _ ->
          Mix.raise("usage: mix shadcn_daisyui.gen.theme NAME [--primary ...] [--radius ...]")
      end

    Mix.Task.run("app.config")

    base_css =
      :shadcn_daisyui
      |> Application.app_dir("priv/static/shadcn-daisyui.css")
      |> File.read!()

    css = build_theme(name, opts, base_css)
    path = "assets/css/themes/#{name}.css"
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, css)
    Mix.shell().info([:green, "* created ", :reset, path])

    patch_app_css(name)
    patch_root_layout(name)

    Mix.shell().info("""

    #{IO.ANSI.green()}Theme "#{name}" generated.#{IO.ANSI.reset()}

    * Edit #{path} to refine the brand (all tokens are listed).
    * Theme toggles: data-phx-theme="#{name}" / "#{name}-dark".
    """)
  end

  defp build_theme(name, opts, base_css) do
    light_overrides =
      [
        opts[:primary] && {"--primary", opts[:primary]},
        opts[:primary_foreground] && {"--primary-foreground", opts[:primary_foreground]},
        opts[:radius] && {"--radius", opts[:radius]}
      ]
      |> Enum.filter(& &1)

    dark_overrides =
      [
        {"--primary", opts[:dark_primary] || opts[:primary]},
        {"--primary-foreground", opts[:dark_primary_foreground] || opts[:primary_foreground]},
        {"--radius", opts[:radius]}
      ]
      |> Enum.filter(fn {_k, v} -> v end)

    dark_body =
      base_css
      |> extract_dark_block()
      |> apply_overrides(dark_overrides)

    """
    /* #{name} — brand theme for shadcn-daisyui.
       Light: overrides only what differs from the base theme (the rest inherits).
       Dark: a complete token set (dark can't inherit across [data-theme] blocks),
       copied from the base dark theme with the brand overrides applied. */

    [data-theme="#{name}"] {
      color-scheme: light;
    #{format_overrides(light_overrides)}
      /* Override any other base token here, e.g.:
         --secondary: oklch(0.97 0 0);
         --destructive: oklch(0.577 0.245 27.325);
         --chart-1: oklch(0.646 0.222 41.116); */
    }

    [data-theme="#{name}-dark"] {
    #{dark_body}
    }
    """
  end

  defp extract_dark_block(base_css) do
    case Regex.run(~r/\[data-theme="shadcn-dark"\][^{]*\{\n(.*?)\n\}/s, base_css) do
      [_, body] ->
        body

      _ ->
        Mix.raise(
          "couldn't find the dark theme block in shadcn-daisyui.css — " <>
            "the packaged CSS layout changed; please report this"
        )
    end
  end

  defp apply_overrides(body, overrides) do
    Enum.reduce(overrides, body, fn {token, value}, acc ->
      Regex.replace(~r/(#{Regex.escape(token)}):\s*[^;]+;/, acc, "\\1: #{value};", global: false)
    end)
  end

  defp format_overrides([]), do: ""

  defp format_overrides(overrides) do
    Enum.map_join(overrides, "", fn {token, value} -> "  #{token}: #{value};\n" end)
  end

  defp patch_app_css(name) do
    path = "assets/css/app.css"

    unless File.exists?(path) do
      Mix.raise("#{path} not found — run this from your Phoenix project root.")
    end

    css =
      path
      |> File.read!()
      |> Patcher.ensure_theme_import(name)
      |> Patcher.add_theme_to_dark_variant(name)

    File.write!(path, css)
    Mix.shell().info([:green, "* patched ", :reset, path])
  end

  defp patch_root_layout(name) do
    case Path.wildcard("lib/*_web/components/layouts/root.html.heex") do
      [path | _] ->
        heex = File.read!(path)

        case Patcher.set_root_theme(heex, name) do
          ^heex ->
            Mix.shell().info("""
            #{IO.ANSI.yellow()}Set the theme yourself in #{path}:#{IO.ANSI.reset()}  <html data-theme="#{name}">
            """)

          patched ->
            File.write!(path, patched)
            Mix.shell().info([:green, "* patched ", :reset, "#{path} (data-theme=\"#{name}\")"])
        end

      [] ->
        Mix.shell().info("""
        #{IO.ANSI.yellow()}Couldn't find root.html.heex — set:#{IO.ANSI.reset()}  <html data-theme="#{name}">
        """)
    end
  end
end
