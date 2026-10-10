defmodule ShadcnDaisyui.JS.SheetSectionsBrowserTest do
  # Sheet / drawer sections in headless Chrome with the real theme CSS and
  # shadcn-daisyui.js (same harness as toast_layer_browser_test.exs): the header
  # and footer stay put while only the body scrolls, and the 1px lines between
  # them show only while content is scrolled under them.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Overlay, only: [sheet: 1, drawer: 1]

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
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui.js")
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui.css")

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp markup do
    assigns = %{rows: 1..60}

    render(~H"""
    <.sheet id="long">
      <:title>Filters</:title>
      <:description>Narrow the list.</:description>
      <:header><input id="long-search" /></:header>
      <div :for={i <- @rows} style="height: 24px">Row {i}</div>
      <:footer>
        <button id="long-clear">Clear all</button>
        <button id="long-apply" style="margin-left: auto">Show 24 results</button>
      </:footer>
    </.sheet>
    <.sheet id="short">
      <:title>Short</:title>
      one line
      <:footer><button>Done</button></:footer>
    </.sheet>
    <.drawer id="drw">
      <:title>Move goal</:title>
      <div :for={i <- @rows} style="height: 24px">Row {i}</div>
      <:footer><button>Submit</button></:footer>
    </.drawer>
    <.drawer id="drw-short"><:title>Short</:title>one line</.drawer>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css}</style></head>
    <body>
    #{markup()}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    #{js}
    const wait = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const $ = (s) => document.querySelector(s)
    const rect = (el) => el.getBoundingClientRect()
    const edges = (d) => [d.hasAttribute("data-scroll-top"), d.hasAttribute("data-scroll-bottom")]
    const lines = (body) => {
      const cs = getComputedStyle(body)
      return [cs.borderTopColor !== "rgba(0, 0, 0, 0)", cs.borderBottomColor !== "rgba(0, 0, 0, 0)"]
    }
    const settle = async () => { await frames(); await wait(350) }
    const out = {}

    // long sheet: header and footer pinned, only the body scrolls
    const sheet = $("#long"), body = sheet.querySelector(".sheet-body")
    sheet.dispatchEvent(new CustomEvent("shadcn:show-modal", { bubbles: true }))
    await settle()
    out.open = sheet.open
    out.footerAtBottom = Math.round(rect(sheet.querySelector(".sheet-footer")).bottom) === Math.round(rect(sheet).bottom)
    out.headerAtTop = Math.round(rect(sheet.querySelector(".sheet-header")).top) === Math.round(rect(sheet).top)
    out.bodyScrolls = body.scrollHeight > body.clientHeight
    out.dialogOverflow = getComputedStyle(sheet).overflowY
    out.atTop = [edges(sheet), lines(body)]
    body.scrollTop = 200
    await settle()
    out.middle = [edges(sheet), lines(body)]
    out.dialogScrollTop = sheet.scrollTop
    out.headerStill = Math.round(rect(sheet.querySelector(".sheet-header")).top) === Math.round(rect(sheet).top)
    body.scrollTop = body.scrollHeight
    await settle()
    out.atEnd = [edges(sheet), lines(body)]

    // a "patch" that adds content keeps the scroll position and re-shows the bottom line
    body.scrollTop = 300
    await settle()
    const content = body.firstElementChild
    for (let i = 0; i < 10; i++) content.appendChild(Object.assign(document.createElement("div"), { style: "height: 24px", textContent: "new" }))
    await settle()
    out.patchKeptScroll = body.scrollTop === 300
    out.afterGrow = edges(sheet)
    // shrinking content under the viewport clears both lines
    content.replaceChildren(Object.assign(document.createElement("div"), { textContent: "only row" }))
    await settle()
    out.afterShrink = edges(sheet)
    out.footerAfterShrink = Math.round(rect(sheet.querySelector(".sheet-footer")).bottom) === Math.round(rect(sheet).bottom)
    sheet.close()
    await settle()

    // short sheet (opened directly, not via show_modal): footer still at the bottom, no lines
    const short = $("#short")
    short.showModal()
    await settle()
    out.shortFooterAtBottom = Math.round(rect(short.querySelector(".sheet-footer")).bottom) === Math.round(rect(short).bottom)
    out.shortEdges = edges(short)
    out.focusInside = short.contains(document.activeElement)
    short.close()
    await settle()

    // drawer: capped at 85vh, footer pinned, body scrolls
    const drw = $("#drw"), dbody = drw.querySelector(".drawer-body")
    drw.showModal()
    await settle()
    out.drawerCapped = rect(drw).height <= innerHeight * 0.85 + 1
    out.drawerFooterAtBottom = Math.round(rect(drw.querySelector(".drawer-footer")).bottom) === Math.round(rect(drw).bottom)
    out.drawerAtTop = edges(drw)
    dbody.scrollTop = 100
    await settle()
    out.drawerMiddle = [edges(drw), lines(dbody)]
    drw.close()
    await settle()

    // short drawer: as tall as its content, no lines
    const ds = $("#drw-short")
    ds.showModal()
    await settle()
    out.shortDrawerFits = rect(ds).height < innerHeight * 0.5
    out.shortDrawerEdges = edges(ds)
    ds.close()

    out.errors = errors
    window.__result = JSON.stringify(out)
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
    {out, 0} = System.cmd(@node, [script, @chrome, file, profile])
    JSON.decode!(out)
  end

  test "sheet and drawer: pinned header and footer, scrolling body, lines only while scrolled under" do
    r = run_in_chrome()

    assert r["errors"] == []
    assert r["open"]

    # layout
    assert r["headerAtTop"]
    assert r["footerAtBottom"]
    assert r["bodyScrolls"]
    assert r["dialogOverflow"] == "hidden"

    # [[top attr, bottom attr], [top line, bottom line]]
    assert r["atTop"] == [[false, true], [false, true]]
    assert r["middle"] == [[true, true], [true, true]]
    assert r["dialogScrollTop"] == 0
    assert r["headerStill"]
    assert r["atEnd"] == [[true, false], [true, false]]

    # content changes while open (a LiveView patch)
    assert r["patchKeptScroll"]
    assert r["afterGrow"] == [true, true]
    assert r["afterShrink"] == [false, false]
    assert r["footerAfterShrink"]

    # short body, opened with showModal() directly
    assert r["shortFooterAtBottom"]
    assert r["shortEdges"] == [false, false]
    assert r["focusInside"]

    # drawer
    assert r["drawerCapped"]
    assert r["drawerFooterAtBottom"]
    assert r["drawerAtTop"] == [false, true]
    assert r["drawerMiddle"] == [[true, true], [true, true]]
    assert r["shortDrawerFits"]
    assert r["shortDrawerEdges"] == [false, false]
  end
end
