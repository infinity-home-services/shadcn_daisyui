defmodule ShadcnDaisyui.NewVersion do
  @moduledoc """
  Tells people when a deploy has changed the app under a page they opened
  earlier. An `on_mount` hook for every live session:

      live_session :default, on_mount: [MyAppWeb.Auth, ShadcnDaisyui.NewVersion] do
        ...
      end

      # or with the app's name in the title
      live_session :default,
        on_mount: [{ShadcnDaisyui.NewVersion, title: "Acme was updated"}] do
        ...
      end

  (A LiveView outside a live session gets it from the app's `live_view`
  macro: `on_mount ShadcnDaisyui.NewVersion`.)

  After a deploy, a tab opened earlier keeps its old stylesheet and script.
  LiveView reconnects and sends the new markup, but the old stylesheet has no
  rules for classes the deploy added, so the page looks broken until it's
  reloaded in full. When a root LiveView mounts over the socket and
  `Phoenix.LiveView.static_changed?/1` says the page's tracked assets are not
  the latest, the hook sends a toast through `push_toast/3`: "A new version is
  available - Reload the page to get it.", with a **Reload** action, a close
  button, and no timeout. Reload loads the current page again in full, in the
  browser (no round trip, so it works while the socket is down). Every page
  mounted before the reload updates the same toast (`id: "new-version"`)
  instead of stacking another.

  It never reloads by itself: someone may be partway through a form.

  Options: `title:`, `description:` (the toast's two lines) and `action:` (the
  button's label, `"Reload"`).

  ## What it needs

    * `phx-track-static` on the root layout's own CSS and JS (Phoenix's
      generator adds it). The browser sends those URLs when it connects.
    * A cache manifest in production (`mix phx.digest` and
      `cache_static_manifest: "priv/static/cache_manifest.json"`, as Phoenix
      generates): the latest digested names the URLs are checked against.
    * A `<.toaster>` in the root layout, which shows the toast.

  Only the root LiveView's connected mount checks: a dead render has no
  tracked assets to compare, and a child LiveView is skipped (LiveView only
  promises the root its connect params, and the root has already told), so a
  page with nested LiveViews still gets one toast.

  ## Trying it locally

  In development there is no cache manifest, so nothing has changed and no
  toast shows. To see it, give the endpoint the manifest's latest names and
  the page a tracked asset with an old name - in `config/dev.exs`:

      config :my_app, MyAppWeb.Endpoint,
        cache_static_manifest_latest: %{
          "assets/css/app.css" => "assets/css/app-new.css",
          "assets/js/app.js" => "assets/js/app-new.js"
        }

  and in the root layout, next to the real stylesheet:

      <link phx-track-static rel="stylesheet" href="/assets/css/app-old.css" />

  Restart the server and open a LiveView page: the toast shows, and Reload
  loads the page again. Remove both afterwards.
  """

  import Phoenix.LiveView, only: [connected?: 1, static_changed?: 1]
  import ShadcnDaisyui.Components.Display, only: [push_toast: 3]

  @defaults [
    title: "A new version is available",
    description: "Reload the page to get it.",
    action: "Reload"
  ]

  @doc false
  def on_mount(:default, params, session, socket), do: on_mount([], params, session, socket)

  def on_mount(opts, _params, _session, socket) when is_list(opts) do
    opts = Keyword.validate!(opts, @defaults)
    {:cont, if(new_version?(socket), do: push_new_version(socket, opts), else: socket)}
  end

  # a dead render has no tracked assets; a child would raise without connect
  # params, or repeat the root's toast with them
  defp new_version?(socket) do
    connected?(socket) and is_nil(socket.parent_pid) and static_changed?(socket)
  end

  defp push_new_version(socket, opts) do
    push_toast(socket, opts[:title],
      id: "new-version",
      description: opts[:description],
      duration: :infinity,
      close_button: true,
      action: %{label: opts[:action], reload: true}
    )
  end
end
