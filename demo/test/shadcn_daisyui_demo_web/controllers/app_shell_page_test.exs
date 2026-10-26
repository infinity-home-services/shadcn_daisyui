defmodule ShadcnDaisyuiDemoWeb.AppShellPageTest do
  use ShadcnDaisyuiDemoWeb.ConnCase

  alias ShadcnDaisyuiDemoWeb.ShellPreview

  describe "/docs/app-shell" do
    test "shows the shell on desktop and on a phone, the page header and the command dialog",
         %{conn: conn} do
      html = conn |> get(~p"/docs/app-shell") |> html_response(200)

      assert html =~ "App shell"
      assert html =~ ~s(id="shell-desktop")
      assert html =~ ~s(src="/docs/app-shell/preview/home")
      assert html =~ ~s(id="shell-phone")
      assert html =~ ~s(src="/docs/app-shell/preview/order")
      assert html =~ "&lt;.page_header"
      # a live palette without a shortcut (⌘K on this site is the docs search)
      assert html =~ ~s(id="shell-switcher")
      assert html =~ ~s(data-shortcut="")
      # listed with the other guides in the sidebar
      assert html =~ ~s(href="/docs/app-shell")
    end
  end

  describe "/docs/app-shell/preview/:page" do
    test "every preview page renders the shell with its item active", %{conn: conn} do
      for page <- ShellPreview.pages() do
        html = conn |> get(~p"/docs/app-shell/preview/#{page}") |> html_response(200)
        active = ShellPreview.page(page).active

        assert html =~ ~s(id="shell" class="app-shell)
        assert html =~ ~r{id="nav-#{active}"[^>]*aria-current="page"}
        assert html =~ ~s(id="page-header")
        # its own ⌘K search, not the docs one
        assert html =~ ~s(<dialog id="search")
        refute html =~ "docs-search-palette"
      end
    end

    test "the record page has crumbs back to its list", %{conn: conn} do
      html = conn |> get(~p"/docs/app-shell/preview/order") |> html_response(200)

      assert html =~ ~r{<a href="/docs/app-shell/preview/orders"[^>]*id="page-header-back"}
      assert html =~ ~s(<span aria-current="page">#1042</span>)
    end

    test "the record page's dialogs sit straight in its reading-width page, no wrapper",
         %{conn: conn} do
      html = conn |> get(~p"/docs/app-shell/preview/order") |> html_response(200)
      doc = LazyHTML.from_document(html)

      dialogs = LazyHTML.query(doc, ".app-shell-page:not([data-wide]) > dialog")
      assert LazyHTML.attribute(dialogs, "id") == ["discard", "activity-log"]
      assert LazyHTML.query(doc, "#discard.alert-dialog") |> Enum.count() == 1
      assert LazyHTML.query(doc, "#activity-log.sheet") |> Enum.count() == 1
      # Cancel asks first; the Activity card's "View all" opens the sheet
      assert html =~ ~r{id="order-cancel"[^>]*phx-click="[^"]*discard}
      assert html =~ ~r{id="activity-all"[^>]*phx-click="[^"]*activity-log}
    end

    test "the table page is wide and fills the window", %{conn: conn} do
      html = conn |> get(~p"/docs/app-shell/preview/orders") |> html_response(200)
      assert html =~ ~s(class="app-shell-page" data-wide data-fill)
    end

    test "an unknown page is a 404", %{conn: conn} do
      assert conn |> get(~p"/docs/app-shell/preview/nope") |> html_response(404)
    end
  end
end
