defmodule ShadcnDaisyui.JS.MessageScrollerBrowserTest do
  # <.message_scroller> in headless Chrome with the real theme CSS and JS
  # (same harness as the other *_browser_test files). Rows are fixed-height
  # blocks so the scroll positions are exact. A streaming reply is text
  # appended to the last row; a stream insert is a row element added to the
  # items container the way LiveView's phx-update="stream" does it (`at: 0`
  # prepends); the reader's scrolling is a scrollTop write (what the
  # scrollbar does), with the wheel/key event that caused it where that
  # matters. One scroller is driven through the LiveView hook object
  # (mounted / updated / destroyed), the rest through initShadcnDaisyui().
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Conversation, only: [message_scroller: 1]

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

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # n turns: a question (an anchor) then an answer, `h` px each
  defp turns(n, h \\ 40) do
    for i <- 1..(2 * n) do
      %{id: i, user?: rem(i, 2) == 1, h: h}
    end
  end

  defp markup do
    assigns = %{
      many: turns(15),
      # the last answer is taller than the viewport
      long_turn: turns(6) ++ [%{id: 13, user?: true, h: 40}, %{id: 14, user?: false, h: 900}],
      # the last answer fits
      short_turn: turns(8),
      few: turns(2)
    }

    render(~H"""
    <div style="display: grid; grid-template-columns: repeat(4, 300px); gap: 16px; padding: 16px">
      <div style="height: 400px"><.message_scroller id="follow" items={@many} anchor={& &1.user?} :let={m}>
        <div id={"follow-text-#{m.id}"} style={"min-height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="pre" items={@many} button="both" :let={m}>
        <div style={"height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="last" items={@long_turn} anchor={& &1.user?} default_position="last-anchor" :let={m}>
        <div style={"height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="fits" items={@short_turn} anchor={& &1.user?} default_position="last-anchor" :let={m}>
        <div style={"height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="live" items={@many} anchor={& &1.user?} :let={m}>
        <div style={"min-height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="start" items={@many} default_position="start" button="both" :let={m}>
        <div style={"height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div id="sheet" style="height: 400px; display: none"><.message_scroller id="hidden" items={@many} :let={m}>
        <div style={"height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="hooked" items={@few} anchor={& &1.user?} :let={m}>
        <div style={"min-height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>

      <div style="height: 400px"><.message_scroller id="empty" items={[]} :let={m}>
        <div style={"height: #{m.h}px"}>Row {m.id}</div>
      </.message_scroller></div>
    </div>
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
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const $ = (id) => document.getElementById(id)
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = (n = 3) => new Promise((r) => { const f = () => (--n ? requestAnimationFrame(f) : r()); requestAnimationFrame(f) })
    const until = async (fn, ms = 2000) => { const t = Date.now(); while (!fn() && Date.now() - t < ms) await sleep(16); return fn() }
    const vp = (id) => $(id + "-viewport")
    const max = (id) => vp(id).scrollHeight - vp(id).clientHeight
    const gap = (id) => Math.round(max(id) - vp(id).scrollTop)
    const button = (id, dir = "end") => $(id + "-to-" + dir)
    const btn = (id, dir) => { const b = button(id, dir); return { active: b.dataset.active, inert: b.inert, tab: b.tabIndex } }
    const top = (el, id) => Math.round(el.getBoundingClientRect().top - vp(id).getBoundingClientRect().top)
    const api = (id) => $(id).__sdScroller
    // a stream insert: a row element as the server renders it
    const row = (id, key, h, anchor) => {
      const el = document.createElement("div")
      el.id = id + "-" + key
      el.setAttribute("data-slot", "message-scroller-item")
      el.setAttribute("data-scroll-anchor", anchor ? "true" : "false")
      el.innerHTML = '<div style="min-height: ' + h + 'px">Row ' + key + '</div>'
      return el
    }
    const append = (id, key, h, anchor) => $(id + "-items").append(row(id, key, h, anchor))
    const prepend = (id, key, h) => $(id + "-items").prepend(row(id, key, h, false))
    const grow = (el, px) => { el.style.minHeight = (parseFloat(el.style.minHeight) + px) + "px"; el.append(" more") }
    const r = {}

    // ---- the LiveView hook: mounted() opens it; a stream insert + updated() follows ----
    const hookEl = $("hooked")
    const hook = Object.assign(Object.create(Hooks.ShadcnMessageScroller), { el: hookEl })
    hook.mounted()

    initShadcnDaisyui()
    await frames()

    // ---- opening ----
    r.open = {
      pending: [$("follow").hasAttribute("data-pending-scroll"), vp("follow").hasAttribute("data-pending-scroll")],
      visibility: getComputedStyle(vp("follow")).visibility,
      gap: gap("follow"),
      scrolled: vp("follow").scrollTop > 0,
      scrollable: vp("follow").dataset.scrollable,
      rootScrollable: $("follow").dataset.scrollable,
      button: btn("follow"),
      following: api("follow").following,
    }
    r.start = {
      top: vp("start").scrollTop,
      pending: vp("start").hasAttribute("data-pending-scroll"),
      startButton: btn("start", "start"),
      endButton: btn("start", "end"),
      scrollable: vp("start").dataset.scrollable,
    }
    const lastAnchor = $("last-13")
    r.last = { anchorTop: top(lastAnchor, "last"), gap: gap("last"), following: api("last").following, button: btn("last") }
    r.fits = { gap: gap("fits"), following: api("fits").following }
    r.empty = { pending: vp("empty").hasAttribute("data-pending-scroll"), visibility: getComputedStyle(vp("empty")).visibility }

    // ---- following a streaming reply at the live edge ----
    const reply = $("follow-text-30")
    for (let i = 0; i < 5; i++) { grow(reply, 30); await frames(2) }
    r.stream = { gap: gap("follow"), following: api("follow").following }
    append("follow", 31, 60, false)
    await frames()
    r.newRow = gap("follow")

    // ---- the reader scrolls up: released; growth no longer moves the view ----
    vp("follow").dispatchEvent(new WheelEvent("wheel", { deltaY: -120, bubbles: true }))
    vp("follow").scrollTop -= 200
    await frames()
    const held = vp("follow").scrollTop
    r.released = { following: api("follow").following, button: btn("follow"), scrollable: vp("follow").dataset.scrollable }
    grow(reply, 90)
    await frames()
    append("follow", 32, 60, false)
    await frames()
    r.held = { moved: vp("follow").scrollTop - held, following: api("follow").following }

    // ---- the button scrolls to the end and re-engages following ----
    button("follow").click()
    r.autoscrolling = vp("follow").hasAttribute("data-autoscrolling")
    await until(() => !vp("follow").hasAttribute("data-autoscrolling") && gap("follow") === 0)
    await frames()
    r.reengaged = { gap: gap("follow"), following: api("follow").following, button: btn("follow"), autoscrolling: vp("follow").hasAttribute("data-autoscrolling") }
    grow(reply, 50)
    await frames()
    r.followsAgain = gap("follow")

    // ---- a scroll key releases it; scrolling back to the end re-engages ----
    vp("follow").focus()
    vp("follow").dispatchEvent(new KeyboardEvent("keydown", { key: "PageUp", bubbles: true }))
    r.keyReleased = api("follow").following
    vp("follow").scrollTop -= 300
    await frames()
    vp("follow").scrollTop = max("follow")
    await frames()
    r.backAtEnd = api("follow").following
    // the scrollbar (no wheel or key): a plain scroll away releases it too
    vp("follow").scrollTop -= 250
    await frames()
    r.scrollbarReleased = api("follow").following

    // ---- rows prepended (stream insert at: 0) keep the row being read in place ----
    vp("pre").scrollTop = 500
    await frames()
    const reading = [...$("pre-items").children].find((el) => el.getBoundingClientRect().bottom > vp("pre").getBoundingClientRect().top + 1)
    const before = { id: reading.id, top: top(reading, "pre") }
    for (let i = 1; i <= 5; i++) prepend("pre", "old-" + i, 40)
    await frames()
    r.prepend = { before, after: top(reading, "pre"), scrollTop: vp("pre").scrollTop }
    // at the very top (where a "Load earlier" button sits), likewise
    vp("pre").scrollTop = 0
    await frames()
    const first = $("pre-items").firstElementChild
    const firstTop = top(first, "pre")
    prepend("pre", "older", 40)
    prepend("pre", "oldest", 40)
    await frames()
    r.prependTop = { before: firstTop, after: top(first, "pre"), startButton: btn("pre", "start") }

    // ---- a new anchored turn moves near the top, the previous row peeking ----
    append("live", 31, 40, true)
    const anchor = $("live-31")
    await until(() => Math.abs(top(anchor, "live") - 64) <= 1)
    await frames()
    const spacer = $("live").querySelector("[data-slot=message-scroller-spacer]")
    r.anchor = { top: top(anchor, "live"), spacer: spacer.offsetHeight, gap: gap("live"), following: api("live").following }
    // the reply streams in under it: the spacer shrinks, the anchor stays put
    append("live", 32, 40, false)
    await frames()
    const answer = $("live-32").firstElementChild
    grow(answer, 100)
    await frames()
    r.replying = { top: top(anchor, "live"), spacer: spacer.offsetHeight }
    // once the reply outgrows the room it is followed like any other
    grow(answer, 600)
    await frames()
    r.outgrown = { spacer: spacer.offsetHeight, gap: gap("live"), anchorTop: top(anchor, "live") }

    // ---- shadcn:scroll-to jumps to a row ----
    $("start").dispatchEvent(new CustomEvent("shadcn:scroll-to", { detail: { to: "start-10" } }))
    await until(() => Math.abs(top($("start-10"), "start")) <= 1)
    await sleep(150)
    r.jump = top($("start-10"), "start")
    button("start", "start").click()
    await until(() => vp("start").scrollTop === 0)
    r.toStart = { top: vp("start").scrollTop, startButton: btn("start", "start") }

    // ---- a scroller in a closed sheet waits until it has a size ----
    r.hiddenBefore = { pending: vp("hidden").hasAttribute("data-pending-scroll"), top: vp("hidden").scrollTop }
    $("sheet").style.display = "block"
    await frames()
    r.hiddenAfter = { pending: vp("hidden").hasAttribute("data-pending-scroll"), gap: gap("hidden"), scrolled: vp("hidden").scrollTop > 0 }

    // ---- the hook: rows arrive in a patch, updated() runs ----
    r.hooked = { pending: vp("hooked").hasAttribute("data-pending-scroll"), following: api("hooked").following }
    for (let i = 5; i <= 14; i++) append("hooked", i, 40, i % 2 === 1)
    hook.updated()
    await until(() => !vp("hooked").hasAttribute("data-autoscrolling") && Math.abs(top($("hooked-13"), "hooked") - 64) <= 1)
    await frames()
    r.hookedPatch = { anchorTop: top($("hooked-13"), "hooked"), scrolled: vp("hooked").scrollTop > 0 }
    hook.destroyed()
    r.destroyed = !hookEl.__sdScroller

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
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  setup_all do
    %{"errors" => errors, "r" => r} = run_in_chrome()
    %{errors: errors, r: r}
  end

  @inactive %{"active" => "false", "inert" => true, "tab" => -1}
  @active %{"active" => "true", "inert" => false, "tab" => 0}

  test "no script errors", %{errors: errors} do
    assert errors == []
  end

  test "opens at the latest message, shown only once positioned", %{r: r} do
    assert r["open"]["pending"] == [false, false]
    assert r["open"]["visibility"] == "visible"
    assert r["open"]["gap"] == 0
    assert r["open"]["scrolled"]
    assert r["open"]["following"]
    # nothing below: the button is inert and out of the tab order
    assert r["open"]["button"] == @inactive
    assert r["open"]["scrollable"] == "start"
    assert r["open"]["rootScrollable"] == "start"
  end

  test "default_position=start opens at the top without hiding first", %{r: r} do
    assert r["start"]["top"] == 0
    refute r["start"]["pending"]
    assert r["start"]["startButton"] == @inactive
    assert r["start"]["endButton"] == @active
    assert r["start"]["scrollable"] == "end"
  end

  test "last-anchor opens at the last turn, or the end when it fits", %{r: r} do
    assert r["last"]["anchorTop"] == 0
    assert r["last"]["gap"] > 0
    refute r["last"]["following"]
    assert r["last"]["button"] == @active
    assert r["fits"]["gap"] == 0
    assert r["fits"]["following"]
  end

  test "an empty transcript is shown at once", %{r: r} do
    refute r["empty"]["pending"]
    assert r["empty"]["visibility"] == "visible"
  end

  test "follows a streaming reply and new rows while at the live edge", %{r: r} do
    assert r["stream"] == %{"gap" => 0, "following" => true}
    assert r["newRow"] == 0
  end

  test "scrolling away releases it: growth no longer moves the view", %{r: r} do
    refute r["released"]["following"]
    assert r["released"]["button"] == @active
    assert r["released"]["scrollable"] == "start end"
    assert r["held"] == %{"moved" => 0, "following" => false}
  end

  test "the button scrolls to the end and follows again", %{r: r} do
    assert r["autoscrolling"]

    assert r["reengaged"] == %{
             "gap" => 0,
             "following" => true,
             "button" => @inactive,
             "autoscrolling" => false
           }

    assert r["followsAgain"] == 0
  end

  test "scroll keys and the scrollbar release it; back at the end re-engages", %{r: r} do
    refute r["keyReleased"]
    assert r["backAtEnd"]
    refute r["scrollbarReleased"]
  end

  test "rows prepended above keep the row being read in place", %{r: r} do
    assert r["prepend"]["after"] == r["prepend"]["before"]["top"]
    # 5 rows of 40px plus 32px gaps went in above
    assert r["prepend"]["scrollTop"] == 500 + 5 * 72
    assert r["prependTop"]["after"] == r["prependTop"]["before"]
    assert r["prependTop"]["startButton"] == @active
  end

  test "a new anchored turn moves near the top with the previous row peeking", %{r: r} do
    assert r["anchor"]["top"] == 64
    assert r["anchor"]["spacer"] > 0
    assert r["anchor"]["gap"] == 0
    assert r["anchor"]["following"]
    # the reply fills the room under it; the anchor doesn't move
    assert r["replying"]["top"] == 64
    assert r["replying"]["spacer"] < r["anchor"]["spacer"]
    # then it's followed like any other content
    assert r["outgrown"]["spacer"] == 0
    assert r["outgrown"]["gap"] == 0
    assert r["outgrown"]["anchorTop"] < 0
  end

  test "shadcn:scroll-to jumps to a row; the start button goes to the top", %{r: r} do
    assert r["jump"] == 0
    assert r["toStart"] == %{"top" => 0, "startButton" => @inactive}
  end

  test "a scroller in a closed sheet opens once it is shown", %{r: r} do
    assert r["hiddenBefore"] == %{"pending" => true, "top" => 0}
    assert r["hiddenAfter"] == %{"pending" => false, "gap" => 0, "scrolled" => true}
  end

  test "through the LiveView hook: rows from a patch, then destroyed", %{r: r} do
    refute r["hooked"]["pending"]
    assert r["hooked"]["following"]
    assert r["hookedPatch"]["anchorTop"] == 64
    assert r["hookedPatch"]["scrolled"]
    assert r["destroyed"]
  end
end
