defmodule ShadcnDaisyui.Install.Steps do
  @moduledoc false
  # File steps shared by `mix shadcn_daisyui.install` and `mix
  # shadcn_daisyui.upgrade`. The patching itself is in `Patcher` (pure).

  alias ShadcnDaisyui.Install.Patcher

  @doc """
  Adds `on_mount ShadcnDaisyui.NewVersion` to the `live_view` quote in
  `lib/<app>_web.ex`. Leaves it alone when it already has the hook or the
  router lists it (a `live_session`'s `on_mount`); prints what to add by hand
  when there's no `use Phoenix.LiveView` to add it after.
  """
  def wire_new_version(unchanged \\ "unchanged") do
    web = List.first(Path.wildcard("lib/*_web.ex"))

    router =
      Enum.find(
        Path.wildcard("lib/*_web/router.ex"),
        &(&1 |> File.read!() |> Patcher.new_version?())
      )

    cond do
      router ->
        Mix.shell().info([
          :yellow,
          "* #{unchanged} ",
          :reset,
          "#{web || "lib/<app>_web.ex"} (#{router} has ShadcnDaisyui.NewVersion)"
        ])

      web ->
        original = File.read!(web)

        case Patcher.patch_new_version(original) do
          {:ok, ^original} ->
            Mix.shell().info([:yellow, "* #{unchanged} ", :reset, web])

          {:ok, patched} ->
            File.write!(web, patched)

            Mix.shell().info([
              :green,
              "* patched ",
              :reset,
              "#{web} (on_mount ShadcnDaisyui.NewVersion)"
            ])

          {:error, :live_view_not_found} ->
            new_version_by_hand(web)
        end

      true ->
        new_version_by_hand("lib/<app>_web.ex")
    end
  end

  defp new_version_by_hand(web) do
    Mix.shell().info("""

    #{IO.ANSI.yellow()}Couldn't find `use Phoenix.LiveView` in the live_view function of #{web} -
    add the new-version check (a Reload toast after a deploy) yourself, after it:#{IO.ANSI.reset()}

        on_mount ShadcnDaisyui.NewVersion

    or to every live_session's on_mount in your router:

        live_session :default, on_mount: [ShadcnDaisyui.NewVersion] do
    """)
  end

  @tracked [
    css: ~S|<link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />|,
    js:
      ~S|<script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}></script>|
  ]

  @doc """
  Prints a note when the root layout's own stylesheet or script has no
  `phx-track-static` (`ShadcnDaisyui.NewVersion` needs it). Changes nothing.
  """
  def check_track_static(root_layout) do
    case Patcher.untracked_assets(File.read!(root_layout)) do
      [] ->
        :ok

      kinds ->
        what = Enum.map_join(kinds, " and ", &%{css: "stylesheet", js: "script"}[&1])
        has = if length(kinds) > 1, do: "have", else: "has"
        tags = Enum.map_join(kinds, "\n", &("    " <> @tracked[&1]))

        Mix.shell().info("""

        #{IO.ANSI.yellow()}#{root_layout}: its #{what} #{has} no phx-track-static.#{IO.ANSI.reset()}
        ShadcnDaisyui.NewVersion compares the tracked assets against the cache
        manifest to offer a reload after a deploy - add it, as Phoenix generates it:

        #{tags}
        """)
    end
  end
end
