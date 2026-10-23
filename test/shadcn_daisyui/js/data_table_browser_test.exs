defmodule ShadcnDaisyui.JS.DataTableBrowserTest do
  # <.data_table> in headless Chrome with the real theme CSS and JS (same
  # harness as the other *_browser_test files; no Tailwind or daisyUI, so a
  # few lines stand in for the bits of daisyUI's .table the layout needs). A
  # mock hook records what the table pushes and hands back a promise the page
  # resolves as "the server's reply"; "the server" answers by patching in the
  # parts a re-render changes (rendered by the component) and calling
  # updated(). Phone-width layout is checked in an iframe (its own viewport).
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.DataTable, only: [data_table: 1]

  alias ShadcnDaisyui.DataTable.State

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

  # the bits of Tailwind's preflight and daisyUI's .table the layout depends on
  # (in a layer before the theme's, as Tailwind orders them, so the theme wins)
  @base """
  @layer base {
    *, ::before, ::after { box-sizing: border-box; } body { margin: 0; font: 14px/20px sans-serif; }
    button { font: inherit; background: none; border: 0; padding: 0; }
    .table { width: 100%; border-collapse: collapse; }
    .table :where(th, td) { padding: 0.75rem 1rem; vertical-align: middle; }
    .hidden { display: none; } .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; }
    .frame { display: flex; flex-direction: column; height: 400px; width: 900px; }
  }
  """

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp rows(n), do: for(i <- 1..n, do: %{id: i, number: "#{1000 + i}", customer: "Customer #{i}"})

  defp table(opts) do
    assigns = %{
      id: opts[:id] || "orders",
      rows: opts[:rows] || rows(30),
      state: opts[:state] || %State{},
      more: opts[:more] || false,
      matching: opts[:matching],
      all_matching: opts[:all_matching] || false,
      active_id: opts[:active_id],
      scroll_key: opts[:scroll_key],
      edge: opts[:edge] || false
    }

    render(~H"""
    <.data_table
      id={@id}
      rows={@rows}
      state={@state}
      selectable
      more={@more}
      matching={@matching}
      all_matching={@all_matching}
      active_id={@active_id}
      scroll_key={@scroll_key}
      edge={@edge}
      row_href={&"/orders/#{&1.id}"}
      noun={{"order", "orders"}}
    >
      <:col :let={o} label="Order" sort="number" class="w-32">
        <a href={"/orders/#{o.id}"} class="order-link">#{o.number}</a>
      </:col>
      <:col :let={o} label="Customer" sort="customer">
        {o.customer} <span data-row-ignore class="ignored">menu</span>
      </:col>
      <:col label="Status" hide_below="md" class="w-32">Paid</:col>
      <:col :let={o} label="Total" sort="total" class="w-32">${o.id}.00</:col>
      <:bulk><button type="button" class="btn btn-sm" id={"export-" <> @id}>Export</button></:bulk>
    </.data_table>
    """)
  end

  defp selected(ids), do: %State{selected: MapSet.new(Enum.map(ids, &to_string/1))}

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    templates = %{
      "two" => table(state: selected([2, 3]), scroll_key: "orders"),
      "all30" => table(state: selected(1..30), matching: 240, scroll_key: "orders"),
      "allmatch" =>
        table(state: selected(1..30), matching: 240, all_matching: true, scroll_key: "orders"),
      "none" => table(state: %State{}, scroll_key: "orders"),
      "one" => table(state: selected([5]), scroll_key: "orders"),
      "active" => table(state: selected([5]), active_id: 28, scroll_key: "orders"),
      "sorted" => table(state: %State{sort: "number", dir: :desc}, scroll_key: "orders"),
      "more-same" => table(id: "paged", rows: rows(3), more: true),
      "more-done" => table(id: "paged", rows: rows(6), more: false)
    }

    tpl =
      Enum.map_join(templates, "\n", fn {k, v} -> ~s(<template id="tpl-#{k}">#{v}</template>) end)

    phone =
      ~s(<!doctype html><html data-theme="shadcn"><head><meta charset="utf-8"><style>#{@base}#{css}</style></head><body style="padding: 0 16px">) <>
        table(id: "phone", rows: rows(4), state: selected([1]), edge: true) <> "</body></html>"

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{@base}#{css}</style></head>
    <body>
    <script>sessionStorage.setItem("data-table:scroll:orders", "300")</script>
    <div class="frame" id="frame-main">#{table(state: selected([2, 3]), scroll_key: "orders")}</div>
    <div class="frame" id="frame-paged" style="height: 600px">#{table(id: "paged", rows: rows(3), more: true)}</div>
    <div id="dead-wrap">#{table(id: "dead", rows: rows(3))}</div>
    <div id="dead-more-wrap" class="frame" style="height: 500px">#{table(id: "dead-more", rows: rows(2), more: true)}</div>
    <iframe id="phone" style="width: 375px; height: 500px; border: 0"></iframe>
    #{tpl}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const $ = (id) => document.getElementById(id)
    const opened = []
    window.open = (url, target) => { opened.push([url, target]) }
    // a click on a row's link must not navigate this page away
    window.addEventListener("click", (e) => { if (e.target instanceof Element && e.target.closest("a[href]")) e.preventDefault() })

    // a dead view first: no hook, so pushes are DOM events
    const domEvents = []
    document.addEventListener("shadcn:data-table", (e) => domEvents.push(e.detail))
    initShadcnDaisyui($("dead-wrap"))
    initShadcnDaisyui($("dead-more-wrap"))

    // the mock hook: each push resolves when the page says "the server replied"
    const pushed = []
    const replies = []
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook=ShadcnDataTable]")) {
      if (el.id === "dead" || el.id === "dead-more" || el.id === "phone") continue
      const hook = Object.assign(Object.create(Hooks.ShadcnDataTable), {
        el,
        pushEvent: (event, payload) => {
          pushed.push({ event, payload })
          return new Promise((resolve) => replies.push(resolve))
        },
        pushEventTo: (target, event, payload) => {
          pushed.push({ target, event, payload })
          return new Promise((resolve) => replies.push(resolve))
        },
      })
      hook.mounted()
      hooks[el.id] = hook
    }
    const reply = () => { while (replies.length) replies.shift()({}) }
    // what a LiveView patch does to the table: the server's head, body, bulk
    // bar and more row, and the root's attributes; then updated()
    const patch = (id, tpl) => {
      const src = $("tpl-" + tpl).content.firstElementChild
      const root = $(id)
      for (const a of [...root.attributes]) if (!src.hasAttribute(a.name)) root.removeAttribute(a.name)
      for (const a of [...src.attributes]) root.setAttribute(a.name, a.value)
      for (const sel of ["thead", "tbody", "[data-dt-bulk]", "[data-dt-more]"]) {
        const from = src.querySelector(sel)
        const to = root.querySelector(sel)
        if (from && to) to.replaceWith(from.cloneNode(true))
        else if (from) root.querySelector("[data-dt-scroll]").appendChild(from.cloneNode(true))
        else if (to) to.remove()
      }
      hooks[id].updated()
    }
    const head = (id) => { const c = $(id).querySelector("[data-dt-select-all]"); return { checked: c.checked, indeterminate: c.indeterminate } }
    const box = (id, rowId) => $(id + "-row-" + rowId + "-check")
    const row = (id, rowId) => $(id + "-row-" + rowId)
    const click = (el, init = {}) => el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, ...init }))
    const events = (name, table = "orders") => pushed.filter((p) => p.event === name && p.payload.table === table).map((p) => p.payload)
    const r = {}
    try {
    await frames()

    // scroll position restored from sessionStorage on mount
    r.restored = $("orders").querySelector("[data-dt-scroll]").scrollTop

    // the header checkbox follows the rows from the start: 2 of 30, half-ticked
    r.head_initial = head("orders")
    r.bulk_initial = { hidden: $("orders").querySelector("[data-dt-bulk]").hidden, text: $("orders").querySelector(".data-table-bulk-count").textContent.trim() }

    // ticking a row pushes dt:select; the header follows at once
    click(box("orders", 7))
    r.select = { pushed: events("dt:select"), checked: box("orders", 7).checked, head: head("orders") }
    // a re-render that doesn't have that tick yet (another event's) doesn't undo it
    patch("orders", "two")
    r.pending = { checked: box("orders", 7).checked }
    // the server's answer: row 7 isn't ticked after all (say, not allowed) - it follows
    reply()
    await sleep(0)
    r.after_reply = { checked: box("orders", 7).checked, head: head("orders") }

    // the header follows the rows after every update
    patch("orders", "all30"); r.head_all = head("orders")
    patch("orders", "none"); r.head_none = head("orders")
    patch("orders", "one"); r.head_one = head("orders")

    // the bulk bar appears without moving the rows
    patch("orders", "none")
    $("orders").querySelector("[data-dt-scroll]").scrollTop = 0
    const before = row("orders", 1).getBoundingClientRect().top
    const headRect = $("orders").querySelector("thead").getBoundingClientRect()
    patch("orders", "one")
    const bar = $("orders").querySelector("[data-dt-bulk]")
    const barRect = bar.getBoundingClientRect()
    const label = $("orders").querySelectorAll("thead th")[1].getBoundingClientRect()
    const checkCell = $("orders").querySelector("thead .data-table-check").getBoundingClientRect()
    r.bulk = {
      hidden: bar.hidden,
      moved: row("orders", 1).getBoundingClientRect().top - before,
      bar_top: barRect.top - headRect.top,
      bar_height: barRect.height - headRect.height,
      covers_labels: bar.contains(document.elementFromPoint(label.left + 20, label.top + label.height / 2)),
      header_checkbox_free: document.elementFromPoint(checkCell.left + checkCell.width / 2 + 4, checkCell.top + checkCell.height / 2) ===
        $("orders").querySelector("[data-dt-select-all]"),
      text: bar.querySelector(".data-table-bulk-count").textContent.trim(),
      export: !!$("export-orders"),
      offer: !!bar.querySelector("[data-dt-select-matching]"),
    }
    patch("orders", "all30")
    r.bulk_all = {
      text: $("orders").querySelector(".data-table-bulk-count").textContent.trim(),
      offer: ($("orders").querySelector("[data-dt-select-matching]") || {}).textContent?.trim() || null,
    }
    patch("orders", "allmatch")
    r.bulk_allmatch = {
      text: $("orders").querySelector(".data-table-bulk-count").textContent.trim(),
      offer: !!$("orders").querySelector("[data-dt-select-matching]"),
    }
    patch("orders", "none")
    r.bulk_gone = { hidden: $("orders").querySelector("[data-dt-bulk]").hidden, moved: row("orders", 1).getBoundingClientRect().top - before }

    // Shift-click ticks a range and doesn't select text
    pushed.length = 0
    const down = new MouseEvent("mousedown", { bubbles: true, cancelable: true, shiftKey: true })
    box("orders", 9).dispatchEvent(down)
    click(box("orders", 9), { shiftKey: true })
    r.shift = { pushed: events("dt:select"), prevented: down.defaultPrevented }
    // a click in the checkbox cell, beside the box, ticks it too
    pushed.length = 0
    click(box("orders", 11).closest("td"))
    r.cell = { pushed: events("dt:select"), checked: box("orders", 11).checked, opened: events("dt:open").length }
    reply()
    await sleep(0)

    // rows open: a click, but not on a link, an ignored part, or with text selected
    pushed.length = 0
    click(row("orders", 4).querySelectorAll("td")[2])
    click(row("orders", 4).querySelector(".order-link"))
    click(row("orders", 4).querySelector(".ignored"))
    const sel = window.getSelection()
    sel.selectAllChildren(row("orders", 6).querySelectorAll("td")[2])
    click(row("orders", 6).querySelectorAll("td")[2])
    sel.removeAllRanges()
    r.open = events("dt:open")
    // Cmd/Ctrl-click and middle click open the record in a new tab
    click(row("orders", 8).querySelectorAll("td")[2], { metaKey: true })
    click(row("orders", 8).querySelectorAll("td")[2], { ctrlKey: true })
    row("orders", 8).querySelectorAll("td")[2].dispatchEvent(new MouseEvent("auxclick", { bubbles: true, cancelable: true, button: 1 }))
    r.new_tab = { opened: [...opened], open_events: events("dt:open").length }

    // keyboard: Enter opens, Down moves to the next row, Space ticks
    pushed.length = 0
    const key = (el, k, init = {}) => el.dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true, ...init }))
    row("orders", 3).focus()
    key(row("orders", 3), "Enter")
    key(row("orders", 3), "ArrowDown")
    const focused = document.activeElement.id
    key(document.activeElement, " ")
    r.keys = { open: events("dt:open"), focused, select: events("dt:select") }
    reply()
    await sleep(0)

    // sorting: aria-sort, and the arrow beside the label, outside its layout
    const th = $("orders").querySelectorAll("thead th")
    const sortBtn = th[1].querySelector(".data-table-sort")
    const iconL = sortBtn.querySelector(".data-table-sort-icon").getBoundingClientRect()
    const labelL = sortBtn.querySelector(".data-table-sort-label").getBoundingClientRect()
    const totalBtn = th[4].querySelector(".data-table-sort")
    const iconR = totalBtn.querySelector(".data-table-sort-icon").getBoundingClientRect()
    const labelR = totalBtn.querySelector(".data-table-sort-label").getBoundingClientRect()
    const cellR = row("orders", 1).querySelectorAll("td")[4]
    r.sort = {
      aria: [...th].map((t) => t.getAttribute("aria-sort")),
      left_icon_after_label: iconL.left >= labelL.right,
      right_icon_before_label: iconR.right <= labelR.left,
      // the label's end lines up with the cells' (both padded 16px from the edge)
      right_label_flush: Math.round(th[4].getBoundingClientRect().right - labelR.right),
      right_text_align: getComputedStyle(th[4]).textAlign,
      right_cell_align: getComputedStyle(cellR).textAlign,
      first_align: getComputedStyle(th[1]).textAlign,
      unsorted_icon_opacity: getComputedStyle(sortBtn.querySelector(".data-table-sort-icon")).opacity,
    }

    // the active row (last opened) is highlighted and scrolled into view
    patch("orders", "active")
    await frames()
    const sc = $("orders").querySelector("[data-dt-scroll]").getBoundingClientRect()
    const ar = row("orders", 28).getBoundingClientRect()
    r.active = {
      marked: row("orders", 28).hasAttribute("data-active"),
      in_view: ar.top >= sc.top && ar.bottom <= sc.bottom + 1,
      background: getComputedStyle(row("orders", 28)).backgroundColor !== getComputedStyle(row("orders", 27)).backgroundColor,
    }

    // scrolling saves the position
    $("orders").querySelector("[data-dt-scroll]").scrollTop = 120
    $("orders").querySelector("[data-dt-scroll]").dispatchEvent(new Event("scroll"))
    await frames()
    r.saved = sessionStorage.getItem("data-table:scroll:orders").split(" ")[0]
    r.saved_view = sessionStorage.getItem("data-table:scroll:orders").split(" ")[1] === $("orders").dataset.view

    // a new sort (or search, or filter) starts the body at the top
    patch("orders", "sorted")
    await frames()
    r.new_view = $("orders").querySelector("[data-dt-scroll]").scrollTop

    // more: the end in view pushes dt:more once, until the reply
    await frames()
    r.more_first = events("dt:more", "paged").length
    hooks.paged.updated()
    $("paged").querySelector("[data-dt-scroll]").dispatchEvent(new Event("scroll"))
    await frames()
    r.more_while_waiting = events("dt:more", "paged").length
    // replied, nothing new and the end still shows: ask again
    patch("paged", "more-same")
    reply()
    await sleep(20)
    r.more_again = events("dt:more", "paged").length
    // the last page: no more pushes
    patch("paged", "more-done")
    reply()
    await sleep(20)
    await frames()
    r.more_done = { pushes: events("dt:more", "paged").length, spinner: !!$("paged").querySelector("[data-dt-more]") }

    // a dead view's dt:more asks once, until the page changes the rows
    const deadMore = () => domEvents.filter((d) => d.payload.table === "dead-more" && d.event === "dt:more").length
    $("dead-more-wrap").scrollIntoView()
    await frames()
    await sleep(30)
    r.dead_more = { first: deadMore() }
    const extra = row("dead-more", 2).cloneNode(true)
    extra.id = "dead-more-row-3"
    extra.dataset.id = "3"
    row("dead-more", 2).after(extra)
    await sleep(30)
    await frames()
    r.dead_more.after_rows = deadMore()
    window.scrollTo(0, 0)

    // the dead view's pushes are DOM events
    click(row("dead", 2).querySelectorAll("td")[2])
    click(box("dead", 3))
    r.dead = domEvents.filter((d) => d.payload.table === "dead")

    // phones: no checkbox column or bulk bar, hidden columns, right-aligned
    // rightmost column, room for a floating bar, edge to edge
    const ifr = $("phone")
    await new Promise((res) => { ifr.onload = res; ifr.srcdoc = document.getElementById("phone-src").textContent })
    const d = ifr.contentDocument
    const pth = d.querySelectorAll("#phone thead th")
    const card = d.getElementById("phone")
    r.phone = {
      check: getComputedStyle(pth[0]).display,
      status: getComputedStyle(pth[3]).display,
      customer_align: getComputedStyle(pth[2]).textAlign,
      total_align: getComputedStyle(pth[4]).textAlign,
      bulk: getComputedStyle(d.querySelector("#phone [data-dt-bulk]")).display,
      padding: getComputedStyle(d.querySelector("#phone [data-dt-scroll]")).paddingBottom,
      edge: { left: Math.round(card.getBoundingClientRect().left), width: Math.round(card.getBoundingClientRect().width), radius: getComputedStyle(card).borderTopLeftRadius, border: getComputedStyle(card).borderLeftWidth },
    }

    } catch (e) { errors.push(String(e && e.stack || e)) }
    window.__result = JSON.stringify({ errors, r })
    </script>
    <script type="text/plain" id="phone-src">#{String.replace(phone, "</script", "<\\/script")}</script>
    </body>
    </html>
    """

    dir = Path.join(System.tmp_dir!(), "sd-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    file = Path.join(dir, "page.html")
    File.write!(file, page)
    if dbg = System.get_env("DT_DEBUG"), do: File.write!(dbg, page)

    script = Path.join(@root, "test/support/chrome_eval.mjs")
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  setup_all do
    %{"errors" => errors, "r" => r} = run_in_chrome()
    %{errors: errors, r: r}
  end

  test "no script errors", %{errors: errors} do
    assert errors == []
  end

  test "the header checkbox follows the rows", %{r: r} do
    assert r["head_initial"] == %{"checked" => false, "indeterminate" => true}
    assert r["select"]["head"] == %{"checked" => false, "indeterminate" => true}
    assert r["head_all"] == %{"checked" => true, "indeterminate" => false}
    assert r["head_none"] == %{"checked" => false, "indeterminate" => false}
    assert r["head_one"] == %{"checked" => false, "indeterminate" => true}
  end

  test "ticking a row pushes dt:select; a stale re-render can't undo it before the reply", %{r: r} do
    assert r["select"]["pushed"] == [%{"id" => "7", "shift" => false, "table" => "orders"}]
    assert r["select"]["checked"] == true
    assert r["pending"]["checked"] == true
    # the server's answer wins once it has replied
    assert r["after_reply"]["checked"] == false
    assert r["after_reply"]["head"] == %{"checked" => false, "indeterminate" => true}
  end

  test "the bulk bar appears without moving the rows", %{r: r} do
    assert r["bulk_initial"] == %{"hidden" => false, "text" => "2 selected"}

    assert %{
             "hidden" => false,
             "moved" => 0,
             "bar_top" => 0,
             "bar_height" => 0,
             "covers_labels" => true,
             "header_checkbox_free" => true,
             "text" => "1 selected",
             "export" => true,
             "offer" => false
           } = r["bulk"]

    assert r["bulk_gone"] == %{"hidden" => true, "moved" => 0}
  end

  test "every loaded row ticked offers all matching; all matching says so", %{r: r} do
    assert r["bulk_all"] == %{"text" => "30 selected", "offer" => "Select all 240 orders"}
    assert r["bulk_allmatch"] == %{"text" => "All 240 selected", "offer" => false}
  end

  test "Shift-click ticks a range without selecting text; the cell ticks its box", %{r: r} do
    assert r["shift"] == %{
             "pushed" => [%{"id" => "9", "shift" => true, "table" => "orders"}],
             "prevented" => true
           }

    assert r["cell"] == %{
             "pushed" => [%{"id" => "11", "shift" => false, "table" => "orders"}],
             "checked" => true,
             "opened" => 0
           }
  end

  test "a row click opens it, except on links, ignored parts or selected text", %{r: r} do
    assert r["open"] == [%{"id" => "4", "table" => "orders"}]
  end

  test "Cmd/Ctrl-click and middle click open row_href in a new tab", %{r: r} do
    assert r["new_tab"]["opened"] == [
             ["/orders/8", "_blank"],
             ["/orders/8", "_blank"],
             ["/orders/8", "_blank"]
           ]

    assert r["new_tab"]["open_events"] == 1
  end

  test "Enter opens a focused row, Down moves, Space ticks", %{r: r} do
    assert r["keys"]["open"] == [%{"id" => "3", "table" => "orders"}]
    assert r["keys"]["focused"] == "orders-row-4"
    assert r["keys"]["select"] == [%{"id" => "4", "shift" => false, "table" => "orders"}]
  end

  test "sort headers: aria-sort, the arrow outside the label, the rightmost column right-aligned",
       %{r: r} do
    assert r["sort"]["aria"] == [nil, "none", "none", nil, "none"]
    assert r["sort"]["left_icon_after_label"]
    assert r["sort"]["right_icon_before_label"]
    assert r["sort"]["right_label_flush"] == 16
    assert r["sort"]["right_text_align"] == "end"
    assert r["sort"]["right_cell_align"] == "end"
    assert r["sort"]["first_align"] == "start"
    assert r["sort"]["unsorted_icon_opacity"] == "0"
  end

  test "the last opened row is highlighted and scrolled into view", %{r: r} do
    assert r["active"] == %{"marked" => true, "in_view" => true, "background" => true}
  end

  test "the scroll position is restored on mount and saved on scroll, with its view", %{r: r} do
    assert r["restored"] == 300
    assert r["saved"] == "120"
    assert r["saved_view"] == true
  end

  test "a new sort, search or filter starts the body at the top", %{r: r} do
    assert r["new_view"] == 0
  end

  test "more: dt:more once until the reply, again while the end shows, never on the last page",
       %{r: r} do
    assert r["more_first"] == 1
    assert r["more_while_waiting"] == 1
    assert r["more_again"] == 2
    assert r["more_done"] == %{"pushes" => 2, "spinner" => false}
  end

  test "a dead view's dt:more asks once, then again once the rows change", %{r: r} do
    assert r["dead_more"] == %{"first" => 1, "after_rows" => 2}
  end

  test "a dead view's pushes are shadcn:data-table events", %{r: r} do
    assert r["dead"] == [
             %{"event" => "dt:open", "payload" => %{"id" => "2", "table" => "dead"}},
             %{
               "event" => "dt:select",
               "payload" => %{"id" => "3", "shift" => false, "table" => "dead"}
             }
           ]
  end

  test "phones: no checkbox column or bulk bar, hidden columns, edge to edge", %{r: r} do
    assert %{
             "check" => "none",
             "status" => "none",
             "customer_align" => "start",
             "total_align" => "end",
             "bulk" => "none",
             "padding" => "80px"
           } = r["phone"]

    assert r["phone"]["edge"] == %{
             "left" => 0,
             "width" => 375,
             "radius" => "0px",
             "border" => "0px"
           }
  end
end
