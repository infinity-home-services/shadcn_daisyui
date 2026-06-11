// Interactive theme creator for the /docs/themes page.
//
// Lets the user tweak the neutral shadcn token palette (per light/dark mode) and
// the radius, see a live preview react instantly, and export a drop-in CSS block.
//
// It overrides CSS custom properties on a scoped preview container. Each token maps
// to one or more vars so the daisyUI utilities the preview uses actually react
// (e.g. "Muted" also drives base-200 surfaces, "Border" drives base-300 hairlines).

const TOKENS = [
  { id: "background", label: "Background", vars: ["--background"] },
  { id: "foreground", label: "Foreground", vars: ["--foreground"] },
  { id: "card", label: "Card", vars: ["--card", "--popover"] },
  { id: "primary", label: "Primary", vars: ["--primary"] },
  { id: "primary-foreground", label: "Primary fg", vars: ["--primary-foreground"] },
  { id: "secondary", label: "Secondary", vars: ["--secondary"] },
  { id: "muted", label: "Muted", vars: ["--muted", "--color-base-200"] },
  { id: "muted-foreground", label: "Muted fg", vars: ["--muted-foreground"] },
  { id: "accent", label: "Accent", vars: ["--accent"] },
  { id: "border", label: "Border", vars: ["--border-color", "--color-base-300"] },
  { id: "destructive", label: "Destructive", vars: ["--destructive"] },
]

const THEME = { light: "shadcn", dark: "shadcn-dark" }

// getComputedStyle returns colors as `oklch(...)` in modern browsers. Painting to a
// 1px canvas is the robust way to resolve any CSS color (oklch, rgb, hex, alpha) to
// straight sRGB bytes.
const _ctx = document.createElement("canvas").getContext("2d", { willReadFrequently: true })

function resolveRGBA(value) {
  _ctx.clearRect(0, 0, 1, 1)
  _ctx.fillStyle = "#000000"
  _ctx.fillStyle = value
  _ctx.fillRect(0, 0, 1, 1)
  const d = _ctx.getImageData(0, 0, 1, 1).data
  return [d[0], d[1], d[2], d[3]]
}

function toHex(r, g, b) {
  return "#" + [r, g, b].map((x) => Math.round(x).toString(16).padStart(2, "0")).join("")
}

function fmtRadius(r) {
  return `${r.toFixed(3).replace(/0+$/, "").replace(/\.$/, "")}rem`
}

// Read the current resolved colors + radius for a given theme via an offscreen probe.
// Semi-transparent tokens (e.g. the dark border) are blended over the background so
// they export as a representative solid hex.
function readTheme(theme) {
  const probe = document.createElement("div")
  probe.setAttribute("data-theme", theme)
  probe.style.cssText = "position:absolute;left:-9999px;top:0;opacity:0;pointer-events:none"
  document.body.appendChild(probe)

  // Read each token's CSS custom property value directly (e.g. "oklch(1 0 0)").
  // Custom properties don't animate, so this is unaffected by the theme colour
  // transitions — reading via a transitioning `color` would return in-flight values.
  const cs = getComputedStyle(probe)
  const colors = {}
  let bg = [255, 255, 255]
  TOKENS.forEach((t) => {
    const [r, g, b, a] = resolveRGBA(cs.getPropertyValue(t.vars[0]).trim())
    const af = a / 255
    const R = r * af + bg[0] * (1 - af)
    const G = g * af + bg[1] * (1 - af)
    const B = b * af + bg[2] * (1 - af)
    if (t.id === "background") bg = [R, G, B]
    colors[t.id] = toHex(R, G, B)
  })
  const radius = parseFloat(cs.getPropertyValue("--radius")) || 0.625

  document.body.removeChild(probe)
  return { colors, radius }
}

// Build one color-control row with DOM methods (no innerHTML).
function buildRow(token) {
  const row = document.createElement("label")
  row.className =
    "flex items-center justify-between gap-2 rounded-md border border-base-300 px-2.5 py-1.5"

  const name = document.createElement("span")
  name.className = "text-xs font-medium"
  name.textContent = token.label

  const controls = document.createElement("span")
  controls.className = "flex items-center gap-1.5"

  const hex = document.createElement("input")
  hex.type = "text"
  hex.spellcheck = false
  hex.dataset.hex = token.id
  hex.className =
    "w-[4.5rem] bg-transparent text-right font-mono text-xs text-muted-foreground outline-none"

  const color = document.createElement("input")
  color.type = "color"
  color.dataset.color = token.id
  color.className = "size-6 cursor-pointer rounded border border-base-300 bg-transparent p-0"

  controls.appendChild(hex)
  controls.appendChild(color)
  row.appendChild(name)
  row.appendChild(controls)
  return { row, hex, color }
}

