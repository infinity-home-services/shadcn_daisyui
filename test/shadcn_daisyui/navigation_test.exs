defmodule ShadcnDaisyui.Components.NavigationTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Navigation

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  describe "tabs/1" do
    test "renders one radio per tab sharing the id as name, plus tab content" do
      assigns = %{}

      html =
        render(~H"""
        <.tabs id="settings">
          <:tab label="Account" checked>Account settings…</:tab>
          <:tab label="Password">Password settings…</:tab>
        </.tabs>
        """)

      assert html =~ ~s(role="tablist")
      assert html =~ "tabs tabs-box"
      assert count(html, ~s(type="radio")) == 2
      assert count(html, ~s(name="settings")) == 2
      assert html =~ ~s(aria-label="Account")
      assert html =~ ~s(aria-label="Password")
      assert count(html, "tab-content") == 2
      assert html =~ "Account settings…"
      assert html =~ "Password settings…"
      assert count(html, "checked") == 1
    end

    test "content_class is applied to panels" do
      assigns = %{}

      html =
        render(~H"""
        <.tabs id="t" content_class="p-8">
          <:tab label="A">a</:tab>
        </.tabs>
        """)

      assert html =~ "tab-content p-8"
    end
  end

  describe "breadcrumb/1" do
    test "items with navigation render links, the rest render as current page" do
      assigns = %{}

      html =
        render(~H"""
        <.breadcrumb>
          <:item navigate="/">Home</:item>
          <:item href="/docs">Components</:item>
          <:item>Breadcrumb</:item>
        </.breadcrumb>
        """)

      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ "breadcrumbs"
      assert html =~ ~s(href="/")
      assert html =~ ~s(href="/docs")
      assert html =~ ~s(<span aria-current="page">)
      assert html =~ "Breadcrumb"
      assert count(html, "<a ") == 2
      assert count(html, ~s(aria-current="page")) == 1
    end
  end

  describe "pagination/1 in event mode" do
    test "renders buttons with phx-click and phx-value-page" do
      assigns = %{}
      html = render(~H|<.pagination page={2} total_pages={3} event="paginate" />|)

      assert html =~ ~s(aria-label="Pagination")
      assert count(html, ~s(phx-click="paginate")) == 5
      assert html =~ ~s(phx-value-page="1")
      assert html =~ ~s(phx-value-page="2")
      assert html =~ ~s(phx-value-page="3")
      assert html =~ "Previous"
      assert html =~ "Next"
    end

    test "previous is disabled on page 1" do
      assigns = %{}
      html = render(~H|<.pagination page={1} total_pages={3} event="paginate" />|)

      assert html =~ ~r/disabled[^>]*phx-value-page="0"/
      refute html =~ ~r/disabled[^>]*phx-value-page="4"/
    end

    test "next is disabled on the last page" do
      assigns = %{}
      html = render(~H|<.pagination page={3} total_pages={3} event="paginate" />|)

      assert html =~ ~r/disabled[^>]*phx-value-page="4"/
      refute html =~ ~r/disabled[^>]*phx-value-page="0"/
    end

    test "current page gets aria-current and the outline style" do
      assigns = %{}
      html = render(~H|<.pagination page={2} total_pages={3} event="paginate" />|)

      assert html =~ ~r/aria-current="page"[^>]*phx-value-page="2"/
      assert count(html, ~s(aria-current="page")) == 1
      assert html =~ "btn-outline"
    end
  end

  describe "pagination/1 window logic" do
    test "lists every page when total <= 7" do
      assigns = %{}
      html = render(~H|<.pagination page={1} total_pages={7} event="go" />|)

      for p <- 1..7 do
        assert html =~ ~s(phx-value-page="#{p}")
      end

      refute html =~ "…"
    end

    test "middle page produces gaps on both sides" do
      assigns = %{}
      html = render(~H|<.pagination page={5} total_pages={10} event="go" />|)

      assert count(html, "…") == 2

      for p <- [1, 4, 5, 6, 10] do
        assert html =~ ~s(phx-value-page="#{p}")
      end

      refute html =~ ~s(phx-value-page="3")
      refute html =~ ~s(phx-value-page="8")
    end

    test "page near the start produces a single trailing gap" do
      assigns = %{}
      html = render(~H|<.pagination page={2} total_pages={10} event="go" />|)

      assert count(html, "…") == 1

      for p <- [1, 2, 3, 10] do
        assert html =~ ~s(phx-value-page="#{p}")
      end
    end

    test "page near the end produces a single leading gap" do
      assigns = %{}
      html = render(~H|<.pagination page={9} total_pages={10} event="go" />|)

      assert count(html, "…") == 1

      for p <- [1, 8, 9, 10] do
        assert html =~ ~s(phx-value-page="#{p}")
      end
    end
  end

  describe "pagination/1 in path mode" do
    test "renders links built from the path function" do
      assigns = %{path: fn p -> "/items?page=#{p}" end}
      html = render(~H|<.pagination page={2} total_pages={3} path={@path} />|)

      assert html =~ ~s(href="/items?page=1")
      assert html =~ ~s(href="/items?page=3")
      assert html =~ ~s(aria-current="page")
      refute html =~ "phx-value-page"
    end

    test "disabled prev link gets btn-disabled and aria-disabled" do
      assigns = %{path: fn p -> "/items?page=#{p}" end}
      html = render(~H|<.pagination page={1} total_pages={3} path={@path} />|)

      assert html =~ "btn-disabled"
      assert html =~ ~s(aria-disabled="true")
    end
  end

  describe "sidebar_layout/1 and sidebar_group/1" do
    test "renders sidebar aside next to main content" do
      assigns = %{}

      html =
        render(~H"""
        <.sidebar_layout>
          <:sidebar>nav here</:sidebar>
          main content
        </.sidebar_layout>
        """)

      assert html =~ "<aside"
      assert html =~ "nav here"
      assert html =~ "<main"
      assert html =~ "main content"
      assert html =~ "w-56"
    end

    test "sidebar_group renders title and marks the active item" do
      assigns = %{}

      html =
        render(~H"""
        <.sidebar_group title="Platform">
          <:item navigate="/" active>Dashboard</:item>
          <:item navigate="/projects">Projects</:item>
        </.sidebar_group>
        """)

      assert html =~ ~s(class="menu-title")
      assert html =~ "Platform"
      assert html =~ ~s(href="/")
      assert html =~ ~s(href="/projects")
      assert html =~ "Dashboard"
      assert html =~ "Projects"
      assert count(html, "menu-active") == 1
    end

    test "sidebar_group without title renders no menu-title" do
      assigns = %{}

      html =
        render(~H"""
        <.sidebar_group>
          <:item href="/a">A</:item>
        </.sidebar_group>
        """)

      refute html =~ "menu-title"
    end
  end

  describe "tab_nav/1" do
    test "renders link tabs with the hook, active state and counts" do
      assigns = %{}

      html =
        render(~H"""
        <.tab_nav id="views" aria_label="Views">
          <:tab patch="/issues" active count={128}>All issues</:tab>
          <:tab patch="/issues?view=active">Active</:tab>
        </.tab_nav>
        """)

      assert html =~ ~s(<nav id="views")
      assert html =~ ~s(phx-hook="ShadcnTabNav")
      assert html =~ ~s(aria-label="Views")
      assert html =~ "tabs tabs-box tab-nav-list"
      assert count(html, "data-tab-nav-item") == 2
      assert html =~ ~s(href="/issues?view=active")
      assert html =~ ~s(data-phx-link="patch")
      assert count(html, ~s(aria-current="page")) == 2
      assert html =~ "tab tab-active"
      assert html =~ ~s(<span class="tab-count">128</span>)
    end

    test "renders a hidden copy of every tab in the More menu, keyed by index" do
      assigns = %{}

      html =
        render(~H"""
        <.tab_nav id="views">
          <:tab href="/a">A</:tab>
          <:tab href="/b">B</:tab>
          <:tab href="/c">C</:tab>
        </.tab_nav>
        """)

      assert count(html, "data-tab-nav-copy") == 3
      assert html =~ ~s(data-index="2")
      assert html =~ ~s(aria-controls="views-menu")
      assert html =~ ~s(id="views-menu")
      # no extra entries: the More slot starts hidden, the separator isn't rendered
      assert html =~ ~r/data-tab-nav-more\s+hidden/
      refute html =~ "data-tab-nav-sep"
      # the hook owns visibility; patches must not reset it
      assert html =~ "ignore_attrs"
    end

    test "menu items render grouped sections after a separator" do
      assigns = %{}

      html =
        render(~H"""
        <.tab_nav id="views">
          <:tab href="/a" active>A</:tab>
          <:menu_item group="Mine" href="/m1">Assigned to me</:menu_item>
          <:menu_item group="Mine" href="/m2">Created by me</:menu_item>
          <:menu_item group="Shared" href="/s1">Open bugs</:menu_item>
          <:menu_item href="/views" icon="hero-cog-6-tooth">Manage views…</:menu_item>
        </.tab_nav>
        """)

      assert html =~ "data-tab-nav-sep"
      assert count(html, "data-tab-nav-entry") == 4
      assert count(html, ~s(role="group")) == 3
      assert count(html, "command-group-label") == 2
      assert html =~ ~s(aria-labelledby="views-group-0")
      assert html =~ "hero-cog-6-tooth"
      # extra entries: More is always shown
      refute html =~ ~r/data-tab-nav-more\s+hidden/
      assert html =~ ">More<"
    end

    test "an active menu item names the More trigger" do
      assigns = %{}

      html =
        render(~H"""
        <.tab_nav id="views" more_label="Views">
          <:tab href="/a">A</:tab>
          <:menu_item href="/bugs" active>Open bugs</:menu_item>
        </.tab_nav>
        """)

      assert html =~ ~s(<span class="sr-only" data-tab-nav-default>Views: </span>)
      assert html =~ ~r/<span class="tab-nav-label" data-tab-nav-default>\s*Open bugs\s*<\/span>/
      assert html =~ "hero-check"
      assert count(html, "tab-active") == 1
      # no active tab: nothing for a collapsed trigger to name
      refute html =~ "data-tab-nav-current"
    end

    test "the trigger carries the active tab's name and count for the collapsed state" do
      assigns = %{}

      html =
        render(~H"""
        <.tab_nav id="queue" aria_label="Call queue">
          <:tab href="/all" count={240}>All calls</:tab>
          <:tab href="/needs-call" active count={17}>Needs a call</:tab>
          <:tab href="/closed">Closed</:tab>
        </.tab_nav>
        """)

      [trigger] = Regex.run(~r/<button[^>]*data-tab-nav-trigger.*?<\/button>/s, html)
      # More stays the default label; CSS swaps in the active tab when collapsed
      assert trigger =~ ~r/<span class="tab-nav-label" data-tab-nav-default>\s*More\s*<\/span>/

      assert trigger =~
               ~r/<span class="tab-nav-label" data-tab-nav-current>\s*Needs a call\s*<\/span>/

      assert trigger =~ ~r/<span class="tab-count" data-tab-nav-current>\s*17\s*<\/span>/
      # the label truncates, the count is a separate element that never does
      assert count(trigger, "data-tab-nav-current") == 2
      # the hook's collapsed flag survives patches
      assert html =~ "data-collapsed"

      # the active tab's menu copy is checked; the others aren't
      copies = Regex.scan(~r/<a[^>]*data-tab-nav-copy.*?<\/a>/s, html) |> List.flatten()
      assert length(copies) == 3
      assert [_] = Enum.filter(copies, &(&1 =~ "hero-check"))
      assert Enum.at(copies, 1) =~ "hero-check"
    end
  end
end
