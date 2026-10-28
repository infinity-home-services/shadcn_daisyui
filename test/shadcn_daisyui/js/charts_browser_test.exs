defmodule ShadcnDaisyui.JS.ChartsBrowserTest do
  # The chart kit (<.chart>, <.number_card>) in headless Chrome with the real
  # theme CSS and the real shadcn_daisyui/charts entry (and its vendored
  # Chart.js), imported as ES modules over file:// (chrome_eval.mjs allows
  # it), under a strict `script-src 'nonce-…'` policy: every CSP violation is
  # recorded. Charts the page mounts through ChartHooks get a stand-in hook
  # that records pushEvent / pushEventTo. window.matchMedia is wrapped so the
  # test can turn reduced motion on.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Chart

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
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui-charts.js")

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  @people [
    {"pat", "Pat Lee", 24_500, 9_310},
    {"sam", "Sam Okafor", 21_800, 7_630},
    {"riley", "Riley Chen", 17_200, 6_880},
    {"jordan", "Jordan Diaz", 14_900, 4_470},
    {"morgan", "Morgan Ito", 11_300, 4_290},
    {"casey", "Casey Park", 6_400, 1_920}
  ]

  defp leaderboard do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(@people, &elem(&1, 1)),
        keys: Enum.map(@people, &elem(&1, 0)),
        datasets: [
          %{
            label: "Margin",
            key: "margin",
            data: Enum.map(@people, &elem(&1, 3)),
            color: "chart-1"
          },
          %{
            label: "Rest of the sale",
            key: "rest",
            data: Enum.map(@people, fn {_, _, s, m} -> s - m end),
            color: "chart-1/35"
          }
        ]
      },
      options: %{
        indexAxis: "y",
        scales: %{
          x: %{
            stacked: true,
            display: false,
            ticks: %{format: %{style: "currency", currency: "USD", maximumFractionDigits: 0}}
          },
          y: %{stacked: true}
        },
        plugins: %{
          endLabels: %{
            labels:
              Enum.map(@people, fn {_, _, s, m} ->
                "$#{s} · #{round(m * 100 / s)}% margin · 2 for 3"
              end)
          }
        }
      }
    }
  end

  defp progress do
    %{
      type: "bar",
      data: %{
        labels: ["Today's appointments"],
        datasets: [
          %{label: "Resulted", key: "resulted", data: [14], color: "chart-1"},
          %{label: "Needs a result", key: "needs_result", data: [3], color: "chart-1/65"},
          %{label: "In progress", key: "in_progress", data: [4], color: "chart-1/35"},
          %{label: "Still to come", key: "to_come", data: [9], color: "muted-foreground/25"}
        ]
      },
      options: %{
        indexAxis: "y",
        scales: %{
          x: %{stacked: true, display: false, max: 30},
          y: %{stacked: true, display: false}
        }
      }
    }
  end

  @bars %{
    type: "bar",
    data: %{labels: ~w(Mon Tue Wed), datasets: [%{label: "Sales", data: [1_200, 2_400, 1_800]}]},
    options: %{
      scales: %{
        y: %{ticks: %{format: %{style: "currency", currency: "USD", maximumFractionDigits: 0}}}
      }
    }
  }

  @lines %{
    type: "line",
    data: %{
      labels: ~w(Mon Tue Wed),
      datasets: [
        %{label: "This week", data: [10, 14, 12]},
        %{label: "Last week", data: [9, 11, 13], color: "muted-foreground"}
      ]
    }
  }

  @pie %{
    type: "doughnut",
    data: %{labels: ~w(Website Referral Phone), datasets: [%{label: "Leads", data: [46, 28, 17]}]}
  }

  defp body do
    assigns = %{lb: leaderboard(), progress: progress(), bars: @bars, lines: @lines, pie: @pie}

    render(~H"""
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="bars" label="Sales by day" config={@bars} />
    </div>
    <div class="card" style="width: 900px; padding: 24px">
      <.chart id="lb" label="Leaderboard" config={@lb} on_click="open_person" />
    </div>
    <div class="card" style="width: 420px; padding: 24px">
      <.chart id="lb-narrow" label="Leaderboard" config={@lb} />
    </div>
    <div class="card" style="width: 200px; padding: 24px">
      <.chart id="lb-phone" label="Leaderboard" config={@lb} />
    </div>
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="progress" label="Today's appointments" config={@progress} on_click="open_state" target="#panel" />
    </div>
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="lines" label="Sales this week and last" config={@lines} />
    </div>
    <div class="card" style="width: 400px; padding: 24px">
      <.chart id="pie" label="Leads by source" config={@pie} />
    </div>
    <div data-theme="acme" class="card" style="width: 600px; padding: 24px">
      <.chart id="brand" label="Brand" config={@bars} />
    </div>
    <div style="width: 300px">
      <.number_card id="sales" label="Sales" value="$42,000" trend={[12, 15, 9, 18]}>Margin</.number_card>
    </div>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    charts = "file://" <> Path.join(@root, "priv/static/shadcn-daisyui-charts.js")
    core = "file://" <> Path.join(@root, "priv/static/shadcn-daisyui.js")
    kurkle = "file://" <> Path.join(@root, "priv/static/vendor/kurkle-color/color.esm.js")

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Security-Policy" content="script-src 'nonce-t3st' file:; object-src 'none'; base-uri 'self'">
    <style>#{css}</style>
    <style>
    /* a brand theme: one series colour of its own */
    [data-theme="acme"] { --chart-1: #ff0000; }
    /* Tailwind's sr-only (the page has no Tailwind build) */
    .sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border-width: 0; }
    body { font-family: system-ui, sans-serif; background: var(--background); }
    </style>
    </head>
    <body>
    #{body()}
    <script nonce="t3st">
    window.__violations = []
    document.addEventListener("securitypolicyviolation", (e) => window.__violations.push(e.effectiveDirective + " " + (e.sample || e.blockedURI)))
    // reduced motion, switchable by the test
    window.__reduce = false
    const mm = window.matchMedia.bind(window)
    window.matchMedia = (q) => q.includes("reduced-motion")
      ? { matches: window.__reduce, media: q, addEventListener() {}, removeEventListener() {} }
      : mm(q)
    </script>
    <script type="module" nonce="t3st">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    const { initCharts, ChartHooks, chartFor } = await import(#{inspect(charts)})
    const { setTheme } = await import(#{inspect(core)})
    const { Color } = await import(#{inspect(kurkle)})
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const $ = (id) => document.getElementById(id)
    const r = {}

    // LiveView-mounted charts get a stand-in hook that records what it pushes
    const pushed = []
    const hookFor = (id) => ({
      el: $(id),
      pushEvent: (e, p) => pushed.push(["pushEvent", e, p]),
      pushEventTo: (t, e, p) => pushed.push(["pushEventTo", t, e, p]),
    })
    const hooks = Object.fromEntries(["lb", "progress", "lines"].map((id) => {
      const h = hookFor(id)
      ChartHooks.ShadcnChart.mounted.call(h)
      return [id, h]
    }))
    // the rest as in a dead view
    initCharts()
    await sleep(450)
    await frames()

    const chart = (id) => chartFor($(id))
    const el = (id, ds, i) => chart(id).getDatasetMeta(ds).data[i]
    const opts = (id, ds, i) => el(id, ds, i).options
    // what the browser makes of a CSS colour, as rgb bytes
    const px = document.createElement("canvas").getContext("2d", { willReadFrequently: true })
    const bytes = (css) => { px.clearRect(0, 0, 1, 1); px.fillStyle = css; px.fillRect(0, 0, 1, 1); return [...px.getImageData(0, 0, 1, 1).data] }
    const rgbOf = (s) => (s.match(/\\d+(\\.\\d+)?/g) || []).map(Number)

    // ---- colours come from the tokens, as rgb ----------------------------------
    const lightBar = opts("bars", 0, 0).backgroundColor
    r.light = {
      bar: lightBar,
      token: bytes("oklch(0.575 0.163 255.53)").slice(0, 3),
      grid: chart("bars").options.scales.y.grid.color,
      ticks: chart("bars").options.scales.y.ticks.color,
      surface: opts("lb", 0, 0).borderColor,
      font: chart("bars").options.font.family,
    }
    // Chart.js's colour library can't read oklch, so the kit converts first;
    // with rgb it works out the hover shade
    r.kurkle = { oklch: new Color("oklch(0.575 0.163 255.53)").valid, rgb: new Color(lightBar).valid }
    r.hover = chart("bars").getDatasetMeta(0).controller.resolveDataElementOptions(0, "active").backgroundColor
    r.brand = opts("brand", 0, 0).backgroundColor
    r.series = {
      lines: chart("lines").data.datasets.map((d) => d.borderColor),
      pie: chart("pie").data.datasets[0].backgroundColor,
      parts: chart("progress").data.datasets.map((d) => d.backgroundColor),
    }

    // ---- the theme switches: every chart redraws from the dark tokens ------------
    setTheme("shadcn-dark")
    await frames()
    r.dark = {
      bar: opts("bars", 0, 0).backgroundColor,
      token: bytes("oklch(0.622 0.161 255.05)").slice(0, 3),
      grid: chart("bars").options.scales.y.grid.color,
      surface: opts("lb", 0, 0).borderColor,
      brand: opts("brand", 0, 0).backgroundColor,
    }
    setTheme("shadcn")
    await frames()
    r.back = opts("bars", 0, 0).backgroundColor

    // ---- marks ---------------------------------------------------------------
    r.vertical = { radius: opts("bars", 0, 0).borderRadius, border: opts("bars", 0, 0).borderWidth, width: el("bars", 0, 0).width }
    r.stack = {
      margin: { radius: opts("lb", 0, 0).borderRadius, border: opts("lb", 0, 0).borderWidth },
      rest: { radius: opts("lb", 1, 0).borderRadius, border: opts("lb", 1, 0).borderWidth },
      height: el("lb", 0, 0).height,
    }
    r.track = chart("progress").data.datasets.map((_, j) => opts("progress", j, 0).borderRadius)
    r.trackFills = (() => { const a = el("progress", 0, 0).getProps(["base"], true).base, z = el("progress", 3, 0).getProps(["x"], true).x, c = chart("progress").chartArea; return { start: Math.round(a - c.left), end: Math.round(c.right - z) } })()

    // ---- end labels and rows --------------------------------------------------
    const rows = (id) => { const c = chart(id); return { mode: c.$kit.labelMode, area: Math.round(c.chartArea.bottom - c.chartArea.top), ticks: c.options.scales.y.ticks.display !== false, thickness: Math.round(el(id, 0, 0).height) } }
    r.labels = { wide: rows("lb"), narrow: rows("lb-narrow"), phone: rows("lb-phone") }
    r.endRoom = chart("lb").options.layout.padding.right

    // ---- legend keys mirror the marks ---------------------------------------------
    r.legend = {
      lines: chart("lines").legend.legendItems.map((i) => ({ text: i.text, stroke: i.strokeStyle, style: i.pointStyle, width: i.lineWidth })),
      bars: chart("lb").legend.legendItems.map((i) => ({ text: i.text, fill: i.fillStyle, width: i.lineWidth })),
      single: chart("bars").options.plugins.legend.display,
    }

    // ---- the number card's trend: decoration, no tooltip, no focus -------------------
    const trend = chart("sales-trend")
    r.trend = {
      tabindex: $("sales-trend-canvas").getAttribute("tabindex"),
      events: trend.options.events,
      external: trend.options.plugins.tooltip.external,
      fill: trend.data.datasets[0].fill,
      points: trend.data.datasets[0].pointRadius,
      legend: trend.options.plugins.legend.display,
      axes: [trend.options.scales.x.display, trend.options.scales.y.display],
    }

    // ---- keyboard: arrows show the tooltip and read it; Enter clicks --------------
    const key = (w, k) => w.dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true }))
    const lbBox = $("lb-canvas")
    lbBox.focus()
    key(lbBox, "ArrowDown")
    await frames()
    const tip = lbBox.querySelector(".chart-tooltip")
    r.keyboard = {
      tabindex: lbBox.getAttribute("tabindex"),
      role: lbBox.getAttribute("role"),
      open: tip.matches(":popover-open"),
      title: tip.querySelector(".chart-tooltip-title").textContent,
      rows: [...tip.querySelectorAll(".chart-tooltip-row")].map((row) => [row.querySelector(".chart-tooltip-name").textContent, row.querySelector(".chart-tooltip-value").textContent]),
      key: tip.querySelector(".chart-tooltip-key").style.getPropertyValue("--chart-key"),
      status: lbBox.querySelector("[data-slot=chart-status]").textContent,
    }
    key(lbBox, "ArrowDown")
    key(lbBox, "Enter")
    key(lbBox, "Escape")
    await frames()
    r.keyboard.closed = !tip.matches(":popover-open")

    const pBox = $("progress-canvas")
    pBox.focus()
    key(pBox, "ArrowRight")
    key(pBox, "ArrowRight")
    await frames()
    r.parts = pBox.querySelector("[data-slot=chart-status]").textContent
    key(pBox, " ")

    // ---- the pointer: a click on a part sends its key and series --------------------
    const clicks = []
    document.addEventListener("chart:click", (e) => clicks.push(e.detail))
    const part = el("progress", 3, 0).getProps(["x", "y", "base"], true)
    const box = chart("progress").canvas.getBoundingClientRect()
    chart("progress").canvas.dispatchEvent(new MouseEvent("click", { bubbles: true, clientX: box.left + (part.x + part.base) / 2, clientY: box.top + part.y }))
    await frames()
    r.pushed = pushed
    r.clicks = clicks

    // ---- LiveView changes the config: the same chart moves to the new data --------
    const before = chart("lines")
    const next = JSON.parse($("lines").dataset.config)
    next.data.labels = ["Thu", "Fri", "Sat", "Sun"]
    next.data.datasets[0].data = [20, 22, 21, 25]
    $("lines").dataset.config = JSON.stringify(next)
    ChartHooks.ShadcnChart.updated.call(hooks.lines)
    const motion = (c) => (c.options.animation === false ? false : c.options.animation.duration)
    r.update = { same: chart("lines") === before, labels: chart("lines").data.labels, data: chart("lines").data.datasets[0].data, color: chart("lines").data.datasets[1].borderColor, animation: motion(chart("lines")) }
    // a new type is a new chart
    next.type = "bar"
    window.__reduce = true
    $("lines").dataset.config = JSON.stringify(next)
    ChartHooks.ShadcnChart.updated.call(hooks.lines)
    r.retype = { same: chart("lines") === before, type: chart("lines").config.type, animation: motion(chart("lines")) }

    // ---- destroyed: the chart and its tooltip go -----------------------------------
    ChartHooks.ShadcnChart.destroyed.call(hooks.lb)
    r.destroyed = { chart: chartFor($("lb")), tip: !!$("lb-canvas").querySelector(".chart-tooltip") }

    await sleep(30)
    window.__result = JSON.stringify({ errors, violations: window.__violations, r })
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
    %{"errors" => errors, "violations" => violations, "r" => r} = run_in_chrome()
    %{errors: errors, violations: violations, r: r}
  end

  defp rgb(s),
    do:
      Regex.scan(~r/\d+(?:\.\d+)?/, s)
      |> List.flatten()
      |> Enum.map(&String.to_float(if &1 =~ ".", do: &1, else: &1 <> ".0"))

  defp close?(a, b), do: Enum.zip(a, b) |> Enum.all?(fn {x, y} -> abs(x - y) <= 1 end)

  test "no script errors and no CSP violations", %{errors: errors, violations: violations} do
    assert errors == []
    assert violations == []
  end

  test "series, grid, text and gaps come from the tokens, as rgb", %{r: r} do
    %{"light" => light} = r
    assert light["bar"] =~ ~r/^rgb\(\d+, \d+, \d+\)$/
    assert close?(rgb(light["bar"]), light["token"])
    # --border-color, --muted-foreground, the card behind the chart
    assert light["grid"] == "rgb(229, 229, 229)"
    assert light["ticks"] == "rgb(115, 115, 115)"
    assert light["surface"] == "rgb(255, 255, 255)"
    assert light["font"] =~ "system-ui"
  end

  test "Chart.js's colour library can't read oklch; from rgb it derives the hover shade", %{r: r} do
    assert r["kurkle"] == %{"oklch" => false, "rgb" => true}
    assert r["hover"] =~ ~r/^#[0-9a-f]{6}$/i
  end

  test "a series takes its slot, a dataset's color token, or one per bar or slice", %{r: r} do
    %{"lines" => [this, last], "pie" => pie, "parts" => parts} = r["series"]
    assert this == r["light"]["bar"]
    assert last == "rgb(115, 115, 115)"
    assert length(Enum.uniq(pie)) == 3
    assert hd(pie) == r["light"]["bar"]
    # chart-1, chart-1 at 65% and 35%, muted-foreground at 25%
    [c1, c65, c35, track] = parts
    assert c1 == r["light"]["bar"]
    assert c65 =~ ~r/^rgba\(.*, 0\.65\)$/
    assert c35 =~ ~r/^rgba\(.*, 0\.35\)$/
    assert track == "rgba(115, 115, 115, 0.25)"
  end

  test "the theme switches: every chart redraws from the dark tokens, and back", %{r: r} do
    %{"dark" => dark} = r
    assert close?(rgb(dark["bar"]), dark["token"])
    refute dark["bar"] == r["light"]["bar"]
    assert dark["grid"] == "rgba(255, 255, 255, 0.1)"
    # the dark card behind the chart
    assert dark["surface"] == "rgb(23, 23, 23)"
    assert r["back"] == r["light"]["bar"]
  end

  test "a brand theme's tokens apply to the charts under it", %{r: r} do
    assert r["brand"] == "rgb(255, 0, 0)"
    assert r["dark"]["brand"] == "rgb(255, 0, 0)"
  end

  test "bars: 24px at most, a 4px rounded data end, square at the baseline", %{r: r} do
    assert r["vertical"] == %{
             "radius" => %{"topLeft" => 4, "topRight" => 4, "bottomLeft" => 0, "bottomRight" => 0},
             "border" => 0,
             "width" => 24
           }
  end

  test "stacked parts: a 2px surface gap between them, the end rounded once", %{r: r} do
    assert r["stack"]["margin"] == %{
             "radius" => %{"topLeft" => 0, "topRight" => 0, "bottomLeft" => 0, "bottomRight" => 0},
             "border" => %{"top" => 0, "right" => 2, "bottom" => 0, "left" => 0}
           }

    assert r["stack"]["rest"] == %{
             "radius" => %{"topLeft" => 0, "topRight" => 4, "bottomLeft" => 0, "bottomRight" => 4},
             "border" => 0
           }

    assert r["stack"]["height"] == 24
  end

  test "a one-row stack with no value axis is a track: round at both ends, full width", %{r: r} do
    none = %{"topLeft" => 0, "topRight" => 0, "bottomLeft" => 0, "bottomRight" => 0}

    assert r["track"] == [
             %{none | "topLeft" => 4, "bottomLeft" => 4},
             none,
             none,
             %{none | "topRight" => 4, "bottomRight" => 4}
           ]

    assert r["trackFills"] == %{"start" => 0, "end" => 0}
  end

  test "end labels sit at the bar ends, above the bars when narrow, on two lines narrower", %{
    r: r
  } do
    # six rows of 36px; beside the names; room on the right for the labels
    assert r["labels"]["wide"] == %{
             "mode" => "end",
             "area" => 216,
             "ticks" => true,
             "thickness" => 24
           }

    assert r["endRoom"] > 150

    assert r["labels"]["narrow"] == %{
             "mode" => "above",
             "area" => 288,
             "ticks" => false,
             "thickness" => 16
           }

    assert r["labels"]["phone"] == %{
             "mode" => "stacked",
             "area" => 432,
             "ticks" => false,
             "thickness" => 12
           }
  end

  test "legend keys mirror the marks; one series has no legend", %{r: r} do
    [this, last] = r["legend"]["lines"]

    assert this == %{
             "text" => "This week",
             "stroke" => r["light"]["bar"],
             "style" => "line",
             "width" => 2
           }

    assert last["stroke"] == "rgb(115, 115, 115)"

    assert [%{"text" => "Margin", "width" => 0}, %{"text" => "Rest of the sale", "width" => 0}] =
             r["legend"]["bars"]

    assert r["legend"]["single"] == false
  end

  test "the number card's trend: a filled line, nothing else, no tooltip, no focus", %{r: r} do
    assert r["trend"] == %{
             "tabindex" => nil,
             "events" => [],
             "external" => nil,
             "fill" => "start",
             "points" => 0,
             "legend" => false,
             "axes" => [false, false]
           }
  end

  test "arrow keys show the tooltip, a popover, and the live region reads it", %{r: r} do
    assert %{
             "tabindex" => "0",
             "role" => "application",
             "open" => true,
             "title" => "Pat Lee",
             "rows" => [["Margin", "$9,310"], ["Rest of the sale", "$15,190"]],
             "status" => "Pat Lee: Margin $9,310, Rest of the sale $15,190",
             "closed" => true
           } = r["keyboard"]

    assert r["keyboard"]["key"] == r["light"]["bar"]
    # a single bar's parts, one at a time
    assert r["parts"] == "Today's appointments: Needs a result 3"
  end

  test "Enter and clicks push %{id, key, series, index}; target goes to pushEventTo", %{r: r} do
    assert r["pushed"] == [
             [
               "pushEvent",
               "open_person",
               %{"id" => "lb", "key" => "sam", "series" => nil, "index" => 1}
             ],
             [
               "pushEventTo",
               "#panel",
               "open_state",
               %{
                 "id" => "progress",
                 "key" => "Today's appointments",
                 "series" => "needs_result",
                 "index" => 0
               }
             ],
             [
               "pushEventTo",
               "#panel",
               "open_state",
               %{
                 "id" => "progress",
                 "key" => "Today's appointments",
                 "series" => "to_come",
                 "index" => 0
               }
             ]
           ]

    assert r["clicks"] == [
             %{
               "id" => "progress",
               "key" => "Today's appointments",
               "series" => "to_come",
               "index" => 0
             }
           ]
  end

  test "a new config moves the same chart; a new type makes a new one", %{r: r} do
    assert r["update"]["same"] == true
    assert r["update"]["labels"] == ~w(Thu Fri Sat Sun)
    assert r["update"]["data"] == [20, 22, 21, 25]
    assert r["update"]["color"] == "rgb(115, 115, 115)"
    assert r["update"]["animation"] == 300
    # reduced motion turns animation off
    assert r["retype"] == %{"same" => false, "type" => "bar", "animation" => false}
  end

  test "destroyed: the chart and its tooltip go", %{r: r} do
    assert r["destroyed"] == %{"chart" => nil, "tip" => false}
  end
end
