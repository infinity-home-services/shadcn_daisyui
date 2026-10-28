// shadcn-daisyui charts - the optional chart kit: <.chart> and <.number_card>.
// A separate entry so apps without charts load nothing new:
//   • Phoenix LiveView: import { ChartHooks } from "shadcn_daisyui/charts"
//                       new LiveSocket(..., { hooks: { ...Hooks, ...ChartHooks } })
//   • Dead views:       import { initCharts } from "shadcn_daisyui/charts"; initCharts()
//
// One hook (ShadcnChart) draws every chart. The server sends an ordinary
// Chart.js config (type, data, options) in the figure's data-config; the hook
// adds the look from the theme tokens (series colours, text, grid lines, the
// font, a popover-styled tooltip) and updates the same chart in place when
// LiveView changes the config. See ShadcnDaisyui.Components.Chart.
//
// Chart.js 4.6.1 ships beside this file (vendor/, see vendor/README.md): no
// CDN, nothing fetched at runtime.
import { Chart, registerables } from "./vendor/chart.js/chart.js"

Chart.register(...registerables)

const PIE = new Set(["pie", "doughnut", "polarArea"])
const RADIAL = new Set(["radar", "polarArea"])
const LINE = new Set(["line", "radar"])
const SERIES = 5 // --chart-1 … --chart-5

// The theme colour tokens a dataset's `color` may name: chart-1…5 plus a few
// roles (emphasis = one series in colour, the rest muted).
const TOKENS = {
  foreground: "--foreground",
  "muted-foreground": "--muted-foreground",
  muted: "--muted",
  border: "--border-color",
  primary: "--primary",
  secondary: "--secondary",
  accent: "--accent",
  destructive: "--destructive",
  success: "--color-success",
  warning: "--color-warning",
  info: "--color-info",
  error: "--color-error",
}
for (let i = 1; i <= SERIES; i++) TOKENS[`chart-${i}`] = `--chart-${i}`

const charts = new Set() // live chart apis, for theme and motion changes
const reducedMotion = () => typeof matchMedia === "function" && matchMedia("(prefers-reduced-motion: reduce)").matches

// ---- Colours ----------------------------------------------------------------
// The tokens are oklch (or whatever a brand theme writes: hex, color-mix…).
// Chart.js works out hover shades with @kurkle/color, which reads hex, rgb,
// hsl and hwb but not oklch, so every colour goes through the browser first:
// a probe element resolves var(), color-mix and the rest into a computed
// colour, and a 1×1 canvas turns that into sRGB bytes. The alpha is read from
// the computed colour and the pixel drawn opaque, since a translucent pixel
// keeps too little of its colour (white at 10% reads back as 245, 255, 255).
let pixel
const ALPHA_SLASH = /\/\s*([\d.]+)(%?)\s*\)\s*$/ // oklch(… / 0.1), color(srgb … / 0.3)
const ALPHA_COMMA = /^rgba?\(([^,]+,[^,]+,[^,]+),\s*([\d.]+)(%?)\s*\)$/ // rgba(r, g, b, 0.1)
function rgba(css) {
  if (!pixel) {
    const c = document.createElement("canvas")
    c.width = c.height = 1
    pixel = c.getContext("2d", { willReadFrequently: true })
  }
  let alpha = 1
  let opaque = css
  let m
  if ((m = css.match(ALPHA_SLASH))) {
    alpha = Number(m[1]) / (m[2] ? 100 : 1)
    opaque = css.replace(ALPHA_SLASH, ")")
  } else if ((m = css.match(ALPHA_COMMA))) {
    alpha = Number(m[2]) / (m[3] ? 100 : 1)
    opaque = `rgb(${m[1]})`
  }
  pixel.clearRect(0, 0, 1, 1)
  pixel.fillStyle = "rgba(0, 0, 0, 0)"
  pixel.fillStyle = opaque
  pixel.fillRect(0, 0, 1, 1)
  const [r, g, b, a] = pixel.getImageData(0, 0, 1, 1).data
  return { r, g, b, a: alpha * (a / 255) }
}
const css = ({ r, g, b, a }, alpha = 1) => {
  const o = Math.round(a * alpha * 1000) / 1000
  return o >= 1 ? `rgb(${r}, ${g}, ${b})` : `rgba(${r}, ${g}, ${b}, ${o})`
}

