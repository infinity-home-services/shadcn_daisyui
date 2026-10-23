defmodule ShadcnDaisyui.Components.OverlayTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Overlay

  alias Phoenix.LiveView.JS

  defp render(template) do
    template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, substring) do
    html |> String.split(substring) |> length() |> Kernel.-(1)
  end

  describe "dialog/1" do
    test "renders a native dialog with the modal class" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="confirm">
          <:title>Are you absolutely sure?</:title>
          <:description>This action cannot be undone.</:description>
          body
          <:actions><button>Delete</button></:actions>
        </.dialog>
        """)

      assert html =~ ~s(<dialog id="confirm" class="modal)
      assert html =~ "Are you absolutely sure?"
      assert html =~ "This action cannot be undone."
      assert html =~ "body"
      assert html =~ "modal-action"
      assert html =~ "Delete"
      assert html =~ "modal-backdrop"
    end

    test "trigger slot opens the dialog with a JS dispatch, not an inline handler" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="confirm">
          <:trigger><button>Open</button></:trigger>
          content
        </.dialog>
        """)

      assert html =~ "phx-click="
      assert html =~ "shadcn:show-modal"
      refute html =~ "sheet-lg"
      assert html =~ "#confirm"
      assert html =~ "Open"
      refute html =~ "showModal"
    end

    test "without trigger no trigger span is rendered" do
      assigns = %{}
      html = render(~H|<.dialog id="d">content</.dialog>|)

      refute html =~ "shadcn:show-modal"
      refute html =~ "<span"
    end

    test "the dialog keeps its browser-owned open attribute across patches" do
      assigns = %{}
      html = render(~H|<.dialog id="d">content</.dialog>|)

      assert html =~ "phx-mounted="
      assert html =~ "ignore_attrs"
      assert html =~ "open"
    end

    test "omits title, description, and actions when slots are absent" do
      assigns = %{}
      html = render(~H|<.dialog id="d">content</.dialog>|)

      refute html =~ "<h3"
      refute html =~ "modal-action"
    end
  end

  describe "sheet/1" do
    test "size adds a width class; default adds none" do
      for {size, class} <- [{"sm", "sheet-sm"}, {"lg", "sheet-lg"}, {"xl", "sheet-xl"}] do
        assigns = %{size: size}

        html =
          render(~H"""
          <.sheet id="s" size={@size} class="extra">body</.sheet>
          """)

        assert html =~ ~s(class="sheet #{class} extra")
      end

      assigns = %{}

      html =
        render(~H"""
        <.sheet id="s" class="sm:w-96">body</.sheet>
        """)

      assert html =~ ~s(class="sheet sm:w-96")
    end

    test "renders a dialog with the sheet class and a close button" do
      assigns = %{}

      html =
        render(~H"""
        <.sheet id="edit-profile">
          <:trigger><button>Open sheet</button></:trigger>
          <:title>Edit profile</:title>
          <:description>Make changes here.</:description>
          form goes here
        </.sheet>
        """)

      assert html =~ ~s(id="edit-profile")
      assert html =~ ~s(class="sheet )
      assert html =~ "Edit profile"
      assert html =~ "Make changes here."
      assert html =~ "form goes here"
      assert html =~ ~s(aria-label="Close")
      assert html =~ "hero-x-mark"
      assert html =~ "shadcn:show-modal"
      assert html =~ "shadcn:hide-modal"
    end

    test "header, scrolling body and footer sections" do
      assigns = %{}

      html =
        render(~H"""
        <.sheet id="filters">
          <:title>Filters</:title>
          <:description>Narrow the list.</:description>
          <:header><input id="filter-search" /></:header>
          body rows
          <:footer><button>Clear all</button><button class="ml-auto">Show 24 results</button></:footer>
        </.sheet>
        """)

      assert html =~
               ~r/class="sheet-header">.*aria-label="Close".*Filters.*Narrow the list\..*filter-search.*<\/div>\s*<\/div>\s*<div class="sheet-body">\s*<div>\s*body rows\s*<\/div>\s*<\/div>\s*<div class="sheet-footer">.*Clear all.*Show 24 results/s

      # the scroll-edge state the JS sets survives LiveView patches
      assert html =~ "data-scroll-top"
      assert html =~ "data-scroll-bottom"
    end

    test "no footer or header slot renders no footer / header content" do
      assigns = %{}
      html = render(~H|<.sheet id="s">body</.sheet>|)
      assert html =~ ~s(class="sheet-body")
      refute html =~ "sheet-footer"
      refute html =~ "sheet-header-content"
    end
  end

  describe "drawer/1" do
    test "renders a dialog with the drawer-bottom class and grab handle" do
      assigns = %{}

      html =
        render(~H"""
        <.drawer id="goal">
          <:trigger><button>Open drawer</button></:trigger>
          drawer content
        </.drawer>
        """)

      assert html =~ ~s(id="goal")
      assert html =~ ~s(class="drawer-bottom )
      assert html =~ "drawer content"
      assert html =~ ~s(class="drawer-handle")
      assert html =~ ~s(class="drawer-body")
      refute html =~ "drawer-header"
      refute html =~ "drawer-footer"
    end

    test "header, scrolling body and footer sections" do
      assigns = %{}

      html =
        render(~H"""
        <.drawer id="goal">
          <:title>Move goal</:title>
          <:description>Set your daily activity goal.</:description>
          content
          <:footer><button>Submit</button></:footer>
        </.drawer>
        """)

      assert html =~
               ~r/class="drawer-header">.*Move goal.*Set your daily.*<div class="drawer-body">.*content.*<div class="drawer-footer">.*Submit/s

      assert html =~ "data-scroll-bottom"
    end
  end

  describe "popover/1" do
    test "renders a daisyUI dropdown with trigger and panel" do
      assigns = %{}

      html =
        render(~H"""
        <.popover>
          <:trigger>Open popover</:trigger>
          Dimensions
        </.popover>
        """)

      assert html =~ ~s(class="dropdown")
      assert html =~ ~s(role="button")
      assert html =~ "btn btn-outline"
      assert html =~ "Open popover"
      assert html =~ "dropdown-content"
      assert html =~ "Dimensions"
    end

    test "trigger_class overrides the trigger styling" do
      assigns = %{}

      html =
        render(~H"""
        <.popover trigger_class="btn btn-ghost">
          <:trigger>T</:trigger>
          c
        </.popover>
        """)

      assert html =~ "btn btn-ghost"
    end
  end

  describe "tooltip/1" do
    test "default top position has no position suffix class" do
      assigns = %{}
      html = render(~H|<.tooltip tip="Add to library">Hover me</.tooltip>|)

      assert html =~ ~s(class="tooltip ")
      assert html =~ ~s(data-tip="Add to library")
      refute html =~ "tooltip-bottom"
      refute html =~ "tooltip-left"
      refute html =~ "tooltip-right"
      refute html =~ "tooltip-top"
    end

    test "bottom, left, and right positions add suffix classes" do
      for pos <- ~w(bottom left right) do
        assigns = %{pos: pos}
        html = render(~H|<.tooltip tip="t" position={@pos}>x</.tooltip>|)
        assert html =~ "tooltip tooltip-#{pos}"
      end
    end
  end

  describe "dropdown_menu/1" do
    test "renders trigger, label, and items" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu>
          <:trigger>Open menu</:trigger>
          <:label>My Account</:label>
          <:item phx-click="logout" class="text-destructive">Log out</:item>
          <:item>Profile</:item>
        </.dropdown_menu>
        """)

      assert html =~ "Open menu"
      assert html =~ "hero-chevron-down"
      assert html =~ ~s(class="menu-title")
      assert html =~ "My Account"
      assert html =~ ~s(phx-click="logout")
      assert html =~ "text-destructive"
      assert html =~ "Log out"
      assert html =~ "Profile"
      assert html =~ "dropdown-content menu"
    end

    test "the menu sits on the floating layer (z-50)" do
      assigns = %{}

      html =
        render(~H|<.dropdown_menu><:trigger>Open</:trigger><:item>A</:item></.dropdown_menu>|)

      assert html =~ "dropdown-content menu z-50"
      refute html =~ "z-10"
    end

    test "chevron={false} + aria-label for an icon-only trigger" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu trigger_class="btn btn-ghost btn-square" chevron={false} aria-label="More actions">
          <:trigger><span class="hero-ellipsis-horizontal size-4"></span></:trigger>
          <:item>Edit</:item>
        </.dropdown_menu>
        """)

      refute html =~ "hero-chevron-down"

      assert html =~
               ~r/role="button"[^>]*aria-label="More actions"|aria-label="More actions"[^>]*role="button"/

      assert html =~ "btn btn-ghost btn-square"
    end

    test "align end adds dropdown-end" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu align="end">
          <:trigger>T</:trigger>
          <:item>I</:item>
        </.dropdown_menu>
        """)

      assert html =~ "dropdown dropdown-end"
    end

    test "no label slot renders no menu-title" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu>
          <:trigger>T</:trigger>
          <:item>I</:item>
        </.dropdown_menu>
        """)

      refute html =~ "menu-title"
    end

    # Other apps depend on this exact output: an item that uses none of the
    # opt-in attributes (confirm, values, id, variant, disabled) and a menu
    # without close_on_select render byte-for-byte as before 0.16.0.
    test "today's usage renders unchanged" do
      assigns = %{id: 7}

      html =
        render(~H"""
        <.dropdown_menu
          trigger_class="btn btn-ghost btn-square btn-sm"
          chevron={false}
          aria-label="More actions"
          align="end"
          class="w-40"
          data-row="r"
        >
          <:trigger><span class="hero-ellipsis-horizontal size-4"></span></:trigger>
          <:label>Actions</:label>
          <:item>Plain</:item>
          <:item phx-click="edit" phx-value-id={@id}>Edit</:item>
          <:item phx-click="delete" phx-value-id={@id} class="text-destructive">Delete</:item>
        </.dropdown_menu>
        """)

      assert html == """
             <div class="dropdown dropdown-end" data-row="r">
               <div tabindex="0" role="button" class="btn btn-ghost btn-square btn-sm" aria-label="More actions">
                 <span class="hero-ellipsis-horizontal size-4"></span>
                 \n  </div>
               <ul tabindex="0" class="dropdown-content menu z-50 mt-2 w-40">
                 <li class="menu-title">Actions</li>
                 <li>
                   <a class="">
                     Plain
                   </a>
                 </li><li>
                   <a class="" phx-click="edit" phx-value-id="7">
                     Edit
                   </a>
                 </li><li>
                   <a class="text-destructive" phx-click="delete" phx-value-id="7">
                     Delete
                   </a>
                 </li>
               </ul>
             </div>\
             """
    end

    defp item_tag(html, text) do
      [tag] = Regex.run(~r/<a\b[^>]*>\s*#{text}\s*<\/a>/, html)
      tag
    end

    test "confirm renders data-confirm" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu>
          <:trigger>T</:trigger>
          <:item phx-click="remove" confirm="Remove Acme Marketing from Pat?">Remove</:item>
        </.dropdown_menu>
        """)

      assert item_tag(html, "Remove") =~ ~s(data-confirm="Remove Acme Marketing from Pat?")
      assert item_tag(html, "Remove") =~ ~s(phx-click="remove")
    end

    test "values renders one phx-value per key; values wins for its own keys only" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu>
          <:trigger>T</:trigger>
          <:item phx-click="a" phx-value-id="1" values={%{user_id: 2, team: "x"}}>A</:item>
          <:item phx-click="b" phx-value-id="1" values={%{"id" => 9, user_id: 3}}>B</:item>
        </.dropdown_menu>
        """)

      a = item_tag(html, "A")
      assert a =~ ~s(phx-value-id="1")
      assert a =~ ~s(phx-value-user_id="2")
      assert a =~ ~s(phx-value-team="x")

      b = item_tag(html, "B")
      assert b =~ ~s(phx-value-id="9")
      refute b =~ ~s(phx-value-id="1")
      assert count(b, "phx-value-id=") == 1
      assert b =~ ~s(phx-value-user_id="3")
    end

    test "id renders on the item" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu><:trigger>T</:trigger><:item id="row-1-edit">Edit</:item></.dropdown_menu>
        """)

      assert item_tag(html, "Edit") =~ ~s(id="row-1-edit")
    end

    test "variant destructive adds text-destructive and the data-variant hook" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu>
          <:trigger>T</:trigger>
          <:item variant="destructive" class="font-medium">Remove</:item>
        </.dropdown_menu>
        """)

      tag = item_tag(html, "Remove")
      assert tag =~ ~s(class="text-destructive font-medium")
      assert tag =~ ~s(data-variant="destructive")
    end

    test "disabled: aria-disabled, no phx-click, no data-confirm" do
      assigns = %{}

      html =
        render(~H"""
        <.dropdown_menu>
          <:trigger>T</:trigger>
          <:item phx-click="remove" confirm="Remove X?" variant="destructive" disabled>Remove</:item>
        </.dropdown_menu>
        """)

      tag = item_tag(html, "Remove")
      assert tag =~ ~s(aria-disabled="true")
      refute tag =~ "phx-click"
      refute tag =~ "data-confirm"
      assert tag =~ "text-destructive"
    end

    test "close_on_select marks the menu; off by default" do
      assigns = %{}

      on =
        render(
          ~H|<.dropdown_menu close_on_select><:trigger>T</:trigger><:item>I</:item></.dropdown_menu>|
        )

      off = render(~H|<.dropdown_menu><:trigger>T</:trigger><:item>I</:item></.dropdown_menu>|)

      assert on =~ ~r/<div class="dropdown ?" data-close-on-select>/
      refute off =~ "data-close-on-select"
    end
  end

  describe "command/1" do
    test "renders trigger button, search input, and the command hook" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="commands">
          <:trigger_label>Search commands…</:trigger_label>
          <:item>Calendar</:item>
        </.command>
        """)

      assert html =~ "Search commands…"
      assert html =~ "⌘K"
      assert html =~ ~s(id="commands")
      assert html =~ ~s(phx-hook="ShadcnCommand")
      assert html =~ "data-command-search"
      assert html =~ "data-command-list"
      assert html =~ "data-command-empty"
      assert html =~ ~s(placeholder="Type a command or search…")
    end

    test "groups consecutive items by their group attribute" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="cmd">
          <:item group="Suggestions" icon="hero-calendar">Calendar</:item>
          <:item group="Suggestions">Calculator</:item>
          <:item group="Settings" shortcut="⌘P">Profile</:item>
        </.command>
        """)

      # two distinct consecutive groups -> two group labels
      assert count(html, "command-group-label") == 2
      assert html =~ "Suggestions"
      assert html =~ "Settings"
      assert count(html, "data-command-item") == 3
      assert html =~ "hero-calendar"
      assert html =~ "⌘P"
    end

    test "items without a group render no group label" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="cmd">
          <:item>One</:item>
          <:item>Two</:item>
        </.command>
        """)

      refute html =~ "command-group-label"
      assert count(html, "data-command-item") == 2
    end

    test "items navigate, link, submit a form or run phx-click" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="search" label="Search" placeholder="Search pages">
          <:item id="page" group="Pages" icon="hero-home" navigate="/home">Home</:item>
          <:item id="patched" group="Pages" patch="/home?tab=2">Tab two</:item>
          <:item id="brand" group="Brands" href="/context/brand?brand=acme">Acme</:item>
          <:item id="loc" group="Locations" form="loc-form" name="location" value="all">
            All locations
          </:item>
          <:item id="act" phx-click="refresh">Refresh</:item>
        </.command>
        """)

      assert html =~ ~s(aria-label="Search")
      assert html =~ ~s(id="search-search")
      assert html =~ ~s(id="search-list")

      assert html =~
               ~r{<a href="/home" data-phx-link="redirect" data-phx-link-state="push" id="page" class="command-item" data-command-item>}

      assert html =~ ~r{<a href="/home\?tab=2" data-phx-link="patch"[^>]* id="patched"}

      assert html =~
               ~r{<a href="/context/brand\?brand=acme" id="brand" class="command-item" data-command-item>}

      assert html =~
               ~s(<button type="submit" id="loc" form="loc-form" name="location" value="all" class="command-item" data-command-item>)

      assert html =~
               ~r{<button type="button" id="act" class="command-item" data-command-item phx-click="refresh">}

      assert count(html, "data-command-item") == 5
      assert count(html, "command-group-label") == 3
    end

    test "opens with Cmd/Ctrl+K by default" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="cmd">
          <:trigger_label>Search…</:trigger_label>
          <:item>One</:item>
        </.command>
        """)

      assert html =~ ~s(data-shortcut="k")
      assert html =~ ~s(<kbd class="kbd">⌘K</kbd>)
    end

    test "shortcut picks another letter, and nil means none" do
      assigns = %{}

      other =
        render(~H"""
        <.command id="cmd" shortcut="j">
          <:trigger_label>Jump…</:trigger_label>
          <:item>One</:item>
        </.command>
        """)

      none =
        render(~H"""
        <.command id="cmd" shortcut={nil}>
          <:trigger_label>Switch…</:trigger_label>
          <:item>One</:item>
        </.command>
        """)

      assert other =~ ~s(data-shortcut="j")
      assert other =~ "⌘J"
      # an empty data-shortcut tells the hook "no key" (no attribute = ⌘K, for raw HTML)
      assert none =~ ~s(data-shortcut="")
      refute none =~ "kbd"

      empty =
        render(~H"""
        <.command id="cmd" shortcut="">
          <:trigger_label>Switch…</:trigger_label>
          <:item>One</:item>
        </.command>
        """)

      assert empty =~ ~s(data-shortcut="")
      refute empty =~ "kbd"
    end
  end

  describe "command/1 without on_search" do
    # v0.20.0's markup, rendered from the same template before server search
    # existed (test/fixtures/command_v0.20.0.html). Only blank lines may differ.
    test "renders exactly what v0.20.0 rendered" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="cmd" label="Search" placeholder="Search pages">
          <:trigger_label>Search…</:trigger_label>
          <:item id="page" group="Pages" icon="hero-home" navigate="/home" shortcut="⌘H">Home</:item>
          <:item id="patched" group="Pages" patch="/home?tab=2">Tab two</:item>
          <:item id="brand" group="Brands" href="/context/brand?brand=acme">Acme</:item>
          <:item id="loc" group="Locations" form="loc-form" name="location" value="all">All locations</:item>
          <:item id="act" phx-click="refresh">Refresh</:item>
          <:item>Plain</:item>
        </.command>
        <.command id="switch" shortcut={nil}><:item>One</:item></.command>
        """)

      baseline = File.read!(Path.expand("../fixtures/command_v0.20.0.html", __DIR__))
      assert squash(html) == squash(baseline)
    end

    test "renders none of the server search parts" do
      assigns = %{}

      html = render(~H|<.command id="cmd"><:item>One</:item></.command>|)

      for part <- ~w(data-on-search data-search-debounce data-query data-command-spinner
                     data-command-hint data-command-status phx-target aria-busy) do
        refute html =~ part
      end
    end

    test "icon sets the search row's heroicon, and nil drops it" do
      assigns = %{}

      default = render(~H|<.command id="a"><:item>One</:item></.command>|)
      custom = render(~H|<.command id="b" icon="hero-user-plus"><:item>One</:item></.command>|)
      mini = render(~H|<.command id="c" icon="hero-funnel-mini"><:item>One</:item></.command>|)
      none = render(~H|<.command id="d" icon={nil}><:item>One</:item></.command>|)

      assert default =~
               ~s(<span class="hero-magnifying-glass size-4 opacity-50" aria-hidden="true">)

      assert custom =~ ~s(<span class="hero-user-plus size-4 opacity-50" aria-hidden="true">)
      refute custom =~ "hero-magnifying-glass"
      assert mini =~ ~s(<span class="hero-funnel-mini size-4 opacity-50" aria-hidden="true">)
      refute none =~ ~r/<span class="[^"]*size-4 opacity-50"/
      assert none =~ ~s(<input id="d-search")
    end

    test "an <:empty> slot replaces the default text" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="cmd">
          <:empty>Nothing here.</:empty>
          <:item>One</:item>
        </.command>
        """)

      assert html =~ ~r{<p data-command-empty[^>]*>\s*Nothing here.\s*</p>}
      refute html =~ "No results found."
    end
  end

  describe "command/1 with on_search" do
    test "marks the dialog with the event, the debounce and the answered text" do
      html =
        render(search_palette(%{query: "pat", results: [], extra: [search_debounce: 400]}))

      assert html =~
               ~r{<dialog id="people" [^>]*data-on-search="search" data-search-debounce="400" data-query="pat"}
    end

    test "debounces 250ms by default; no data-query before the first answer" do
      html = render(search_palette(%{query: nil, results: [], extra: []}))

      assert html =~ ~s(data-search-debounce="250")
      refute html =~ "data-query"
    end

    test "an empty answer still echoes the text" do
      html = render(search_palette(%{query: "", results: [], extra: []}))

      assert html =~ ~s(data-query="")
    end

    test "renders the hint, a hidden spinner, the empty text and a polite status region" do
      html = render(search_palette(%{query: "zz", results: [], extra: []}))

      assert html =~
               ~r{<span data-command-spinner class="loading loading-spinner loading-xs hidden[^"]*" aria-hidden="true">}

      assert html =~ ~r{<p data-command-hint[^>]*>\s*Type a name or email.\s*</p>}

      assert html =~
               ~r{<p data-command-empty class="hidden[^>]*>\s*No one matches "zz".\s*</p>}

      # LiveView leaves the region's text (set by the hook) alone
      assert html =~
               ~s(<div id="people-status" data-command-status role="status" class="sr-only" phx-update="ignore">)
    end

    test "no hint slot, no hint element; no empty slot, the default text" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="p" on_search="search" query={nil}><:item :for={_ <- []}>x</:item></.command>
        """)

      refute html =~ "data-command-hint"
      assert html =~ "No results found."
    end

    test "renders the server's items with a description and phx-value-*" do
      results = [%{id: "7", name: "Pat Rivera", email: "pat@example.test"}]
      html = render(search_palette(%{query: "pat", results: results, extra: []}))

      assert html =~
               ~s(<button type="button" id="person-7" class="command-item" data-command-item phx-click="add" phx-value-id="7">)

      assert html =~
               ~r{<span class="command-item-text">\s*<span class="command-item-title">\s*Pat Rivera\s*</span>\s*<span class="command-item-description">pat@example.test</span>}
    end

    test "phx-target goes on the dialog and on items that run phx-click" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="p" on_search="search" query="a" phx-target="#owner">
          <:item id="add" phx-click="add">Add</:item>
          <:item id="open" navigate="/people/1">Open</:item>
        </.command>
        """)

      assert html =~ ~r{<dialog id="p" [^>]*phx-target="#owner"}
      assert html =~ ~r{<button type="button" id="add" [^>]*phx-click="add" phx-target="#owner"}
      assert html =~ ~r{<a href="/people/1"[^>]*id="open"}
      refute html =~ ~r{id="open"[^>]*phx-target}
    end

    test "needs query" do
      assigns = %{}

      assert_raise ArgumentError, ~r/needs query=/, fn ->
        render(~H|<.command id="p" on_search="search"><:item>x</:item></.command>|)
      end
    end

    test "has no inline event handlers and keeps `open` across patches" do
      html = render(search_palette(%{query: "pat", results: [], extra: []}))

      assert Regex.scan(~r/<[^>]*\son[a-z]+\s*=/i, html) == []
      assert count(html, "ignore_attrs") == 1
    end
  end

  describe "command/1 item attributes" do
    test "confirm renders data-confirm" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="p">
          <:item id="back" phx-click="add" confirm="Add Pat back? They start with no roles.">
            Add back
          </:item>
        </.command>
        """)

      assert html =~
               ~s(<button type="button" id="back" class="command-item" data-command-item phx-click="add" data-confirm="Add Pat back? They start with no roles.">)
    end

    test "disabled: aria-disabled, no click, no confirm, and a link becomes an inert button" do
      assigns = %{}

      html =
        render(~H"""
        <.command id="p" phx-target="#owner">
          <:item id="a" phx-click="add" values={%{id: 1}} confirm="Sure?" disabled>Add</:item>
          <:item id="b" navigate="/people/1" disabled>Open</:item>
          <:item id="c" form="f" name="n" value="v" disabled>Submit</:item>
        </.command>
        """)

      for id <- ~w(a b c) do
        assert html =~
                 ~s(<button type="button" id="#{id}" class="command-item" data-command-item aria-disabled="true">)
      end

      for gone <- ~w(phx-click data-confirm phx-value-id phx-target href= type="submit") do
        refute html =~ gone
      end
    end

    test "an item without them renders as before" do
      assigns = %{}

      html = render(~H|<.command id="p"><:item id="x" phx-click="go">Go</:item></.command>|)

      assert html =~
               ~s(<button type="button" id="x" class="command-item" data-command-item phx-click="go">)

      refute html =~ "command-item-text"
    end
  end

  # a server search palette, as an app renders one
  defp search_palette(assigns) do
    ~H"""
    <.command
      id="people"
      placeholder="Name or email"
      shortcut={nil}
      on_search="search"
      query={@query}
      {@extra}
    >
      <:hint>Type a name or email.</:hint>
      <:empty>No one matches "{@query}".</:empty>
      <:item
        :for={p <- @results}
        id={"person-#{p.id}"}
        description={p.email}
        phx-click="add"
        values={%{id: p.id}}
      >
        {p.name}
      </:item>
    </.command>
    """
  end

  # whitespace runs collapse, and none between tags
  defp squash(html) do
    html |> String.replace(~r/\s+/, " ") |> String.replace(~r/>\s+</, "><") |> String.trim()
  end

  describe "toast host" do
    # toasts move into the topmost open modal (outside it they'd be inert);
    # each package dialog gives them a slot LiveView patches leave alone
    test "every modal renders an ignored [data-toast-host] slot" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="dlg">body</.dialog>
        <.sheet id="sht">body</.sheet>
        <.drawer id="drw">body</.drawer>
        <.command id="cmd"><:item>One</:item></.command>
        """)

      for id <- ~w(dlg sht drw cmd) do
        assert html =~ ~s(<div id="#{id}-toasts" data-toast-host phx-update="ignore"></div>)
      end
    end
  end

  describe "strict CSP" do
    # every overlay, fully slotted; none may emit an inline event handler
    # (onclick=, onsubmit=, …) - those are blocked by `script-src 'self' 'nonce-…'`
    test "no overlay component renders an inline event handler" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="dlg">
          <:trigger><button>Open</button></:trigger>
          <:title>T</:title>
          <:description>D</:description>
          body
          <:actions><button>OK</button></:actions>
        </.dialog>
        <.sheet id="sht">
          <:trigger><button>Open</button></:trigger>
          <:title>T</:title>
          <:description>D</:description>
          body
        </.sheet>
        <.drawer id="drw">
          <:trigger><button>Open</button></:trigger>
          body
        </.drawer>
        <.popover><:trigger>P</:trigger>body</.popover>
        <.tooltip tip="t">x</.tooltip>
        <.dropdown_menu close_on_select>
          <:trigger>M</:trigger><:label>L</:label><:item>I</:item>
          <:item confirm="Remove X?" variant="destructive" values={%{a: 1}}>R</:item>
        </.dropdown_menu>
        <.command id="cmd">
          <:trigger_label>Search</:trigger_label>
          <:item group="G" icon="hero-calendar" shortcut="⌘P">Calendar</:item>
        </.command>
        """)

      assert Regex.scan(~r/<[^>]*\son[a-z]+\s*=/i, html) == []
      refute html =~ "javascript:"
      # every modal dialog keeps `open` across LiveView patches
      assert count(html, "<dialog") == 4
      assert count(html, "ignore_attrs") == 4
    end
  end

  describe "show_modal/2 and hide_modal/2" do
    test "show_modal returns a JS dispatch of shadcn:show-modal targeted at the id" do
      assert %JS{ops: [["dispatch", %{event: "shadcn:show-modal", to: "#confirm"}]]} =
               show_modal("confirm")
    end

    test "hide_modal returns a JS dispatch of shadcn:hide-modal targeted at the id" do
      assert %JS{ops: [["dispatch", %{event: "shadcn:hide-modal", to: "#confirm"}]]} =
               hide_modal("confirm")
    end

    test "composes with an existing JS command" do
      js = JS.push("track") |> show_modal("x")

      assert %JS{ops: [["push", _], ["dispatch", %{event: "shadcn:show-modal", to: "#x"}]]} = js
    end

    test "encoded ops contain the event name and target selector" do
      encoded = inspect(show_modal("x").ops)

      assert encoded =~ "shadcn:show-modal"
      assert encoded =~ "#x"

      encoded = inspect(hide_modal("y").ops)

      assert encoded =~ "shadcn:hide-modal"
      assert encoded =~ "#y"
    end
  end

  describe "opening from the server" do
    test "push_show_modal and push_hide_modal push shadcn:show-modal / hide-modal with the id" do
      socket = %Phoenix.LiveView.Socket{}

      assert %{assigns: %{__changed__: _}} = socket = push_show_modal(socket, "discard")
      assert [["shadcn:show-modal", %{id: "discard"}]] = socket.private.live_temp.push_events

      socket = push_hide_modal(socket, "discard")

      assert ["shadcn:hide-modal", %{id: "discard"}] in socket.private.live_temp.push_events
      assert length(socket.private.live_temp.push_events) == 2
    end

    test "show renders data-show and opens on mount; off renders neither" do
      assigns = %{}

      html = render(~H|<.dialog id="d" show>Hi</.dialog>|)
      assert html =~ ~r/<dialog[^>]* data-show[ >]/
      assert html =~ "shadcn:show-modal"

      html = render(~H|<.dialog id="d" show={false}>Hi</.dialog>|)
      refute html =~ "data-show"
      refute html =~ "shadcn:show-modal"
    end

    test "every modal takes show" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="a" show>x</.dialog>
        <.sheet id="b" show>x</.sheet>
        <.drawer id="c" show>x</.drawer>
        <.command id="d" show><:item>x</:item></.command>
        """)

      assert count(html, " data-show") == 4
      assert count(html, "shadcn:show-modal") == 4
      # the open attribute is still kept across patches
      assert count(html, "ignore_attrs") == 4
    end

    test "on_close renders a hidden button that runs the event or JS" do
      assigns = %{}

      html = render(~H|<.dialog id="d" on_close="keep_editing">Hi</.dialog>|)

      assert html =~
               ~s(<button type="button" hidden tabindex="-1" aria-hidden="true" data-on-close phx-click="keep_editing">)

      html =
        render(~H|<.sheet id="s" on_close={JS.push("closed", target: "#owner")}>Hi</.sheet>|)

      assert html =~ "data-on-close"
      assert html =~ "&quot;closed&quot;"
      assert html =~ "#owner"
    end

    test "without on_close there is no close action" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="a">x</.dialog>
        <.sheet id="b">x</.sheet>
        <.drawer id="c">x</.drawer>
        <.command id="d"><:item>x</:item></.command>
        """)

      refute html =~ "data-on-close"
      refute html =~ "data-show"
    end
  end
end
