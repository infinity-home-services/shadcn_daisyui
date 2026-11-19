defmodule ShadcnDaisyui.Components.CommandMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.CommandMenu

  alias Phoenix.LiveView.JS

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # the opening tag of the element with this id
  defp tag(html, id) do
    [tag] = Regex.run(~r{<[a-z]+ [^>]*\bid="#{id}"[^>]*>}, html)
    tag
  end

  defp menu(extra \\ %{}) do
    assigns = Map.merge(%{current: "loc-dal"}, extra)

    render(~H"""
    <.command_menu id="scope" label="Switch location" placeholder="Search locations">
      <:trigger>Acme</:trigger>
      <:item id="org" group="Company" icon="hero-building-office-2" patch="/?scope=org">
        All of Acme
      </:item>
      <:item id="brand-a" group="Brands" icon="hero-tag" description="2 locations" patch="/?s=a">
        Alpha
      </:item>
      <:item
        id="loc-dal"
        group="Brands"
        parent="brand-a"
        icon="hero-map-pin"
        keywords="DAL Texas"
        current={@current == "loc-dal"}
        form="scope-form"
        name="scope"
        value="dal"
      >
        Dallas
      </:item>
      <:item id="room-1" group="Brands" parent="loc-dal" phx-click="pick" values={%{id: 1}}>
        Room 1
      </:item>
      <:item id="off" group="Brands" disabled phx-click="nope">Closed</:item>
      <:item id="del" group="Danger" phx-click="remove" confirm="Remove it?">Remove</:item>
      <:empty>Nothing matches.</:empty>
    </.command_menu>
    """)
  end

  test "the root carries the hook, side and align; the trigger opens the panel" do
    html = menu()

    assert html =~
             ~r{<div id="scope" phx-hook="ShadcnCommandMenu" class="command-menu" data-command-menu data-side="bottom" data-align="start">}

    assert html =~
             ~r{<button type="button" id="scope-trigger" class="btn btn-outline w-64 justify-between font-normal" data-command-menu-trigger aria-haspopup="dialog" aria-expanded="false" aria-controls="scope-panel"}

    assert html =~ ">\n    Acme\n  </button>" or
             html =~ ~r{data-command-menu-trigger[^>]*>\s*Acme\s*</button>}
  end

  test "the panel is a labelled top-layer dialog with a combobox over a listbox" do
    html = menu()

    assert html =~
             ~r{<div id="scope-panel" popover="manual" role="dialog" aria-label="Switch location" tabindex="-1" class="command-menu-panel w-72" data-command-menu-panel}

    assert html =~
             ~r{<input id="scope-search" type="text" data-command-menu-search role="combobox" aria-expanded="true" aria-controls="scope-list" aria-autocomplete="list" aria-label="Search locations"}

    assert html =~
             ~s(<div id="scope-list" role="listbox" aria-label="Switch location" class="command-menu-list">)

    assert html =~
             ~r{<div id="scope-status" role="status" class="sr-only" data-command-menu-status}
  end

  test "groups share a heading and label their group" do
    html = menu()

    assert html =~ ~s(aria-labelledby="scope-group-0")
    assert html =~ ~s(<div id="scope-group-0" class="command-group-label">Company</div>)
    assert html =~ ~s(<div id="scope-group-1" class="command-group-label">Brands</div>)
    assert html =~ ~s(<div id="scope-group-2" class="command-group-label">Danger</div>)
    assert length(String.split(html, "data-command-menu-group")) - 1 == 3
  end

  test "rows: options with links, form submits and phx-click; nesting depth from parents" do
    html = menu()

    org = tag(html, "org")
    assert org =~ ~r{^<a href="/\?scope=org"}

    for attr <- [
          ~s(data-phx-link="patch"),
          ~s(role="option"),
          ~s(class="command-item command-menu-item"),
          ~s(aria-selected="false"),
          "data-command-menu-item",
          ~s(tabindex="-1")
        ] do
      assert org =~ attr
    end

    # a child of a child, two levels in
    assert html =~
             ~r{<button type="submit" id="loc-dal" form="scope-form" name="scope" value="dal" class="command-item command-menu-item" role="option" tabindex="-1" aria-selected="true" data-command-menu-item data-depth="1" data-parent="brand-a" data-keywords="DAL Texas" data-current>}

    assert html =~ ~r{id="room-1"[^>]*data-depth="2" data-parent="loc-dal"[^>]*phx-value-id="1"}
    assert html =~ ~r{id="room-1"[^>]*phx-click="pick"}
    refute html =~ ~r{id="brand-a"[^>]*data-depth}
  end

  test "current gets a check, description a second line, icon a heroicon" do
    html = menu()
    [_, dallas] = String.split(html, ~s(id="loc-dal"), parts: 2)
    [dallas, _] = String.split(dallas, "</button>", parts: 2)

    assert dallas =~ ~s(<span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>)
    assert dallas =~ ~s(<span class="hero-check command-menu-check" aria-hidden="true"></span>)
    assert html =~ ~s(<span class="command-item-description">2 locations</span>)
    assert length(String.split(html, "command-menu-check")) - 1 == 1

    refute menu(%{current: nil}) =~ "command-menu-check"
  end

  test "disabled rows are inert; confirm adds data-confirm" do
    html = menu()

    assert html =~ ~r{<button type="button" id="off"[^>]*aria-disabled="true"}
    refute html =~ ~s(phx-click="nope")
    assert html =~ ~r{id="del"[^>]*data-confirm="Remove it\?"}
  end

  test "the empty text is hidden until the hook shows it" do
    assert menu() =~
             ~r{<p data-command-menu-empty hidden class="command-menu-empty">\s*Nothing matches.\s*</p>}
  end

  test "trigger_id points at an element elsewhere instead of a trigger slot" do
    assigns = %{}

    html =
      render(~H"""
      <.command_menu id="m" label="Pick" trigger_id="heading" side="right" align="end" class="w-80">
        <:item>One</:item>
      </.command_menu>
      """)

    assert html =~ ~s(data-trigger="heading" data-side="right" data-align="end")
    refute html =~ "data-command-menu-trigger"
    assert html =~ ~s(class="command-menu-panel w-80")
    assert html =~ ~s(<p data-command-menu-empty hidden class="command-menu-empty">)
    assert html =~ "No results found."
    # rows without an id get one
    assert html =~ ~s(id="m-row-0-0")
  end

  test "needs a trigger" do
    assigns = %{}

    assert_raise ArgumentError, ~r/needs a <:trigger> or trigger_id/, fn ->
      render(~H"""
      <.command_menu id="m" label="Pick"><:item>One</:item></.command_menu>
      """)
    end
  end

  test "phx-target goes on clickable rows" do
    assigns = %{}

    html =
      render(~H"""
      <.command_menu id="m" label="Pick" phx-target="#comp">
        <:trigger>Open</:trigger>
        <:item id="a" phx-click={JS.push("x")}>A</:item>
        <:item id="b" navigate="/b">B</:item>
      </.command_menu>
      """)

    assert html =~ ~r{id="a"[^>]*phx-target="#comp"}
    refute html =~ ~r{id="b"[^>]*phx-target}
  end

  test "renders no inline event handler" do
    refute menu() =~ ~r/\son[a-z]+=/
  end
end
