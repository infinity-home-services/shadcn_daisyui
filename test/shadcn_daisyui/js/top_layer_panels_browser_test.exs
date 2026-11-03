defmodule ShadcnDaisyui.JS.TopLayerPanelsBrowserTest do
  # The panels that open from a row - <.chip_row>'s "+N" and <.tab_nav>'s
  # More menu - in headless Chrome with the real theme CSS and JS (same
  # harness as the other *_browser_test files; a few lines stand in for the
  # bits of daisyUI's .table and .tab the layout needs). They open in the top
  # layer (popover="manual"), so an ancestor that clips doesn't cut them off:
  # a chip row in a <.data_table> cell (cells clip, the body scrolls) and a
  # tab nav in an overflow-hidden box show their whole panel. The +N panel
  # stays in the row's DOM: a click in it never opens the row, removing a
  # chip from it works, the keyboard moves into it and Esc closes it. It
  # follows its trigger as the table body or the page scrolls and the window
  # resizes, closes once the trigger is under the sticky header, stays open
  # through a patch, and opens above the trigger near the window's bottom.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.DataTable, only: [data_table: 1]
  import ShadcnDaisyui.Components.Display, only: [chip_row: 1]
  import ShadcnDaisyui.Components.Navigation, only: [tab_nav: 1]

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

  @base """
  @layer base {
    *, ::before, ::after { box-sizing: border-box; } body { margin: 0; padding: 24px; font: 14px/20px sans-serif; }
    button { font: inherit; background: none; border: 0; padding: 0; }
    [hidden] { display: none !important; }
    .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
    .table { width: 100%; border-collapse: collapse; }
    .table :where(th, td) { padding: 0.75rem 1rem; vertical-align: middle; }
    .w-40 { width: 10rem; } .w-56 { width: 14rem; }
    .tabs { display: flex; padding: 3px; } .tab { display: inline-flex; align-items: center; height: 2rem; padding-inline: 0.75rem; }
    .frame { display: flex; flex-direction: column; height: 400px; width: 760px; }
  }
  """

  @brands ~w(Acme Northwind Globex Initech Umbrella Hooli Vandelay Soylent)

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp brands(assigns) do
    ~H"""
    <.chip_row id={@id} aria_label="Brands">
      <:chip :for={b <- @brands} value={b}>{b}</:chip>
    </.chip_row>
    """
  end

  defp body do
    assigns = %{
      people: for(i <- 1..30, do: %{id: i, name: "Person #{i}"}),
      brands: @brands
    }

    render(~H"""
    <div class="frame" id="frame">
      <.data_table id="people" rows={@people}>
        <:col :let={p} label="Name" class="w-40">{p.name}</:col>
        <:col :let={p} label="Brands" class="w-56">
          <.brands id={"brands-#{p.id}"} brands={@brands} />
        </:col>
        <:col :let={p} label="Email">person{p.id}@example.com</:col>
      </.data_table>
    </div>
    <div id="clip" style="width: 320px; height: 48px; margin-top: 16px; overflow: hidden">
      <.tab_nav id="views" aria-label="Views">
        <:tab :for={n <- 1..8} navigate={"/views/#{n}"} active={n == 1}>View {n}</:tab>
      </.tab_nav>
    </div>
    <div style="position: fixed; bottom: 16px; left: 820px; width: 200px">
      <.brands id="low" brands={@brands} />
    </div>
    <div style="position: fixed; top: 24px; right: 16px; width: 200px">
      <.brands id="edge" brands={@brands} />
    </div>
    <div style="height: 1600px"></div>
    """)
  end

  setup_all do
    %{r: run_in_chrome()}
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css} #{@base}</style></head>
    <body>
    #{body()}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const $ = (id) => document.getElementById(id)
    // the table's pushes, answered at once; the chip rows' and the tab nav's hooks
    const pushed = []
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook]")) {
      const name = el.getAttribute("phx-hook")
      const hook = Object.assign(Object.create(Hooks[name]), {
        el,
        pushEvent: (event, payload) => { pushed.push(event); return Promise.resolve({}) },
      })
      hook.mounted()
      hooks[el.id] = hook
    }
    const opens = () => pushed.filter((e) => e === "dt:open").length
    const click = (el, detail = 1) => el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, detail }))
    const key = (el, k) => el.dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true }))
    const box = (el) => { const r = el.getBoundingClientRect(); return { left: r.left, right: r.right, top: r.top, bottom: r.bottom } }
    const trigger = (id) => $(id).querySelector("[data-chip-row-trigger]")
    const more = (id) => $(id).querySelector("[data-chip-row-more]")
    const panel = (id) => $(id).querySelector("[data-chip-row-panel]")
    const isOpen = (p) => p.matches(":popover-open") && !p.hidden
    // the whole panel is on screen and on top: inside the window, and every
    // corner and every chip in it takes a click where it shows
    const shows = (p, items) => {
      const r = p.getBoundingClientRect()
      const vw = document.documentElement.clientWidth
      const vh = document.documentElement.clientHeight
      const at = (x, y) => { const el = document.elementFromPoint(x, y); return !!el && p.contains(el) }
      // (6px in: the rounded corners let the page show through at their tips)
      const corners = [[r.left + 6, r.top + 6], [r.right - 6, r.top + 6], [r.left + 6, r.bottom - 6], [r.right - 6, r.bottom - 6]]
      return {
        inWindow: r.left >= 0 && r.top >= 0 && r.right <= vw && r.bottom <= vh,
        corners: corners.every(([x, y]) => at(x, y)),
        items: items.length > 0 && items.every((el) => { const b = el.getBoundingClientRect(); return at((b.left + b.right) / 2, (b.top + b.bottom) / 2) }),
      }
    }
    const copies = (id) => [...panel(id).querySelectorAll("[data-chip-copy]")].filter((c) => !c.hidden)
    const r = {}
    try {
    await document.fonts.ready
    await frames()
    const scroller = $("people").querySelector("[data-dt-scroll]")

    // +N in a table cell: the whole panel shows, past the cell's edges
    const p2 = panel("brands-2")
    const cell = $("brands-2").closest("td")
    click(trigger("brands-2"))
    await frames()
    r.cell = {
      open: isOpen(p2),
      expanded: trigger("brands-2").getAttribute("aria-expanded"),
      inRow: $("people").contains(p2),
      pastCell: Math.round(p2.getBoundingClientRect().bottom - cell.getBoundingClientRect().bottom),
      cellClips: getComputedStyle(cell).overflow,
      ...shows(p2, copies("brands-2")),
      // under +N, start-aligned, the panel's gap below
      gap: Math.round(p2.getBoundingClientRect().top - more("brands-2").getBoundingClientRect().bottom),
      startDelta: Math.round(p2.getBoundingClientRect().left - more("brands-2").getBoundingClientRect().left),
      count: trigger("brands-2").dataset.count,
      copies: copies("brands-2").length,
      cursor: getComputedStyle(p2).cursor,
    }

    // a click in the panel (its padding, a chip's label) doesn't open the row
    click(p2)
    click(copies("brands-2")[0].querySelector(".chip-label"))
    r.clickIn = { opens: opens(), open: isOpen(p2) }
    // a press on its text or padding focuses the panel (the nearest focusable
    // element; a dispatched click moves no focus, so focus it as the press
    // would), not the row - that would close it before the click lands
    trigger("brands-2").focus()
    p2.focus()
    const keptByFocus = isOpen(p2) && document.activeElement === p2
    $("brands-2").closest("tr").focus()
    r.pressFocus = { tabIndex: p2.tabIndex, keptByFocus, closedByRow: !isOpen(p2) }
    // a click on the row itself still does
    click($("people").querySelector("[data-dt-row] td"))
    r.rowClick = { opens: opens() }
    click(trigger("brands-2"))
    await frames()

    // removing a chip from the panel: it goes, the panel stays open, no row opens
    const before = copies("brands-2").length
    const first = copies("brands-2")[0].dataset.value
    const removed = []
    $("brands-2").addEventListener("chip-remove", (e) => removed.push(e.detail.value))
    click(copies("brands-2")[0].querySelector("[data-chip-remove]"))
    await sleep(250)
    r.remove = { removed, first, before, after: copies("brands-2").length, open: isOpen(p2), opens: opens() }

    // a patch keeps it open, where it was
    const placed = box(p2)
    hooks["brands-2"].beforeUpdate()
    hooks["brands-2"].updated()
    await frames()
    r.patch = { open: isOpen(p2), same: JSON.stringify(box(p2)) === JSON.stringify(placed) }

    // the table body scrolls: the panel goes with +N
    scroller.scrollTop = 40
    await frames()
    r.bodyScroll = {
      open: isOpen(p2),
      gap: Math.round(p2.getBoundingClientRect().top - more("brands-2").getBoundingClientRect().bottom),
      moved: Math.round(placed.top - p2.getBoundingClientRect().top),
    }

    // the page scrolls: the same
    window.scrollTo(0, 30)
    await frames()
    r.pageScroll = {
      open: isOpen(p2),
      gap: Math.round(p2.getBoundingClientRect().top - more("brands-2").getBoundingClientRect().bottom),
    }
    window.scrollTo(0, 0)
    await frames()

    // the window resizes (the table moves with the layout): the same
    $("frame").style.marginLeft = "40px"
    window.dispatchEvent(new Event("resize"))
    await frames()
    r.resize = {
      open: isOpen(p2),
      startDelta: Math.round(p2.getBoundingClientRect().left - more("brands-2").getBoundingClientRect().left),
    }
    $("frame").style.marginLeft = ""
    window.dispatchEvent(new Event("resize"))
    await frames()

    // +N goes under the sticky header (still inside the scroll region): it closes
    // (the header cells are what's sticky; the thead's own box scrolls away)
    const head = $("people").querySelector("thead th").getBoundingClientRect()
    const t = trigger("brands-2").getBoundingClientRect()
    scroller.scrollTop += (t.top + t.bottom) / 2 - (head.top + head.bottom) / 2
    await frames()
    const under = trigger("brands-2").getBoundingClientRect()
    r.underHeader = {
      open: isOpen(p2),
      hidden: p2.hidden,
      expanded: trigger("brands-2").getAttribute("aria-expanded"),
      insideScroller: under.top >= scroller.getBoundingClientRect().top,
      underHead: under.bottom <= $("people").querySelector("thead th").getBoundingClientRect().bottom,
    }
    scroller.scrollTop = 0
    await frames()

    // the keyboard: Enter on +N moves into the panel, Esc closes it and
    // gives focus back; scrolling it out of view with focus inside does too
    const p4 = panel("brands-4")
    trigger("brands-4").focus()
    click(trigger("brands-4"), 0)
    await frames()
    const focusIn = p4.contains(document.activeElement)
    key(document.activeElement, "ArrowRight")
    const moved = p4.contains(document.activeElement)
    key(document.activeElement, "Escape")
    await frames()
    r.keyboard = { focusIn, moved, closed: !isOpen(p4), back: document.activeElement === trigger("brands-4") }
    click(trigger("brands-4"), 0)
    await frames()
    scroller.scrollTop = 600
    await frames()
    r.scrolledAway = { closed: !isOpen(p4), back: document.activeElement === trigger("brands-4"), scroll: scroller.scrollTop }
    scroller.scrollTop = 0
    await frames()

    // a click outside closes it
    click(trigger("brands-3"))
    await frames()
    const wasOpen = isOpen(panel("brands-3"))
    click(document.body)
    r.outside = { wasOpen, closed: !isOpen(panel("brands-3")) }

    // near the window's bottom it opens above +N; near its right edge it
    // lines up with +N's end
    click(trigger("low"))
    await frames()
    r.low = {
      open: isOpen(panel("low")),
      above: Math.round(more("low").getBoundingClientRect().top - panel("low").getBoundingClientRect().bottom),
      ...shows(panel("low"), copies("low")),
    }
    click(trigger("edge"))
    await frames()
    r.edge = {
      open: isOpen(panel("edge")),
      closedOther: !isOpen(panel("low")),
      align: panel("edge").getAttribute("data-align"),
      endDelta: Math.round(more("edge").getBoundingClientRect().right - panel("edge").getBoundingClientRect().right),
      ...shows(panel("edge"), copies("edge")),
    }
    click(document.body)

    // a tab nav in an overflow-hidden box: its More menu shows in full
    const menu = $("views").querySelector("[data-tab-nav-menu]")
    const moreBtn = $("views").querySelector("[data-tab-nav-trigger]")
    click(moreBtn)
    await frames()
    const links = [...menu.querySelectorAll("a")].filter((a) => !a.closest("[hidden]"))
    r.tabNav = {
      open: isOpen(menu),
      links: links.length,
      pastBox: Math.round(menu.getBoundingClientRect().bottom - $("clip").getBoundingClientRect().bottom),
      // end-aligned under More
      endDelta: Math.round($("views").querySelector("[data-tab-nav-more]").getBoundingClientRect().right - menu.getBoundingClientRect().right),
      ...shows(menu, links),
    }
    click(document.body)
    r.tabNav.closed = !isOpen(menu)
    } catch (e) { errors.push(String(e) + " " + (e.stack || "")) }
    window.__result = JSON.stringify({ errors, r })
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

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn ->
        System.cmd(@node, [script, @chrome, file, Path.join(dir, "profile")])
      end)

    result = JSON.decode!(out)
    assert result["errors"] == []
    result["r"]
  end

  test "+N in a data table cell opens in the top layer and the whole panel shows", %{r: r} do
    c = r["cell"]
    msg = inspect(c, pretty: true)
    assert c["open"] and c["expanded"] == "true", msg
    # still in the row's DOM, the cell clips, and the panel reaches past it
    assert c["inRow"], msg
    assert c["cellClips"] == "hidden", msg
    assert c["pastCell"] > 0, msg
    # every corner and chip of it is on screen and takes a click
    assert c["inWindow"] and c["corners"] and c["items"], msg
    # under +N, start-aligned, 4px apart (0.25rem), as before
    assert c["gap"] == 4, msg
    assert c["startDelta"] == 0, msg
    assert c["copies"] > 1 and c["count"] == "+#{c["copies"]}", msg
    assert c["cursor"] == "default", msg
  end

  test "a click in the panel never opens the row; removing a chip from it works", %{r: r} do
    assert r["clickIn"] == %{"opens" => 0, "open" => true}
    assert r["pressFocus"] == %{"tabIndex" => -1, "keptByFocus" => true, "closedByRow" => true}
    assert r["rowClick"] == %{"opens" => 1}

    rm = r["remove"]
    assert rm["removed"] == [rm["first"]], inspect(rm)
    assert rm["after"] == rm["before"] - 1, inspect(rm)
    assert rm["open"], inspect(rm)
    assert rm["opens"] == 1, inspect(rm)
  end

  test "it follows +N through a patch, scrolling and resizing, and closes when +N is hidden",
       %{r: r} do
    assert r["patch"] == %{"open" => true, "same" => true}
    assert r["bodyScroll"] == %{"open" => true, "gap" => 4, "moved" => 40}
    assert r["pageScroll"] == %{"open" => true, "gap" => 4}
    assert r["resize"] == %{"open" => true, "startDelta" => 0}
    # under the sticky header (inside the scroll region, but covered)
    assert r["underHeader"] == %{
             "open" => false,
             "hidden" => true,
             "expanded" => "false",
             "insideScroller" => true,
             "underHead" => true
           }

    # scrolled away with focus inside: closed, focus back on +N
    assert r["scrolledAway"]["closed"] and r["scrolledAway"]["back"], inspect(r["scrolledAway"])
    assert r["scrolledAway"]["scroll"] == 600
  end

  test "the keyboard moves into it, Esc and a click outside close it", %{r: r} do
    assert r["keyboard"] == %{
             "focusIn" => true,
             "moved" => true,
             "closed" => true,
             "back" => true
           }

    assert r["outside"] == %{"wasOpen" => true, "closed" => true}
  end

  test "near the window's bottom it opens above +N; near its right edge it ends with +N",
       %{r: r} do
    low = r["low"]
    assert low["open"] and low["above"] == 4, inspect(low)
    assert low["inWindow"] and low["corners"] and low["items"], inspect(low)

    edge = r["edge"]
    assert edge["open"] and edge["closedOther"], inspect(edge)
    assert edge["align"] == "end" and edge["endDelta"] == 0, inspect(edge)
    assert edge["inWindow"] and edge["corners"] and edge["items"], inspect(edge)
  end

  test "a tab nav's More menu in an overflow-hidden box shows in full", %{r: r} do
    t = r["tabNav"]
    msg = inspect(t, pretty: true)
    assert t["open"] and t["links"] > 0, msg
    assert t["pastBox"] > 0, msg
    assert t["endDelta"] == 0, msg
    assert t["inWindow"] and t["corners"] and t["items"], msg
    assert t["closed"], msg
  end
end
