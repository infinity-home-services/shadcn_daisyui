defmodule ShadcnDaisyuiDemoWeb.AlertDialogPageTest do
  @moduledoc """
  The Alert Dialog gallery page renders its examples from `<.alert_dialog>`
  (no class recipe), the styled data-confirm example shows the opt-in, and the
  CSP pages carry the component.
  """
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the alert dialog page shows every example, rendered from the component", %{conn: conn} do
    html = conn |> get(~p"/docs/components/alert-dialog") |> html_response(200)

    for title <- [
          "Default",
          "Destructive",
          "Small, with media",
          "Open from the server",
          "Styled data-confirm"
        ] do
      assert html =~ ~r{>\s*#{title}\s*</h[23]>}, "missing the #{title} example"
    end

    # the live previews are the component's markup
    for id <- ~w(alert-default alert-delete alert-share alert-discard) do
      assert html =~ ~r{<dialog id="#{id}" class="modal alert-dialog[^"]*" role="alertdialog"},
             "#{id} is not an alert dialog"
    end

    assert html =~ ~s(aria-labelledby="alert-delete-title")
    assert html =~ ~s(aria-describedby="alert-delete-description")
    assert html =~ "alert-dialog-sm"
    assert html =~ ~s(class="alert-dialog-media")
    assert html =~ "data-alert-dialog-cancel"
    assert html =~ ~r/class="btn btn-error"[^>]*data-alert-dialog-action/

    # the styled data-confirm example: the opt-in and the attributes it reads
    assert html =~ "initConfirmDialog()"
    assert html =~ ~s(data-confirm="Remove Acme Marketing from Pat Lee?")
    assert html =~ ~s(data-confirm-action="Delete report")

    # no class recipe left over, and the code tab carries no LiveView wiring
    refute html =~ "alert_dialog_demo"
    refute html =~ ~r/<dialog id="alert-[a-z]+"[^>]*phx-mounted/
  end

  test "the markdown export documents the component", %{conn: conn} do
    md = conn |> get("/docs/components/alert-dialog.md") |> response(200)
    assert md =~ "Alert Dialog"
    assert md =~ "<.alert_dialog"
    assert md =~ "initConfirmDialog"
  end

  test "the CSP pages carry the alert dialog", %{conn: conn} do
    html = conn |> get(~p"/docs/dark-mode") |> html_response(200)
    assert html =~ ~s(<dialog id="dm-alert-shadcn" class="modal alert-dialog)
    assert html =~ ~s(<dialog id="dm-alert-shadcn-dark" class="modal alert-dialog)

    {:ok, view, _html} = live(conn, ~p"/lab/csp")
    assert has_element?(view, ~s(dialog#live-alert[role="alertdialog"][phx-mounted]))
    assert has_element?(view, ~s(#confirm-error[data-confirm][phx-click="flash"]))

    send(view.pid, :tick)
    assert render(view) =~ ~r/id="alert-ticks">[1-9]/

    # the action sends its phx-click like any button
    view |> element("#live-alert-save") |> render_click()
    assert render(view) =~ "Profile saved"
  end
end
