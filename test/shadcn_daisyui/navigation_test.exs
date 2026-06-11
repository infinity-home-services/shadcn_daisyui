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
end
