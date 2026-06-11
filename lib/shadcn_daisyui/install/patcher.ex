defmodule ShadcnDaisyui.Install.Patcher do
  @moduledoc false
  # Pure string-in/string-out patching used by the install/upgrade Mix tasks.
  # Every function is idempotent: applying it twice equals applying it once.

  @css_dep_import ~s(@import "../../deps/shadcn_daisyui/priv/static/shadcn-daisyui.css";)
  @css_copy_import ~s(@import "./shadcn-daisyui.css";)
  @css_source ~s(@source "../../deps/shadcn_daisyui/lib";)
  @dark_variant ~s|@custom-variant dark (&:where([data-theme=shadcn-dark], [data-theme=shadcn-dark] *, [data-theme=dark], [data-theme=dark] *, .dark, .dark *));|

  @doc "Patches app.css: daisyUI themes off, theme import, @source, dark variant."
  def patch_app_css(css, mode) when mode in [:deps, :copy] do
    css
    |> ensure_themes_false()
    |> ensure_import(if(mode == :deps, do: @css_dep_import, else: @css_copy_import))
    |> then(fn css -> if mode == :deps, do: ensure_source(css), else: css end)
    |> ensure_dark_variant()
  end

  # turn the `@plugin ".../daisyui" { ... }` themes line into `themes: false`
  defp ensure_themes_false(css) do
    cond do
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

  defp ensure_import(css, line) do
    if css =~ "shadcn-daisyui.css" do
      css
    else
      # place it right after the daisyui @plugin block if we can, else append
      case Regex.run(~r/@plugin\s+"[^"]*daisyui"\s*\{[^}]*\}\s*\n/, css, return: :index) do
        [{start, len} | _] ->
          {a, b} = String.split_at(css, start + len)
          a <> line <> "\n" <> b

        _ ->
          css <> "\n" <> line <> "\n"
      end
    end
  end

  defp ensure_source(css) do
    if css =~ "deps/shadcn_daisyui/lib" do
      css
    else
      # right after the theme import so all package class names get scanned
      String.replace(css, @css_dep_import, @css_dep_import <> "\n" <> @css_source)
    end
  end

  defp ensure_dark_variant(css) do
    cond do
      css =~ "data-theme=shadcn-dark" ->
        css

      Regex.match?(~r/@custom-variant\s+dark\s/, css) ->
        Regex.replace(~r/@custom-variant\s+dark\s[^\n]*\n/, css, @dark_variant <> "\n")

      true ->
        css <> @dark_variant <> "\n"
    end
  end

  @doc """
  Patches app.js: adds the Hooks import and spreads `...Hooks` into the
  LiveSocket options. Returns `{:ok, js}` or `{:error, reason}` when the
  LiveSocket call can't be located (caller prints manual instructions).
  """
  def patch_app_js(js, mode) when mode in [:deps, :copy] do
    import_line =
      case mode do
        :deps -> ~s(import { Hooks as ShadcnHooks } from "shadcn_daisyui")
        :copy -> ~s(import { Hooks as ShadcnHooks } from "./shadcn-daisyui")
      end

    js = ensure_js_import(js, import_line)
    ensure_hooks(js)
  end

  defp ensure_js_import(js, import_line) do
    if js =~ "ShadcnHooks" do
      js
    else
      # after the last top-level import so bundlers keep imports grouped
      case Regex.scan(~r/^import .*$/m, js, return: :index) do
        [] ->
          import_line <> "\n" <> js

        matches ->
          {start, len} = matches |> List.last() |> List.first()
          {a, b} = String.split_at(js, start + len)
          a <> "\n" <> import_line <> b
      end
    end
  end

  defp ensure_hooks(js) do
    cond do
      js =~ "...ShadcnHooks" ->
        {:ok, js}

      # an existing hooks: { ... } option — merge ours in first
      Regex.match?(~r/hooks:\s*\{/, js) ->
        {:ok, Regex.replace(~r/hooks:\s*\{/, js, "hooks: { ...ShadcnHooks, ", global: false)}

      # no hooks option — add one to the LiveSocket options object
      Regex.match?(~r/new LiveSocket\([^,]+,\s*\w+,\s*\{/, js) ->
        {:ok,
         Regex.replace(
           ~r/(new LiveSocket\([^,]+,\s*\w+,\s*\{)/,
           js,
           "\\1\n  hooks: { ...ShadcnHooks },",
           global: false
         )}

      true ->
        {:error, :livesocket_not_found}
    end
  end

  @doc ~S"""
  Adds data-theme="shadcn" to the <html> tag of the root layout.

  Phoenix 1.8's stock layout manages data-theme client-side (the phx:set-theme
  script, values "light"/"dark"/"system") — the theme CSS aliases those values,
  so such layouts are left untouched.
  """
  def patch_root_layout(heex) do
    if heex =~ "phx:set-theme" or Regex.match?(~r/<html[^>]*data-theme/, heex) do
      heex
    else
      Regex.replace(~r/<html/, heex, ~s(<html data-theme="shadcn"), global: false)
    end
  end

  @doc """
  Adds `use ShadcnDaisyui.Components` to the `html_helpers` block of
  `my_app_web.ex` (right after the CoreComponents import).
  """
  def patch_web_module(source) do
    cond do
      source =~ "ShadcnDaisyui.Components" ->
        source

      Regex.match?(~r/import\s+\w+(\.\w+)*\.CoreComponents/, source) ->
        Regex.replace(
          ~r/(import\s+\w+(?:\.\w+)*\.CoreComponents)/,
          source,
          "\\1\n      use ShadcnDaisyui.Components",
          global: false
        )

      true ->
        source
    end
  end

  @doc """
  Builds the thin CoreComponents module that replaces the Phoenix-generated
  one. Preserves the app's Gettext-backed `translate_error/1` when a backend
  is detected in the original source.
  """
  def core_components_source(original_source) do
    with [_, module] <- Regex.run(~r/defmodule\s+([\w.]+)\s+do/, original_source) do
      gettext =
        case Regex.run(~r/use\s+Gettext,\s*backend:\s*([\w.]+)/, original_source) do
          [_, backend] -> backend
          _ -> nil
        end

      {:ok, module, build_core_components(module, gettext)}
    else
      _ -> {:error, :module_not_found}
    end
  end

  defp build_core_components(module, nil) do
    """
    defmodule #{module} do
      @moduledoc \"\"\"
      Core UI components, provided by the shadcn_daisyui design system.

      Every component delegates to `ShadcnDaisyui.CoreComponents` and is
      overridable — redefine any of them here to customize for this app.
      The original Phoenix-generated file was backed up next to this one.
      \"\"\"
      use ShadcnDaisyui.CoreComponents
    end
    """
  end

  defp build_core_components(module, gettext) do
    """
    defmodule #{module} do
      @moduledoc \"\"\"
      Core UI components, provided by the shadcn_daisyui design system.

      Every component delegates to `ShadcnDaisyui.CoreComponents` and is
      overridable — redefine any of them here to customize for this app.
      The original Phoenix-generated file was backed up next to this one.
      \"\"\"
      use ShadcnDaisyui.CoreComponents
      use Gettext, backend: #{gettext}

      @doc "Translates an error message using gettext."
      def translate_error({msg, opts}) do
        if count = opts[:count] do
          Gettext.dngettext(#{gettext}, "errors", msg, msg, count, opts)
        else
          Gettext.dgettext(#{gettext}, "errors", msg, opts)
        end
      end
    end
    """
  end

  @doc ~S|Adds `@import "./themes/NAME.css";` to app.css (after the base theme import).|
  def ensure_theme_import(css, name) do
    line = ~s(@import "./themes/#{name}.css";)

    cond do
      css =~ line ->
        css

      css =~ "shadcn-daisyui.css" ->
        Regex.replace(~r/(@import "[^"]*shadcn-daisyui\.css";)/, css, "\\1\n#{line}",
          global: false
        )

      true ->
        css <> "\n" <> line <> "\n"
    end
  end

  @doc "Extends the dark `@custom-variant` to cover `NAME-dark`."
  def add_theme_to_dark_variant(css, name) do
    selector = "[data-theme=#{name}-dark]"

    cond do
      css =~ selector ->
        css

      Regex.match?(~r/@custom-variant\s+dark\s+\(&:where\(/, css) ->
        Regex.replace(
          ~r/(@custom-variant\s+dark\s+\(&:where\()/,
          css,
          "\\g{1}#{selector}, #{selector} *, ",
          global: false
        )

      true ->
        css <>
          "@custom-variant dark (&:where(#{selector}, #{selector} *, " <>
          "[data-theme=shadcn-dark], [data-theme=shadcn-dark] *, .dark, .dark *));\n"
    end
  end

  @doc ~S|Sets (or replaces) the data-theme on the root layout's <html> tag.|
  def set_root_theme(heex, name) do
    cond do
      heex =~ ~s(data-theme="#{name}") ->
        heex

      heex =~ ~r/<html[^>]*data-theme="[^"]*"/ ->
        Regex.replace(
          ~r/(<html[^>]*data-theme=")[^"]*(")/,
          heex,
          "\\g{1}#{name}\\g{2}",
          global: false
        )

      true ->
        Regex.replace(~r/<html/, heex, ~s(<html data-theme="#{name}"), global: false)
    end
  end

  @doc """
  Adds the `:translate_error` config to config.exs (before any `import_config`
  so it stays in the general section).
  """
  def patch_config(config, core_components_module) do
    if config =~ ":shadcn_daisyui" do
      config
    else
      block = """

      # shadcn_daisyui translates form errors through your CoreComponents
      config :shadcn_daisyui, :translate_error, {#{core_components_module}, :translate_error}
      """

      case Regex.run(~r/^import_config/m, config, return: :index) do
        [{start, _len} | _] ->
          {a, b} = String.split_at(config, start)
          a <> String.trim_leading(block, "\n") <> "\n" <> b

        _ ->
          config <> block
      end
    end
  end
end
