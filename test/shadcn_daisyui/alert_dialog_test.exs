defmodule ShadcnDaisyui.Components.AlertDialogTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Overlay

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp tag(html, pattern) do
    [tag] = Regex.run(pattern, html)
    tag
  end

  defp dialog_tag(html), do: tag(html, ~r/<dialog [^>]*>/)

  describe "alert_dialog/1" do
    test "a native modal dialog with role alertdialog, named and described by its slots" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="delete-account">
          <:title>Delete your account?</:title>
          <:description>This permanently deletes your account.</:description>
          <:action variant="destructive" phx-click="delete_account">Delete account</:action>
        </.alert_dialog>
        """)

      dialog = dialog_tag(html)
      assert dialog =~ ~s(id="delete-account")
      assert dialog =~ ~r/class="modal alert-dialog\s*"/
      assert dialog =~ ~s(role="alertdialog")
      assert dialog =~ ~s(aria-labelledby="delete-account-title")
      assert dialog =~ ~s(aria-describedby="delete-account-description")

      assert html =~
               ~r{<h2 id="delete-account-title" class="alert-dialog-title">\s*Delete your account\?\s*</h2>}

      assert html =~
               ~r{<p id="delete-account-description" class="alert-dialog-description">\s*This permanently deletes your account.\s*</p>}

      assert html =~ ~s(class="alert-dialog-header")
      assert html =~ ~s(class="alert-dialog-footer")
    end

    test "without a description: no description element and no aria-describedby" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="d">
          <:title>Sign out?</:title>
          <:action>Sign out</:action>
        </.alert_dialog>
        """)

      refute dialog_tag(html) =~ "aria-describedby"
      refute html =~ "alert-dialog-description"
    end

    test "a backdrop click doesn't close it: no .modal-backdrop form" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="d">
          <:title>Sign out?</:title>
          <:action>Sign out</:action>
        </.alert_dialog>
        """)

      refute html =~ "modal-backdrop"
      refute html =~ ~s(method="dialog")
    end

    test "Cancel comes first, is a plain button with focus on open, and takes a label" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="d" cancel="Keep editing">
          <:title>Discard your changes?</:title>
          <:action variant="destructive">Discard</:action>
        </.alert_dialog>
        """)

      cancel = tag(html, ~r/<button [^>]*data-alert-dialog-cancel[^>]*>/)
      assert cancel =~ ~s(type="button")
      assert cancel =~ ~s(class="btn btn-outline")
      assert cancel =~ "autofocus"
      assert html =~ ~r{data-alert-dialog-cancel autofocus>\s*Keep editing\s*</button>}

      [cancel_at, action_at] =
        for marker <- ["data-alert-dialog-cancel", "data-alert-dialog-action"] do
          html |> :binary.match(marker) |> elem(0)
        end

      assert cancel_at < action_at

      default =
        render(~H|<.alert_dialog id="x"><:title>T</:title><:action>Go</:action></.alert_dialog>|)

      assert default =~ ~r{data-alert-dialog-cancel autofocus>\s*Cancel\s*</button>}
    end

    test "the action: a primary button by default, destructive on request" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="a">
          <:title>Continue?</:title>
          <:action phx-click="go">Continue</:action>
        </.alert_dialog>
        <.alert_dialog id="b">
          <:title>Delete?</:title>
          <:action variant="destructive" phx-click="delete" phx-value-id="42" id="b-delete">
            Delete
          </:action>
        </.alert_dialog>
        """)

      [a, b] = Regex.scan(~r/<button [^>]*data-alert-dialog-action[^>]*>/, html) |> List.flatten()
      assert a =~ ~s(class="btn btn-primary")
      assert a =~ ~s(type="button")
      assert a =~ ~s(phx-click="go")
      refute a =~ "data-keep-open"

      assert b =~ ~s(class="btn btn-error")
      assert b =~ ~s(phx-click="delete")
      assert b =~ ~s(phx-value-id="42")
      assert b =~ ~s(id="b-delete")
    end

    test "the action submits a form, goes somewhere, or stays open" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="submit">
          <:title>Place the order?</:title>
          <:action type="submit" form="order-form" class="min-w-32">Place order</:action>
        </.alert_dialog>
        <.alert_dialog id="nav">
          <:title>Discard your changes?</:title>
          <:action variant="destructive" navigate="/orders">Discard</:action>
        </.alert_dialog>
        <.alert_dialog id="out">
          <:title>Sign out?</:title>
          <:action href="/session" method="delete">Sign out</:action>
        </.alert_dialog>
        <.alert_dialog id="keep">
          <:title>Delete?</:title>
          <:action variant="destructive" phx-click="delete" close={false}>Delete</:action>
        </.alert_dialog>
        """)

      submit = tag(html, ~r/<button [^>]*form="order-form"[^>]*>/)
      assert submit =~ ~s(type="submit")
      assert submit =~ ~s(class="btn btn-primary min-w-32")
      assert submit =~ "data-alert-dialog-action"

      nav = tag(html, ~r/<a [^>]*href="\/orders"[^>]*>/)
      assert nav =~ ~s(data-phx-link="redirect")
      assert nav =~ ~s(class="btn btn-error")
      assert nav =~ "data-alert-dialog-action"

      out = tag(html, ~r/<a [^>]*href="\/session"[^>]*>/)
      assert out =~ ~s(data-method="delete")

      keep = tag(html, ~r/<button [^>]*phx-click="delete"[^>]*>/)
      assert keep =~ "data-keep-open"
      refute html =~ ~s(close=)
      refute html =~ ~s(variant=)
    end

    test "an unknown action variant raises" do
      assigns = %{}

      assert_raise ArgumentError, ~r/expected "default" or "destructive"/, fn ->
        render(~H"""
        <.alert_dialog id="d">
          <:title>Delete?</:title>
          <:action variant="danger">Delete</:action>
        </.alert_dialog>
        """)
      end
    end

    test "the trigger opens it with a JS dispatch; no inline handlers anywhere" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="d">
          <:trigger><button type="button">Delete account</button></:trigger>
          <:title>Delete your account?</:title>
          <:action variant="destructive" phx-click="delete">Delete account</:action>
        </.alert_dialog>
        """)

      assert html =~ "shadcn:show-modal"
      assert html =~ "#d"
      refute html =~ ~r/\son[a-z]+=/
      refute html =~ "javascript:"
      refute html =~ "showModal"
    end

    test "keeps its open attribute across patches; show + on_close as the other modals" do
      assigns = %{}

      plain =
        render(~H|<.alert_dialog id="d"><:title>T</:title><:action>Go</:action></.alert_dialog>|)

      assert dialog_tag(plain) =~ "phx-mounted="
      assert dialog_tag(plain) =~ "ignore_attrs"
      refute dialog_tag(plain) =~ "data-show"
      refute plain =~ "data-on-close"

      html =
        render(~H"""
        <.alert_dialog id="discard" show on_close="keep_editing">
          <:title>Discard your changes?</:title>
          <:action variant="destructive" phx-click="discard">Discard</:action>
        </.alert_dialog>
        """)

      assert dialog_tag(html) =~ "data-show"
      assert dialog_tag(html) =~ "shadcn:show-modal"
      assert html =~ ~r/<button[^>]*data-on-close[^>]*phx-click="keep_editing"/
    end

    test "size sm, media, extra content and the toast host" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="share" size="sm" class="extra">
          <:media><span class="hero-share" aria-hidden="true"></span></:media>
          <:title>Share this project?</:title>
          <:description>Anyone with the link can view it.</:description>
          <p id="more">Link expires in 7 days.</p>
          <:action>Share</:action>
        </.alert_dialog>
        """)

      assert dialog_tag(html) =~ ~s(class="modal alert-dialog alert-dialog-sm extra")

      assert html =~
               ~r{<div class="alert-dialog-media"><span class="hero-share" aria-hidden="true"></span></div>}

      # the media comes before the title, the extra content after the header
      assert :binary.match(html, "alert-dialog-media") < :binary.match(html, ~s(id="share-title"))
      assert :binary.match(html, ~s(id="share-description")) < :binary.match(html, ~s(id="more"))
      assert :binary.match(html, ~s(id="more")) < :binary.match(html, "alert-dialog-footer")
      assert html =~ ~s(<div id="share-toasts" data-toast-host phx-update="ignore"></div>)

      refute render(
               ~H|<.alert_dialog id="x"><:title>T</:title><:action>Go</:action></.alert_dialog>|
             ) =~
               "alert-dialog-sm"
    end

    test "global attributes go on the dialog" do
      assigns = %{}

      html =
        render(~H"""
        <.alert_dialog id="d" data-test="x">
          <:title>T</:title>
          <:action>Go</:action>
        </.alert_dialog>
        """)

      assert dialog_tag(html) =~ ~s(data-test="x")
    end

    test "the action slot takes any attribute without compile warnings" do
      code = """
      defmodule ShadcnDaisyui.AlertDialogWarningProbe do
        use Phoenix.Component
        import ShadcnDaisyui.Components.Overlay

        def probe(assigns) do
          ~H\"\"\"
          <.alert_dialog id="p">
            <:title>Delete?</:title>
            <:action variant="destructive" phx-click="delete" phx-value-id="1" close={false}>
              Delete
            </:action>
            <:action navigate="/x" id="go" data-x="y">Go</:action>
          </.alert_dialog>
          \"\"\"
        end
      end
      """

      warnings = ExUnit.CaptureIO.capture_io(:stderr, fn -> Code.compile_string(code) end)
      refute warnings =~ "undefined attribute"
      refute warnings =~ "warning"
    end
  end
end
