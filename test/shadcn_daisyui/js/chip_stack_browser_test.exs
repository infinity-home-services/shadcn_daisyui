defmodule ShadcnDaisyui.JS.ChipStackBrowserTest do
  # Stacked chips in <.chip_row>, in headless Chrome with the real theme CSS
  # and JS (same harness as the other *_browser_test files): how a stack opens
  # inline and closes by pointer, keyboard and touch, what removing a value
  # does, and the row's fit, in a pinned page header too. Pointer input is
  # dispatched PointerEvents; a LiveView patch is the morph below, keeping what
  # the component marks with JS.ignore_attributes, then the hook's updated().
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Display, only: [chip_row: 1]
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1]

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
    *, ::before, ::after { box-sizing: border-box; } body { margin: 0; font: 14px/20px sans-serif; }
    button, input { font: inherit; } button { background: none; border: 0; padding: 0; }
    [hidden] { display: none !important; }
    .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
  }
  """

  # helpers every probe gets
  @helpers ~S"""
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
  const $ = (id) => document.getElementById(id)
  const q = (s) => document.querySelector(s)
  const stack = (id) => $(id + "-chip-v-brands")
  const opener = (id) => stack(id).querySelector("[data-chip-stack-open]")
  const panel = (id) => stack(id).querySelector("[data-chip-stack-list]")
  const isOpen = (id) => opener(id).getAttribute("aria-expanded") === "true" && !panel(id).hidden
  const over = (el, type = "mouse", from = null) => el.dispatchEvent(new PointerEvent("pointerover", { bubbles: true, pointerType: type, relatedTarget: from }))
  const out = (el, to = null, type = "mouse") => el.dispatchEvent(new PointerEvent("pointerout", { bubbles: true, pointerType: type, relatedTarget: to }))
  const move = (el) => el.dispatchEvent(new PointerEvent("pointermove", { bubbles: true, pointerType: "mouse" }))
  // the pointer arrives, the short pause passes, it moves on the chip
  const hover = async (el) => { move(el); over(el); await sleep(150); move(el) }
  const tap = (el) => {
    el.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, pointerType: "touch" }))
    el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1 }))
  }
  const mouseClick = (el) => {
    el.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, pointerType: "mouse" }))
    el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1 }))
  }
  const esc = (el = document.activeElement || document.body) =>
    el.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }))
  const rect = (el) => { const r = el.getBoundingClientRect(); return [r.left, r.top, r.width, r.height] }
  const active = () => document.activeElement && document.activeElement.id
  const valueBtn = (id, v) => $(`${id}-chip-v-brands-value-v-${v}-remove`)
  const face = (id) => ({
    name: stack(id).querySelector("[data-chip-stack-name]").textContent,
    count: stack(id).querySelector("[data-chip-stack-count]").textContent,
    edges: stack(id).dataset.edges,
    label: stack(id).querySelector("[data-chip-stack-open]").textContent.replace(/\s+/g, " ").trim(),
  })
  """

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp brands(values) do
    labels = %{
      "acme" => "Acme sandbox",
      "northwind" => "Northwind",
      "ps" => "Northwind sandbox",
      "long" => "A brand with a very long name indeed that should truncate in the row"
    }

    for v <- values, do: %{value: v, label: Map.get(labels, v, v)}
  end

  defp row(id, values \\ ~w(acme northwind ps), opts \\ []) do
    assigns = %{
      id: id,
      items: brands(values),
      extra: opts[:extra] || [],
      removable: Keyword.get(opts, :removable, true)
    }

    render(~H"""
    <.chip_row id={@id} aria_label="Active filters">
      <:chip value="brands" items={@items} removable={@removable}>Brands</:chip>
      <:chip :for={e <- @extra} value={e}>{e}</:chip>
    </.chip_row>
    """)
  end

  defp run(body, probe, opts \\ []) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))
    theme = opts[:theme] || "shadcn"
    # before the module runs: stub matchMedia (hover: none, reduced motion)
    stubs = opts[:stubs] || ""

    page = """
    <!doctype html>
    <html data-theme="#{theme}">
    <head><meta charset="utf-8"><style>#{css} #{@base}</style></head>
    <body>
    #{body}
    <script>#{stubs}</script>
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook=ShadcnChipRow]")) {
      const hook = Object.assign(Object.create(Hooks.ShadcnChipRow), { el })
      hook.mounted()
      hooks[el.id] = hook
    }
    #{@helpers}
    // morphdom, as far as these patches go: keep elements by id, attributes
    // from the server's markup except what JS.ignore_attributes marks
    const IGNORED = (el) => {
      if (el.matches("[data-chip-stack-list]")) return ["hidden", "inert", "style"]
      if (el.matches("[data-chip-stack-open]")) return ["aria-expanded"]
      if (el.matches("[data-chip], [data-chip-copy], [data-chip-value], [data-chip-row-more], [data-chip-row-panel]")) return ["hidden"]
      if (el.matches("[data-chip-row-trigger]")) return ["aria-expanded", "aria-label", "data-count"]
      if (el.matches("[data-chip-row]")) return ["data-ready"]
      return []
    }
    const morph = (from, to) => {
      const keep = IGNORED(from)
      for (const a of [...from.attributes]) if (!to.hasAttribute(a.name) && !keep.includes(a.name)) from.removeAttribute(a.name)
      for (const a of [...to.attributes]) if (!keep.includes(a.name) && from.getAttribute(a.name) !== a.value) from.setAttribute(a.name, a.value)
      const old = new Map([...from.children].filter((c) => c.id).map((c) => [c.id, c]))
      const next = []
      for (const n of [...to.childNodes]) {
        const match = n.nodeType === 1 && n.id && old.get(n.id)
        if (match) { morph(match, n); next.push(match) }
        else if (n.nodeType === 1 && !n.id && from.children.length) {
          const same = [...from.children].find((c) => !c.id && c.tagName === n.tagName && !next.includes(c))
          if (same) { morph(same, n); next.push(same) } else next.push(n.cloneNode(true))
        }
        else next.push(n.cloneNode(true))
      }
      from.replaceChildren(...next)
    }
    const patch = (id, tpl) => {
      hooks[id].beforeUpdate()
      morph($(id), $(tpl).content.firstElementChild)
      hooks[id].updated()
    }
    await document.fonts.ready
    await sleep(30)
    let probe = null
    try { probe = await (async () => { #{probe} })() } catch (e) { errors.push(String(e) + " " + (e.stack || "")) }
    window.__result = JSON.stringify({ errors, probe })
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
    result["probe"]
  end

  defp wide(html), do: ~s(<div style="width: 1000px; padding: 40px">#{html}</div>)

  test "one edge for two values, two for more; the name truncates, +N never; edges count toward the width" do
    many = row("many", ~w(long northwind ps))
    two = row("two", ~w(acme northwind))

    p =
      run(wide(many <> "<br><br>" <> two), ~S"""
      const front = (id) => stack(id).querySelector("[data-chip-stack-front]")
      const name = stack("many").querySelector("[data-chip-stack-name]")
      const count = stack("many").querySelector("[data-chip-stack-count]")
      const edge = (id, pseudo) => getComputedStyle(front(id), pseudo)
      return {
        many: face("many"), two: face("two"),
        truncated: name.scrollWidth > name.clientWidth,
        countWhole: count.scrollWidth <= count.clientWidth,
        liWider: [stack("many").getBoundingClientRect().width - front("many").getBoundingClientRect().width,
                  stack("two").getBoundingClientRect().width - front("two").getBoundingClientRect().width],
        edges: [edge("many", "::before").display, edge("many", "::after").display, edge("two", "::before").display, edge("two", "::after").display],
        shadow: edge("many", "::before").boxShadow,
      }
      """)

    assert p["many"]["edges"] == "2"
    assert p["many"]["count"] == "+2"
    assert p["many"]["label"] =~ "Brands: A brand with a very long name"
    assert p["two"]["edges"] == "1"
    assert p["two"]["name"] == "Acme sandbox"
    assert p["two"]["count"] == "+1"
    assert p["two"]["label"] =~ "Brands: Acme sandbox, Northwind"
    assert p["truncated"]
    assert p["countWhole"]
    assert p["liWider"] == [8, 4]
    assert p["edges"] == ["block", "block", "block", "none"]
    assert p["shadow"] == "none"
  end

  test "hover opens it inline: the face stays, the next chips slide over, it closes about 150ms after leaving" do
    p =
      run(wide(row("r", ~w(acme northwind ps), extra: ~w(Next))), ~S"""
      const face = () => stack("r").querySelector("[data-chip-stack-front]")
      const faceBefore = rect(face()), nextBefore = rect($("r-chip-v-Next")), heightBefore = rect($("r"))[3]
      const closedAtFirst = opener("r").getAttribute("aria-expanded") === "false" && panel("r").hidden
      over(opener("r"))
      await sleep(40)
      // a pointer just crossing doesn't open it
      const notYet = opener("r").getAttribute("aria-expanded")
      await sleep(120)
      const opened = isOpen("r")
      const slides = $("r-chip-v-Next").getAnimations().length
      await sleep(220)
      const f = rect(face())
      const n = rect($("r-chip-v-Next"))
      const values = [...panel("r").querySelectorAll("[data-chip-value]")]
      const last = values[values.length - 1].getBoundingClientRect()
      // in line with the face, in order, between it and the next chip
      const middle = f[1] + f[3] / 2
      const inLine = values.every((v) => { const r = v.getBoundingClientRect(); return Math.abs(r.top + r.height / 2 - middle) < 1 })
      const between = values[0].getBoundingClientRect().left >= f[0] + f[2] && last.right <= n[0]
      // no dead gap: the space between the face and its first value is the stack
      const gapAt = (f[0] + f[2] + values[0].getBoundingClientRect().left) / 2
      const gapInside = stack("r").contains(document.elementFromPoint(gapAt, f[1] + f[3] / 2))
      const x = $("r-chip-v-brands-remove").getBoundingClientRect()
      const xOnTop = document.elementFromPoint(x.left + x.width / 2, x.top + x.height / 2).closest("[data-chip-remove]") === $("r-chip-v-brands-remove")
      // moving on to a value is not leaving
      move(opener("r"))
      out(opener("r"), values[1])
      over(values[1], "mouse", opener("r"))
      await sleep(220)
      const stillOpen = isOpen("r")
      // leaving: open just before 150ms, closing after, sliding back
      out(values[1])
      await sleep(90)
      const at90 = opener("r").getAttribute("aria-expanded")
      await sleep(110)
      const at200 = opener("r").getAttribute("aria-expanded")
      const floating = getComputedStyle(panel("r")).position
      await sleep(250)
      return { closedAtFirst, notYet, opened, slides, sameFace: JSON.stringify(f) === JSON.stringify(faceBefore), moved: n[0] > nextBefore[0],
               sameHeight: rect($("r"))[3] === heightBefore, inLine, between, gapInside, xOnTop, stillOpen, at90, at200, floating,
               hidden: panel("r").hidden, back: JSON.stringify(rect($("r-chip-v-Next"))) === JSON.stringify(nextBefore) }
      """)

    assert p["closedAtFirst"]
    assert p["notYet"] == "false"
    assert p["opened"]
    assert p["slides"] > 0
    assert p["sameFace"]
    assert p["moved"]
    assert p["sameHeight"]
    assert p["inLine"]
    assert p["between"]
    assert p["gapInside"]
    assert p["xOnTop"]
    assert p["stillOpen"]
    assert p["at90"] == "true"
    assert p["at200"] == "false"
    assert p["floating"] == "absolute"
    assert p["hidden"]
    assert p["back"]
  end

  test "a pointer that leaves before the pause opens nothing; re-entering keeps it open; one open at a time" do
    p =
      run(wide(row("a") <> "<br><br>" <> row("b")), ~S"""
      over(opener("a"))
      await sleep(40)
      out(opener("a"))
      await sleep(150)
      const crossed = opener("a").getAttribute("aria-expanded")
      await hover(opener("a"))
      out(opener("a"))
      await sleep(50)
      over(opener("a"))
      await sleep(200)
      const kept = isOpen("a")
      await hover(opener("b"))
      await sleep(10)
      const swapped = [opener("a").getAttribute("aria-expanded"), isOpen("b")]
      await sleep(250)
      const hiddenA = panel("a").hidden
      return { crossed, kept, swapped, hiddenA }
      """)

    assert p["crossed"] == "false"
    assert p["kept"]
    assert p["swapped"] == ["false", true]
    assert p["hiddenA"]
  end

  test "keyboard: opens on focus-visible, closes when focus leaves; Esc closes and returns to the stack" do
    p =
      run(
        wide(
          ~s(<button id="before">before</button>) <>
            row("r") <> ~s(<button id="after">after</button>)
        ),
        ~S"""
        $("before").focus()
        opener("r").focus()
        await sleep(20)
        const onFocus = isOpen("r"), focusVisible = opener("r").matches(":focus-visible")
        // the opener and the × are separate stops, then each value's ×
        const stops = [opener("r"), $("r-chip-v-brands-remove"), valueBtn("r", "acme"), valueBtn("r", "northwind"), valueBtn("r", "ps")]
        const inOrder = stops.every((b, i) => !i || (stops[i - 1].compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING))
        const names = stops.slice(2).map((b) => [...b.getAttribute("aria-labelledby").split(" ")].map((id) => $(id).getAttribute("aria-label") || $(id).textContent).join(" "))
        stops[2].focus()
        await sleep(10)
        const insidePanel = isOpen("r")
        // Esc from inside the panel
        esc(stops[2])
        const afterEsc = [opener("r").getAttribute("aria-expanded"), active()]
        await sleep(250)
        const hiddenAfterEsc = panel("r").hidden
        // it stays closed while focus stays in the stack...
        $("r-chip-v-brands-remove").focus()
        await sleep(10)
        const dismissed = opener("r").getAttribute("aria-expanded")
        // ...until focus has left
        $("after").focus()
        opener("r").focus()
        await sleep(10)
        const reopened = isOpen("r")
        $("after").focus()
        await sleep(10)
        const closedOnLeave = opener("r").getAttribute("aria-expanded")
        await sleep(250)
        return { onFocus, focusVisible, inOrder, names, insidePanel, afterEsc, hiddenAfterEsc, dismissed, reopened, closedOnLeave, hidden: panel("r").hidden }
        """
      )

    assert p["onFocus"] and p["focusVisible"]
    assert p["inOrder"]
    assert p["names"] == ["Remove Acme sandbox", "Remove Northwind", "Remove Northwind sandbox"]
    assert p["insidePanel"]
    assert p["afterEsc"] == ["false", "r-chip-v-brands-open"]
    assert p["hiddenAfterEsc"]
    assert p["dismissed"] == "false"
    assert p["reopened"]
    assert p["closedOnLeave"] == "false"
    assert p["hidden"]
  end

  test "Enter toggles it; Esc while only hovering closes it and doesn't take focus from a field" do
    p =
      run(wide(row("r") <> ~s(<input id="field">)), ~S"""
      opener("r").focus()
      await sleep(10)
      opener("r").click()
      const toggledOff = opener("r").getAttribute("aria-expanded")
      await sleep(250)
      opener("r").click()
      const toggledOn = isOpen("r")
      $("field").focus()
      await sleep(10)
      await hover(opener("r"))
      await sleep(10)
      const hoverOpen = isOpen("r")
      let reached = false
      window.addEventListener("keydown", (e) => { reached = !e.defaultPrevented })
      esc($("field"))
      const afterEsc = [opener("r").getAttribute("aria-expanded"), active(), reached]
      // still hovering: stays closed until the pointer has left
      over(opener("r"))
      await sleep(150)
      const dismissed = opener("r").getAttribute("aria-expanded")
      out(opener("r"))
      await hover(opener("r"))
      const again = opener("r").getAttribute("aria-expanded")
      return { toggledOff, toggledOn, hoverOpen, afterEsc, dismissed, again }
      """)

    assert p["toggledOff"] == "false"
    assert p["toggledOn"]
    assert p["hoverOpen"]
    assert p["afterEsc"] == ["false", "field", false]
    assert p["dismissed"] == "false"
    assert p["again"] == "true"
  end

  test "touch: a tap toggles it, a tap outside closes it, touch never opens by hover" do
    p =
      run(wide(row("r") <> ~s(<p id="outside">outside</p>)), ~S"""
      over(opener("r"), "touch")
      await sleep(150)
      const noHover = opener("r").getAttribute("aria-expanded")
      tap(opener("r"))
      const tapped = isOpen("r")
      out(opener("r"), null, "touch")
      await sleep(220)
      const staysOpen = isOpen("r")
      // a tap on the stack's panel stays; a tap outside closes
      tap(panel("r"))
      const panelTap = isOpen("r")
      tap($("outside"))
      const outside = opener("r").getAttribute("aria-expanded")
      await sleep(250)
      const hidden = panel("r").hidden
      tap(opener("r"))
      const reopen = isOpen("r")
      tap(opener("r"))
      const toggled = opener("r").getAttribute("aria-expanded")
      return { noHover, tapped, staysOpen, panelTap, outside, hidden, reopen, toggled }
      """)

    assert p["noHover"] == "false"
    assert p["tapped"] and p["staysOpen"] and p["panelTap"]
    assert p["outside"] == "false"
    assert p["hidden"]
    assert p["reopen"]
    assert p["toggled"] == "false"
  end

  test "without (hover: hover) a mouse pointer doesn't open it, a click does" do
    stubs = ~S"""
    const real = window.matchMedia.bind(window)
    window.matchMedia = (q) => q.includes("hover: hover") ? { matches: false, addEventListener() {} } : real(q)
    """

    p =
      run(
        wide(row("r")),
        ~S"""
        over(opener("r"))
        await sleep(150)
        const hovered = opener("r").getAttribute("aria-expanded")
        mouseClick(opener("r"))
        const clicked = isOpen("r")
        return { hover: hovered, clicked }
        """,
        stubs: stubs
      )

    assert p["hover"] == "false"
    assert p["clicked"]
  end

  test "with hover a mouse click on the opener leaves it open" do
    p =
      run(wide(row("r")), ~S"""
      await hover(opener("r"))
      mouseClick(opener("r"))
      return isOpen("r")
      """)

    assert p
  end

  test "reduced motion: opening and closing are instant, nothing animates" do
    stubs = ~S"""
    const real = window.matchMedia.bind(window)
    window.matchMedia = (q) => q.includes("reduced-motion") ? { matches: true, addEventListener() {} } : real(q)
    """

    p =
      run(
        wide(row("r")),
        ~S"""
        await hover(opener("r"))
        const opening = $("r").getAnimations({ subtree: true }).filter((a) => a.effect && a.effect.getKeyframes().length && !a.transitionProperty).length
        const opened = isOpen("r")
        out(opener("r"))
        await sleep(170)
        return { opening, opened, closed: panel("r").hidden }
        """,
        stubs: stubs
      )

    assert p["opening"] == 0
    assert p["opened"]
    assert p["closed"]
  end

  test "motion: each value travels from the stack to its place and back, about 180ms, transform and opacity only" do
    p =
      run(wide(row("r")), ~S"""
      over(opener("r"))
      await sleep(135)
      const chips = [...panel("r").querySelectorAll("[data-chip-value]")]
      const report = (anims) => anims.map((a) => ({
        duration: a.effect.getTiming().duration,
        easing: a.effect.getTiming().easing,
        props: [...new Set(a.effect.getKeyframes().flatMap((k) => Object.keys(k)))].filter((k) => !["offset", "easing", "composite", "computedOffset"].includes(k)).sort(),
      }))
      const opening = report(chips.flatMap((c) => c.getAnimations()))
      const frames = chips.map((c) => c.getAnimations()[0].effect.getKeyframes())
      await sleep(220)
      // the first frame sits on the stack, the last at the chip's own place
      const li = stack("r").querySelector("[data-chip-stack-front]").getBoundingClientRect()
      const starts = chips.map((c, i) => {
        const [dx, dy = 0] = frames[i][0].translate.match(/-?[\d.]+/g).map(Number)
        const r = c.getBoundingClientRect()
        return [Math.abs(dx - (li.left - r.left)) < 1, Math.abs(dy - (li.top - r.top)) < 1, Number(frames[i][0].opacity), frames[i][1].translate]
      })
      move(opener("r"))
      out(opener("r"))
      await sleep(170)
      const closingFrames = chips[1].getAnimations()[0].effect.getKeyframes()
      const closing = [Number(closingFrames[0].opacity), Number(closingFrames[1].opacity), panel("r").hidden]
      await sleep(220)
      return { opening, starts, closing, hidden: panel("r").hidden, left: chips.flatMap((c) => c.getAnimations()).length, style: panel("r").style.position }
      """)

    for a <- p["opening"] do
      assert a["duration"] == 180
      assert a["easing"] == "ease-out"
      assert a["props"] -- ["opacity", "translate", "scale"] == []
    end

    assert length(p["opening"]) == 3
    assert Enum.all?(p["starts"], &(&1 == [true, true, 0, "0px"]))
    assert p["closing"] == [1, 0, false]
    assert p["hidden"]
    assert p["left"] == 0
    assert p["style"] == ""
  end

  test "removing a value: it stays open and focus moves on, then a normal chip with focus on its ×" do
    p =
      run(wide(row("r", ~w(acme northwind ps), extra: ~w(Next))), ~S"""
      const events = []
      $("r").addEventListener("chip-remove", (e) => events.push(e.detail))
      opener("r").focus()
      await sleep(10)
      valueBtn("r", "acme").focus()
      valueBtn("r", "acme").click()
      await sleep(250)
      const two = { open: isOpen("r"), focus: active(), face: face("r"), left: stack("r").querySelectorAll("[data-chip-value]").length,
                    copies: [...$("r").querySelectorAll("[data-chip-copy]")].filter((c) => c.dataset.index === "0").length }
      valueBtn("r", "northwind").click()
      await sleep(250)
      const chip = stack("r")
      const one = {
        stack: chip.hasAttribute("data-chip-stack"),
        badge: chip.classList.contains("badge"),
        text: chip.querySelector(".chip-label").textContent,
        panel: !!chip.querySelector("[data-chip-stack-panel]"),
        focus: active() === chip.querySelector("[data-chip-remove]").id,
        chipPresent: !!$("r-chip-v-Next"),
      }
      chip.querySelector("[data-chip-remove]").click()
      await sleep(250)
      return { events, two, one, gone: !stack("r"), copiesGone: [...$("r").querySelectorAll("[data-chip-copy]")].filter((c) => c.dataset.index === "0").length, focusNext: active() }
      """)

    assert [
             %{"value" => "brands", "item" => "acme", "index" => 0},
             %{"item" => "northwind"},
             last
           ] =
             p["events"]

    assert last["value"] == "brands"
    refute Map.has_key?(last, "item")

    assert p["two"]["open"]
    assert p["two"]["focus"] == "r-chip-v-brands-value-v-northwind-remove"
    assert p["two"]["face"]["name"] == "Northwind"
    assert p["two"]["face"]["count"] == "+1"
    assert p["two"]["face"]["edges"] == "1"
    assert p["two"]["face"]["label"] =~ "Brands: Northwind, Northwind sandbox"
    assert p["two"]["left"] == 2
    assert p["two"]["copies"] == 2

    assert p["one"] == %{
             "stack" => false,
             "badge" => true,
             "text" => "Northwind sandbox",
             "panel" => false,
             "focus" => true,
             "chipPresent" => true
           }

    assert p["gone"]
    assert p["copiesGone"] == 0
    assert p["focusNext"] == "r-chip-v-Next-remove"
  end

  test "the stack's × clears the whole filter; removable={false} keeps the values' ×" do
    p =
      run(wide(row("r") <> row("fixed", ~w(acme northwind), removable: false)), ~S"""
      const hasClear = !!$("fixed-chip-v-brands-remove")
      const valueX = !!valueBtn("fixed", "acme")
      await hover(opener("r"))
      await sleep(10)
      $("r-chip-v-brands-remove").click()
      await sleep(10)
      const leaving = stack("r").hasAttribute("data-chip-exiting")
      const closed = panel("r").inert || panel("r").hidden
      await sleep(250)
      return { hasClear, valueX, leaving, closed, gone: !stack("r") }
      """)

    refute p["hasClear"]
    assert p["valueX"]
    assert p["leaving"]
    assert p["closed"]
    assert p["gone"]
  end

  test "a value removed under the pointer: it stays open until the pointer really moves away" do
    p =
      run(wide(row("r", ~w(acme northwind ps long))), ~S"""
      await hover(opener("r"))
      await sleep(10)
      mouseClick(valueBtn("r", "acme"))
      // the layout moved under the pointer, which reports leaving without moving
      out(panel("r"))
      await sleep(250)
      const stayed = isOpen("r")
      move(document.body)
      await sleep(200)
      return { stayed, closed: opener("r").getAttribute("aria-expanded") }
      """)

    assert p["stayed"]
    assert p["closed"] == "false"
  end

  test "after a × click a stack that slid under the resting pointer waits for a real move" do
    assigns = %{items: brands(~w(acme northwind))}

    other =
      render(~H"""
      <.chip_row id="r">
        <:chip value="first">First</:chip>
        <:chip value="brands" items={@items}>Brands</:chip>
      </.chip_row>
      """)

    p =
      run(wide(other), ~S"""
      mouseClick($("r-chip-v-first-remove"))
      await sleep(10)
      // the browser reports the pointer entering what moved under it
      over(opener("r"))
      await sleep(150)
      const held = opener("r").getAttribute("aria-expanded")
      move(opener("r"))
      await sleep(150)
      return { held, moved: isOpen("r") }
      """)

    assert p["held"] == "false"
    assert p["moved"]
  end

  test "an open stack survives a patch and shows the server's values; a stack the server reduced becomes a chip" do
    tpl = fn id, values ->
      ~s(<template id="#{id}">#{row("r", values)}</template>)
    end

    body =
      wide(row("r")) <>
        tpl.("same", ~w(acme northwind ps)) <>
        tpl.("more", ~w(northwind ps acme long)) <>
        tpl.("two", ~w(northwind ps)) <>
        tpl.("one", ~w(ps))

    p =
      run(body, ~S"""
      await hover(opener("r"))
      await sleep(220)
      const r0 = rect(panel("r"))
      patch("r", "same")
      await sleep(20)
      const same = { open: isOpen("r"), place: JSON.stringify(rect(panel("r"))) === JSON.stringify(r0) }
      patch("r", "more")
      await sleep(40)
      const more = { open: isOpen("r"), face: face("r"), values: [...panel("r").querySelectorAll("[data-chip-value] .chip-label")].map((l) => l.textContent.slice(0, 7)) }
      valueBtn("r", "acme").focus()
      valueBtn("r", "acme").click()
      patch("r", "two")
      await sleep(250)
      const two = { open: isOpen("r"), face: face("r") }
      patch("r", "one")
      await sleep(30)
      const chip = stack("r")
      return { same, more, two, one: !chip.hasAttribute("data-chip-stack") && !chip.querySelector("[data-chip-stack-open]") && chip.querySelector(".chip-label").textContent }
      """)

    assert p["same"] == %{"open" => true, "place" => true}
    assert p["more"]["open"]
    assert p["more"]["face"]["count"] == "+3"
    assert p["more"]["face"]["name"] == "Northwind"
    assert p["more"]["values"] == ["Northwi", "Northwi", "Acme sa", "A brand"]
    assert p["two"]["open"]
    assert p["two"]["face"]["count"] == "+1"
    assert p["one"] == "Northwind sandbox"
  end

  test "patch to one value: the × of that chip gets focus, the stack is closed" do
    body =
      wide(row("r", ~w(acme ps))) <> ~s(<template id="one">#{row("r", ~w(ps))}</template>)

    p =
      run(body, ~S"""
      opener("r").focus()
      await sleep(10)
      valueBtn("r", "acme").focus()
      valueBtn("r", "acme").setAttribute("phx-click", "x")
      valueBtn("r", "acme").click()
      patch("r", "one")
      await sleep(40)
      return { focus: active(), stack: stack("r").hasAttribute("data-chip-stack") }
      """)

    assert p["focus"] == "r-chip-v-brands-remove"
    refute p["stack"]
  end

  test "fit: a stack counts as one chip with its edges; in +N its values show flat and removable" do
    p =
      run(
        ~s(<div style="width: 300px">#{row("r", ~w(acme northwind ps), extra: ~w(Alpha-filter-one Beta-filter-two Gamma-filter-three))}</div>) <>
          ~s(<div style="width: 90px">#{row("n", ~w(acme northwind ps), extra: ~w(Alpha-filter-one))}</div>),
        ~S"""
        const row = $("r")
        const shown = (el) => !el.closest("[hidden]")
        const chips = [...row.querySelectorAll("[data-chip]")]
        const used = [...row.querySelector("[data-chip-row-chips]").children].filter((c) => !c.hidden)
        const right = Math.max(...used.map((c) => c.getBoundingClientRect().right))
        const more = row.querySelector("[data-chip-row-more]").getBoundingClientRect()
        const n = $("n")
        const nStack = stack("n")
        // the stack is in +N: its values flat in the panel, no popover there
        const trigger = n.querySelector("[data-chip-row-trigger]")
        const hiddenStack = nStack.hidden
        trigger.click()
        await sleep(10)
        const flat = [...n.querySelectorAll("[data-chip-row-panel] [data-chip-copy]")].filter(shown)
        const texts = flat.map((c) => c.querySelector(".chip-label").textContent)
        const inPanel = n.querySelector("[data-chip-row-panel]").querySelectorAll("[data-chip-stack]").length
        over(trigger)
        await sleep(150)
        const noOpen = stack("n").querySelector("[data-chip-stack-open]").getAttribute("aria-expanded")
        flat[0].querySelector("[data-chip-remove]").click()
        await sleep(250)
        const after = [...n.querySelectorAll("[data-chip-row-panel] [data-chip-copy]")].filter(shown).map((c) => c.querySelector(".chip-label").textContent)
        return {
          count: row.querySelector("[data-chip-row-trigger]").dataset.count,
          total: chips.length, visible: chips.filter(shown).length,
          noOverlap: right <= more.left + 0.5,
          hiddenStack, texts, inPanel, noOpen, after,
          nCount: trigger.dataset.count,
          stayedOpen: !n.querySelector("[data-chip-row-panel]").hidden,
          focusInPanel: n.querySelector("[data-chip-row-panel]").contains(document.activeElement),
        }
        """
      )

    assert p["total"] == 4
    assert p["count"] == "+#{p["total"] - p["visible"]}"
    assert p["noOverlap"]
    assert p["hiddenStack"]
    assert "Acme sandbox" in p["texts"]
    assert "Northwind" in p["texts"]
    assert "Northwind sandbox" in p["texts"]
    assert p["inPanel"] == 0
    assert p["noOpen"] == "false"
    refute "Acme sandbox" in p["after"]
    assert "Northwind" in p["after"]
    assert p["stayedOpen"]
    assert p["focusInPanel"]
  end

  test "no room: the next chips fold into +N and return; too many values, the last ones go flat into +N" do
    p =
      run(
        ~s(<div style="width: 520px">#{row("r", ~w(acme northwind ps), extra: ~w(Alpha Beta Gamma))}</div>) <>
          ~s(<div style="width: 380px">#{row("t", ~w(acme northwind ps long), extra: ~w(Alpha))}</div>),
        ~S"""
        const shown = (el) => !el.closest("[hidden]")
        const state = (id) => {
          const row = $(id)
          const chips = [...row.querySelectorAll("[data-chip]")]
          const list = stack(id).querySelector("[data-chip-stack-list]")
          const more = row.querySelector("[data-chip-row-more]")
          const inRow = [...row.querySelector("[data-chip-row-chips]").children].filter((c) => !c.hidden)
          return {
            visible: chips.filter(shown).length,
            values: [...list.querySelectorAll("[data-chip-value]")].filter(shown).length,
            copies: [...row.querySelectorAll("[data-chip-copy]")].filter((c) => !c.hidden).map((c) => c.querySelector(".chip-label").textContent.slice(0, 7)),
            count: more.hidden ? null : row.querySelector("[data-chip-row-trigger]").dataset.count,
            fits: Math.max(...inRow.map((c) => c.getBoundingClientRect().right), more.hidden ? 0 : more.getBoundingClientRect().right) <= row.getBoundingClientRect().right + 0.5,
            oneLine: new Set(inRow.map((c) => Math.round(c.getBoundingClientRect().top))).size === 1,
            scroll: row.scrollWidth <= row.clientWidth + 1,
          }
        }
        const closed = state("r")
        await hover(opener("r"))
        await sleep(220)
        const opened = state("r")
        move(opener("r"))
        out(opener("r"))
        await sleep(400)
        const closedAgain = state("r")
        const face = rect(stack("t").querySelector("[data-chip-stack-front]"))
        await hover(opener("t"))
        await sleep(220)
        const tight = state("t")
        const sameFace = JSON.stringify(rect(stack("t").querySelector("[data-chip-stack-front]"))) === JSON.stringify(face)
        // a value folded into +N is removable there, and the stack keeps the rest
        const copy = [...$("t").querySelectorAll("[data-chip-copy]")].find((c) => !c.hidden && c.hasAttribute("data-chip-value"))
        const copyValue = copy && copy.dataset.value
        return { closed, opened, closedAgain, tight, sameFace, copyValue }
        """
      )

    assert p["closed"]["visible"] == 4
    assert p["closed"]["values"] == 0

    assert p["opened"]["values"] == 3
    assert p["opened"]["visible"] < p["closed"]["visible"]
    assert p["opened"]["fits"] and p["opened"]["oneLine"] and p["opened"]["scroll"]
    assert p["opened"]["count"] == "+#{4 - p["opened"]["visible"]}"

    assert p["closedAgain"]["visible"] == 4
    assert p["closedAgain"]["count"] == nil

    tight = p["tight"]
    assert tight["values"] < 4
    assert tight["fits"] and tight["oneLine"]
    assert "Alpha" in Enum.map(tight["copies"], &String.trim/1)
    assert length(tight["copies"]) == String.to_integer(String.trim_leading(tight["count"], "+"))
    assert p["sameFace"]
    assert p["copyValue"]
  end

  test "values folded into +N stay reachable: pointer, keyboard and click don't close the stack" do
    p =
      run(
        ~s(<div style="width: 380px">#{row("t", ~w(acme northwind ps long))}<button id="after">after</button></div>),
        ~S"""
        const more = $("t").querySelector("[data-chip-row-more]")
        const trigger = $("t").querySelector("[data-chip-row-trigger]")
        const copies = () => [...$("t").querySelectorAll("[data-chip-copy]")].filter((c) => !c.hidden)
        await hover(opener("t"))
        await sleep(220)
        const folded = copies().length
        // the pointer crosses to +N: the stack stays, and so do the values there
        move(trigger)
        out(opener("t"), trigger)
        over(trigger, "mouse", opener("t"))
        await sleep(220)
        const overMore = [isOpen("t"), copies().length]
        // a click on +N, then on a value there
        mouseClick(trigger)
        await sleep(20)
        const popover = !$("t").querySelector("[data-chip-row-panel]").hidden
        const copyButton = copies()[0].querySelector("[data-chip-remove]")
        const copyValue = copies()[0].dataset.value
        mouseClick(copyButton)
        await sleep(250)
        const afterRemoval = [isOpen("t"), copies().some((c) => c.dataset.value === copyValue)]
        // leaving +N for the page closes it
        out(trigger)
        move(document.body)
        await sleep(400)
        const closed = opener("t").getAttribute("aria-expanded")
        // keyboard: from the last value on to +N and its values, then out
        opener("t").focus()
        await sleep(20)
        trigger.focus()
        await sleep(20)
        const onTrigger = isOpen("t")
        $("after").focus()
        await sleep(20)
        return { folded, overMore, popover, afterRemoval, closed, onTrigger, afterFocus: opener("t").getAttribute("aria-expanded") }
        """
      )

    assert p["folded"] > 0
    assert p["overMore"] == [true, p["folded"]]
    assert p["popover"]
    assert p["afterRemoval"] == [true, false]
    assert p["closed"] == "false"
    assert p["onTrigger"]
    assert p["afterFocus"] == "false"
  end

  test "no room for any value in the row: a tap shows them in the +N popover, and closes it again" do
    p =
      run(
        ~s(<div style="width: 190px">#{row("t", ~w(acme northwind))}</div><p id="outside">outside</p>),
        ~S"""
        tap(opener("t"))
        await sleep(30)
        const panel_ = $("t").querySelector("[data-chip-row-panel]")
        const shown = !panel_.hidden
        const list = [...panel_.querySelectorAll("[data-chip-copy]")].filter((c) => !c.hidden).map((c) => c.dataset.value)
        const inline = panel("t").hidden
        tap($("t").querySelector("[data-chip-row-panel] [data-chip-copy]:not([hidden]) .chip-label"))
        const stays = isOpen("t") || opener("t").getAttribute("aria-expanded") === "true"
        tap($("outside"))
        await sleep(30)
        return { shown, list, inline, stays, closed: panel_.hidden, expanded: opener("t").getAttribute("aria-expanded") }
        """
      )

    assert p["shown"]
    assert p["list"] == ["acme", "northwind"]
    assert p["inline"]
    assert p["stays"]
    assert p["closed"]
    assert p["expanded"] == "false"
  end

  test "the +N popover stays in the window even when too wide for either alignment" do
    wide_labels = ~w(acme northwind ps) ++ ["Alpha-filter-one"]

    p =
      run(
        ~s(<div style="position: fixed; top: 10px; left: 100px; width: 140px">#{row("r", wide_labels, extra: ~w(Beta-filter-two Gamma-filter-three Delta-filter-four))}</div>),
        ~S"""
        Object.defineProperty(document.documentElement, "clientWidth", { get: () => 300, configurable: true })
        const trigger = $("r").querySelector("[data-chip-row-trigger]")
        trigger.click()
        await sleep(20)
        const panel = $("r").querySelector("[data-chip-row-panel]")
        const r = panel.getBoundingClientRect()
        return { open: !panel.hidden, left: r.left, right: r.right }
        """
      )

    assert p["open"]
    assert p["left"] >= 8
    assert p["right"] <= 292
  end

  test "in a pinned page header: opens in the row, nothing scrolls or wraps" do
    assigns = %{row: row("r", ~w(acme northwind ps), extra: ~w(Next))}

    header =
      render(~H"""
      <.page_header crumbs={[%{label: "Lab"}]}>
        Title
        <:below>{Phoenix.HTML.raw(@row)}</:below>
      </.page_header>
      """)

    body = ~s"""
    <div style="display: flex; height: 100dvh; overflow: hidden">
      <div id="main" class="app-shell-main" style="flex: 1">
        #{header}
        <div style="height: 2000px" id="content">content</div>
      </div>
    </div>
    """

    p =
      run(body, ~S"""
      const main = $("main")
      const header = main.querySelector(".sticky-top")
      const before = [main.scrollHeight, main.scrollWidth, main.clientWidth, header.getBoundingClientRect().height]
      await hover(opener("r"))
      await sleep(220)
      const after = [main.scrollHeight, main.scrollWidth, main.clientWidth, header.getBoundingClientRect().height]
      const last = [...panel("r").querySelectorAll("[data-chip-value]")].pop().getBoundingClientRect()
      const hit = header.contains(document.elementFromPoint(last.left + 4, last.top + last.height / 2))
      return { open: isOpen("r"), same: JSON.stringify(before) === JSON.stringify(after), hit }
      """)

    assert p["open"]
    assert p["same"]
    assert p["hit"]
  end

  # WCAG contrast between CSS colours, painted to a canvas (alpha over `under`).
  @contrast ~S"""
  const ctx = document.createElement("canvas").getContext("2d", { willReadFrequently: true })
  const paint = (color, under) => {
    ctx.clearRect(0, 0, 1, 1)
    if (under) { ctx.fillStyle = under; ctx.fillRect(0, 0, 1, 1) }
    ctx.fillStyle = color
    ctx.fillRect(0, 0, 1, 1)
    return [...ctx.getImageData(0, 0, 1, 1).data]
  }
  const lum = ([r, g, b]) => { const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b) }
  const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05) }
  const token = (css, el = document.body) => { const d = document.createElement("div"); d.style.color = css; el.append(d); const c = getComputedStyle(d).color; d.remove(); return c }
  """

  defp colours(body, theme) do
    run(
      body,
      @contrast <>
        ~S"""
        const front = stack("r").querySelector("[data-chip-stack-front]")
        const fill = getComputedStyle(front).backgroundColor
        const page = paint(token("var(--page-background)"))
        const white = paint(token("var(--background)"))
        const chip = paint(fill)
        const before = getComputedStyle(front, "::before")
        const edgeLine = paint(before.borderTopColor, fill)
        const remove = $("r-chip-v-brands-remove")
        const hoverX = paint(token("color-mix(in oklab, currentColor 12%, transparent)", remove), fill)
        const secondary = paint(token("var(--secondary)"))
        const plain = paint(getComputedStyle($("r-chip-v-Next")).backgroundColor)
        const more = getComputedStyle(q("[data-chip-row-trigger]"))
        const badge = document.createElement("span"); badge.className = "badge badge-secondary"; document.body.append(badge)
        await hover(opener("r"))
        await sleep(240)
        const open = paint(getComputedStyle(front).backgroundColor)
        const openText = paint(getComputedStyle(front).color)
        return {
          onPage: ratio(chip, page), onBackground: ratio(chip, white), text: ratio(paint(getComputedStyle(front).color), chip),
          plainIsChip: JSON.stringify(plain) === JSON.stringify(chip),
          line: ratio(edgeLine, chip), lineOnPage: ratio(edgeLine, page), xHover: ratio(hoverX, chip),
          openOnPage: ratio(open, page), openText: ratio(openText, open),
          moreFill: more.backgroundColor,
          badge: [paint(getComputedStyle(badge).backgroundColor), secondary],
          value: paint(token("var(--chip-background)")),
        }
        """,
      theme: theme
    )
  end

  test "the chip fill has its own token: it reads on the page, text at 4.5:1, × hover and edges show, in both themes" do
    body = wide(row("r", ~w(acme northwind), extra: ~w(Next)))

    for {theme, on_background} <- [{"shadcn", 1.2}, {"shadcn-dark", 1.2}] do
      p = colours(body, theme)

      assert p["onBackground"] >= on_background, "#{theme}: chip on the page #{p["onBackground"]}"
      assert p["onPage"] >= 1.15, "#{theme}: chip on the tinted page #{p["onPage"]}"
      assert p["text"] >= 4.5, "#{theme}: text #{p["text"]}"
      assert p["plainIsChip"]
      assert p["line"] >= 1.3, "#{theme}: edge against the chip in front #{p["line"]}"
      assert p["lineOnPage"] >= 1.3, "#{theme}: edge against the page #{p["lineOnPage"]}"
      assert p["xHover"] >= 1.2, "#{theme}: × hover against the chip #{p["xHover"]}"
      assert p["openOnPage"] >= 1.2, "#{theme}: open stack on the page #{p["openOnPage"]}"
      assert p["openText"] >= 4.5, "#{theme}: open stack's text #{p["openText"]}"
      # +N stays outlined; other badges keep --secondary
      assert p["moreFill"] == "rgba(0, 0, 0, 0)"
      assert [same, same] = p["badge"]
    end
  end

  test "brand themes: a brand's value wins, a *-dark brand doesn't get the light fill" do
    brand = ~s"""
    <style>
    [data-theme="acme"] { --chip-background: oklch(0.8 0.1 200); }
    [data-theme="acme-dark"] { --secondary: oklch(0.3 0 0); }
    </style>
    """

    body = brand <> wide(row("r", ~w(acme northwind), extra: ~w(Next)))

    probe = ~S"""
    const fill = getComputedStyle($("r-chip-v-Next")).backgroundColor
    const d = document.createElement("div"); d.style.backgroundColor = "var(--secondary)"; document.body.append(d)
    return { fill, secondary: getComputedStyle(d).backgroundColor }
    """

    assert run(body, probe, theme: "acme")["fill"] =~ "0.8"
    dark = run(body, probe, theme: "acme-dark")
    assert dark["fill"] == dark["secondary"]
  end
end