// Reads the tokens as they apply to this chart (so a brand theme on an
// ancestor counts), its surface (the first opaque background behind it: a
// card, a sheet, the page) and its font.
function readTheme(el) {
  const probe = document.createElement("span")
  probe.hidden = true
  el.appendChild(probe)
  const resolved = {}
  for (const [name, v] of Object.entries(TOKENS)) {
    probe.style.color = ""
    probe.style.color = `var(${v})`
    resolved[name] = rgba(getComputedStyle(probe).color)
  }
  probe.remove()
  let surface = null
  for (let n = el; n && n.nodeType === 1 && !surface; n = n.parentElement) {
    const bg = rgba(getComputedStyle(n).backgroundColor)
    if (bg.a > 0.99) surface = bg
  }
  if (!surface) surface = rgba(getComputedStyle(document.body).backgroundColor)
  if (surface.a < 0.99) surface = { r: 255, g: 255, b: 255, a: 1 }
  const style = getComputedStyle(el)
  return {
    // "chart-1", "muted", "chart-1/40" (40% opacity) -> a colour Chart.js reads
    color(spec, alpha = 1) {
      const [name, pct] = String(spec || "").split("/")
      const c = resolved[name.trim()] || resolved["muted-foreground"]
      return css(c, alpha * (pct ? Number(pct) / 100 : 1))
    },
    text: css(resolved.foreground),
    muted: css(resolved["muted-foreground"]),
    grid: css(resolved.border),
    crosshair: css(resolved["muted-foreground"], 0.5),
    surface: css(surface),
    font: style.fontFamily || "system-ui, sans-serif",
    key: JSON.stringify([resolved, surface, style.fontFamily]),
  }
}

let warnedSeries = false
function seriesToken(i) {
  if (i < SERIES) return `chart-${i + 1}`
  if (!warnedSeries) {
    warnedSeries = true
    console.warn(`shadcn charts: more than ${SERIES} series - fold the rest into "Other"; the extra ones are muted`)
  }
  return "muted-foreground"
}

// ---- Helpers ----------------------------------------------------------------
const isPlain = (v) => v !== null && typeof v === "object" && !Array.isArray(v)
function merge(base, over) {
  if (!isPlain(over)) return over === undefined ? base : over
  const out = isPlain(base) ? { ...base } : {}
  for (const [k, v] of Object.entries(over)) out[k] = merge(out[k], v)
  return out
}
const dig = (obj, ...path) => path.reduce((o, k) => (o == null ? undefined : o[k]), obj)

const formats = new Map()
function numberFormat(locale, options) {
  const key = JSON.stringify([locale, options])
  if (!formats.has(key)) {
    try {
      formats.set(key, new Intl.NumberFormat(locale, options))
    } catch {
      formats.set(key, new Intl.NumberFormat(locale))
    }
  }
  return formats.get(key)
}

// Value-axis ticks: the axis's ticks.format (Chart.js's Intl options),
// compacted from 1,000 up ($25K). Tooltips keep the full value.
function compactTick(value) {
  const fmt = { ...(this.options.ticks.format || {}) }
  if (Math.abs(value) >= 1000) {
    fmt.notation = "compact"
    delete fmt.minimumFractionDigits
    delete fmt.maximumFractionDigits
  }
  return numberFormat(this.chart.options.locale, fmt).format(value)
}

let measureCtx
function textWidth(text, font) {
  if (!measureCtx) measureCtx = document.createElement("canvas").getContext("2d")
  measureCtx.font = font
  return measureCtx.measureText(String(text)).width
}
const fontString = (size, family, weight = 400) => `${weight} ${size}px ${family}`

