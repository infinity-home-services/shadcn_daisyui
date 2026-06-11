defmodule Mix.Tasks.ShadcnDaisyui.Install do
  @shortdoc "Wires shadcn-daisyui into your Phoenix app (CSS, JS hooks, CoreComponents)"
  @moduledoc """
  Sets up shadcn-daisyui in a Phoenix 1.8 app.

      mix shadcn_daisyui.install

  By default assets are **imported from deps** so `mix deps.update shadcn_daisyui`
  upgrades styling and behavior everywhere — nothing is copied into your app.

  It will:

    * patch `assets/css/app.css` — daisyUI `themes: false`, import the theme from
      `deps/`, add `@source` for the package's components, set the `dark:` variant
    * patch `assets/js/app.js` — import the `Hooks` and spread them into your
      `LiveSocket`
    * patch your root layout — `data-theme="shadcn"` on `<html>`
    * replace `lib/<app>_web/components/core_components.ex` with a thin module
      delegating to `ShadcnDaisyui.CoreComponents` (original backed up; every
      component stays overridable; your Gettext error translation is preserved)
    * patch `lib/<app>_web.ex` so templates get `use ShadcnDaisyui.Components`
    * add the `:translate_error` config

  ## Options

    * `--copy` — copy the CSS/JS into `assets/` instead of importing from deps
      (you own the files; refresh them later with `mix shadcn_daisyui.upgrade`)
    * `--no-core-components` — skip the CoreComponents replacement
  """
  use Mix.Task

  alias ShadcnDaisyui.Install.Patcher

  @impl true
  def run(args) do
    {opts, _} =
      OptionParser.parse!(args, strict: [copy: :boolean, core_components: :boolean])

    mode = if opts[:copy], do: :copy, else: :deps

    Mix.Task.run("app.config")

    if mode == :copy, do: copy_assets()
    patch_file("assets/css/app.css", &Patcher.patch_app_css(&1, mode), required: true)
    patch_app_js(mode)
    patch_root_layout()
    patch_web_module()

    core_components_module =
      if Keyword.get(opts, :core_components, true), do: replace_core_components()

    if core_components_module, do: patch_config(core_components_module)

    finish(mode)
  end

  defp copy_assets do
    priv = Application.app_dir(:shadcn_daisyui, "priv/static")

    # JS goes in assets/js (already scanned by Tailwind) so the classes the
    # components build at runtime get generated.
    copy(Path.join(priv, "shadcn-daisyui.css"), "assets/css/shadcn-daisyui.css")
    copy(Path.join(priv, "shadcn-daisyui.js"), "assets/js/shadcn-daisyui.js")
  end

  defp copy(src, dest) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(src, dest)
    Mix.shell().info([:green, "* copied ", :reset, dest])
  end

  defp patch_file(path, fun, opts \\ []) do
    cond do
      File.exists?(path) ->
        original = File.read!(path)

        case fun.(original) do
          ^original ->
            Mix.shell().info([:yellow, "* unchanged ", :reset, path])
            :ok

          patched when is_binary(patched) ->
            File.write!(path, patched)
            Mix.shell().info([:green, "* patched ", :reset, path])
            :ok

          {:ok, ^original} ->
            Mix.shell().info([:yellow, "* unchanged ", :reset, path])
            :ok

          {:ok, patched} ->
            File.write!(path, patched)
            Mix.shell().info([:green, "* patched ", :reset, path])
            :ok

          {:error, reason} ->
            {:error, reason}
        end

      opts[:required] ->
        Mix.raise("#{path} not found — run this from your Phoenix project root.")

      true ->
        Mix.shell().info([:yellow, "* skipped (not found) ", :reset, path])
        :ok
    end
  end

  defp patch_app_js(mode) do
    case patch_file("assets/js/app.js", &Patcher.patch_app_js(&1, mode)) do
      {:error, :livesocket_not_found} ->
        import_from = if mode == :deps, do: "shadcn_daisyui", else: "./shadcn-daisyui"

        Mix.shell().info("""

        #{IO.ANSI.yellow()}Couldn't find your LiveSocket in assets/js/app.js — register the hooks manually:#{IO.ANSI.reset()}

            import { Hooks as ShadcnHooks } from "#{import_from}"
            new LiveSocket("/live", Socket, { params, hooks: { ...ShadcnHooks } })

        (dead views instead: `import { initShadcnDaisyui } from "#{import_from}"; initShadcnDaisyui()`)
        """)

      _ ->
        :ok
    end
  end

  defp patch_root_layout do
    case Path.wildcard("lib/*_web/components/layouts/root.html.heex") do
      [path | _] ->
        patch_file(path, &Patcher.patch_root_layout/1)

      [] ->
        Mix.shell().info("""

        #{IO.ANSI.yellow()}Couldn't find root.html.heex — set the theme manually:#{IO.ANSI.reset()}

            <html lang="en" data-theme="shadcn">
        """)
    end
  end

  defp patch_web_module do
    case Path.wildcard("lib/*_web.ex") do
      [path | _] ->
        patch_file(path, &Patcher.patch_web_module/1)
        path

      [] ->
        nil
    end
  end

  defp replace_core_components do
    case Path.wildcard("lib/*_web/components/core_components.ex") do
      [path | _] ->
        original = File.read!(path)

        if original =~ "ShadcnDaisyui.CoreComponents" do
          Mix.shell().info([:yellow, "* unchanged ", :reset, path])
          extract_module(original)
        else
          case Patcher.core_components_source(original) do
            {:ok, module, source} ->
              backup = path <> ".backup"
              File.write!(backup, original)
              File.write!(path, source)
              Mix.shell().info([:green, "* replaced ", :reset, "#{path} (backup: #{backup})"])
              module

            {:error, _} ->
              Mix.shell().info([
                :yellow,
                "* skipped core_components (couldn't parse) ",
                :reset,
                path
              ])

              nil
          end
        end

      [] ->
        Mix.shell().info([:yellow, "* skipped core_components (not found)", :reset])
        nil
    end
  end

  defp extract_module(source) do
    case Regex.run(~r/defmodule\s+([\w.]+)\s+do/, source) do
      [_, module] -> module
      _ -> nil
    end
  end

  defp patch_config(core_components_module) do
    patch_file("config/config.exs", &Patcher.patch_config(&1, core_components_module))
  end

  defp finish(mode) do
    upgrade_note =
      case mode do
        :deps -> "Upgrades: just `mix deps.update shadcn_daisyui`."
        :copy -> "Upgrades: `mix deps.update shadcn_daisyui && mix shadcn_daisyui.upgrade`."
      end

    Mix.shell().info("""

    #{IO.ANSI.green()}shadcn-daisyui installed.#{IO.ANSI.reset()}

    * Theme toggle buttons: point them at data-phx-theme="shadcn" / "shadcn-dark".
    * #{upgrade_note}
    * AI agents: add the design-system rules to your AGENTS.md / CLAUDE.md —
      with the usage_rules package installed, run:

          mix usage_rules.sync AGENTS.md --all
    """)
  end
end
