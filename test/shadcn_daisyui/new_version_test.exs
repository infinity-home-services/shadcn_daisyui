defmodule ShadcnDaisyui.NewVersionTest do
  # Not async: the tests change the endpoint's :cache_static_manifest_latest.
  use ExUnit.Case, async: false

  @moduletag :capture_log

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :shadcn_daisyui
  end

  defmodule DefaultLive do
    use Phoenix.LiveView
    on_mount(ShadcnDaisyui.NewVersion)
    def render(assigns), do: ~H"<p>page</p>"
  end

  defmodule TitledLive do
    use Phoenix.LiveView

    on_mount(
      {ShadcnDaisyui.NewVersion,
       title: "The app was updated", description: "Reload to keep going."}
    )

    def render(assigns), do: ~H"<p>page</p>"
  end

  defmodule ChildLive do
    use Phoenix.LiveView
    on_mount(ShadcnDaisyui.NewVersion)
    def render(assigns), do: ~H"<p>child</p>"
  end

  defmodule ParentLive do
    use Phoenix.LiveView

    def render(assigns) do
      ~H"""
      <div>{live_render(@socket, ChildLive, id: "child")}</div>
      """
    end
  end

  @endpoint Endpoint
  @config [
    secret_key_base: String.duplicate("s", 64),
    live_view: [signing_salt: "new-version-test"]
  ]

  @latest %{
    "assets/css/app.css" => "assets/css/app-2d6a1f.css",
    "assets/js/app.js" => "assets/js/app-91c0de.js"
  }
  @current ["/assets/css/app-2d6a1f.css?vsn=d", "/assets/js/app-91c0de.js?vsn=d"]
  @old ["/assets/css/app-0b7e3a.css?vsn=d", "/assets/js/app-91c0de.js?vsn=d"]

  setup_all do
    Application.put_env(:shadcn_daisyui, Endpoint, @config)
    start_supervised!(Endpoint)
    :ok
  end

  setup do
    on_exit(fn -> manifest(nil) end)
    :ok
  end

  defp manifest(latest) do
    config = if latest, do: [{:cache_static_manifest_latest, latest} | @config], else: @config
    :ok = Endpoint.config_change([{Endpoint, config}], [])
  end

  defp tracking(statics), do: put_connect_params(build_conn(), %{"_track_static" => statics})

  test "a page opened before a deploy gets one sticky toast with a Reload action" do
    manifest(@latest)
    {:ok, view, _html} = live_isolated(tracking(@old), DefaultLive)

    assert_push_event(view, "shadcn:toast", payload)

    assert payload == %{
             id: "new-version",
             message: "A new version is available",
             description: "Reload the page to get it.",
             type: "default",
             duration: "infinity",
             close_button: true,
             action: %{label: "Reload", reload: true}
           }
  end

  test "title: and description: replace the defaults" do
    manifest(@latest)
    {:ok, view, _html} = live_isolated(tracking(@old), TitledLive)

    assert_push_event(view, "shadcn:toast", %{
      id: "new-version",
      message: "The app was updated",
      description: "Reload to keep going."
    })
  end

  test "nothing when the page has the latest assets" do
    manifest(@latest)
    {:ok, view, _html} = live_isolated(tracking(@current), DefaultLive)
    refute_push_event(view, "shadcn:toast", _)
  end

  test "nothing without a cache manifest (development)" do
    {:ok, view, _html} = live_isolated(tracking(@old), DefaultLive)
    refute_push_event(view, "shadcn:toast", _)
  end

  test "a child LiveView mounts and pushes nothing" do
    manifest(@latest)
    {:ok, view, _html} = live_isolated(tracking(@old), ParentLive)

    assert view |> find_live_child("child") |> render() =~ "child"
    refute_push_event(view, "shadcn:toast", _)
  end

  # LiveViewTest's child join carries no tracked assets, so the guard is
  # checked on a child socket directly
  test "a child's mount is skipped: no second toast, and no raise" do
    manifest(@latest)

    with_statics = %Phoenix.LiveView.Socket{
      endpoint: Endpoint,
      transport_pid: self(),
      parent_pid: self(),
      private: %{connect_params: %{"_track_static" => @old}, live_temp: %{}}
    }

    assert {:cont, %{private: %{live_temp: temp}}} =
             ShadcnDaisyui.NewVersion.on_mount(:default, %{}, %{}, with_statics)

    refute temp[:push_events]

    # without connect_params (LiveView documents them as the root's only),
    # static_changed?/1 raises
    without = %{with_statics | private: %{live_temp: %{}}}
    assert {:cont, _} = ShadcnDaisyui.NewVersion.on_mount(:default, %{}, %{}, without)
  end

  test "nothing on the dead render" do
    manifest(@latest)
    socket = %Phoenix.LiveView.Socket{endpoint: Endpoint}

    assert {:cont, %{private: private}} =
             ShadcnDaisyui.NewVersion.on_mount(:default, %{}, %{}, socket)

    refute get_in(private, [:live_temp, :push_events])
  end

  test "an unknown option raises" do
    assert_raise ArgumentError, fn ->
      ShadcnDaisyui.NewVersion.on_mount([titel: "x"], %{}, %{}, %Phoenix.LiveView.Socket{})
    end
  end
end
