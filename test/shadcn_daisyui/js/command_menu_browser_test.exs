defmodule ShadcnDaisyui.JS.CommandMenuBrowserTest do
  # <.command_menu> in headless Chrome (1280x900) with the real theme CSS and
  # JS: placement and flipping, filtering across levels, keys, ARIA, a few
  # hundred rows, and the phone drawer (the same page in a 375px iframe).
  # No LiveView: a row's phx-click doesn't run, choosing it only closes.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.CommandMenu
  import ShadcnDaisyui.Components.Shell, only: [app_shell_heading: 1]

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

  @preflight "*, ::before, ::after { box-sizing: border-box; } body { margin: 0; } button { font: inherit; } .w-72 { width: 18rem; } .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }"

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # Company > brands (each with locations); `brands` of them
  defp menu(brands, opts \\ []) do
    assigns = %{
      brands: brands,
      id: opts[:id] || "scope",
      trigger_id: opts[:trigger_id],
      side: opts[:side] || "bottom"
    }

    render(~H"""
    <.command_menu
      id={@id}
      label="Switch location"
      placeholder="Search"
      trigger_id={@trigger_id}
      side={@side}
    >
      <:trigger :if={!@trigger_id}>Acme</:trigger>
      <:item
        :for={row <- rows(@brands)}
        id={row.id}
        group={row.group}
        parent={row[:parent]}
        keywords={row[:keywords]}
        current={row[:current]}
        disabled={row[:disabled]}
        phx-click="pick"
      >
        {row.label}
      </:item>
      <:item id="link" group="Other" href="#chosen">A link</:item>
    </.command_menu>
    """)
  end

  defp rows(brands) do
    [%{id: "org", group: "Company", label: "All of Acme"}] ++
      for b <- 1..brands,
          row <- [
            %{id: "b#{b}", group: "Brands", label: "Brand #{b}"}
            | for l <- 1..3 do
                %{
                  id: "b#{b}-l#{l}",
                  group: "Brands",
                  parent: "b#{b}",
                  label: "Location #{b}.#{l}" <> if(b == 3 and l == 1, do: " Montréal", else: ""),
                  keywords: if(b == 2 and l == 2, do: "Texas"),
                  current: b == 2 and l == 1,
                  disabled: b == 1 and l == 3
                }
              end
          ],
          do: row
  end

  defp page(body, test, opts \\ []) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))
    done = if opts[:framed], do: "parent.__result", else: "window.__result"

    """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{@preflight}#{css}</style></head>
    <body>
    #{body}
    <script type="module">
    #{js}
    const wait = (ms) => new Promise((r) => setTimeout(r, ms))
    const frame = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const key = (target, init) => {
      const e = new KeyboardEvent("keydown", { bubbles: true, cancelable: true, ...init })
      target.dispatchEvent(e)
      return e.defaultPrevented
    }
    const type = (input, text) => { input.value = text; input.dispatchEvent(new Event("input", { bubbles: true })) }
    const $ = (s) => document.querySelector(s)
    const shown = (id) => { const el = document.getElementById(id); return !!el && !el.hidden && el.offsetParent !== null }
    const box = (el) => { const r = el.getBoundingClientRect(); return { top: Math.round(r.top), left: Math.round(r.left), bottom: Math.round(r.bottom), right: Math.round(r.right), width: Math.round(r.width) } }
    const out = {}
    try {
    #{test}
    } catch (e) { out.error = String(e && e.stack || e) }
    #{done} = JSON.stringify(out)
    </script>
    </body>
    </html>
    """
  end

  defp run_in_chrome(html) do
    dir = Path.join(System.tmp_dir!(), "sd-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    file = Path.join(dir, "page.html")
    File.write!(file, html)
    script = Path.join(@root, "test/support/chrome_eval.mjs")
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  test "opens below its trigger at the current row; filters every level; keys; closes" do
    body =
      ~s(<div style="padding: 40px 0 0 40px">#{menu(4)}</div><button id="after">After</button>)

    r =
      run_in_chrome(
        page(body, ~S"""
        initShadcnDaisyui()
        const t = $("#scope-trigger"), p = $("#scope-panel"), input = $("#scope-search")
        const active = () => input.getAttribute("aria-activedescendant")
        t.click()
        await frame()
        const tb = box(t), pb = box(p)
        out.open = {
          popover: p.matches(":popover-open"), expanded: t.getAttribute("aria-expanded"),
          focused: document.activeElement === input, active: active(), mode: p.dataset.mode,
          placement: p.dataset.placement, gap: pb.top - tb.bottom, left: pb.left - tb.left,
          wider: pb.width >= tb.width, selected: $("#b2-l1").getAttribute("aria-selected")
        }

        // a location's name: it, under its brand (context); groups without rows hide
        type(input, "location 3.1")
        out.location = {
          shown: ["org", "b3", "b3-l1", "b3-l2", "b2"].map(shown),
          context: $("#b3").hasAttribute("data-context"), active: active(),
          company: !$("#org").closest("[data-command-menu-group]").hidden
        }
        // accents and case don't matter; keywords count
        type(input, "MONTREAL"); out.accent = active()
        type(input, "texas"); out.keyword = active()
        // a brand's name shows it and its locations, the brand active
        type(input, "brand 2")
        out.brand = { shown: ["b2", "b2-l1", "b2-l2", "b2-l3", "b1"].map(shown), active: active() }
        await wait(500)
        out.status = $("#scope-status").textContent.trim()
        type(input, "zzz")
        out.empty = { empty: shown("scope-list") ? "list" : !$("[data-command-menu-empty]").hidden, active: active() }

        // while searching the keys skip the context rows (brand 3 here)
        type(input, "location 3.")
        const ctx = [active()]
        for (let i = 0; i < 3; i++) { key(input, { key: "ArrowDown" }); ctx.push(active()) }
        out.contextKeys = ctx

        // keys: down / up wrap, the disabled row is skipped, Enter chooses
        type(input, "brand 1")
        const seq = []
        for (let i = 0; i < 4; i++) { key(input, { key: "ArrowDown" }); seq.push(active()) }
        key(input, { key: "ArrowUp" }); seq.push(active())
        out.keys = seq
        key(input, { key: "Enter" })
        await frame()
        out.chosen = { open: p.matches(":popover-open"), focus: document.activeElement === t, expanded: t.getAttribute("aria-expanded") }

        // reopening clears the search; Esc closes and refocuses the trigger
        t.focus()
        out.arrowOpens = key(t, { key: "ArrowDown" })
        await frame()
        out.reopen = { open: p.matches(":popover-open"), value: input.value, allShown: [...document.querySelectorAll("[data-command-menu-item]")].every((el) => !el.hidden) }
        key(input, { key: "Escape" })
        out.esc = { open: p.matches(":popover-open"), focus: document.activeElement === t }

        // a press outside closes it
        t.click(); await frame()
        document.getElementById("after").dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }))
        out.outside = p.matches(":popover-open")

        // a link row: its link runs and the menu closes
        t.click(); await frame()
        type(input, "a link")
        key(input, { key: "Enter" })
        await frame()
        out.link = { hash: location.hash, open: p.matches(":popover-open") }
        """)
      )

    refute r["error"]

    assert r["open"] == %{
             "popover" => true,
             "expanded" => "true",
             "focused" => true,
             "active" => "b2-l1",
             "mode" => "popover",
             "placement" => "bottom",
             "gap" => 4,
             "left" => 0,
             "wider" => true,
             "selected" => "true"
           }

    assert r["location"] == %{
             "shown" => [false, true, true, false, false],
             "context" => true,
             "active" => "b3-l1",
             "company" => false
           }

    assert r["accent"] == "b3-l1"
    assert r["keyword"] == "b2-l2"
    assert r["brand"] == %{"shown" => [true, true, true, true, false], "active" => "b2"}
    assert r["status"] == "4 results"
    assert r["empty"] == %{"empty" => true, "active" => nil}
    assert r["contextKeys"] == ["b3-l1", "b3-l2", "b3-l3", "b3-l1"]
    # brand 1, its locations 1.1 and 1.2 (1.3 disabled), then round to the brand
    assert r["keys"] == ["b1-l1", "b1-l2", "b1", "b1-l1", "b1"]
    assert r["chosen"] == %{"open" => false, "focus" => true, "expanded" => "false"}
    assert r["arrowOpens"] == true
    assert r["reopen"] == %{"open" => true, "value" => "", "allShown" => true}
    assert r["esc"] == %{"open" => false, "focus" => true}
    assert r["outside"] == false
    assert r["link"] == %{"hash" => "#chosen", "open" => false}
  end

  test "flips above a trigger near the bottom, and opens beside a trigger_id trigger with side right" do
    assigns = %{}

    heading =
      render(~H"""
      <div style="width: 240px; padding: 8px">
        <.app_shell_heading id="heading" as="button" icon="hero-cube" title="Acme" chevron />
      </div>
      """)

    body = """
    #{heading}
    #{menu(3, id: "side", trigger_id: "heading", side: "right")}
    <div style="position: fixed; bottom: 20px; left: 300px">#{menu(3, id: "low")}</div>
    """

    r =
      run_in_chrome(
        page(body, ~S"""
        initShadcnDaisyui()
        const h = $("#heading"), sp = $("#side-panel")
        h.click(); await frame()
        out.side = {
          open: sp.matches(":popover-open"), placement: sp.dataset.placement,
          gap: box(sp).left - box(h).right, top: box(sp).top - box(h).top,
          haspopup: h.getAttribute("aria-haspopup"), expanded: h.getAttribute("aria-expanded"),
          controls: h.getAttribute("aria-controls"), tag: h.tagName
        }
        // opening another closes this one
        const lt = $("#low-trigger"), lp = $("#low-panel")
        lt.click(); await frame()
        out.low = {
          other: sp.matches(":popover-open"), placement: lp.dataset.placement,
          gap: box(lt).top - box(lp).bottom, inWindow: box(lp).top >= 8
        }
        """)
      )

    refute r["error"]

    assert r["side"] == %{
             "open" => true,
             "placement" => "right",
             "gap" => 4,
             "top" => 0,
             "haspopup" => "dialog",
             "expanded" => "true",
             "controls" => "side-panel",
             "tag" => "BUTTON"
           }

    assert r["low"] == %{"other" => false, "placement" => "top", "gap" => 4, "inWindow" => true}
  end

  test "stays quick with a few hundred rows" do
    # 150 brands x 3 locations + 151 = 601 rows
    body = ~s(<div style="padding: 40px">#{menu(150)}</div>)

    r =
      run_in_chrome(
        page(body, ~S"""
        initShadcnDaisyui()
        const t = $("#scope-trigger"), input = $("#scope-search")
        out.rows = document.querySelectorAll("[data-command-menu-item]").length
        let t0 = performance.now()
        t.click()
        $("#scope-panel").getBoundingClientRect()
        out.open = performance.now() - t0
        const times = []
        for (const q of ["l", "lo", "loc", "location 1", "location 14", "location 149.2", "brand 7", ""]) {
          t0 = performance.now()
          type(input, q)
          $("#scope-panel").getBoundingClientRect()
          times.push(performance.now() - t0)
        }
        out.slowest = Math.max(...times)
        out.active = input.getAttribute("aria-activedescendant")
        """)
      )

    refute r["error"]
    assert r["rows"] == 602
    # generous bounds for a loaded CI machine; locally both are a few ms
    assert r["open"] < 150, "opening took #{r["open"]}ms"
    assert r["slowest"] < 60, "a keystroke took #{r["slowest"]}ms"
  end

  test "on a phone it's a drawer from the bottom, its search not focused" do
    inner = page(menu(3), phone_test(), framed: true)
    srcdoc = inner |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    body =
      ~s(<iframe id="phone" style="width: 375px; height: 700px; border: 0" srcdoc="#{srcdoc}"></iframe>)

    r = run_in_chrome(page(body, "await new Promise(() => {})"))

    refute r["error"]

    assert r["drawer"] == %{
             "mode" => "drawer",
             "open" => true,
             "bottom" => 700,
             "left" => 0,
             "width" => 375,
             "panelFocused" => true,
             "inputFocused" => false,
             "rowHeight" => 44,
             "inputFont" => "16px",
             "locked" => "hidden"
           }

    assert r["typed"] == %{"input" => true, "active" => "b2"}
    assert r["backdrop"] == false
  end

  defp phone_test do
    ~S"""
    initShadcnDaisyui()
    const t = $("#scope-trigger"), p = $("#scope-panel"), input = $("#scope-search")
    t.click()
    await wait(400)
    const pb = box(p)
    out.drawer = {
      mode: p.dataset.mode, open: p.matches(":popover-open"), bottom: pb.bottom, left: pb.left,
      width: pb.width, panelFocused: document.activeElement === p, inputFocused: document.activeElement === input,
      rowHeight: Math.round($("#org").getBoundingClientRect().height),
      inputFont: getComputedStyle(input).fontSize,
      locked: getComputedStyle(document.documentElement).overflow
    }
    // typing on the drawer goes to its search box
    key(p, { key: "b" })
    type(input, "brand 2")
    out.typed = { input: document.activeElement === input, active: input.getAttribute("aria-activedescendant") }
    // a press on the backdrop (the panel itself, outside its box) closes it
    p.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, clientX: 100, clientY: 10 }))
    out.backdrop = p.matches(":popover-open")
    """
  end
end