// ---- Building the config -------------------------------------------------------
// The server's config plus the look. Server options win (they can hide an
// axis, stack, set ticks.format); colours come from the tokens.
function build(api) {
  const { el, cfg } = api
  const theme = readTheme(el)
  const type = cfg.type || "bar"
  const data = cfg.data || {}
  const labels = data.labels || []
  const sets = data.datasets || []
  const server = cfg.options || {}
  const indexAxis = server.indexAxis === "y" ? "y" : "x"
  const valueAxis = indexAxis === "x" ? "y" : "x"
  const pieLike = PIE.has(type)
  const radial = RADIAL.has(type)
  const cartesian = !pieLike && !radial
  const trend = el.dataset.variant === "trend"
  const horizontalBars = type === "bar" && indexAxis === "y"
  const stacked = cartesian && !!dig(server, "scales", valueAxis, "stacked")
  const valueAxisShown = dig(server, "scales", valueAxis, "display") !== false
  const endLabels = dig(server, "plugins", "endLabels", "labels")
  const tooltipOn = !trend && dig(server, "plugins", "tooltip") !== false && dig(server, "plugins", "tooltip", "enabled") !== false
  const series = pieLike ? labels.length : sets.length
  const fontSize = 12

  // end labels sit after each bar's end ("end"); when that leaves the bars
  // too little room (a phone), the name and the label move above the bar,
  // side by side ("above") or, narrower still, on two lines ("stacked")
  let labelMode = null
  let labelRoom = 0
  let widths = null
  if (type === "bar" && Array.isArray(endLabels) && endLabels.length) {
    const labelFont = fontString(fontSize, theme.font)
    labelRoom = Math.ceil(Math.max(...endLabels.map((t) => textWidth(t || "", labelFont)))) + 8
    if (horizontalBars) {
      const name = Math.max(0, ...labels.map((t) => textWidth(t, fontString(fontSize, theme.font, 500))))
      // beside their labels, the bars keep at least half the width (and 120px);
      // position: "above" keeps them above at every width
      const text = name + 8 + labelRoom
      const above = dig(server, "plugins", "endLabels", "position") === "above"
      widths = { end: above ? Infinity : Math.max(text + 120, text * 2), above: name + 16 + labelRoom }
      labelMode = labelLayout(widths, api.wrapper.clientWidth || el.clientWidth || 600)
    } else {
      labelMode = "end"
    }
  }
  const aboveBars = labelMode === "above" || labelMode === "stacked"

  const datasets = sets.map((raw, i) => {
    const { color, key, ...ds } = raw
    const t = ds.type || type
    const per = Array.isArray(color)
    const token = per ? null : color || (pieLike ? null : seriesToken(i))
    const pointColors = (alpha = 1) =>
      (per ? color : labels.map((_, j) => seriesToken(j))).map((c) => theme.color(c, alpha))
    const c = token ? theme.color(token) : null
    if (PIE.has(t)) {
      return {
        backgroundColor: pointColors(t === "polarArea" ? 0.6 : 1),
        borderColor: theme.surface,
        borderWidth: 2,
        hoverBorderColor: theme.surface,
        hoverOffset: t === "polarArea" ? 0 : 4,
        ...ds,
      }
    }
    if (LINE.has(t)) {
      const fillAlpha = trend ? 0.25 : 0.1
      return {
        borderColor: c,
        backgroundColor: token ? theme.color(token, fillAlpha) : pointColors(fillAlpha),
        borderWidth: 2,
        borderCapStyle: "round",
        borderJoinStyle: "round",
        cubicInterpolationMode: "monotone",
        pointRadius: 0,
        pointHoverRadius: 4,
        pointBackgroundColor: c,
        pointBorderColor: theme.surface,
        pointBorderWidth: 2,
        pointHoverBorderWidth: 2,
        pointHitRadius: 12,
        ...ds,
      }
    }
    if (t === "scatter" || t === "bubble") {
      return {
        backgroundColor: c,
        borderColor: theme.surface,
        borderWidth: 2,
        pointRadius: 5,
        pointHoverRadius: 6,
        pointHitRadius: 12,
        ...ds,
      }
    }
    // bars: thin (24px at most, 16px when the label sits above), a 4px
    // rounded data end and a square baseline; stacked parts are parted by a
    // 2px gap in the surface colour
    return {
      backgroundColor: per ? pointColors() : c,
      borderColor: theme.surface,
      borderWidth: (ctx) => barBorder(ctx),
      borderRadius: (ctx) => barRadius(ctx),
      borderSkipped: false,
      maxBarThickness: labelMode === "stacked" ? 12 : labelMode === "above" ? 16 : 24,
      ...ds,
    }
  })

  const scales = {}
  if (cartesian) {
    scales[valueAxis] = {
      beginAtZero: type === "bar",
      grid: { color: theme.grid, drawTicks: false },
      border: { display: false },
      ticks: { color: theme.muted, padding: 8, maxTicksLimit: 6, callback: compactTick },
    }
    scales[indexAxis] = {
      grid: { display: false },
      border: { display: false },
      ticks: { color: theme.muted, padding: 8, maxRotation: 0, autoSkipPadding: 12 },
    }
    if (aboveBars) scales[indexAxis].ticks.display = false
  } else if (radial) {
    scales.r = {
      grid: { color: theme.grid },
      angleLines: { color: theme.grid },
      pointLabels: { color: theme.muted, font: { size: fontSize } },
      ticks: { color: theme.muted, backdropColor: "rgba(0, 0, 0, 0)", showLabelBackdrop: false, maxTicksLimit: 5 },
    }
  }

  const padding = { top: 0, right: 0, bottom: 0, left: 0 }
  if (labelMode === "end" && horizontalBars) padding.right = labelRoom
  if (labelMode === "end" && !horizontalBars) padding.top = fontSize + 8
  if (!trend && cartesian && !valueAxisShown && !stacked) padding.top = Math.max(padding.top, 4)
  // a trend runs edge to edge: Chart.js's auto padding (room for a hover
  // point and half the line) would leave a strip inside the card's border,
  // so it's off and only the top keeps half the line, so a peak isn't shaved
  if (trend) padding.top = Math.max(0, ...datasets.map((d) => (typeof d.borderWidth === "number" ? d.borderWidth : 0))) / 2

  const base = {
    responsive: true,
    maintainAspectRatio: false,
    animation: reducedMotion() ? false : { duration: 300 },
    color: theme.muted,
    borderColor: theme.grid,
    font: { family: theme.font, size: fontSize },
    layout: { padding, autoPadding: !trend },
    interaction: cartesian ? { mode: "index", intersect: false, axis: indexAxis } : { mode: "nearest", intersect: true },
    plugins: {
      legend: {
        display: series > 1 && !trend,
        position: "bottom",
        labels: {
          color: theme.text,
          usePointStyle: true,
          pointStyle: LINE.has(type) ? "line" : "rectRounded",
          boxWidth: 8,
          boxHeight: 8,
          padding: 16,
          font: { size: fontSize },
          generateLabels: legendLabels,
        },
      },
      tooltip: { enabled: false },
    },
    scales,
  }
  const options = merge(base, server)
  // the canvas tooltip never draws: the popover-styled one does (or nothing)
  options.plugins.tooltip = { ...options.plugins.tooltip, enabled: false, external: tooltipOn ? externalTooltip : null }
  options.onResize = onResize
  if (trend) options.events = []
  const clickable = !!el.dataset.onClick && !trend
  if (clickable) {
    options.onClick = onClick
    options.onHover = (e, active, chart) => {
      chart.canvas.style.cursor = active.length ? "pointer" : ""
    }
  }

  const kit = {
    api,
    theme,
    type,
    indexAxis,
    valueAxis,
    pieLike,
    cartesian,
    stacked,
    // one stacked bar with no value axis (a progress row): no baseline, so it
    // rounds at both ends, like a track
    track: stacked && !valueAxisShown && labels.length === 1,
    endLabels: labelMode ? endLabels : null,
    labelMode,
    labelWidths: widths,
    labelFont: fontString(fontSize, theme.font),
    nameFont: fontString(fontSize, theme.font, 500),
    rowHeight: horizontalBars ? ROW_HEIGHT[labelMode] || ROW_HEIGHT.end : null,
    crosshair: tooltipOn && LINE.has(type) && cartesian,
    tooltipOn,
    clickable,
    keys: Array.isArray(data.keys) ? data.keys : labels,
    seriesKeys: sets.map((ds, i) => (ds.key != null ? ds.key : ds.label != null ? ds.label : i)),
    themeKey: theme.key,
  }
  return { type, data: { labels, datasets }, options, kit }
}

