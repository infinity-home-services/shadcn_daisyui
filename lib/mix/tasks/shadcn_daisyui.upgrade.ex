defmodule Mix.Tasks.ShadcnDaisyui.Upgrade do
  @shortdoc "Refreshes copied shadcn-daisyui assets after a dep update"
  @moduledoc """
  Re-copies the shadcn-daisyui CSS/JS into your app after
  `mix deps.update shadcn_daisyui`.

      mix shadcn_daisyui.upgrade

  Only needed for `--copy`-mode installs. If you installed in the default
  import-from-deps mode there is nothing to do — `mix deps.update` is enough.

  Local edits to the copied files are overwritten — diff first if you changed
  them (`git diff assets/css/shadcn-daisyui.css assets/js/shadcn-daisyui.js`).
  """
  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Task.run("app.config")
    priv = Application.app_dir(:shadcn_daisyui, "priv/static")

    copies = [
      {Path.join(priv, "shadcn-daisyui.css"), "assets/css/shadcn-daisyui.css"},
      {Path.join(priv, "shadcn-daisyui.js"), "assets/js/shadcn-daisyui.js"}
    ]

    existing = Enum.filter(copies, fn {_src, dest} -> File.exists?(dest) end)

    if existing == [] do
      Mix.shell().info("""
      No copied assets found — you're on the import-from-deps install, so
      `mix deps.update shadcn_daisyui` already upgraded everything.
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
end
