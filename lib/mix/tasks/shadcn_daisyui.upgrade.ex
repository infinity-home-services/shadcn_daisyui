defmodule Mix.Tasks.ShadcnDaisyui.Upgrade do
  @shortdoc "Brings an installed app up to date after a shadcn_daisyui dep update"
  @moduledoc """
  Brings an installed app up to date after `mix deps.update shadcn_daisyui`.

      mix shadcn_daisyui.upgrade

  It will:

    * patch your root layout's pre-paint script, as `mix shadcn_daisyui.install`
      does: the `theme-transition` guard around Phoenix's theme script, and the
      `<.app_shell>` sidebar's state (`data-sidebar` from localStorage
      `shadcn:sidebar`) - added once, then left alone; and check its own CSS
      and JS keep `phx-track-static` (it says so if they don't)
    * add `on_mount ShadcnDaisyui.NewVersion` to the `live_view` quote in
      `lib/<app>_web.ex`, as `mix shadcn_daisyui.install` does (after a
      deploy, a page opened earlier offers a reload) - unless it's there
      already or the router's live sessions list it
    * `--copy`-mode installs only: re-copy the CSS/JS into `assets/`. In the
      default import-from-deps mode `mix deps.update` already upgraded them.

  Local edits to the copied files are overwritten - diff first if you changed
  them (`git diff assets/css/shadcn-daisyui.css assets/js/shadcn-daisyui.js`).
  """
  use Mix.Task

  alias ShadcnDaisyui.Install.{Patcher, Steps}

  @impl true
  def run(_args) do
    Mix.Task.run("app.config")
    priv = Application.app_dir(:shadcn_daisyui, "priv/static")

    patch_root_layout()
    Steps.wire_new_version("up to date")

    copies = [
      {Path.join(priv, "shadcn-daisyui.css"), "assets/css/shadcn-daisyui.css"},
      {Path.join(priv, "shadcn-daisyui.js"), "assets/js/shadcn-daisyui.js"}
    ]

    existing = Enum.filter(copies, fn {_src, dest} -> File.exists?(dest) end)

    if existing == [] do
      Mix.shell().info("""
      No copied assets found - you're on the import-from-deps install, so
      `mix deps.update shadcn_daisyui` already upgraded the CSS and JS.
      """)
    else
      for {src, dest} <- existing do
        if File.read!(src) == File.read!(dest) do
          Mix.shell().info([:yellow, "* up to date ", :reset, dest])
        else
          File.cp!(src, dest)
          Mix.shell().info([:green, "* refreshed ", :reset, dest])
        end
      end
    end
  end

  defp patch_root_layout do
    case Path.wildcard("lib/*_web/components/layouts/root.html.heex") do
      [path | _] ->
        original = File.read!(path)

        case Patcher.patch_root_layout(original) do
          ^original ->
            Mix.shell().info([:yellow, "* up to date ", :reset, path])

          patched ->
            File.write!(path, patched)
            Mix.shell().info([:green, "* patched ", :reset, path])
        end

        Steps.check_track_static(path)

      [] ->
        Mix.shell().info([:yellow, "* skipped (not found) ", :reset, "root.html.heex"])
    end
  end
end