// Legend keys mirror the marks: a line for a line, a rounded box for a bar or
// a slice. Chart.js styles a point-style key from the first point, whose
// border is the surface ring (a line's key would vanish), so the keys take
// the series colour here, with no border.
function legendLabels(chart) {
  const items = Chart.defaults.plugins.legend.labels.generateLabels(chart)
  for (const item of items) {
    if (item.datasetIndex == null) continue
    const ds = chart.data.datasets[item.datasetIndex]
    if (LINE.has(ds.type || chart.config.type)) {
      item.strokeStyle = ds.borderColor
      item.fillStyle = ds.borderColor
      item.lineWidth = 2
    } else {
      item.strokeStyle = "rgba(0, 0, 0, 0)"
      item.lineWidth = 0
    }
  }
  return items
}

// Row heights for horizontal bars: the bar (24, 16 or 12px) centred in its
// row, with the text above it in the "above" layouts
const ROW_HEIGHT = { end: 36, above: 48, stacked: 72 }
const labelLayout = (widths, width) => (width >= widths.end ? "end" : width >= widths.above ? "above" : "stacked")

// ---- Bars: rounded ends and stack gaps ---------------------------------------------
// Which visible datasets in this bar's stack carry a value at this index, in
// stacking order (dataset order, from the baseline out).
function stackParts(ctx) {
  const chart = ctx.chart
  const kit = chart.$kit
  const mine = chart.data.datasets[ctx.datasetIndex]
  const value = ctx.parsed && ctx.parsed[kit.valueAxis]
  if (!kit.stacked || value == null) return null
  const sign = Math.sign(value)
  const parts = []
  chart.data.datasets.forEach((ds, j) => {
    if (!chart.isDatasetVisible(j) || (ds.type && ds.type !== "bar") || (ds.stack || "") !== (mine.stack || "")) return
    const meta = chart.getDatasetMeta(j)
    const p = meta._parsed && meta._parsed[ctx.dataIndex]
    const v = p && p[kit.valueAxis]
    if (v && Math.sign(v) === sign) parts.push(j)
  })
  return { parts, sign }
}

// screen-space corner / side names for a bar's end (away from the baseline)
// and its start
function sides(kit, sign) {
  const horizontal = kit.indexAxis === "y"
  const end = horizontal ? (sign < 0 ? "left" : "right") : sign < 0 ? "bottom" : "top"
  const start = { left: "right", right: "left", top: "bottom", bottom: "top" }[end]
  const corners = (side) =>
    ({
      top: ["topLeft", "topRight"],
      bottom: ["bottomLeft", "bottomRight"],
      left: ["topLeft", "bottomLeft"],
      right: ["topRight", "bottomRight"],
    })[side]
  return { end, start, corners }
}

