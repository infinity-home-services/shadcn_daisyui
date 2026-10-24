defmodule ShadcnDaisyui.JS.TraceBrowserTest do
  # <.trace> in headless Chrome with the real theme CSS and JS (same harness
  # as the other *_browser_test files): the disclosure toggles from its
  # trigger's aria-expanded alone (one delegated listener, no hook), nested
  # rows open on their own, closed detail is out of the tab order, titles
  # truncate while descriptions don't, and the status styles.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Conversation, only: [trace: 1, trace_line: 1]

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

  defp markup do
    assigns = %{}

    render(~H"""
    <div style="width: 240px; padding: 16px">
      <.trace id="t">
        <:line icon="hero-check" description="1.2s">Searched every order placed in the last ninety days</:line>
        <:line status="running" icon="hero-sparkles">Checking the invoices</:line>
        <:line status="pending">Write the summary</:line>
        <:line status="error" icon="hero-x-circle">Failed to send</:line>
        <.trace_line id="steps">
          Worked through 2 steps
          <:detail>
            <.trace>
              <.trace_line id="inner">
                Ran the report
                <:detail><a id="inner-link" href="#">report.csv</a></:detail>
              </.trace_line>
            </.trace>
          </:detail>
        </.trace_line>
      </.trace>
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
    const css = (el, prop) => getComputedStyle(el).getPropertyValue(prop)
    const probe = document.createElement("div")
    document.body.appendChild(probe)
    const color = (token) => { probe.style.color = "var(" + token + ")"; return getComputedStyle(probe).color }
    const lines = [...document.querySelectorAll("#t > [data-slot=trace-item] > [data-slot=trace-line]")]
    const title = (i) => lines[i].querySelector("[data-slot=trace-title]")
    const detail = (id) => $(id + "-detail")
    const state = (id) => ({ expanded: $(id + "-trigger").getAttribute("aria-expanded"), height: detail(id).offsetHeight, visibility: css(detail(id), "visibility") })
    const r = {}

    // ---- the rows ----
    r.row = { gap: Math.round(lines[1].getBoundingClientRect().top - lines[0].getBoundingClientRect().bottom), font: css(lines[0], "font-size"), color: css(lines[0], "color"), muted: color("--muted-foreground") }
    r.truncated = { title: title(0).scrollWidth > title(0).clientWidth, overflow: css(title(0), "text-overflow"), whiteSpace: css(title(0), "white-space") }
    const desc = lines[0].querySelector("[data-slot=trace-description]")
    r.description = { whole: desc.scrollWidth <= desc.clientWidth, shrink: css(desc, "flex-shrink"), numeric: css(desc, "font-variant-numeric") }
    r.icon = { w: lines[0].querySelector("[data-slot=trace-icon]").offsetWidth, h: lines[0].querySelector("[data-slot=trace-icon]").offsetHeight }
    r.running = { animation: css(title(1), "animation-name"), icon: css(lines[1].querySelector("[data-slot=trace-icon]"), "animation-name") }
    r.pending = css(lines[2], "opacity")
    r.error = { color: css(lines[3], "color"), destructive: color("--destructive") }

    // ---- the disclosure: closed, then open, then closed ----
    r.closed = state("steps")
    r.closedFocusable = $("inner-trigger").checkVisibility({ visibilityProperty: true })
    $("steps-trigger").click()
    await sleep(300)
    r.open = state("steps")
    r.chevron = css($("steps-trigger").querySelector("[data-chevron]"), "rotate")
    r.innerClosed = state("inner")
    // the nested row opens on its own
    $("inner-trigger").click()
    await sleep(300)
    r.innerOpen = { inner: state("inner"), outer: $("steps-trigger").getAttribute("aria-expanded"), link: $("inner-link").checkVisibility({ visibilityProperty: true }) }
    $("steps-trigger").click()
    await sleep(300)
    r.reclosed = { outer: state("steps"), inner: $("inner-trigger").getAttribute("aria-expanded") }
    // keyboard: the trigger is a real button (Enter / Space click it)
    $("steps-trigger").focus()
    r.focusRing = css($("steps-trigger"), "box-shadow") !== "none"

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

  test "no script errors", %{errors: errors} do
    assert errors == []
  end

  test "rows: text-sm muted, 8px apart, 16px icons", %{r: r} do
    assert r["row"]["gap"] == 8
    assert r["row"]["font"] == "14px"
    assert r["row"]["color"] == r["row"]["muted"]
    assert r["icon"] == %{"w" => 16, "h" => 16}
  end

  test "the title truncates; the description never does", %{r: r} do
    assert r["truncated"] == %{
             "title" => true,
             "overflow" => "ellipsis",
             "whiteSpace" => "nowrap"
           }

    assert r["description"] == %{"whole" => true, "shrink" => "0", "numeric" => "tabular-nums"}
  end

  test "running shimmers and pulses; pending is dimmed; error is destructive", %{r: r} do
    assert r["running"] == %{"animation" => "shadcn-shimmer", "icon" => "shadcn-trace-pulse"}
    assert r["pending"] == "0.6"
    assert r["error"]["color"] == r["error"]["destructive"]
  end

  test "a row with detail opens and closes from its button", %{r: r} do
    assert r["closed"] == %{"expanded" => "false", "height" => 0, "visibility" => "hidden"}
    refute r["closedFocusable"]
    assert r["open"]["expanded"] == "true"
    assert r["open"]["height"] > 0
    assert r["open"]["visibility"] == "visible"
    assert r["chevron"] == "90deg"
    assert r["innerClosed"]["expanded"] == "false"
  end

  test "nested rows open on their own", %{r: r} do
    assert r["innerOpen"]["inner"]["expanded"] == "true"
    assert r["innerOpen"]["inner"]["height"] > 0
    assert r["innerOpen"]["outer"] == "true"
    assert r["innerOpen"]["link"]
    assert r["reclosed"]["outer"]["expanded"] == "false"
    assert r["reclosed"]["outer"]["height"] == 0
    # closing the outer row keeps the inner one's state
    assert r["reclosed"]["inner"] == "true"
    assert r["focusRing"]
  end
end
