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

  defp leaderboard(people \\ @people) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(people, &elem(&1, 1)),
        keys: Enum.map(people, &elem(&1, 0)),
        datasets: [
          %{
            label: "Margin",
            key: "margin",
            data: Enum.map(people, &elem(&1, 3)),
            color: "chart-1"
          },
          %{
            label: "Rest of the sale",
            key: "rest",
            data: Enum.map(people, fn {_, _, s, m} -> s - m end),
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
              Enum.map(people, fn {_, _, s, m} ->
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

  # a progress row with its numbers on the parts; at 552px wide the 1 (5px)
  # is too narrow for its label
  defp segments(opts \\ []) do
    thick = Keyword.take(opts, [:maxBarThickness]) |> Map.new()

    parts = [
      {"Completed", 61, "chart-1"},
      {"Needs a result", 9, "chart-1/65"},
      {"In progress", 4, "chart-1/35"},
      {"Didn't happen", 1, "muted-foreground/50"},
      {"Still to come", 25, "muted-foreground/25"}
    ]

    %{
      type: "bar",
      data: %{
        labels: ["This week's appointments"],
        datasets:
          Enum.map(parts, fn {label, n, color} ->
            Map.merge(%{label: label, data: [n], color: color}, thick)
          end)
      },
      options: %{
        indexAxis: "y",
        scales: %{
          x: %{stacked: true, display: false, max: 100},
          y: %{stacked: true, display: false}
        },
        plugins: %{segmentLabels: true}
      }
    }
  end

  # stacked columns: a 3-digit value is too wide for a 24px bar, a short part too low
  @columns %{
    type: "bar",
    data: %{
      labels: ~w(Mon Tue Wed),
      datasets: [
        %{label: "Done", data: [40, 3, 100]},
        %{label: "Open", data: [20, 30, 2]}
      ]
    },
    options: %{
      scales: %{x: %{stacked: true}, y: %{stacked: true}},
      plugins: %{segmentLabels: true}
    }
  }

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
    above = put_in(leaderboard(), [:options, :plugins, :endLabels, :position], "above")
    one = leaderboard(Enum.take(@people, 1))
    one = put_in(one, [:options, :plugins, :endLabels, :position], "above")
    # an app that padded the top itself, before the kit made room
    padded = put_in(above, [:options, :layout], %{padding: %{top: 12}})

    assigns = %{
      lb: leaderboard(),
      above: above,
      one: one,
      padded: padded,
      progress: progress(),
      seg: segments(),
      seg_thin: segments(maxBarThickness: 12),
      columns: @columns,
      bars: @bars,
      lines: @lines,
      pie: @pie
    }

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
    <div class="card" style="width: 900px; padding: 24px">
      <.chart id="lb-above" label="Leaderboard" config={@above} />
    </div>
    <div class="card" style="width: 200px; padding: 24px">
      <.chart id="lb-above-phone" label="Leaderboard" config={@above} />
    </div>
    <div class="card" style="width: 900px; padding: 24px">
      <.chart id="lb-above-one" label="Leaderboard" config={@one} />
    </div>
    <div class="card" style="width: 900px; padding: 24px">
      <.chart id="lb-above-padded" label="Leaderboard" config={@padded} />
    </div>
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="progress" label="Today's appointments" config={@progress} on_click="open_state" target="#panel" />
    </div>
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="seg" label="This week's appointments" config={@seg} />
    </div>
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="seg-thin" label="This week's appointments" config={@seg_thin} />
    </div>
    <div class="card" style="width: 250px; padding: 24px">
      <.chart id="seg-phone" label="This week's appointments" config={@seg} />
    </div>
    <div class="card" style="width: 250px; padding: 24px">
      <.chart id="progress-phone" label="Today's appointments" config={@progress} />
    </div>
    <div class="card" style="width: 600px; padding: 24px">
      <.chart id="seg-columns" label="Tasks by day" config={@columns} />
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
    <div style="width: 300px">
      <.number_card id="edges" label="Edges" value="18" trend={[18, 6, 9, 7, 18]}>
        <:change vs="vs PP" by="+$8,000" percent="+24%" direction="up" />
        <:change vs="vs PY" percent="-3%" direction="down" />
        <:change vs="vs plan" by="$0" direction="flat" />
      </.number_card>
    </div>
    <div style="width: 300px">
      <.number_card id="flat" label="Flat" value="37%" trend={[37, 37, 37, 37, 37, 37, 37, 37]} />
    </div>
    <div style="width: 300px">
      <.number_card id="wiggle" label="Wiggle" value="37%" trend={[37, 37, 37, 36, 37, 37, 37, 37]} />
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
    const hooks = Object.fromEntries(["lb", "progress", "lines", "seg"].map((id) => {
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
    // WCAG contrast of two colours, each painted over the one under it
    const over = (...layers) => { px.clearRect(0, 0, 1, 1); for (const c of layers) { px.fillStyle = c; px.fillRect(0, 0, 1, 1) } return [...px.getImageData(0, 0, 1, 1).data].slice(0, 3) }
    const lum = (rgb) => rgb.map((c) => (c /= 255) <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4).reduce((s, c, i) => s + c * [0.2126, 0.7152, 0.0722][i], 0)
    const contrast = (a, b) => { const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x); return Math.round(((hi + 0.05) / (lo + 0.05)) * 100) / 100 }
    // the number card's change badges: text on its fill, the border against the card
    const badges = () => {
      const card = getComputedStyle($("edges")).backgroundColor
      const line = getComputedStyle(document.documentElement).getPropertyValue("--border-color")
      const out = { line: contrast(over(card, line), over(card)) }
      const pick = { vs: ".number-card-vs", good: '[data-tone="good"]', bad: '[data-tone="bad"]', neutral: '[data-tone="neutral"]' }
      for (const [name, sel] of Object.entries(pick)) {
        const cs = getComputedStyle(document.querySelector(`#edges ${sel}`))
        out[name] = {
          text: contrast(over(card, cs.backgroundColor, cs.color), over(card, cs.backgroundColor)),
          border: contrast(over(card, cs.borderTopColor), over(card)),
          fill: contrast(over(card, cs.backgroundColor), over(card)),
        }
      }
      return out
    }
    // the topmost inked row of a canvas, per column or over the whole canvas
    const inkTops = (c) => {
      const cv = c.canvas
      const d = cv.getContext("2d").getImageData(0, 0, cv.width, cv.height).data
      return Array.from({ length: cv.width }, (_, x) => {
        let y = 0
        while (y < cv.height && !d[(y * cv.width + x) * 4 + 3]) y++
        return y
      })
    }
    // a trend's shape: where its peak sits (a share of the canvas height) and
    // how far the line's top edge travels up and down
    const trendShape = (id) => {
      const c = chart(id)
      c.update("none")
      const values = c.data.datasets[0].data.filter(Number.isFinite)
      const tops = inkTops(c)
      return {
        height: c.canvas.height,
        peak: c.scales.y.getPixelForValue(Math.max(...values)) / c.canvas.height,
        ink: [Math.min(...tops), Math.max(...tops)],
      }
    }
    const trends = () => Object.fromEntries(["edges", "flat", "wiggle"].map((id) => [id, trendShape(`${id}-trend`)]))
    // labels above the bars: the room over the first row, and where the ink starts
    const aboveRoom = (id) => {
      const c = chart(id)
      c.update("none")
      return {
        mode: c.$kit.labelMode,
        top: c.chartArea.top,
        area: Math.round(c.chartArea.bottom - c.chartArea.top),
        height: c.height,
        ink: Math.min(...inkTops(c)),
      }
    }
    const above = () => Object.fromEntries(["lb-above", "lb-above-phone", "lb-above-one", "lb-above-padded"].map((id) => [id, aboveRoom(id)]))
    // segment labels: the canvas with and without them, compared - each inked
    // pixel should sit inside the part whose label it is, clear of its edges
    const segmentInk = (id) => {
      const c = chart(id)
      c.update("none")
      const read = () => c.ctx.getImageData(0, 0, c.canvas.width, c.canvas.height).data
      const on = read()
      c.$kit.segmentLabels = false
      c.draw()
      const off = read()
      c.$kit.segmentLabels = true
      c.draw()
      const dpr = c.currentDevicePixelRatio
      const horizontal = c.$kit.indexAxis === "y"
      const boxes = c.$kit.segments.map((s) => {
        const p = c.getDatasetMeta(s.datasetIndex).data[s.index].getProps(["x", "y", "base", "width", "height"], true)
        const [l, rt] = horizontal ? [Math.min(p.x, p.base), Math.max(p.x, p.base)] : [p.x - p.width / 2, p.x + p.width / 2]
        const [t, b] = horizontal ? [p.y - p.height / 2, p.y + p.height / 2] : [Math.min(p.y, p.base), Math.max(p.y, p.base)]
        return { l: (l + 2) * dpr, r: (rt - 2) * dpr, t: (t + 2) * dpr, b: (b - 2) * dpr, ink: 0 }
      })
      let outside = 0
      const w = c.canvas.width
      for (let k = 0; k < on.length; k += 4) {
        if (on[k] === off[k] && on[k + 1] === off[k + 1] && on[k + 2] === off[k + 2] && on[k + 3] === off[k + 3]) continue
        const x = ((k / 4) % w) + 0.5
        const y = Math.floor(k / 4 / w) + 0.5
        const box = boxes.find((bx) => x >= bx.l && x <= bx.r && y >= bx.t && y <= bx.b)
        box ? box.ink++ : outside++
      }
      return { drawn: c.$kit.segments.map((s) => s.text), ink: boxes.map((bx) => bx.ink), outside }
    }
    // each segment label's text against its part's fill, over the card
    const segColours = (id) => {
      const card = getComputedStyle($(id).closest(".card")).backgroundColor
      return chart(id).$kit.segments.map((s) => ({ text: s.text, fill: s.fill, color: s.color, ratio: contrast(over(card, s.fill, s.color), over(card, s.fill)) }))
    }
    const segs = () => Object.fromEntries(["seg", "seg-columns"].map((id) => [id, segColours(id)]))

    // ---- colours come from the tokens, as rgb ----------------------------------
    const lightBar = opts("bars", 0, 0).backgroundColor
    r.light = {
      badges: badges(),
      trends: trends(),
      above: above(),
      segs: segs(),
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
      badges: badges(),
      trends: trends(),
      above: above(),
      segs: segs(),
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

    // ---- segment labels: what fits, a resize, a hovered (darker) part, the legend --
    r.segInk = { seg: segmentInk("seg"), columns: segmentInk("seg-columns"), thin: segmentInk("seg-thin") }
    r.segOff = { on: chart("progress").$kit.segmentLabels, drawn: chart("progress").$kit.segments }
    const segCard = $("seg").closest(".card")
    segCard.style.width = "300px"
    await sleep(150)
    await frames()
    r.segResize = { narrow: segmentInk("seg") }
    segCard.style.width = "600px"
    await sleep(150)
    await frames()
    r.segResize.wide = segmentInk("seg")
    const sc = chart("seg")
    sc.setActiveElements(sc.data.datasets.map((_, j) => ({ datasetIndex: j, index: 0 })))
    sc.update("none")
    await sleep(500)
    await frames()
    r.segHover = segColours("seg")
    sc.setActiveElements([])
    sc.update("none")
    await sleep(500)
    // a phone: the legend wraps, and the one-row chart grows to hold every line
    const legendFit = (id) => {
      const c = chart(id)
      const lg = c.legend
      return {
        lines: lg.lineWidths.length,
        items: lg.legendItems.length,
        inside: lg.legendHitBoxes.every((h) => h.top >= 0 && h.top + h.height <= c.height),
        area: Math.round(c.chartArea.bottom - c.chartArea.top),
      }
    }
    r.phoneLegend = { seg: legendFit("seg-phone"), progress: legendFit("progress-phone") }
    r.segLegend = {
      seg: sc.legend.legendItems.map((i) => i.text),
      thin: chart("seg-thin").legend.legendItems.map((i) => i.text),
      columns: chart("seg-columns").legend.legendItems.map((i) => i.text),
      progress: chart("progress").legend.legendItems.map((i) => i.text),
      labels: sc.data.datasets.map((d) => d.label),
    }

    // ---- end labels and rows --------------------------------------------------
    const rows = (id) => { const c = chart(id); return { mode: c.$kit.labelMode, area: Math.round(c.chartArea.bottom - c.chartArea.top), ticks: c.options.scales.y.ticks.display !== false, thickness: Math.round(el(id, 0, 0).height) } }
    r.labels = { wide: rows("lb"), narrow: rows("lb-narrow"), phone: rows("lb-phone"), above: rows("lb-above"), abovePhone: rows("lb-above-phone") }
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

    // ---- a trend runs edge to edge: peaks at both ends, the fill to each side --------
    const edges = chart("edges-trend")
    edges.update("none")
    const ec = edges.canvas
    const pixels = ec.getContext("2d").getImageData(0, 0, ec.width, ec.height).data
    const alpha = (x, y) => pixels[(y * ec.width + x) * 4 + 3]
    const painted = (x) => { let n = 0; for (let y = 0; y < ec.height; y++) if (alpha(x, y)) n++; return n }
    const top = (x) => { let y = 0; while (y < ec.height && !alpha(x, y)) y++; return y }
    r.edges = {
      autoPadding: edges.options.layout.autoPadding,
      area: [edges.chartArea.left, edges.chartArea.top, edges.width - edges.chartArea.right, edges.height - edges.chartArea.bottom],
      height: ec.height,
      columns: [[top(0), painted(0)], [top(ec.width - 1), painted(ec.width - 1)]],
      foot: [alpha(0, ec.height - 1), alpha(ec.width - 1, ec.height - 1)],
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
    // new data under reduced motion: the segment labels are where they end up at once
    const segNext = JSON.parse($("seg").dataset.config)
    segNext.data.datasets[3].data = [10]
    segNext.data.datasets[4].data = [16]
    $("seg").dataset.config = JSON.stringify(segNext)
    ChartHooks.ShadcnChart.updated.call(hooks.seg)
    r.segUpdate = { drawn: chart("seg").$kit.segments.map((s) => s.text), legend: chart("seg").legend.legendItems.map((i) => i.text), animation: motion(chart("seg")) }

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

  test "position: \"above\" keeps the end labels above the bars at every width", %{r: r} do
    # as wide as the leaderboard that labels its bar ends, but above, side by side
    assert r["labels"]["above"] == r["labels"]["narrow"]
    # still on two lines when the name and label don't fit side by side
    assert r["labels"]["abovePhone"] == r["labels"]["phone"]
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

  test "a trend runs edge to edge: no strip at the sides or the foot, a peak keeps its line",
       %{r: r} do
    e = r["edges"]
    assert e["autoPadding"] == false
    # left, top, right, bottom: only the top keeps half the 2px line
    assert e["area"] == [0, 1, 0, 0]
    # the first and last columns hold the peaks' line and the fill under it, unbroken down
    # to the foot (with auto padding they held only the line's round cap: 4px)
    for [top, painted] <- e["columns"] do
      assert painted == e["height"] - top, inspect(e)
      assert painted > e["height"] / 2, inspect(e)
    end

    assert Enum.all?(e["foot"], &(&1 > 0)), inspect(e)
  end

  test "change badges: text 4.5:1 on its fill, a border stronger than the card's own line",
       %{r: r} do
    for mode <- ["light", "dark"], b = r[mode]["badges"], tone <- ~w(vs good bad neutral) do
      badge = b[tone]
      msg = "#{mode} #{tone}: #{inspect(b)}"
      assert badge["text"] >= 4.5, msg
      # edged in its own tone: the border stands out from the card more than the
      # card's border colour does, and more than the badge's own fill
      assert badge["border"] > b["line"], msg
      assert badge["border"] > badge["fill"], msg
    end
  end

  test "a trend's peak sits a sixth below the top, whatever its values; flat is level",
       %{r: r} do
    for mode <- ["light", "dark"], t = r[mode]["trends"] do
      msg = "#{mode}: #{inspect(t, pretty: true)}"

      # the same headroom over every peak, not wherever nice ticks land
      for {_id, shape} <- t, do: assert(shape["peak"] > 0.15 and shape["peak"] < 0.2, msg)

      # nothing drawn at the top edge: the line's highest point has room above it
      for {_id, shape} <- t, do: assert(hd(shape["ink"]) >= shape["height"] * 0.1, msg)

      # a flat series is a level line, and a 1-point wiggle on 37 a gentle one
      [top, bottom] = t["flat"]["ink"]
      assert bottom - top <= 1, msg
      [top, bottom] = t["wiggle"]["ink"]
      assert bottom - top < t["wiggle"]["height"] * 0.15, msg
    end
  end

  test "labels above the bars have room over the first row: one row or many, light and dark",
       %{r: r} do
    rows = %{
      "lb-above" => {"above", 6, 48},
      "lb-above-phone" => {"stacked", 6, 72},
      "lb-above-one" => {"above", 1, 48},
      # the server's own 12px counts toward the 16px: the larger wins, never both
      "lb-above-padded" => {"above", 6, 48}
    }

    for mode <- ["light", "dark"], {id, {layout, n, row}} <- rows do
      l = r[mode]["above"][id]
      msg = "#{mode} #{id}: #{inspect(l)}"
      assert l["mode"] == layout, msg
      # the font size (12px) plus the 4px gap over the first bar
      assert l["top"] == 16, msg
      assert l["area"] == n * row, msg
      # the canvas holds the rows and that room
      assert l["height"] >= l["top"] + l["area"], msg
      # the first row's text starts well under the canvas's top edge
      assert l["ink"] >= 8, msg
    end
  end

  test "segment labels: each part's value centred in it when it fits, none when it doesn't",
       %{r: r} do
    %{"seg" => seg, "columns" => columns, "thin" => thin} = r["segInk"]
    # 61, 9, 4 and 25 fit; the 1 (5px wide) has no label rather than spilling over
    assert seg["drawn"] == ["61", "9", "4", "25"], inspect(seg)
    # columns: the 3-digit 100 is wider than a 24px bar, the 3 and the 2 too low
    assert columns["drawn"] == ["40", "20", "30"], inspect(columns)

    # every inked pixel sits inside its own part, clear of the edges: nothing
    # spills into a neighbour and nothing is cut off
    for ink <- [seg, columns] do
      assert ink["outside"] == 0, inspect(ink)
      assert Enum.all?(ink["ink"], &(&1 > 10)), inspect(ink)
    end

    # a bar under 16px thick has no labels, however wide its parts
    assert thin == %{"drawn" => [], "ink" => [], "outside" => 0}
    # no option, no labels
    assert r["segOff"] == %{"on" => false, "drawn" => []}
  end

  test "segment labels re-fit on a resize: a part's label hides when narrow, shows again",
       %{r: r} do
    %{"narrow" => narrow, "wide" => wide} = r["segResize"]
    # at 252px the 4 is 10px wide: no label; the 9 (22px) still has one
    assert narrow["drawn"] == ["61", "9", "25"], inspect(narrow)
    assert narrow["outside"] == 0, inspect(narrow)
    assert wide["drawn"] == ["61", "9", "4", "25"], inspect(wide)
    assert wide["outside"] == 0, inspect(wide)
  end

  test "segment label text is 4.5:1 on its part's fill, light, dark and hovered", %{r: r} do
    sets = [
      {"light", r["light"]["segs"]["seg"]},
      {"light columns", r["light"]["segs"]["seg-columns"]},
      {"dark", r["dark"]["segs"]["seg"]},
      {"dark columns", r["dark"]["segs"]["seg-columns"]},
      {"hovered", r["segHover"]}
    ]

    for {name, labels} <- sets do
      assert labels != [], name

      for l <- labels,
          do: assert(l["ratio"] >= 4.5, "#{name}: #{inspect(labels, pretty: true)}")
    end

    # the hovered parts are darker fills, not the resting ones
    refute Enum.map(r["segHover"], & &1["fill"]) ==
             Enum.map(r["light"]["segs"]["seg"], & &1["fill"])
  end

  test "segment labels on a one-row stack: the legend gives each part's number", %{r: r} do
    l = r["segLegend"]

    assert l["seg"] == [
             "Completed 61",
             "Needs a result 9",
             "In progress 4",
             "Didn't happen 1",
             "Still to come 25"
           ]

    # with no room for the labels, the legend still has every number
    assert l["thin"] == l["seg"]
    # several rows: the legend keeps the names; without the option too
    assert l["columns"] == ["Done", "Open"]
    assert l["progress"] == ["Resulted", "Needs a result", "In progress", "Still to come"]
    # the datasets keep their names: the tooltip and the table are unchanged
    assert hd(l["labels"]) == "Completed"
  end

  test "a one-row chart grows for a legend that wraps: every part's number stays on screen",
       %{r: r} do
    for {id, l} <- r["phoneLegend"] do
      # Chart.js caps a legend at half the canvas: on a 36px row that kept one line
      assert l["lines"] > 1, "#{id}: #{inspect(l)}"
      assert l["inside"], "#{id}: #{inspect(l)}"
      assert l["area"] == 36, "#{id}: #{inspect(l)}"
    end

    assert r["phoneLegend"]["seg"]["items"] == 5
  end

  test "segment labels follow new data; under reduced motion at once", %{r: r} do
    assert r["segUpdate"] == %{
             "drawn" => ["61", "9", "4", "10", "16"],
             "legend" => [
               "Completed 61",
               "Needs a result 9",
               "In progress 4",
               "Didn't happen 10",
               "Still to come 16"
             ],
             "animation" => false
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