function barRadius(ctx) {
  const kit = ctx.chart.$kit
  if (!kit || ctx.type !== "data") return 0
  const value = ctx.parsed && ctx.parsed[kit.valueAxis]
  if (!value) return 0
  const s = sides(kit, Math.sign(value))
  const r = { topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0 }
  const stack = stackParts(ctx)
  const last = !stack || stack.parts[stack.parts.length - 1] === ctx.datasetIndex
  const first = stack && stack.parts[0] === ctx.datasetIndex
  if (last) s.corners(s.end).forEach((c) => (r[c] = 4))
  if (first && kit.track) s.corners(s.start).forEach((c) => (r[c] = 4))
  return r
}

function barBorder(ctx) {
  const kit = ctx.chart.$kit
  if (!kit || ctx.type !== "data") return 0
  const stack = stackParts(ctx)
  if (!stack || stack.parts[stack.parts.length - 1] === ctx.datasetIndex) return 0
  const s = sides(kit, stack.sign)
  return { top: 0, right: 0, bottom: 0, left: 0, [s.end]: 2 }
}

// ---- Kit plugins (registered once; they act only on kit charts) ---------------
// End labels: one text per bar at the end of its stack, or above the bar with
// the name beside it ("above") or over it ("stacked") on narrow screens.
const endLabelsPlugin = {
  id: "endLabels",
  afterDatasetsDraw(chart) {
    const kit = chart.$kit
    if (!kit || !kit.endLabels) return
    const { ctx, chartArea } = chart
    const horizontal = kit.indexAxis === "y"
    ctx.save()
    ctx.fillStyle = kit.theme.text
    kit.endLabels.forEach((text, i) => {
      if (text == null || text === "") return
      let end = null
      let center = null
      let top = null
      chart.data.datasets.forEach((ds, j) => {
        if (!chart.isDatasetVisible(j)) return
        const bar = chart.getDatasetMeta(j).data[i]
        if (!bar) return
        const { x, y, height } = bar.getProps(["x", "y", "height"])
        if (horizontal) {
          end = end == null ? x : Math.max(end, x)
          center = y
          top = y - height / 2
        } else {
          end = end == null ? y : Math.min(end, y)
          center = x
          top = y
        }
      })
      if (end == null) return
      ctx.font = kit.labelFont
      const name = String(chart.data.labels[i] ?? "")
      if (kit.labelMode === "above") {
        ctx.textBaseline = "bottom"
        ctx.textAlign = "right"
        ctx.fillText(String(text), chartArea.right, top - 4)
        ctx.font = kit.nameFont
        ctx.textAlign = "left"
        ctx.fillText(name, chartArea.left, top - 4)
      } else if (kit.labelMode === "stacked") {
        ctx.textBaseline = "bottom"
        ctx.textAlign = "left"
        ctx.fillText(String(text), chartArea.left, top - 4)
        ctx.font = kit.nameFont
        ctx.fillText(name, chartArea.left, top - 4 - 14)
      } else if (horizontal) {
        ctx.textBaseline = "middle"
        ctx.textAlign = "left"
        ctx.fillText(String(text), end + 8, center)
      } else {
        ctx.textBaseline = "bottom"
        ctx.textAlign = "center"
        ctx.fillText(String(text), center, end - 6)
      }
    })
    ctx.restore()
  },
}

// Crosshair: a hairline at the hovered (or keyboard-picked) label on line charts.
const crosshairPlugin = {
  id: "shadcnCrosshair",
  beforeDatasetsDraw(chart) {
    const kit = chart.$kit
    const active = chart.getActiveElements()
    if (!kit || !kit.crosshair || !active.length) return
    const { ctx, chartArea } = chart
    const horizontal = kit.indexAxis === "y"
    const at = Math.round(horizontal ? active[0].element.y : active[0].element.x) + 0.5
    ctx.save()
    ctx.strokeStyle = kit.theme.crosshair
    ctx.lineWidth = 1
    ctx.beginPath()
    if (horizontal) {
      ctx.moveTo(chartArea.left, at)
      ctx.lineTo(chartArea.right, at)
    } else {
      ctx.moveTo(at, chartArea.top)
      ctx.lineTo(at, chartArea.bottom)
    }
    ctx.stroke()
    ctx.restore()
  },
}

// Horizontal bar charts size themselves to their rows: after a layout, the
// canvas box grows or shrinks by the difference between the plot's height
// and rows × row height (the legend and axis keep their own height).
const rowsPlugin = {
  id: "shadcnRows",
  afterLayout(chart) {
    const kit = chart.$kit
    if (!kit || !kit.rowHeight) return
    const api = kit.api
    const rows = Math.max(1, chart.data.labels.length)
    const diff = rows * kit.rowHeight - (chart.chartArea.bottom - chart.chartArea.top)
    if (Math.abs(diff) < 1) {
      api.sizing = 0
      return
    }
    if (api.sizing >= 3) return // never fight a layout that won't settle
    api.sizing++
    api.wrapper.style.height = `${Math.max(kit.rowHeight, api.wrapper.clientHeight + diff)}px`
    queueMicrotask(() => chart.resize())
  },
}

