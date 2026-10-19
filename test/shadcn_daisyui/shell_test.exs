defmodule ShadcnDaisyui.Components.ShellTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Shell

  alias Phoenix.LiveView.JS

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  # The part of the page between two ids' elements (sidebar, dock, More sheet…).
  defp section(html, from, to) do
    [_, rest] = String.split(html, ~s(id="#{from}"), parts: 2)
    [part | _] = String.split(rest, ~s(id="#{to}"), parts: 2)
    part
  end

  defp sidebar(html), do: section(html, "sidebar", "main")
  defp dock(html), do: section(html, "bottom-bar", "more-nav")
  defp more(html), do: html |> String.split(~s(id="more-nav"), parts: 2) |> List.last()

  @nav [
    %{label: nil, items: [%{id: "home", label: "Home", path: "/", icon: "hero-home"}]},
    %{
      label: "Sales",
      items: [
        %{
          id: "orders",
          label: "Orders",
          short: "Ord",
          path: "/orders",
          icon: "hero-shopping-cart"
        },
        %{id: "customers", label: "Customers", path: "/customers", icon: "hero-users"},
        %{id: "quotes", label: "Quotes", path: "/quotes", icon: "hero-document-text"}
      ]
    },
    %{
      label: "Settings",
      items: [
        %{id: "team", label: "Team", path: "/team", icon: "hero-user-group"},
        %{id: "billing", label: "Billing", path: "/billing", icon: "hero-credit-card"}
      ]
    }
  ]

  @person %{name: "Pat Lee", email: "pat@example.com"}

  defp shell(extra \\ %{}) do
    assigns = Map.merge(%{nav: @nav, person: @person, active: "orders", search: "search"}, extra)

    render(~H"""
    <.app_shell
      nav={@nav}
      bar={assigns[:bar]}
      more={assigns[:more]}
      active={@active}
      search={@search}
      environment={assigns[:environment]}
      wide={assigns[:wide] || false}
      fill={assigns[:fill] || false}
      person={@person}
    >
      <:header>
        <.app_shell_heading id="app-heading" icon="hero-cube" title="Acme" subtitle="Ops" />
      </:header>
      <:phone_header><span id="phone-title">Acme</span></:phone_header>
      <:footer_item
        id="whats-new-open"
        icon="hero-megaphone"
        label="What's new"
        phx-click={JS.dispatch("shadcn:show-dialog", to: "#whats-new")}
      />
      <:footer_item id="help" icon="hero-question-mark-circle" label="Help" href="/help" />
      <:account_item id="account" icon="hero-user-circle" navigate="/account">Account</:account_item>
      <:account_item id="notifications" icon="hero-bell" navigate="/notifications">
        Notifications
      </:account_item>
      <:account_item id="support" icon="hero-lifebuoy" soon divider>Support</:account_item>
      <:account_item id="feedback" icon="hero-chat-bubble-left-ellipsis" soon>Feedback</:account_item>
      <:account_item
        id="sign-out"
        icon="hero-arrow-right-start-on-rectangle"
        href="/sign-out"
        method="delete"
        destructive
        divider
      >
        Sign out
      </:account_item>
      <p id="page-content">Page content</p>
    </.app_shell>
    """)
  end

  describe "app_shell/1 sidebar" do
    test "renders the groups with their labels, in order, and every item" do
      html = sidebar(shell())

      assert html =~ ~s(<nav id="main-nav" aria-label="Main" class="app-shell-nav">)
      assert count(html, ~s(class="app-shell-group-label")) == 2
      assert html =~ ~r{<div class="app-shell-group-label">Sales</div>.*Settings}s

      for id <- ~w(home orders customers quotes team billing) do
        assert html =~ ~s(id="nav-#{id}")
      end

      assert html =~ ~r{<a href="/customers" data-phx-link="redirect"[^>]*id="nav-customers"}
      # the rail's tooltip is the label
      assert html =~
               ~r{id="nav-customers" class="tooltip tooltip-right app-shell-item" data-tip="Customers"}

      assert html =~ ~s(<span class="hero-users size-4 shrink-0" aria-hidden="true"></span>)
    end

    test "marks the active item, and only it" do
      html = sidebar(shell())

      assert count(html, ~s(aria-current="page")) == 1
      assert html =~ ~r{id="nav-orders"[^>]*aria-current="page"}
      refute html =~ ~r{id="nav-home"[^>]*aria-current}
    end

    test "has the grab strip, the header slot and the collapse row" do
      html = sidebar(shell())

      assert html =~ ~s(id="sidebar-rail")
      assert html =~ ~r{<div class="app-shell-heading ?" id="app-heading">}
      assert html =~ ~s(id="sidebar-toggle")
      assert html =~ "Collapse sidebar"
      assert html =~ "⌘B"
      # both dispatch the toggle event
      assert count(html, "shadcn:toggle-sidebar") == 2
    end

    test "the search row opens the named dialog and shows the shortcut" do
      html = shell()

      assert sidebar(html) =~
               ~r{id="search-open" class="btn btn-outline btn-sm tooltip tooltip-right app-shell-search" data-tip="Search \(⌘K\)"}

      assert sidebar(html) =~ ~s(<kbd class="kbd kbd-sm app-shell-label">⌘K</kbd>)
      assert html =~ ~s(id="search-open-phone")

      assert count(
               html,
               "&quot;to&quot;:&quot;#search&quot;,&quot;event&quot;:&quot;shadcn:show-dialog&quot;"
             ) == 2
    end

    test "no search button anywhere when search is nil" do
      html = shell(%{search: nil})

      refute html =~ ~s(id="search-open")
      refute html =~ ~s(id="search-open-phone")
      refute html =~ "Search"
      # the phone row still renders (the page header pins below it)
      assert html =~ ~s(id="phone-header")
    end

    test "the environment badge shows only when given" do
      assert shell(%{environment: "Staging"}) =~
               ~r{<span id="environment-badge" class="badge badge-secondary app-shell-label app-shell-badge">\s*Staging\s*</span>}

      refute shell() =~ "environment-badge"
    end

    test "the account trigger shows initials, name and email" do
      html = sidebar(shell())

      assert html =~
               ~s(<div id="user-menu" class="dropdown dropdown-right dropdown-end app-shell-account">)

      assert html =~ ~s(aria-label="Account menu")
      assert count(html, ~s(<span class="app-shell-avatar">PL</span>)) == 2
      assert html =~ "Pat Lee"
      assert html =~ "pat@example.com"
      assert html =~ "hero-chevron-up-down"
    end
  end

  describe "app_shell/1 footer and account items" do
    test "footer items render in the sidebar and in the More sheet" do
      html = shell()

      assert sidebar(html) =~
               ~r{<button type="button" id="whats-new-open" class="tooltip tooltip-right app-shell-item"[^>]*data-tip="What&#39;s new"}

      assert sidebar(html) =~
               ~r{<a href="/help" id="help" class="tooltip tooltip-right app-shell-item"}

      assert more(html) =~
               ~r{<button type="button" id="whats-new-open-phone" class="app-shell-sheet-row"}

      assert more(html) =~ ~r{<a href="/help" id="help-phone" class="app-shell-sheet-row"}
      assert count(html, "#whats-new") == 2
    end

    test "account items render in the menu and the More sheet, theme row after the first section" do
      html = shell()
      menu = section(html, "user-menu", "main")
      sheet = more(html)

      for {part, prefix} <- [{menu, "user-menu-"}, {sheet, "account-phone-"}] do
        assert part =~ ~r{<a href="/account"[^>]*id="#{prefix}account" class="app-shell-menu-row"}
        assert part =~ ~r{id="#{prefix}notifications"}

        # Account, Notifications, Theme, a line, Support, Feedback, a line, Sign out
        order =
          Regex.scan(
            ~r{id="#{prefix}(account|notifications|support|feedback|sign-out)"|(app-shell-theme-row)|(class="app-shell-sep")},
            part
          )
          |> Enum.map(fn match -> match |> Enum.drop(1) |> Enum.find(&(&1 != "")) end)

        assert order == [
                 "class=\"app-shell-sep\"",
                 "account",
                 "notifications",
                 "app-shell-theme-row",
                 "class=\"app-shell-sep\"",
                 "support",
                 "feedback",
                 "class=\"app-shell-sep\"",
                 "sign-out"
               ]
      end

      assert sheet =~ ~s(id="account-phone" class="app-shell-more-account")
      # the theme toggle in both
      assert count(html, ~s(class="theme-toggle ")) == 2
    end

    test "soon items are muted, marked Soon and do nothing" do
      html = shell()

      assert html =~
               ~r{<div id="user-menu-support" class="app-shell-menu-row" data-soon>\s*<span class="hero-lifebuoy size-4 shrink-0" aria-hidden="true"></span>\s*<span class="app-shell-grow">Support</span>\s*<span class="badge badge-outline">Soon</span>}

      assert html =~ ~r{<div id="account-phone-feedback" class="app-shell-menu-row" data-soon>}
      assert count(html, ">Soon</span>") == 4
    end

    test "destructive items link with their method and get the destructive variant" do
      html = shell()

      for id <- ~w(user-menu-sign-out account-phone-sign-out) do
        assert html =~
                 ~r{<a href="/sign-out" data-method="delete" data-csrf="[^"]+" data-to="/sign-out" id="#{id}" class="app-shell-menu-row" data-variant="destructive">}
      end

      refute html =~ ~r{id="user-menu-account"[^>]*data-variant}
    end

    test "a leading divider adds no second line under the person" do
      assigns = %{nav: @nav, person: @person}

      html =
        render(~H"""
        <.app_shell nav={@nav} person={@person}>
          <:account_item id="out" href="/out" divider destructive>Sign out</:account_item>
          content
        </.app_shell>
        """)

      menu = section(html, "user-menu", "main")
      assert count(menu, ~s(class="app-shell-sep")) == 1
      assert menu =~ ~r{id="user-menu-out".*app-shell-theme-row}s
    end
  end

  describe "app_shell/1 phones" do
    test "the dock shows the first four items of more, then More" do
      html = dock(shell())

      assert Regex.scan(~r{id="bar-([\w-]+)"}, html, capture: :all_but_first) ==
               [["home"], ["orders"], ["customers"], ["quotes"], ["more"]]

      # the short label when there is one
      assert html =~ ~s(<span class="dock-label">Ord</span>)
      assert html =~ ~s(<span class="dock-label">Customers</span>)
      assert html =~ ~r{id="bar-orders" class="dock-active" aria-current="page"}
      assert html =~ ~r{<button type="button" id="bar-more" aria-haspopup="dialog"}
      assert html =~ "&quot;to&quot;:&quot;#more-nav&quot;"
    end

    test "bar and more can be given, and the dock never holds more than four" do
      more = [%{label: "Phone", items: Enum.flat_map(@nav, & &1.items) |> Enum.drop(1)}]
      bar = Enum.flat_map(@nav, & &1.items)

      html = shell(%{more: more, bar: bar})

      assert Regex.scan(~r{id="bar-([\w-]+)"}, dock(html), capture: :all_but_first) ==
               [["home"], ["orders"], ["customers"], ["quotes"], ["more"]]

      sheet = more(html)
      assert sheet =~ ~s(<div class="app-shell-more-label">Phone</div>)
      refute sheet =~ ~s(href="/")
      assert sheet =~ ~s(href="/billing")
      # the sidebar still shows nav
      assert sidebar(html) =~ ~s(id="nav-home")
    end

    test "the More sheet lists the groups, the footer items and the account" do
      html = more(shell())

      assert html =~ ~s(class="drawer-bottom app-shell-more" aria-label="More")
      assert html =~ ~s(<div class="app-shell-more-label">Sales</div>)
      assert count(html, ~s(class="app-shell-sheet-row")) == 6 + 2
      assert html =~ ~r{href="/orders"[^>]*class="app-shell-sheet-row" aria-current="page"}
      assert html =~ "Pat Lee"
    end

    test "the phone header holds the slot, then search" do
      html = section(shell(), "phone-header", "search-open-phone")
      assert html =~ ~s(<span id="phone-title">Acme</span>)
    end
  end

  describe "app_shell/1 main" do
    test "#main holds the page; narrow by default, wide and fill on request" do
      html = shell()

      assert html =~ ~s(<main id="main" class="app-shell-main">)
      assert html =~ ~r{<div class="app-shell-page">\s*<p id="page-content">}

      assert shell(%{wide: true, fill: true}) =~
               ~s(<div class="app-shell-page" data-wide data-fill>)
    end

    test "renders no inline event handler" do
      refute shell() =~ ~r/\son[a-z]+=/
    end
  end

  describe "app_shell_heading/1" do
    test "a tile, title and subtitle; tip and chevron on request" do
      assigns = %{}

      plain =
        render(~H"""
        <.app_shell_heading icon="hero-cube" title="Acme" />
        """)

      trigger =
        render(~H"""
        <.app_shell_heading
          tabindex="0"
          role="button"
          icon="hero-cube"
          title="Acme"
          subtitle="Grandville"
          tip="Acme · Grandville"
          chevron
        />
        """)

      assert plain =~ ~r{<div class="app-shell-heading ?">}
      assert plain =~ ~s(<span class="app-shell-tile"><span class="hero-cube size-4")
      assert plain =~ ~s(<span class="app-shell-heading-title">Acme</span>)
      refute plain =~ "subtitle"
      refute plain =~ "chevron"

      assert trigger =~
               ~s(<div class="app-shell-heading tooltip tooltip-right" data-tip="Acme · Grandville" role="button" tabindex="0">)

      assert trigger =~ ~s(<span class="app-shell-heading-subtitle">Grandville</span>)
      assert trigger =~ "hero-chevron-up-down"
    end
  end

  describe "toggle_sidebar/1" do
    test "dispatches shadcn:toggle-sidebar" do
      assert toggle_sidebar() == JS.dispatch("shadcn:toggle-sidebar")
    end
  end

  describe "theme_toggle/1" do
    test "system, light and dark buttons dispatch phx:set-theme" do
      assigns = %{}

      html =
        render(~H"""
        <ShadcnDaisyui.Components.theme_toggle />
        """)

      branded =
        render(~H"""
        <ShadcnDaisyui.Components.theme_toggle light="acme" dark="acme-dark" />
        """)

      assert html =~ ~s(role="group" aria-label="Theme")
      assert html =~ ~s(<span class="theme-toggle-thumb" aria-hidden="true"></span>)

      for theme <- ~w(system shadcn shadcn-dark) do
        assert html =~ ~s(data-phx-theme="#{theme}")
      end

      assert count(html, "phx:set-theme") == 3
      assert branded =~ ~s(data-phx-theme="acme")
      assert branded =~ ~s(data-phx-theme="acme-dark")
    end
  end
end
