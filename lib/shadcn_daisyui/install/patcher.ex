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

      # an existing hooks: { ... } option - merge ours in first
      Regex.match?(~r/hooks:\s*\{/, js) ->
        {:ok, Regex.replace(~r/hooks:\s*\{/, js, "hooks: { ...ShadcnHooks, ", global: false)}

      # no hooks option - add one to the LiveSocket options object
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
  Patches the root layout's pre-paint setup: the theme and `<.app_shell>`'s
  sidebar state, both set on `<html>` before first paint.

  Theme: adds data-theme="shadcn" to the <html> tag. Phoenix 1.8's stock layout
  manages data-theme client-side (the phx:set-theme script, values
  "light"/"dark"/"system") - the theme CSS aliases those values, so no
  data-theme is added. Instead its inline `setTheme` is wrapped in the
  `theme-transition` guard so the swap stays instant (see `setTheme` in
  shadcn-daisyui.js).

  Sidebar: sets `data-sidebar` from localStorage `shadcn:sidebar` - inside the
  theme script (before its `storage` listener) when there is one, else in a
  small script of its own at the end of `<head>`. Untouched once the layout
  mentions `shadcn:sidebar`.
  """
  def patch_root_layout(heex) do
    heex
    |> ensure_theme()
    |> ensure_sidebar_state()
  end

  defp ensure_theme(heex) do
    cond do
      heex =~ "phx:set-theme" -> ensure_theme_transition_guard(heex)
      Regex.match?(~r/<html[^>]*data-theme/, heex) -> heex
      true -> Regex.replace(~r/<html/, heex, ~s(<html data-theme="shadcn"), global: false)
    end
  end

  @sidebar_lines [
    "// <.app_shell>: the sidebar's collapsed or open state, before first paint",
    "document.documentElement.dataset.sidebar =",
    ~s|  localStorage.getItem("shadcn:sidebar") === "collapsed" ? "collapsed" : "open";|
  ]

  defp ensure_sidebar_state(heex) do
    storage = ~r/^([ \t]*)window\.addEventListener\("storage"/m
    head = ~r/^([ \t]*)<\/head>/m

    cond do
      heex =~ "shadcn:sidebar" ->
        heex

      heex =~ "phx:set-theme" and Regex.match?(storage, heex) ->
        [{start, _}, {ind_start, ind_len}] = Regex.run(storage, heex, return: :index)
        indent = binary_part(heex, ind_start, ind_len)
        insert_at(heex, start, indented(@sidebar_lines, indent))

      Regex.match?(head, heex) ->
        [{start, _}, {ind_start, ind_len}] = Regex.run(head, heex, return: :index)
        indent = binary_part(heex, ind_start, ind_len) <> "  "

        script =
          [indent <> "<script nonce={assigns[:csp_nonce]}>"] ++
            indented(@sidebar_lines, indent <> "  ") ++ [indent <> "</script>"]

        insert_at(heex, start, script)

      true ->
        heex
    end
  end

  defp indented(lines, indent), do: Enum.map(lines, &(indent <> &1))

  # Inserts whole lines before the line starting at byte `start`.
  defp insert_at(heex, start, lines) do
    binary_part(heex, 0, start) <>
      Enum.map_join(lines, &(&1 <> "\n")) <> binary_part(heex, start, byte_size(heex) - start)
  end

  # Wrap the body of the stock `const setTheme = (theme) => { ... };` in
  # add/remove of the `theme-transition` class (removed two frames later, after
  # the new theme has painted). Untouched if already guarded or not found.
  defp ensure_theme_transition_guard(heex) do
    with false <- heex =~ "theme-transition",
         [{start, len}, {ind_start, ind_len}] <-
           Regex.run(~r/^([ \t]*)const setTheme = \(theme\) => \{[ \t]*\n/m, heex, return: :index),
         body_start = start + len,
         {:ok, close} <- matching_brace(heex, body_start, 1) do
      body = binary_part(heex, ind_start, ind_len) <> "  "

      add = ~s|#{body}document.documentElement.classList.add("theme-transition");\n|

      remove = """
      #{body}requestAnimationFrame(() =>
      #{body}  requestAnimationFrame(() => document.documentElement.classList.remove("theme-transition"))
      #{body});
      """

      # insert before the line holding the closing brace
      {newline, 1} = heex |> binary_part(0, close) |> :binary.matches("\n") |> List.last()
      close_line = newline + 1

      binary_part(heex, 0, body_start) <>
        add <>
        binary_part(heex, body_start, close_line - body_start) <>
        remove <>
        binary_part(heex, close_line, byte_size(heex) - close_line)
    else
      _ -> heex
    end
  end

  # Byte index of the `}` closing a block whose body starts at `i` (`depth` open).
  defp matching_brace(string, i, depth) when i < byte_size(string) do
    case :binary.at(string, i) do
      ?{ -> matching_brace(string, i + 1, depth + 1)
      ?} when depth == 1 -> {:ok, i}
      ?} -> matching_brace(string, i + 1, depth - 1)
      _ -> matching_brace(string, i + 1, depth)
    end
  end

  defp matching_brace(_string, _i, _depth), do: :error

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

  @new_version_lines [
    "# after a deploy, a page opened earlier offers a reload (no toast in dev)",
    "on_mount ShadcnDaisyui.NewVersion"
  ]

  @doc """
  Adds `on_mount ShadcnDaisyui.NewVersion` to the `live_view` quote of
  `my_app_web.ex`, right after its `use Phoenix.LiveView` (so every LiveView,
  in a live session or not, checks for a new version when it connects).

  Returns `{:ok, source}` (unchanged when the module already mentions the
  hook) or `{:error, :live_view_not_found}` when there's no `use
  Phoenix.LiveView` in a `live_view` function to add it after (the caller
  prints manual instructions).
  """
  def patch_new_version(source) do
    cond do
      new_version?(source) ->
        {:ok, source}

      position = live_view_use(source) ->
        {line_end, indent} = position
        patched = insert_new_version(source, line_end, indent)

        # a statement this didn't read right would break the module: leave it
        case Code.string_to_quoted(patched) do
          {:ok, _} -> {:ok, patched}
          _ -> {:error, :live_view_not_found}
        end

      true ->
        {:error, :live_view_not_found}
    end
  end

  @doc """
  True when `source` (the web module or a router) mentions
  `ShadcnDaisyui.NewVersion` outside a comment, e.g. in a `live_session`'s
  `on_mount`.
  """
  def new_version?(source), do: Regex.match?(~r/^[^#\n]*ShadcnDaisyui\.NewVersion\b/m, source)

  # {byte index of the newline that ends `use Phoenix.LiveView ...`, its indent}
  # - the first one in the body of `def live_view`, before the next def
  defp live_view_use(source) do
    with [{def_start, def_len}] <- Regex.run(~r/^[ \t]*def live_view\b/m, source, return: :index),
         body_start = def_start + def_len,
         body = source |> binary_part(body_start, byte_size(source) - body_start) |> def_body(),
         [{use_start, _}, {ind_start, ind_len}] <-
           Regex.run(~r/^([ \t]*)use Phoenix\.LiveView(?![\w.])/m, body, return: :index) do
      indent = binary_part(body, ind_start, ind_len)
      {body_start + statement_end(body, use_start), indent}
    else
      _ -> nil
    end
  end

  # the text up to the next `def`/`defp` (or the end)
  defp def_body(rest) do
    case Regex.run(~r/^[ \t]*defp?\s/m, rest, return: :index) do
      [{next, _}] -> binary_part(rest, 0, next)
      _ -> rest
    end
  end

  # Byte index of the newline ending the statement that starts at `start`: a
  # line ending in `,` or with brackets still open continues it.
  defp statement_end(string, start, depth \\ 0) do
    line_end =
      case :binary.match(string, "\n", scope: {start, byte_size(string) - start}) do
        {i, 1} -> i
        :nomatch -> byte_size(string)
      end

    line = binary_part(string, start, line_end - start)
    depth = depth + bracket_depth(line)
    continues? = depth > 0 or String.ends_with?(String.trim_trailing(line), ",")

    if continues? and line_end < byte_size(string),
      do: statement_end(string, line_end + 1, depth),
      else: line_end
  end

  defp bracket_depth(line) do
    for <<c <- line>>, reduce: 0 do
      depth when c in ~c"([{" -> depth + 1
      depth when c in ~c")]}" -> depth - 1
      depth -> depth
    end
  end

  # a blank line, the comment and the call after the `use`, and a blank line
  # before whatever follows unless it's blank already
  defp insert_new_version(source, line_end, indent) do
    rest = binary_part(source, line_end, byte_size(source) - line_end)
    blank_after? = Regex.match?(~r/\A\n[ \t]*(\n|\z)/, rest) or rest == ""

    lines = ["" | Enum.map(@new_version_lines, &(indent <> &1))]
    lines = if blank_after?, do: lines, else: lines ++ [""]

    binary_part(source, 0, line_end) <> Enum.map_join(lines, &("\n" <> &1)) <> rest
  end

  @doc """
  Which of the root layout's own assets (`:css`, `:js`) no tag tracks with
  `phx-track-static`: `ShadcnDaisyui.NewVersion` compares those URLs against
  the cache manifest. Stylesheets and scripts from another host don't count.
  """
  def untracked_assets(heex) do
    tags = fn tag, keep? ->
      ~r/<#{tag}\b[^>]*>/
      |> Regex.scan(heex)
      |> List.flatten()
      |> Enum.filter(
        &(keep?.(&1) and not Regex.match?(~r/(href|src)=\{?["']?(https?:)?\/\//, &1))
      )
    end

    css = tags.("link", &Regex.match?(~r/rel=["']stylesheet["']/, &1))
    js = tags.("script", &Regex.match?(~r/\ssrc=/, &1))

    for {kind, found} <- [css: css, js: js],
        not Enum.any?(found, &(&1 =~ "phx-track-static")),
        do: kind
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
      overridable - redefine any of them here to customize for this app.
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
      overridable - redefine any of them here to customize for this app.
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