Chart.register(endLabelsPlugin, crosshairPlugin, rowsPlugin)

// ---- Tooltip: a popover-styled DOM element in the top layer --------------------------
function tipFor(api) {
  if (api.tip) return api.tip
  const tip = document.createElement("div")
  tip.className = "chart-tooltip"
  tip.setAttribute("aria-hidden", "true")
  if (typeof tip.showPopover === "function") tip.setAttribute("popover", "manual")
  api.wrapper.appendChild(tip)
  api.tip = tip
  return tip
}
function showTip(tip) {
  if (tip.hasAttribute("popover")) {
    if (!tip.matches(":popover-open")) tip.showPopover()
  } else tip.setAttribute("data-open", "")
}
function hideTip(tip) {
  if (!tip) return
  if (tip.hasAttribute("popover")) {
    if (tip.matches(":popover-open")) tip.hidePopover()
  } else tip.removeAttribute("data-open")
}

// The tooltip's rows: the label, then each series' colour key, name and value
// (values lead: the value is the strong text). Labels are data, so textContent.
function tooltipRows(chart, points) {
  const kit = chart.$kit
  const title = kit.pieLike ? "" : (points[0] && points[0].label) || ""
  const rows = points.map((p) => {
    const opts = p.element && p.element.options
    const key = opts ? opts.backgroundColor : ""
    return {
      key: typeof key === "string" ? key : "",
      name: kit.pieLike ? p.label : p.dataset.label || "",
      value: p.formattedValue,
    }
  })
  return { title, rows }
}
const tooltipText = ({ title, rows }) =>
  [title, rows.map((r) => [r.name, r.value].filter(Boolean).join(" ")).join(", ")].filter(Boolean).join(": ")

function externalTooltip({ chart, tooltip }) {
  const kit = chart.$kit
  if (!kit) return
  const api = kit.api
  const tip = tipFor(api)
  if (!tooltip.opacity || !tooltip.dataPoints || !tooltip.dataPoints.length) {
    hideTip(tip)
    api.tipKey = null
    return
  }
  const content = tooltipRows(chart, tooltip.dataPoints)
  const key = JSON.stringify(content)
  if (key !== api.tipKey) {
    api.tipKey = key
    tip.replaceChildren()
    if (content.title) {
      const t = document.createElement("div")
      t.className = "chart-tooltip-title"
      t.textContent = content.title
      tip.appendChild(t)
    }
    for (const r of content.rows) {
      const row = document.createElement("div")
      row.className = "chart-tooltip-row"
      const k = document.createElement("span")
      k.className = "chart-tooltip-key"
      k.style.setProperty("--chart-key", r.key)
      const n = document.createElement("span")
      n.className = "chart-tooltip-name"
      n.textContent = r.name
      const v = document.createElement("span")
      v.className = "chart-tooltip-value"
      v.textContent = r.value
      row.append(k, n, v)
      tip.appendChild(row)
    }
    if (api.keyboard) api.status.textContent = tooltipText(content)
  }
  showTip(tip)
  // above the point (below it when there's no room), inside the viewport
  const box = chart.canvas.getBoundingClientRect()
  const w = tip.offsetWidth
  const h = tip.offsetHeight
  const x = box.left + tooltip.caretX
  const y = box.top + tooltip.caretY
  const left = Math.min(Math.max(8, x - w / 2), window.innerWidth - w - 8)
  const top = y - h - 12 >= 8 ? y - h - 12 : y + 16
  tip.style.left = `${Math.round(left)}px`
  tip.style.top = `${Math.round(top)}px`
}

// ---- Clicks and keys -------------------------------------------------------------
function send(api, index, datasetIndex) {
  const kit = api.chart.$kit
  const detail = {
    id: api.el.id,
    key: kit.keys[index] != null ? kit.keys[index] : null,
    series: datasetIndex != null && kit.seriesKeys[datasetIndex] != null ? kit.seriesKeys[datasetIndex] : null,
    index,
  }
  api.el.dispatchEvent(new CustomEvent("chart:click", { bubbles: true, detail }))
  const event = api.el.dataset.onClick
  const h = api.hook
  if (!event || !h) return
  const target = api.el.getAttribute("phx-target")
  target ? h.pushEventTo(target, event, detail) : h.pushEvent(event, detail)
}

