defmodule ShadcnDaisyui.Install.StepsTest do
  # changes the working directory and the Mix shell: not async
  use ExUnit.Case, async: false

  alias ShadcnDaisyui.Install.Steps

  @moduletag :tmp_dir

  @web_module """
  defmodule MyAppWeb do
    def live_view do
      quote do
        use Phoenix.LiveView

        unquote(html_helpers())
      end
    end

    defp html_helpers do
      quote do
        import MyAppWeb.CoreComponents
      end
    end
  end
  """

  @router """
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router

    scope "/", MyAppWeb do
      live_session :default, on_mount: [MyAppWeb.Auth] do
        live "/", HomeLive
      end
    end
  end
  """

  setup %{tmp_dir: dir} do
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    File.mkdir_p!(Path.join(dir, "lib/my_app_web/components/layouts"))
    File.write!(Path.join(dir, "lib/my_app_web.ex"), @web_module)
    File.write!(Path.join(dir, "lib/my_app_web/router.ex"), @router)

    on_exit(fn -> Mix.shell(shell) end)
    :ok
  end

  defp info do
    receive do
      {:mix_shell, :info, [message]} -> message
    after
      0 -> flunk("nothing printed")
    end
  end

  describe "wire_new_version/1" do
    test "patches the web module once, then leaves it", %{tmp_dir: dir} do
      File.cd!(dir, fn ->
        Steps.wire_new_version()
        assert info() =~ "* patched lib/my_app_web.ex (on_mount ShadcnDaisyui.NewVersion)"

        patched = File.read!("lib/my_app_web.ex")
        assert patched =~ "use Phoenix.LiveView\n\n      # after a deploy"
        assert patched =~ "on_mount ShadcnDaisyui.NewVersion\n\n      unquote(html_helpers())"

        Steps.wire_new_version("up to date")
        assert info() =~ "* up to date lib/my_app_web.ex"
        assert File.read!("lib/my_app_web.ex") == patched
      end)
    end

    test "skips an app whose router lists it", %{tmp_dir: dir} do
      File.cd!(dir, fn ->
        File.write!(
          "lib/my_app_web/router.ex",
          String.replace(@router, "[MyAppWeb.Auth]", "[MyAppWeb.Auth, ShadcnDaisyui.NewVersion]")
        )

        Steps.wire_new_version()

        assert info() =~
                 "* unchanged lib/my_app_web.ex (lib/my_app_web/router.ex has ShadcnDaisyui.NewVersion)"

        assert File.read!("lib/my_app_web.ex") == @web_module
      end)
    end

    test "says what to add when it can't find use Phoenix.LiveView", %{tmp_dir: dir} do
      File.cd!(dir, fn ->
        source = String.replace(@web_module, "use Phoenix.LiveView", "use MyAppWeb.BaseLive")
        File.write!("lib/my_app_web.ex", source)

        Steps.wire_new_version()
        message = info()
        assert message =~ "Couldn't find `use Phoenix.LiveView`"
        assert message =~ "on_mount ShadcnDaisyui.NewVersion"
        assert File.read!("lib/my_app_web.ex") == source
      end)
    end
  end

  describe "check_track_static/1" do
    test "prints a note only when the layout's CSS or JS isn't tracked", %{tmp_dir: dir} do
      File.cd!(dir, fn ->
        path = "lib/my_app_web/components/layouts/root.html.heex"

        File.write!(path, """
        <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}></script>
        """)

        assert Steps.check_track_static(path) == :ok
        refute_received {:mix_shell, :info, _}

        File.write!(path, """
        <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
        <script defer type="text/javascript" src={~p"/assets/js/app.js"}></script>
        """)

        Steps.check_track_static(path)
        message = info()
        assert message =~ "#{path}: its script has no phx-track-static."
        assert message =~ ~S|<script defer phx-track-static type="text/javascript"|
        refute message =~ "<link"
      end)
    end
  end
end
