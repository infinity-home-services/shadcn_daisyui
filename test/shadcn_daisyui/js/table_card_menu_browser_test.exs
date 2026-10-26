defmodule ShadcnDaisyui.JS.TableCardMenuBrowserTest do
  # <.table_card> with a ⋯ <.dropdown_menu> on every row, in headless Chrome
  # with the real theme CSS and JS (same harness as the other *_browser_test
  # files). The card must not clip: a row's menu, the last row's included,
  # and a menu in a short card's :actions open in full over the card's edge
  # and the card under it (every item can be clicked where it shows). The
  # rows at the card's corners round with it instead, so a row_class
  # background stays inside them. daisyUI's dropdown positioning (an
  # absolute panel under the trigger, shown while it has focus) stands in,
  # as the harness has no daisyUI.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Record, only: [table_card: 1]
  import ShadcnDaisyui.Components.Overlay, only: [dropdown_menu: 1]

  @chrome [
            System.get_env("CHROME"),
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/Applications/Chromium.app/Contents/MacOS/Chromium",
            System.find_executable("google-chrome"),
            System.find_executable("google-chrome-stable"),
            System.find_executable("chromium"),
            System.find_executable("chromium-browser")
          ]
          |> Enum.find(&(&1 && File.exists?(&1)))

  @node System.find_executable("node")

  @moduletag :browser
  if !(@chrome && @node), do: @moduletag(skip: "needs node and Chrome/Chromium (set CHROME)")

  @root Path.expand("../../..", __DIR__)
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui.css")
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui.js")

  # Tailwind's layer order and preflight bits, the classes the markup uses,
  # and daisyUI's dropdown positioning
  @base """
  @layer theme, base, components, utilities;
  *, ::before, ::after { box-sizing: border-box; margin: 0; padding: 0; } body { padding: 1.5rem; }
  ul { list-style: none; } .w-48 { width: 12rem; } .mt-2 { margin-top: 0.5rem; } .bg-muted { background-color: var(--muted); }
  .dropdown { position: relative; display: inline-block; }
  .dropdown-content { position: absolute; visibility: hidden; }
  .dropdown-end .dropdown-content { inset-inline-end: 0; }
  .dropdown:focus-within .dropdown-content { visibility: visible; }
  .menu { display: flex; flex-direction: column; }
  .menu li > a { display: block; padding: 0.375rem 0.5rem; }
  """

  @contacts [
    %{id: 1, name: "Pat Lee", role: "Billing"},
    %{id: 2, name: "Sam Ortiz", role: "Office"},
    %{id: 3, name: "Robin Park", role: "Owner"}
  ]

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp body do
    assigns = %{contacts: @contacts}

    render(~H"""
    <.table_card
      id="contacts"
      title="Contacts"
      rows={@contacts}
      row_id={&"contact-#{&1.id}"}
      row_class={&(&1.id == 3 && "bg-muted")}
      grid="grid-cols-[minmax(0,1fr)_6rem_2rem]"
    >
      <:col :let={c} label="Name">{c.name}</:col>
      <:col :let={c} label="Role">{c.role}</:col>
      <:col :let={c}>
        <.dropdown_menu
          id={"contact-#{c.id}-menu"}
          trigger_class="btn"
          chevron={false}
          aria-label={"Actions for #{c.name}"}
          align="end"
        >
          <:trigger>⋯</:trigger>
          <:item>Edit</:item>
          <:item>Make primary</:item>
          <:item variant="destructive">Remove</:item>
        </.dropdown_menu>
      </:col>
    </.table_card>
    <div id="below-contacts" class="card" style="height: 20rem">Below</div>
    <.table_card id="files" title="Files" rows={[]}>
      <:actions>
        <.dropdown_menu id="files-menu" align="end" chevron={false} aria-label="File actions">
          <:trigger>Add</:trigger>
          <:item>Upload</:item>
          <:item>From a link</:item>
          <:item>From another order</:item>
        </.dropdown_menu>
      </:actions>
      <:col :let={f}>{f}</:col>
      <:empty>No files yet.</:empty>
    </.table_card>
    <div id="below-files" class="card" style="height: 20rem">Below</div>
    <.table_card id="bare" rows={[%{t: "First"}, %{t: "Last"}]} row_class={fn _ -> "bg-muted" end}>
      <:col :let={r}>{r.t}</:col>
    </.table_card>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{@base}#{css}</style></head>
    <body>
    #{body()}
    <script type="module">
    #{js}
    const $ = (id) => document.getElementById(id)
    const frame = () => new Promise((r) => requestAnimationFrame(() => r()))
    // open a menu (focus its trigger) and read where it shows against its card
    const open = async (menuId, cardId) => {
      const menu = $(menuId)
      menu.querySelector("[role=button]").focus()
      await frame()
      const panel = menu.querySelector("ul").getBoundingClientRect()
      const card = $(cardId).getBoundingClientRect()
      // each item can be clicked in the middle of where it shows: not cut off
      // at the card's edge, and above the card after it
      const hit = [...menu.querySelectorAll("li > a")].map((a) => {
        const r = a.getBoundingClientRect()
        const el = document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2)
        return a === el || a.contains(el)
      })
      menu.querySelector("[role=button]").blur()
      await frame()
      return { past_edge: Math.round(panel.bottom - card.bottom), hit }
    }
    const corners = (el) => {
      const cs = getComputedStyle(el)
      return [cs.borderStartStartRadius, cs.borderStartEndRadius, cs.borderEndStartRadius, cs.borderEndEndRadius]
    }
    const r = {
      overflow: ["contacts", "files", "bare"].map((id) => getComputedStyle($(id)).overflow),
      card_radius: getComputedStyle($("contacts")).borderEndStartRadius,
    }
    r.first = await open("contact-1-menu", "contacts")
    r.last = await open("contact-3-menu", "contacts")
    r.actions = await open("files-menu", "files")
    // the last row (row_class bg-muted) rounds its bottom corners; with no
    // header, the first row its top ones; middle rows stay square
    r.last_row = corners($("contact-3"))
    r.middle_row = corners($("contact-2"))
    const bare = $("bare").querySelectorAll("[role=row]")
    r.bare_first = corners(bare[0])
    r.bare_last = corners(bare[bare.length - 1])
    r.files_empty = corners($("files").querySelector(".table-card-empty"))
    window.__result = JSON.stringify(r)
    </script>
    </body>
    </html>
    """

    dir = Path.join(System.tmp_dir!(), "sd-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    file = Path.join(dir, "page.html")
    File.write!(file, page)

    script = Path.join(@root, "test/support/chrome_eval.mjs")
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  test "row menus and an :actions menu open in full over the card's edge; the corner rows round" do
    r = run_in_chrome()
    msg = inspect(r, pretty: true)

    # nothing clips
    assert r["overflow"] == ["visible", "visible", "visible"], msg

    # the last row's menu (and the short card's :actions menu) reaches past
    # the card's bottom edge, and every item shows and takes the click
    assert r["last"]["past_edge"] > 0, msg
    assert r["actions"]["past_edge"] > 0, msg

    for menu <- ~w(first last actions) do
      assert Enum.all?(r[menu]["hit"]), "#{menu}: #{msg}"
    end

    # rows at the corners round with the card (its radius less the 1px border)
    {radius, "px"} = Float.parse(r["card_radius"])
    inner = "#{trunc(radius - 1)}px"

    assert r["last_row"] == ["0px", "0px", inner, inner], msg
    assert r["middle_row"] == ["0px", "0px", "0px", "0px"], msg
    assert r["bare_first"] == [inner, inner, "0px", "0px"], msg
    assert r["bare_last"] == ["0px", "0px", inner, inner], msg
    assert r["files_empty"] == ["0px", "0px", inner, inner], msg
  end
end