function onClick(e, _active, chart) {
  const api = chart.$kit.api
  const interaction = chart.options.interaction
  const els = chart.getElementsAtEventForMode(e, interaction.mode, interaction, true)
  if (!els.length) return
  // the part under the pointer, when there is one (a segment of a stack)
  const hit = chart.getElementsAtEventForMode(e, "nearest", { intersect: true }, true)[0]
  const index = (hit || els[0]).index
  const series = hit ? hit.datasetIndex : els.length === 1 ? els[0].datasetIndex : null
  send(api, index, series)
}

function onResize(chart, size) {
  const kit = chart.$kit
  if (!kit || !kit.labelWidths) return
  // a width where the end labels change place (above the bars, or back)
  if (labelLayout(kit.labelWidths, size.width) !== kit.labelMode) queueMicrotask(() => kit.api.apply("none", true))
}

// Keyboard stops: each label (every series at it), or - for a single bar
// split into parts (a progress row) - each part; a pie's slices.
function stops(chart) {
  const kit = chart.$kit
  const visible = chart.data.datasets.map((_, j) => j).filter((j) => chart.isDatasetVisible(j))
  const has = (j, i) => {
    const el = chart.getDatasetMeta(j).data[i]
    const raw = chart.data.datasets[j].data[i]
    return el && raw != null && !(el.skip)
  }
  if (kit.pieLike) {
    const j = visible[0]
    return j == null ? [] : chart.data.labels.map((_, i) => [{ datasetIndex: j, index: i }]).filter(([p]) => has(p.datasetIndex, p.index))
  }
  if (chart.data.labels.length === 1 && visible.length > 1) {
    return visible.filter((j) => has(j, 0)).map((j) => [{ datasetIndex: j, index: 0 }])
  }
  return chart.data.labels
    .map((_, i) => visible.filter((j) => has(j, i)).map((j) => ({ datasetIndex: j, index: i })))
    .filter((s) => s.length)
}

function activate(api, stop) {
  const chart = api.chart
  if (!stop) {
    chart.setActiveElements([])
    chart.tooltip.setActiveElements([], { x: 0, y: 0 })
    chart.update("none")
    api.status.textContent = ""
    hideTip(api.tip)
    return
  }
  const el = chart.getDatasetMeta(stop[0].datasetIndex).data[stop[0].index]
  const { x, y } = el.getProps(["x", "y"], true)
  chart.setActiveElements(stop)
  chart.tooltip.setActiveElements(stop, { x, y })
  chart.update("none")
}

function onKey(api, e) {
  const chart = api.chart
  if (!chart || !api.chart.$kit.tooltipOn) return
  const list = stops(chart)
  if (!list.length) return
  const keys = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }
  let i = api.stop
  if (e.key in keys) i = i == null ? (keys[e.key] > 0 ? 0 : list.length - 1) : Math.min(list.length - 1, Math.max(0, i + keys[e.key]))
  else if (e.key === "Home") i = 0
  else if (e.key === "End") i = list.length - 1
  else if ((e.key === "Enter" || e.key === " ") && api.chart.$kit.clickable && api.stop != null) {
    e.preventDefault()
    const stop = list[Math.min(api.stop, list.length - 1)]
    send(api, stop[0].index, stop.length === 1 ? stop[0].datasetIndex : null)
    return
  } else if (e.key === "Escape" && api.stop != null) {
    e.preventDefault()
    e.stopPropagation()
    api.stop = null
    activate(api, null)
    return
  } else return
  e.preventDefault()
  api.stop = i
  api.keyboard = true
  api.tipKey = null
  activate(api, list[i])
}

