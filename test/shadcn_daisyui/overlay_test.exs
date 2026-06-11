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

    test "trigger slot wires an onclick that calls showModal" do
      assigns = %{}

      html =
        render(~H"""
        <.dialog id="confirm">
          <:trigger><button>Open</button></:trigger>
          content
        </.dialog>
        """)

      assert html =~ "showModal"
      assert html =~ "getElementById"
      assert html =~ "confirm"
      assert html =~ "Open"
    end

    test "without trigger no onclick span is rendered" do
      assigns = %{}
      html = render(~H|<.dialog id="d">content</.dialog>|)

      refute html =~ "showModal"
      refute html =~ "<span"
    end

    test "omits title, description, and actions when slots are absent" do
      assigns = %{}
      html = render(~H|<.dialog id="d">content</.dialog>|)

      refute html =~ "<h3"
      refute html =~ "modal-action"
    end
  end

  describe "sheet/1" do
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
      assert html =~ "showModal"
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
      assert html =~ "rounded-full bg-base-300"
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
