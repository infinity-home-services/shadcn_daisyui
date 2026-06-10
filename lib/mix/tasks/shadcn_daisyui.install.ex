defmodule Mix.Tasks.ShadcnDaisyui.Install do
  @shortdoc "Copies the shadcn-daisyui CSS/JS into your app and wires app.css"
  @moduledoc """
  Sets up shadcn-daisyui in a Phoenix app.

      mix shadcn_daisyui.install

  It will:

    * copy the theme into `assets/css/shadcn-daisyui.css`
    * copy the JS into `assets/vendor/shadcn-daisyui.js`
    * make sure `assets/css/app.css` turns off daisyUI's default themes,
      imports the theme, and uses `shadcn-dark` for the `dark:` variant

  Then finish the two manual steps it prints (one line in `app.js`, and
  `data-theme="shadcn"` on `<html>`).
  """
  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Task.run("app.config")
    priv = Application.app_dir(:shadcn_daisyui, "priv/static")

    # JS goes in assets/js (already scanned by Tailwind) so the classes the
    # components build at runtime get generated.
    copy(Path.join(priv, "shadcn-daisyui.css"), "assets/css/shadcn-daisyui.css")
    copy(Path.join(priv, "shadcn-daisyui.js"), "assets/js/shadcn-daisyui.js")
    patch_app_css("assets/css/app.css")

    Mix.shell().info("""

    #{IO.ANSI.green()}shadcn-daisyui assets installed.#{IO.ANSI.reset()}

    Two manual steps to finish:

    1) assets/js/app.js — register the interactive components:

         import { Hooks } from "./shadcn-daisyui"
         // add to your LiveSocket:  new LiveSocket("/live", Socket, { params, hooks: { ...Hooks } })
         // (dead views: `import { initShadcnDaisyui } from "./shadcn-daisyui"; initShadcnDaisyui()`)

    2) lib/<app>_web/components/layouts/root.html.heex — set the default theme:

         <html lang="en" data-theme="shadcn">

       and point your theme toggle buttons at data-phx-theme="shadcn" / "shadcn-dark".
    """)
  end

  defp copy(src, dest) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(src, dest)
    Mix.shell().info([:green, "* copied ", :reset, dest])
  end

  defp patch_app_css(path) do
    unless File.exists?(path) do
      Mix.raise("#{path} not found — run this from your Phoenix project root.")
    end

    css = File.read!(path)
    css = ensure_themes_false(css)
    css = ensure_import(css)
    css = ensure_dark_variant(css)
    File.write!(path, css)
    Mix.shell().info([:green, "* patched ", :reset, path])
  end

  # turn `@plugin ".../daisyui" { ... }` themes on/off line into `themes: false`
  defp ensure_themes_false(css) do
    cond do
      css =~ "shadcn-daisyui.css" ->
        css

      Regex.match?(~r/themes:\s*false/, css) ->
        css

      Regex.match?(~r/@plugin\s+"[^"]*daisyui"\s*\{/, css) ->
        Regex.replace(~r/(@plugin\s+"[^"]*daisyui"\s*\{)([^}]*)\}/, css, fn _, open, body ->
          if body =~ "themes:",
            do: open <> Regex.replace(~r/themes:\s*[^;]+;/, body, "themes: false;") <> "}",
            else: open <> body <> "  themes: false;\n}"
        end)

      true ->
        css
    end
  end

  defp ensure_import(css) do
    if css =~ "shadcn-daisyui.css" do
      css
    else
      line = ~s(@import "./shadcn-daisyui.css";\n)

      # place it right after the daisyui @plugin block if we can, else append
      case Regex.run(~r/@plugin\s+"[^"]*daisyui"\s*\{[^}]*\}\s*\n/, css, return: :index) do
        [{start, len}] ->
          {a, b} = String.split_at(css, start + len)
          a <> line <> b

        _ ->
          css <> "\n" <> line
      end
    end
  end

  defp ensure_dark_variant(css) do
    variant =
      ~s|@custom-variant dark (&:where([data-theme=shadcn-dark], [data-theme=shadcn-dark] *, .dark, .dark *));\n|

    cond do
      css =~ "data-theme=shadcn-dark" ->
        css

      Regex.match?(~r/@custom-variant\s+dark\s/, css) ->
        Regex.replace(~r/@custom-variant\s+dark\s[^\n]*\n/, css, variant)

      true ->
        css <> variant
    end
  end
end