// ---- One chart --------------------------------------------------------------------
function initChart(el, hook) {
  if (el.__shadcnChart) {
    if (hook) el.__shadcnChart.hook = hook
    return el.__shadcnChart
  }
  const wrapper = el.querySelector('[data-slot="chart-canvas"]')
  const canvas = wrapper && wrapper.querySelector("canvas")
  if (!canvas) return null
  const api = {
    el,
    hook,
    wrapper,
    canvas,
    status: wrapper.querySelector('[data-slot="chart-status"]') || document.createElement("div"),
    chart: null,
    cfg: null,
    json: null,
    sizing: 0,
    stop: null,
    keyboard: false,
  }

  // build the chart, or apply a new config / theme to it in place
  api.apply = (mode, rebuild) => {
    const next = build(api)
    const chart = api.chart
    if (!chart) return
    if (!rebuild && next.kit.themeKey === chart.$kit.themeKey && next.kit.labelMode === chart.$kit.labelMode && mode === "none") return
    chart.$kit = next.kit
    chart.data.labels = next.data.labels
    next.data.datasets.forEach((ds, i) => {
      const cur = chart.data.datasets[i]
      if (!cur) return chart.data.datasets.push(ds)
      for (const k of Object.keys(cur)) if (!(k in ds)) delete cur[k]
      Object.assign(cur, ds)
    })
    chart.data.datasets.length = next.data.datasets.length
    chart.options = next.options
    chart.update(mode)
  }

  const create = () => {
    const next = build(api)
    if (next.kit.rowHeight) {
      // a first guess at the height (rows, plus the legend and axis bands),
      // so the first frame is close; the rows plugin corrects it
      const legend = next.options.plugins.legend.display !== false ? 32 : 0
      const axis = dig(next.options, "scales", next.kit.valueAxis, "display") !== false ? 24 : 0
      wrapper.style.height = `${Math.max(1, next.data.labels.length) * next.kit.rowHeight + legend + axis}px`
    }
    // the kit's state rides on the chart from before its first draw
    const kitPlugin = { id: "shadcnKit", beforeInit: (c) => (c.$kit = next.kit) }
    const chart = new Chart(canvas, { type: next.type, data: next.data, options: next.options, plugins: [kitPlugin] })
    api.chart = chart
    if (next.kit.tooltipOn && el.dataset.variant !== "trend") wrapper.tabIndex = 0
    else wrapper.removeAttribute("tabindex")
  }

  api.refresh = () => {
    const json = el.dataset.config || "{}"
    const label = el.dataset.label
    if (label && wrapper.getAttribute("aria-label") !== label) wrapper.setAttribute("aria-label", label)
    if (json === api.json && api.chart) return
    let cfg
    try {
      cfg = JSON.parse(json)
    } catch (e) {
      console.error("shadcn charts: data-config isn't JSON", e)
      return
    }
    const prev = api.cfg
    api.cfg = cfg
    api.json = json
    const same =
      api.chart &&
      prev &&
      (prev.type || "bar") === (cfg.type || "bar") &&
      dig(prev, "options", "indexAxis") === dig(cfg, "options", "indexAxis")
    if (same) {
      api.stop = null
      api.apply(reducedMotion() ? "none" : undefined, true)
    } else {
      if (api.chart) api.chart.destroy()
      create()
    }
  }

  api.destroy = () => {
    charts.delete(api)
    hideTip(api.tip)
    if (api.tip) api.tip.remove()
    if (api.chart) api.chart.destroy()
    api.chart = null
    wrapper.removeEventListener("keydown", api.onKey)
    wrapper.removeEventListener("blur", api.onBlur)
    delete el.__shadcnChart
  }

  api.onKey = (e) => onKey(api, e)
  api.onBlur = () => {
    if (api.stop == null) return
    api.stop = null
    api.keyboard = false
    activate(api, null)
  }
  wrapper.addEventListener("keydown", api.onKey)
  wrapper.addEventListener("blur", api.onBlur)
  // the pointer takes over from the keyboard
  wrapper.addEventListener("pointermove", () => {
    if (api.keyboard) {
      api.keyboard = false
      api.stop = null
    }
  })

  el.__shadcnChart = api
  charts.add(api)
  api.refresh()
  return api
}

// ---- Theme, fonts and motion ------------------------------------------------------
// The look follows the theme: setTheme / any data-theme change on <html>, the
// OS scheme (a "system" theme), reduced motion, and web fonts arriving.
function retheme() {
  for (const api of charts) {
    if (!api.el.isConnected) continue
    api.apply("none", false)
  }
}
if (typeof window !== "undefined" && !window.__shadcnCharts) {
  window.__shadcnCharts = true
  if (typeof MutationObserver !== "undefined") {
    new MutationObserver(retheme).observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme", "class", "style"],
    })
  }
  if (typeof matchMedia === "function") {
    for (const q of ["(prefers-color-scheme: dark)", "(prefers-reduced-motion: reduce)"]) {
      const mq = matchMedia(q)
      if (mq.addEventListener) mq.addEventListener("change", () => {
        for (const api of charts) if (api.el.isConnected) api.apply("none", true)
      })
    }
  }
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(() => {
      for (const api of charts) if (api.el.isConnected) api.apply("none", true)
    })
  }
}

// ---- Public API --------------------------------------------------------------------

// Draw every chart under `root` (default: the document). For dead views.
export function initCharts(root) {
  root = root || document
  root.querySelectorAll('[data-slot="chart"]').forEach((el) => initChart(el))
}

// LiveView hooks: spread into the LiveSocket's hooks beside the package's own.
export const ChartHooks = {
  // <.chart> / <.number_card>'s trend; updated(): the config (or the label)
  // changed - the same chart moves to the new data
  ShadcnChart: {
    mounted() {
      this.api = initChart(this.el, this)
    },
    updated() {
      this.api && this.api.refresh()
    },
    destroyed() {
      this.api && this.api.destroy()
    },
  },
}

// The chart behind a <.chart> element (its Chart.js instance), for tests and
// debugging. Pages don't configure charts through it.
export function chartFor(el) {
  const api = el && el.__shadcnChart
  return api ? api.chart : null
}