export function initThemeCreator() {
  const root = document.querySelector("[data-theme-creator]")
  if (!root) return

  const grid = root.querySelector("[data-token-grid]")
  const preview = root.querySelector("[data-theme-preview]")
  const exportEl = root.querySelector("[data-export]")
  const radiusInput = root.querySelector("[data-radius]")
  const radiusVal = root.querySelector("[data-radius-val]")
  const copyBtn = root.querySelector("[data-copy]")
  const resetBtn = root.querySelector("[data-reset]")
  const modeBtns = root.querySelectorAll("[data-mode]")

  const initial = { light: readTheme(THEME.light), dark: readTheme(THEME.dark) }
  const clone = (o) => JSON.parse(JSON.stringify(o))
  const state = clone(initial)
  let mode = "light"

  const cur = () => state[mode]

  // Build the color control rows.
  const colorInputs = {}
  const hexInputs = {}
  while (grid.firstChild) grid.removeChild(grid.firstChild)
  TOKENS.forEach((t) => {
    const { row, hex, color } = buildRow(t)
    grid.appendChild(row)
    colorInputs[t.id] = color
    hexInputs[t.id] = hex
  })

  function applyPreview() {
    preview.setAttribute("data-theme", THEME[mode])
    const c = cur().colors
    TOKENS.forEach((t) => t.vars.forEach((v) => preview.style.setProperty(v, c[t.id])))
    const r = cur().radius
    const lg = `${r}rem`
    const md = `calc(${r}rem - 2px)`
    const sm = `calc(${r}rem - 4px)`
    preview.style.setProperty("--radius", `${r}rem`)
    // shadcn-named scale (rounded-sm/md/lg/xl utilities)
    preview.style.setProperty("--radius-lg", lg)
    preview.style.setProperty("--radius-md", md)
    preview.style.setProperty("--radius-sm", sm)
    preview.style.setProperty("--radius-xl", `calc(${r}rem + 4px)`)
    // daisyUI component radii (cards/inputs/controls)
    preview.style.setProperty("--radius-box", lg)
    preview.style.setProperty("--radius-field", md)
    preview.style.setProperty("--radius-selector", sm)
  }

  function syncControls() {
    const c = cur().colors
    TOKENS.forEach((t) => {
      colorInputs[t.id].value = c[t.id]
      hexInputs[t.id].value = c[t.id]
    })
    radiusInput.value = cur().radius
    radiusVal.textContent = fmtRadius(cur().radius)
  }

  function cssBlock(theme, data) {
    const lines = []
    TOKENS.forEach((t) => t.vars.forEach((v) => lines.push(`  ${v}: ${data.colors[t.id]};`)))
    lines.push(`  --radius: ${data.radius}rem;`)
    return `[data-theme="${theme}"] {\n${lines.join("\n")}\n}`
  }

  function updateExport() {
    exportEl.textContent =
      cssBlock(THEME.light, state.light) + "\n\n" + cssBlock(THEME.dark, state.dark)
  }

  function refresh() {
    applyPreview()
    updateExport()
  }

  TOKENS.forEach((t) => {
    colorInputs[t.id].addEventListener("input", (e) => {
      cur().colors[t.id] = e.target.value
      hexInputs[t.id].value = e.target.value
      refresh()
    })
    hexInputs[t.id].addEventListener("change", (e) => {
      const v = e.target.value.trim()
      if (/^#[0-9a-fA-F]{6}$/.test(v)) {
        cur().colors[t.id] = v.toLowerCase()
        colorInputs[t.id].value = v
        refresh()
      } else {
        e.target.value = cur().colors[t.id]
      }
    })
  })

  radiusInput.addEventListener("input", (e) => {
    cur().radius = parseFloat(e.target.value)
    radiusVal.textContent = fmtRadius(cur().radius)
    refresh()
  })

  modeBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      mode = btn.dataset.mode
      modeBtns.forEach((b) => b.setAttribute("aria-selected", b === btn ? "true" : "false"))
      syncControls()
      applyPreview()
    })
  })

  resetBtn.addEventListener("click", () => {
    state.light = clone(initial.light)
    state.dark = clone(initial.dark)
    syncControls()
    refresh()
  })

  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).catch(() => fallbackCopy(text))
    }
    return Promise.resolve(fallbackCopy(text))
  }

  function fallbackCopy(text) {
    const ta = document.createElement("textarea")
    ta.value = text
    ta.style.cssText = "position:fixed;left:-9999px;top:0"
    document.body.appendChild(ta)
    ta.select()
    try {
      document.execCommand("copy")
    } catch (_) {}
    document.body.removeChild(ta)
  }

  if (copyBtn) {
    const original = copyBtn.textContent
    copyBtn.addEventListener("click", () => {
      copyText(exportEl.textContent)
      copyBtn.textContent = "Copied!"
      setTimeout(() => (copyBtn.textContent = original), 1500)
    })
  }

  modeBtns.forEach((b) =>
    b.setAttribute("aria-selected", b.dataset.mode === "light" ? "true" : "false")
  )
  syncControls()
  refresh()
}
