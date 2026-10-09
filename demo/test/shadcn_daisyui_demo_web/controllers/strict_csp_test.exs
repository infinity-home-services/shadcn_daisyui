defmodule ShadcnDaisyuiDemoWeb.StrictCSPTest do
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # `<tag … onclick=…>` / onsubmit= / onload= …, but only inside a start tag
  @inline_handler ~r/<[a-z][^>]*\son[a-z]+\s*=/i

  defp policy_header(conn), do: conn |> get_resp_header("content-security-policy") |> Enum.join()

  defp nonce!(conn) do
    policy = policy_header(conn)
    assert policy =~ "script-src 'self' 'nonce-"
    refute policy =~ "unsafe-inline"
    [_, nonce] = Regex.run(~r/'nonce-([^']+)'/, policy)
    nonce
  end

  # every inline <script> must carry the response nonce, or the page breaks
  defp assert_inline_scripts_nonced(html, nonce) do
    inline = Regex.scan(~r/<script(?![^>]*\ssrc=)[^>]*>/, html) |> List.flatten()
    assert inline != []
    for tag <- inline, do: assert(tag =~ ~s(nonce="#{nonce}"), "un-nonced inline script: #{tag}")
  end

  describe "/docs/dark-mode" do
    test "is served under a strict nonce policy, as header and meta tag", %{conn: conn} do
      conn = get(conn, ~p"/docs/dark-mode")
      html = html_response(conn, 200)
      nonce = nonce!(conn)

      assert html =~ ~s(http-equiv="Content-Security-Policy")
      [meta] = Regex.run(~r/<meta http-equiv="Content-Security-Policy"[^>]*>/, html)
      assert meta =~ "nonce-#{nonce}"
      assert policy_header(conn) =~ "frame-ancestors 'self'"
      assert_inline_scripts_nonced(html, nonce)
    end

    test "renders every overlay with no inline event handler", %{conn: conn} do
      html = conn |> get(~p"/docs/dark-mode") |> html_response(200)

      # the one deliberate handler is the canary button that demonstrates the block
      [canary] = Regex.scan(~r/<button[^>]*data-csp-canary[^>]*>/, html) |> List.flatten()
      assert canary =~ "onclick="
      rest = String.replace(html, canary, "")

      assert Regex.scan(@inline_handler, rest) == []
      refute rest =~ "javascript:"

      for cls <- ~w(modal sheet drawer-bottom command-dialog) do
        assert html =~ ~s(class="#{cls}), "missing #{cls} dialog"
      end

      assert html =~ "shadcn:show-modal"
      assert html =~ "shadcn:hide-modal"
      assert html =~ "ignore_attrs"
    end

    test "other pages keep Phoenix's default policy and no nonce meta", %{conn: conn} do
      conn = get(conn, ~p"/docs/themes")
      refute policy_header(conn) =~ "script-src"
      refute html_response(conn, 200) =~ ~s(http-equiv="Content-Security-Policy")
    end
  end

  describe "/lab/csp LiveView" do
    test "renders the overlays under the strict policy and keeps patching", %{conn: conn} do
      conn = get(conn, ~p"/lab/csp")
      html = html_response(conn, 200)
      assert_inline_scripts_nonced(html, nonce!(conn))
      assert Regex.scan(@inline_handler, html) == []

      {:ok, view, _html} = live(conn)
      assert has_element?(view, "dialog#live-dialog[phx-mounted]")
      assert has_element?(view, "dialog#live-sheet[phx-mounted]")

      send(view.pid, :tick)
      assert render(view) =~ ~r/id="dialog-ticks">[1-9]/
    end
  end
end
