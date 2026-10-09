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
      assert html =~ "rounded-full bg-muted"
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
        <.dropdown_menu><:trigger>M</:trigger><:label>L</:label><:item>I</:item></.dropdown_menu>
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
end
