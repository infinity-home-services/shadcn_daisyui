// shadcn-daisyui — interactive components.
// Two ways to use:
//   • Dead views / plain HTML:  import { initShadcnDaisyui } from "shadcn-daisyui"; initShadcnDaisyui()
//   • Phoenix LiveView:         import { Hooks } from "shadcn-daisyui"; new LiveSocket(..., { hooks: { ...Hooks } })
// The matching CSS is shadcn-daisyui.css.

// Counter for generating unique ids when a component root has none (needed for
// ARIA relationships like aria-controls / aria-activedescendant).
let a11yUid = 0

// Global listeners so the server side can open/close native <dialog> elements
// (dialog, sheet, drawer, command) via JS.dispatch — see
// ShadcnDaisyui.Components.show_modal/2 and hide_modal/2. Registered once at
// module load; works for both dead views and LiveView.
if (typeof window !== "undefined" && !window.__shadcnDialogEvents) {
  window.__shadcnDialogEvents = true
  window.addEventListener("shadcn:show-modal", (e) => {
    const el = e.target
    if (el && typeof el.showModal === "function" && !el.open) el.showModal()
  })
  window.addEventListener("shadcn:hide-modal", (e) => {
    const el = e.target
    if (el && typeof el.close === "function" && el.open) el.close()
  })
  // Backdrop click closes a sheet / drawer / command dialog. These <dialog>s ARE
  // the panel, so a click on the ::backdrop and one on the panel's own padding
  // both target the dialog - tell them apart by the click point. One delegated
  // listener instead of inline onclick handlers keeps the markup CSP-safe.
  // (.modal dialogs close via their <form method="dialog" class="modal-backdrop">.)
  document.addEventListener("click", (e) => {
    const d = e.target
    if (!(d instanceof HTMLDialogElement) || !d.open || e.detail === 0) return
    if (!d.matches(".sheet, .drawer-bottom, .command-dialog")) return
    const r = d.getBoundingClientRect()
    const inside = e.clientX >= r.left && e.clientX <= r.right && e.clientY >= r.top && e.clientY <= r.bottom
    if (!inside) d.close()
  })
}

// ---- Sonner (toast) --------------------------------------------------------
// A dependency-free port of sonner's behaviour (the toast shadcn/ui ships):
// typed toasts with icons, description, action / cancel buttons, promise
// toasts, per-toast position, a collapsed stack that expands on hover/focus,
// pause-on-hover timers, swipe to dismiss, and the Alt+T hotkey.
//
//   import { toast } from "shadcn-daisyui"
//   toast("Event has been created", { description: "Sunday at 9:00 AM", action: { label: "Undo", onClick: undo } })
//   toast.success("Saved")  ·  toast.error("Failed")  ·  toast.info(…)  ·  toast.warning(…)
//   const id = toast.loading("Uploading…"); toast.success("Uploaded", { id })
//   toast.promise(fetch("/api"), { loading: "Saving…", success: "Saved", error: "Could not save" })
//   toast.dismiss(id)   // or toast.dismiss() for all
//
// Render one <.toaster /> (ShadcnDaisyui.Components) in the root layout to set
// position and options; toast() creates a default bottom-right toaster if none
// exists. From LiveView: ShadcnDaisyui.Components.push_toast(socket, "Saved").

const TOAST_SVG = (paths) =>
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + paths + "</svg>"
const TOAST_ICONS = {
  success: TOAST_SVG('<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>'),
  info: TOAST_SVG('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>'),
  warning: TOAST_SVG('<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>'),
  error: TOAST_SVG('<path d="m15 9-6 6"/><path d="M2.586 16.726A2 2 0 0 1 2 15.312V8.688a2 2 0 0 1 .586-1.414l4.688-4.688A2 2 0 0 1 8.688 2h6.624a2 2 0 0 1 1.414.586l4.688 4.688A2 2 0 0 1 22 8.688v6.624a2 2 0 0 1-.586 1.414l-4.688 4.688a2 2 0 0 1-1.414.586H8.688a2 2 0 0 1-1.414-.586z"/><path d="m9 9 6 6"/>'),
  loading: TOAST_SVG('<path d="M21 12a9 9 0 1 1-6.219-8.56"/>'),
}
const TOAST_CLOSE = TOAST_SVG('<path d="M18 6 6 18"/><path d="m6 6 12 12"/>')
const TOAST_GAP = 14
const TOAST_UNMOUNT_MS = 400
const SWIPE_THRESHOLD = 45

const sonner = { toasts: [], seq: 0, hotkey: false }

function toasterSection() {
  let section = document.querySelector("[data-sonner-section]")
  if (!section) {
    section = document.createElement("section")
    section.setAttribute("data-sonner-section", "")
    document.body.appendChild(section)
  }
  if (!section.dataset.sonnerInit) {
    section.dataset.sonnerInit = "1"
    section.setAttribute("aria-label", "Notifications alt+T")
    section.setAttribute("tabindex", "-1")
    section.setAttribute("aria-live", "polite")
    section.setAttribute("aria-relevant", "additions text")
    section.setAttribute("aria-atomic", "false")
  }
  if (!sonner.hotkey) {
    sonner.hotkey = true
    document.addEventListener("keydown", (e) => {
      if (e.altKey && e.code === "KeyT") {
        const ol = document.querySelector("[data-sonner-toaster]")
        if (ol) { setExpanded(ol, true); ol.focus() }
      } else if (e.key === "Escape") {
        const ol = document.activeElement && document.activeElement.closest && document.activeElement.closest("[data-sonner-toaster]")
        if (ol) { ol.blur(); setExpanded(ol, false) }
      }
    })
    document.addEventListener("visibilitychange", () => {
      sonner.toasts.forEach((t) => (document.hidden ? pauseToast(t) : resumeToast(t)))
    })
  }
  return section
}

function toasterOptions() {
  const d = toasterSection().dataset
  return {
    position: d.position || "bottom-right",
    expand: d.expand === "true",
    richColors: d.richColors === "true",
    closeButton: d.closeButton === "true",
    duration: d.duration ? Number(d.duration) : 4000,
    visibleToasts: d.visibleToasts ? Number(d.visibleToasts) : 3,
  }
}

function toasterList(position) {
  const section = toasterSection()
  let ol = section.querySelector('[data-sonner-toaster][data-position="' + position + '"]')
  if (ol) return ol
  const [y, x] = position.split("-")
  const opts = toasterOptions()
  ol = document.createElement("ol")
  ol.setAttribute("data-sonner-toaster", "")
  ol.dataset.position = position
  ol.dataset.yPosition = y
  ol.dataset.xPosition = x
  ol.dataset.richColors = String(opts.richColors)
  ol.dataset.expanded = String(opts.expand)
  ol.setAttribute("tabindex", "-1")
  ol.dir = document.documentElement.dir || "ltr"
  ol.addEventListener("mouseenter", () => setExpanded(ol, true))
  ol.addEventListener("mousemove", () => setExpanded(ol, true))
  ol.addEventListener("mouseleave", () => { if (!ol.contains(document.activeElement)) setExpanded(ol, false) })
  ol.addEventListener("focusin", () => setExpanded(ol, true))
  ol.addEventListener("focusout", (e) => { if (!ol.contains(e.relatedTarget)) setExpanded(ol, false) })
  section.appendChild(ol)
  return ol
}

function setExpanded(ol, on) {
  const pinned = toasterOptions().expand
  const next = String(on || pinned)
  const hovering = on && !pinned
  if (ol.dataset.expanded === next && ol.dataset.hovering === String(hovering)) return
  ol.dataset.expanded = next
  ol.dataset.hovering = String(hovering)
  sonner.toasts.filter((t) => t.ol === ol).forEach((t) => (on ? pauseToast(t) : resumeToast(t)))
  layoutToasts(ol)
}

function layoutToasts(ol) {
  const list = sonner.toasts.filter((t) => t.ol === ol) // newest first
  const max = toasterOptions().visibleToasts
  const expanded = ol.dataset.expanded === "true"
  let offset = 0
  list.forEach((t, i) => {
    const el = t.el
    el.dataset.front = String(i === 0)
    el.dataset.visible = String(i < max)
    el.dataset.expanded = String(expanded)
    el.dataset.index = String(i)
    el.style.setProperty("--toasts-before", String(i))
    el.style.setProperty("--z-index", String(list.length - i))
    el.style.setProperty("--offset", offset + "px")
    el.style.setProperty("--initial-height", t.height + "px")
    offset += t.height + TOAST_GAP
  })
  if (list[0]) ol.style.setProperty("--front-toast-height", list[0].height + "px")
}

function measureToast(t) {
  const el = t.el
  const prev = el.style.height
  el.style.height = "auto"
  t.height = el.getBoundingClientRect().height
  el.style.height = prev
}

function startToastTimer(t) {
  clearTimeout(t.timer)
  if (t.type === "loading" || t.duration === Infinity || t.removed) return
  t.remaining = t.remaining == null ? t.duration : t.remaining
  t.startedAt = Date.now()
  t.timer = setTimeout(() => dismissToast(t.id), t.remaining)
}
function pauseToast(t) {
  if (!t.timer || t.paused) return
  clearTimeout(t.timer)
  t.paused = true
  t.remaining = Math.max(0, t.remaining - (Date.now() - t.startedAt))
}
function resumeToast(t) {
  if (!t.paused || document.hidden) return
  if (t.ol && t.ol.dataset.hovering === "true") return
  t.paused = false
  startToastTimer(t)
}

function renderToast(t) {
  const el = t.el
  el.replaceChildren()
  el.dataset.type = t.type
  el.setAttribute("aria-live", t.important ? "assertive" : "polite")
  if (t.closeButton && t.dismissible) {
    const close = document.createElement("button")
    close.type = "button"
    close.setAttribute("data-close-button", "")
    close.setAttribute("aria-label", "Close toast")
    close.innerHTML = TOAST_CLOSE
    close.addEventListener("click", () => dismissToast(t.id))
    el.appendChild(close)
  }
  const iconHTML = t.icon || TOAST_ICONS[t.type]
  if (iconHTML) {
    const icon = document.createElement("div")
    icon.setAttribute("data-icon", "")
    icon.innerHTML = iconHTML
    el.appendChild(icon)
  }
  const content = document.createElement("div")
  content.setAttribute("data-content", "")
  const title = document.createElement("div")
  title.setAttribute("data-title", "")
  title.textContent = t.title
  content.appendChild(title)
  if (t.description) {
    const desc = document.createElement("div")
    desc.setAttribute("data-description", "")
    desc.textContent = t.description
    content.appendChild(desc)
  }
  el.appendChild(content)
  const button = (spec, cancel) => {
    const b = document.createElement("button")
    b.type = "button"
    b.setAttribute("data-button", "")
    if (cancel) b.setAttribute("data-cancel", "")
    b.textContent = spec.label
    b.addEventListener("click", (e) => {
      if (spec.onClick) spec.onClick(e)
      if (!e.defaultPrevented) dismissToast(t.id)
    })
    return b
  }
  if (t.cancel) el.appendChild(button(t.cancel, true))
  if (t.action) el.appendChild(button(t.action, false))
}

function bindSwipe(t) {
  const el = t.el
  const [y, x] = t.position.split("-")
  let start = null
  el.addEventListener("pointerdown", (e) => {
    if (!t.dismissible || e.button !== 0 || e.target.closest("button")) return
    start = { x: e.clientX, y: e.clientY, at: Date.now() }
    el.setPointerCapture(e.pointerId)
  })
  el.addEventListener("pointermove", (e) => {
    if (!start) return
    let dx = e.clientX - start.x
    let dy = e.clientY - start.y
    // only toward the screen edge the stack is anchored to; resist the other way
    dy = y === "bottom" ? Math.max(0, dy) : Math.min(0, dy)
    dx = x === "left" ? Math.min(0, dx) : x === "right" ? Math.max(0, dx) : 0
    if (Math.abs(dx) < 2 && Math.abs(dy) < 2) return
    el.dataset.swiping = "true"
    el.style.setProperty("--swipe-x", dx + "px")
    el.style.setProperty("--swipe-y", dy + "px")
  })
  const end = () => {
    if (!start) return
    const dx = parseFloat(el.style.getPropertyValue("--swipe-x")) || 0
    const dy = parseFloat(el.style.getPropertyValue("--swipe-y")) || 0
    const dist = Math.max(Math.abs(dx), Math.abs(dy))
    const velocity = dist / Math.max(1, Date.now() - start.at)
    start = null
    el.dataset.swiping = "false"
    if (dist >= SWIPE_THRESHOLD || velocity > 0.11) {
      el.dataset.swipeOut = "true"
      el.style.setProperty("--swipe-x", dx * 2.5 + "px")
      el.style.setProperty("--swipe-y", dy * 2.5 + "px")
      dismissToast(t.id)
    } else {
      el.style.setProperty("--swipe-x", "0px")
      el.style.setProperty("--swipe-y", "0px")
    }
  }
  el.addEventListener("pointerup", end)
  el.addEventListener("pointercancel", end)
}

function createToast(message, data) {
  data = data || {}
  const opts = toasterOptions()
  const existing = data.id != null && sonner.toasts.find((t) => t.id === data.id && !t.removed)
  if (existing) {
    const wasLoading = existing.type === "loading"
    Object.assign(existing, {
      title: message,
      type: data.type || "default",
      description: data.description,
      action: data.action,
      cancel: data.cancel,
      icon: data.icon,
      important: !!data.important,
      duration: data.duration != null ? data.duration : opts.duration,
      remaining: null,
    })
    renderToast(existing)
    measureToast(existing)
    layoutToasts(existing.ol)
    if (wasLoading || existing.type !== "loading") startToastTimer(existing)
    return existing.id
  }
  const position = data.position || opts.position
  const ol = toasterList(position)
  const t = {
    id: data.id != null ? data.id : ++sonner.seq,
    title: message,
    type: data.type || "default",
    description: data.description,
    action: data.action,
    cancel: data.cancel,
    icon: data.icon,
    important: !!data.important,
    duration: data.duration != null ? data.duration : opts.duration,
    dismissible: data.dismissible !== false,
    closeButton: data.closeButton != null ? data.closeButton : opts.closeButton,
    position,
    ol,
    remaining: null,
  }
  const el = document.createElement("li")
  el.setAttribute("data-sonner-toast", "")
  el.setAttribute("role", "status")
  el.setAttribute("aria-atomic", "true")
  el.setAttribute("tabindex", "0")
  el.dataset.mounted = "false"
  el.dataset.removed = "false"
  el.dataset.swiping = "false"
  el.dataset.swipeOut = "false"
  el.dataset.yPosition = position.split("-")[0]
  el.dataset.xPosition = position.split("-")[1]
  t.el = el
  renderToast(t)
  ol.appendChild(el)
  sonner.toasts.unshift(t)
  measureToast(t)
  layoutToasts(ol)
  bindSwipe(t)
  // next frame: flip data-mounted so the enter transition runs
  requestAnimationFrame(() => requestAnimationFrame(() => { el.dataset.mounted = "true" }))
  if (ol.dataset.hovering === "true") { t.paused = true; t.remaining = t.duration } else startToastTimer(t)
  return t.id
}

function dismissToast(id) {
  const targets = id == null ? sonner.toasts.slice() : sonner.toasts.filter((t) => t.id === id)
  targets.forEach((t) => {
    if (t.removed) return
    t.removed = true
    clearTimeout(t.timer)
    t.el.dataset.removed = "true"
    sonner.toasts = sonner.toasts.filter((x) => x !== t)
    layoutToasts(t.ol)
    setTimeout(() => {
      t.el.remove()
      if (!t.ol.children.length) t.ol.remove()
    }, TOAST_UNMOUNT_MS)
  })
}

function toast(message, data) { return createToast(message, data) }
;["success", "info", "warning", "error", "loading"].forEach((type) => {
  toast[type] = (message, data) => createToast(message, Object.assign({}, data, { type }))
})
toast.message = (message, data) => createToast(message, data)
toast.dismiss = dismissToast
toast.promise = (promise, msgs) => {
  msgs = msgs || {}
  const pick = (v, arg) => (typeof v === "function" ? v(arg) : v)
  const id = createToast(msgs.loading || "Loading…", { type: "loading", id: msgs.id, position: msgs.position })
  Promise.resolve(typeof promise === "function" ? promise() : promise)
    .then((data) => {
      if (msgs.success == null) return dismissToast(id)
      createToast(pick(msgs.success, data), { id, type: "success", description: pick(msgs.description, data) })
    })
    .catch((err) => {
      if (msgs.error == null) return dismissToast(id)
      createToast(pick(msgs.error, err), { id, type: "error" })
    })
    .finally(() => { if (msgs.finally) msgs.finally() })
  return id
}

// LiveView: ShadcnDaisyui.Components.push_toast/3 sends "shadcn:toast" to the
// <.toaster> hook. An action with an `event` pushes that event back to the view.
function toastFromServer(payload, hook) {
  const p = payload || {}
  const wrap = (spec) =>
    spec && {
      label: spec.label,
      onClick: () => { if (spec.event && hook) hook.pushEvent(spec.event, spec.value || {}) },
    }
  if (p.dismiss) return dismissToast(p.id != null ? p.id : undefined)
  return createToast(p.message, {
    id: p.id,
    type: p.type,
    description: p.description,
    duration: p.duration,
    position: p.position,
    important: p.important,
    closeButton: p.close_button,
    action: wrap(p.action),
    cancel: wrap(p.cancel),
  })
}

// Deprecated (0.4): the docs-demo toast. Use toast() instead.
function showToast(variant) {
  const success = variant === "success"
  return toast(success ? "Changes saved" : "Event has been created", {
    type: success ? "success" : "default",
    description: "Sunday, December 03 at 9:00 AM",
    action: { label: "Undo" },
  })
}

function initResizable(root) {
    if (root.dataset.rsInit) return
    root.dataset.rsInit = "1"
    const left = root.querySelector(".resizable-panel")
    const handle = root.querySelector(".resizable-handle")
    if (!left || !handle) return
    let dragging = false
    const move = (e) => {
      if (!dragging) return
      const rect = root.getBoundingClientRect()
      const clientX = e.clientX != null ? e.clientX : (e.touches && e.touches[0].clientX)
      const pct = Math.min(100, Math.max(0, ((clientX - rect.left) / rect.width) * 100))
      left.style.flex = "0 0 auto"
      left.style.width = pct + "%"
    }
    handle.addEventListener("pointerdown", (e) => {
      dragging = true
      handle.setPointerCapture(e.pointerId)
      document.body.style.userSelect = "none"
    })
    handle.addEventListener("pointermove", move)
    handle.addEventListener("pointerup", (e) => {
      dragging = false
      try { handle.releasePointerCapture(e.pointerId) } catch (_) {}
      document.body.style.userSelect = ""
    })
}

function initDock(scope) {
  ;(scope || document).addEventListener("click", (e) => {
    const btn = e.target.closest(".dock button")
    if (!btn) return
    btn.parentElement.querySelectorAll("button").forEach((b) => b.classList.remove("dock-active"))
    btn.classList.add("dock-active")
  })
}

  // Server/echo reconciliation for hook-driven form controls. A LiveView patch
  // re-renders the server's opinion of the value; `changed()` tells a genuine
  // server change (a reset, a cap) apart from the echo of a value we emitted
  // ourselves, so fast toggling never snaps back to a stale echo.
  function serverValue(read) {
    let last = read()
    const sent = []
    return {
      initial: last,
      sent(key) { sent.push(key); if (sent.length > 50) sent.shift() },
      changed() {
        const now = read()
        if (now === last) return null
        last = now
        const i = sent.indexOf(now)
        if (i >= 0) { sent.splice(0, i + 1); return null }
        sent.length = 0
        return now
      },
    }
  }

  const emitChange = (input) =>
    ["input", "change"].forEach((t) => input.dispatchEvent(new Event(t, { bubbles: true })))

  // Select + Combobox, single or multiple (`data-multiple` on the root). `p` is
  // the data-attribute prefix: "select" | "combobox". All state lives here and
  // sync() writes it to the DOM, so the hook's updated() can restore an open
  // list, the label, the checks and the hidden inputs after a LiveView patch
  // re-renders the server markup. Every listener is delegated on the root, so
  // options the server adds or replaces keep working.
  function initPicker(root, p) {
    if (root.__sdPicker) return root.__sdPicker
    const q = (part) => root.querySelector("[data-" + p + "-" + part + "]")
    if (!q("trigger") || !q("panel")) return null
    const multiple = root.hasAttribute("data-multiple")
    const itemSel = p === "select" ? "[data-select-item]" : ".combo-item[data-value]"
    if (!root.id) root.id = "sd-" + p + "-" + (++a11yUid)
    const listId = root.id + "-list"
    const items = () => [...root.querySelectorAll(itemSel)]
    const text = (it) => ((it.querySelector("[data-label]") || it).textContent || "").trim()
    const label0 = q("label")
    const placeholder = root.dataset.placeholder ?? (label0 ? label0.textContent.trim() : "")
    const row = (it) => (it.parentElement && it.parentElement.tagName === "LI" ? it.parentElement : it)

    // the server's value: options it marked data-selected, else the hidden inputs
    const readServer = () => {
      let v = items().filter((it) => it.hasAttribute("data-selected")).map((it) => it.dataset.value)
      if (!v.length) {
        v = [...root.querySelectorAll("[data-" + p + "-input], [data-" + p + "-value]")].map((i) => i.value).filter(Boolean)
      }
      return JSON.stringify(multiple ? [...new Set(v)].sort() : v.slice(0, 1))
    }
    const server = serverValue(readServer)
    const ordered = (vals) => {
      const order = items().map((it) => it.dataset.value)
      const rank = (v) => { const i = order.indexOf(v); return i < 0 ? order.length : i }
      return [...new Set(vals)].sort((a, b) => rank(a) - rank(b))
    }
    let selected = ordered(JSON.parse(server.initial))
    let isOpen = false, query = "", activeValue = null

    const matches = (it) => !query || (text(it) + " " + it.dataset.value).toLowerCase().includes(query.toLowerCase())
    const visible = () => items().filter(matches)
    const activeEl = () => visible().find((it) => it.dataset.value === activeValue)

    const renderLabel = () => {
      const lab = q("label")
      if (!lab) return
      const chosen = items().filter((it) => selected.includes(it.dataset.value))
      lab.classList.toggle("text-muted-foreground", chosen.length === 0)
      if (!chosen.length) { lab.textContent = placeholder; return }
      const t = document.createElement("span")
      t.className = "truncate"
      t.textContent = chosen.slice(0, multiple ? 2 : 1).map(text).join(", ")
      lab.replaceChildren(t)
      if (multiple && chosen.length > 2) {
        const more = document.createElement("span")
        more.className = "shrink-0 text-muted-foreground"
        more.textContent = "+" + (chosen.length - 2)
        const sr = document.createElement("span")
        sr.className = "sr-only"; sr.textContent = " more"
        more.appendChild(sr)
        lab.appendChild(more)
      }
    }

    const writeInputs = () => {
      const single = q("input")
      if (single) single.value = selected[0] || ""
      const sentinel = q("sentinel")
      if (!sentinel) return
      const cur = [...root.querySelectorAll("input[data-" + p + "-value]")]
      if (cur.map((i) => i.value).join("\u0000") === selected.join("\u0000")) return
      cur.forEach((i) => i.remove())
      let after = sentinel
      selected.forEach((v) => {
        const i = document.createElement("input")
        i.type = "hidden"; i.name = sentinel.name + "[]"; i.value = v; i.disabled = sentinel.disabled
        i.setAttribute("data-" + p + "-value", "")
        after.after(i); after = i
      })
    }

    const sync = () => {
      const trigger = q("trigger"), panel = q("panel"), list = q("list") || panel, search = q("search")
      list.id = listId
      list.setAttribute("role", "listbox")
      if (multiple) list.setAttribute("aria-multiselectable", "true")
      panel.classList.toggle("hidden", !isOpen)
      if (p === "select") trigger.setAttribute("role", "combobox")
      trigger.setAttribute("aria-haspopup", "listbox")
      trigger.setAttribute("aria-expanded", String(isOpen))
      trigger.setAttribute("aria-controls", listId)
      if (search) {
        search.setAttribute("role", "combobox")
        search.setAttribute("aria-controls", listId)
        search.setAttribute("aria-expanded", String(isOpen))
        search.setAttribute("aria-autocomplete", "list")
        if (!search.getAttribute("aria-label")) search.setAttribute("aria-label", "Search options")
        if (search.value !== query) search.value = query
      }
      let shown = 0
      items().forEach((it, i) => {
        const on = selected.includes(it.dataset.value)
        it.id = listId + "-opt-" + i
        it.setAttribute("role", "option")
        it.setAttribute("aria-selected", String(on))
        it.tabIndex = -1
        const chk = it.querySelector(":scope > .hero-check")
        if (chk) chk.classList.toggle("opacity-0", !on)
        const m = matches(it)
        row(it).classList.toggle("hidden", !m)
        if (m) shown++
      })
      const empty = q("empty")
      if (empty) empty.classList.toggle("hidden", shown > 0)
      const clear = q("clear")
      if (clear) clear.classList.toggle("hidden", selected.length === 0)
      let act = isOpen ? activeEl() : null
      if (isOpen && !act) { act = visible()[0] || null; activeValue = act ? act.dataset.value : null }
      items().forEach((it) => it.classList.toggle("is-active", it === act))
      const owner = search || trigger
      if (act) owner.setAttribute("aria-activedescendant", act.id)
      else owner.removeAttribute("aria-activedescendant")
      renderLabel()
      writeInputs()
    }

    const emit = () => {
      server.sent(JSON.stringify([...selected].sort()))
      const target = q("sentinel") || q("input")
      if (target) emitChange(target)
      root.dispatchEvent(new CustomEvent(p + "-change", {
        bubbles: true,
        detail: { value: multiple ? [...selected] : selected[0] || null },
      }))
    }

    const open = (o) => {
      if (o === isOpen) return
      isOpen = o
      if (o) {
        query = ""
        const first = items().find((it) => selected.includes(it.dataset.value))
        activeValue = first ? first.dataset.value : null
      }
      sync()
      if (o) {
        const search = q("search")
        if (search) search.focus()
        const a = activeEl(); if (a) a.scrollIntoView({ block: "nearest" })
      }
    }

    const toggle = (it) => {
      const v = it.dataset.value
      activeValue = v
      if (multiple) {
        selected = ordered(selected.includes(v) ? selected.filter((x) => x !== v) : [...selected, v])
        sync(); emit()
      } else {
        const changed = selected[0] !== v
        selected = [v]
        isOpen = false
        sync(); if (changed) emit()
        q("trigger").focus()
      }
    }

    const clear = () => {
      if (!selected.length) return
      selected = []
      sync(); emit()
      ;(q("search") || q("trigger")).focus()
    }

    const move = (to) => {
      const vis = visible()
      if (!vis.length) return
      const i = vis.findIndex((it) => it.dataset.value === activeValue)
      const n = to === "first" ? 0 : to === "last" ? vis.length - 1 : i < 0 ? 0 : (i + to + vis.length) % vis.length
      activeValue = vis[n].dataset.value
      sync()
      vis[n].scrollIntoView({ block: "nearest" })
    }

    root.addEventListener("keydown", (e) => {
      const fromSearch = e.target.matches("[data-" + p + "-search]")
      if (!fromSearch && !e.target.matches("[data-" + p + "-trigger]")) return
      if (!isOpen) {
        if (!fromSearch && ["ArrowDown", "ArrowUp", "Enter", " "].includes(e.key)) { e.preventDefault(); open(true) }
        return
      }
      switch (e.key) {
        case "ArrowDown": e.preventDefault(); move(1); break
        case "ArrowUp": e.preventDefault(); move(-1); break
        case "Home": if (!fromSearch) { e.preventDefault(); move("first") } break
        case "End": if (!fromSearch) { e.preventDefault(); move("last") } break
        case "Enter": e.preventDefault(); if (activeEl()) toggle(activeEl()); break
        case " ": if (!fromSearch) { e.preventDefault(); if (activeEl()) toggle(activeEl()) } break
        // preventDefault also stops Esc from closing a surrounding <dialog> (sheet)
        case "Escape": e.preventDefault(); e.stopPropagation(); open(false); q("trigger").focus(); break
        case "Tab": if (!multiple) open(false); break
      }
    })
    // keep focus on the trigger / search box while clicking rows
    root.addEventListener("mousedown", (e) => {
      if (e.target.closest(itemSel + ", [data-" + p + "-clear-btn]")) e.preventDefault()
    })
    root.addEventListener("click", (e) => {
      if (e.target.closest("[data-" + p + "-trigger]")) { open(!isOpen); return }
      const it = e.target.closest(itemSel)
      if (it) { toggle(it); return }
      if (e.target.closest("[data-" + p + "-clear-btn]")) clear()
    })
    root.addEventListener("mouseover", (e) => {
      const it = e.target.closest(itemSel)
      if (it && isOpen && it.dataset.value !== activeValue) { activeValue = it.dataset.value; sync() }
    })
    // the search box is not a form field: keep its keystrokes away from phx-change
    root.addEventListener("input", (e) => {
      if (!e.target.matches("[data-" + p + "-search]")) return
      e.stopPropagation()
      query = e.target.value
      activeValue = null
      sync()
    })
    root.addEventListener("change", (e) => { if (e.target.matches("[data-" + p + "-search]")) e.stopPropagation() })
    root.addEventListener("focusout", (e) => {
      if (isOpen && e.relatedTarget && !root.contains(e.relatedTarget)) open(false)
    })
    document.addEventListener("click", (e) => { if (isOpen && !root.contains(e.target)) open(false) })

    sync()
    const api = {
      // after a LiveView patch: adopt a genuine server change, then re-apply state
      refresh() {
        const changed = server.changed()
        if (changed !== null) selected = ordered(JSON.parse(changed))
        sync()
      },
    }
    root.__sdPicker = api
    return api
  }

  const initCombobox = (root) => initPicker(root, "combobox")
  const initSelect = (root) => initPicker(root, "select")

  function initCommand(dialog) {
    const search = dialog.querySelector("[data-command-search]")
    const listEl = dialog.querySelector("[data-command-list]")
    const items = [...dialog.querySelectorAll("[data-command-item]")]
    const groups = [...dialog.querySelectorAll("[data-group]")]
    const empty = dialog.querySelector("[data-command-empty]")

    // a11y: combobox-style palette over a listbox of options
    if (!dialog.id) dialog.id = "sd-cmd-" + (++a11yUid)
    const listId = dialog.id + "-list"
    if (listEl) { listEl.id = listId; listEl.setAttribute("role", "listbox") }
    if (search) {
      search.setAttribute("role", "combobox")
      search.setAttribute("aria-controls", listId)
      search.setAttribute("aria-expanded", "true")
      search.setAttribute("aria-autocomplete", "list")
      if (!search.getAttribute("aria-label")) search.setAttribute("aria-label", "Search commands")
    }
    items.forEach((it, i) => {
      it.id = listId + "-opt-" + i
      it.setAttribute("role", "option")
      it.setAttribute("aria-selected", "false")
    })

    let active = -1
    const visible = () => items.filter((it) => !it.parentElement.classList.contains("hidden"))
    const setActive = (i) => {
      const vis = visible()
      items.forEach((it) => { it.classList.remove("bg-accent", "text-accent-foreground"); it.setAttribute("aria-selected", "false") })
      if (!vis.length) { active = -1; search && search.removeAttribute("aria-activedescendant"); return }
      active = (i + vis.length) % vis.length
      const el = vis[active]
      el.classList.add("bg-accent", "text-accent-foreground")
      el.setAttribute("aria-selected", "true")
      el.scrollIntoView({ block: "nearest" })
      search && search.setAttribute("aria-activedescendant", el.id)
    }
    const filter = (q) => {
      const ql = q.toLowerCase()
      let total = 0
      items.forEach((it) => {
        const m = it.textContent.toLowerCase().includes(ql)
        it.parentElement.classList.toggle("hidden", !m)
        if (m) total++
      })
      groups.forEach((g) => {
        let el = g.nextElementSibling, vis = false
        while (el && !el.hasAttribute("data-group")) {
          if (!el.classList.contains("hidden")) vis = true
          el = el.nextElementSibling
        }
        g.classList.toggle("hidden", !vis)
      })
      empty.classList.toggle("hidden", total > 0)
      setActive(0)
    }
    // backdrop click is handled by the module-level dialog listener at the top
    new MutationObserver(() => {
      if (dialog.open) { search.value = ""; filter(""); search.focus() }
    }).observe(dialog, { attributes: true, attributeFilter: ["open"] })
    search.addEventListener("input", () => filter(search.value))
    search.addEventListener("keydown", (e) => {
      if (e.key === "ArrowDown") { e.preventDefault(); setActive(active + 1) }
      else if (e.key === "ArrowUp") { e.preventDefault(); setActive(active - 1) }
      else if (e.key === "Enter") { e.preventDefault(); const v = visible(); if (v[active]) v[active].click() }
    })
    items.forEach((it) => it.addEventListener("click", () => dialog.close()))
    window.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault()
        if (!dialog.open) dialog.showModal()
      }
    })
  }

  function initOtp(root) {
    const slots = [...root.querySelectorAll(".otp-slot")]
    if (!root.getAttribute("role")) root.setAttribute("role", "group")
    if (!root.getAttribute("aria-label")) root.setAttribute("aria-label", "One-time code")
    slots.forEach((s, i) => {
      if (!s.getAttribute("aria-label")) s.setAttribute("aria-label", "Digit " + (i + 1) + " of " + slots.length)
      s.addEventListener("input", () => {
        s.value = s.value.replace(/\D/g, "").slice(0, 1)
        if (s.value && slots[i + 1]) slots[i + 1].focus()
      })
      s.addEventListener("keydown", (e) => {
        if (e.key === "Backspace" && !s.value && slots[i - 1]) slots[i - 1].focus()
      })
      s.addEventListener("paste", (e) => {
        e.preventDefault()
        const digits = (e.clipboardData.getData("text") || "").replace(/\D/g, "").split("")
        slots.forEach((sl, j) => { if (digits[j] != null) sl.value = digits[j] })
        ;(slots.find((sl) => !sl.value) || slots[slots.length - 1]).focus()
      })
    })
  }

  function initContextMenu() {
    const menu = document.querySelector("[data-context-menu]")
    const trigger = document.querySelector("[data-context-menu-trigger]")
    if (!menu || !trigger) return
    menu.setAttribute("role", "menu")
    menu.querySelectorAll("button").forEach((b) => b.setAttribute("role", "menuitem"))
    const hide = () => menu.classList.add("hidden")
    const showAt = (x, y) => {
      menu.classList.remove("hidden")
      menu.style.left = Math.min(x, window.innerWidth - menu.offsetWidth - 8) + "px"
      menu.style.top = Math.min(y, window.innerHeight - menu.offsetHeight - 8) + "px"
      const first = menu.querySelector("button"); if (first) first.focus()
    }
    trigger.addEventListener("contextmenu", (e) => { e.preventDefault(); showAt(e.clientX, e.clientY) })
    menu.addEventListener("keydown", (e) => {
      const btns = [...menu.querySelectorAll("button")]
      const i = btns.indexOf(document.activeElement)
      if (e.key === "Escape") { hide(); trigger.focus() }
      else if (e.key === "ArrowDown") { e.preventDefault(); (btns[i + 1] || btns[0]).focus() }
      else if (e.key === "ArrowUp") { e.preventDefault(); (btns[i - 1] || btns[btns.length - 1]).focus() }
    })
    document.addEventListener("click", hide)
    document.addEventListener("scroll", hide, true)
    window.addEventListener("blur", hide)
    menu.querySelectorAll("button").forEach((b) => b.addEventListener("click", hide))
  }

  function buildCalendar(container, opts) {
    opts = opts || {}
    container.dataset.built = "1"
    const range = opts.mode === "range"
    const monthCount = opts.months || 1
    let view = new Date(opts.selected || opts.start || new Date())
    view.setDate(1)
    let selected = opts.selected || null     // single mode
    const rng = { start: opts.start || null, end: opts.end || null } // range mode
    let hover = null                         // tentative end while picking a range
    let cells = []                           // { el, date } for in-place repaint
    let focusDate = opts.selected || opts.start || null // roving-tabindex target
    const today = new Date()
    const months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    const same = (a, b) =>
      a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    const addMonths = (d, n) => new Date(d.getFullYear(), d.getMonth() + n, 1)
    const addDays = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n)
    const shiftMonths = (d, n) => {
      const last = new Date(d.getFullYear(), d.getMonth() + n + 1, 0).getDate()
      return new Date(d.getFullYear(), d.getMonth() + n, Math.min(d.getDate(), last))
    }

    // returns null, or { endpoint, roundL, roundR } describing the range band at `date`
    const bandInfo = (date) => {
      if (!range || !rng.start) return null
      let lo = rng.start, hi = rng.end
      if (!hi) {
        if (hover) { lo = hover < rng.start ? hover : rng.start; hi = hover < rng.start ? rng.start : hover }
        else return same(date, rng.start) ? { endpoint: true, roundL: true, roundR: true } : null
      }
      if (date < lo || date > hi) return null
      const dow = date.getDay()
      const endpoint = rng.end ? same(date, lo) || same(date, hi) : same(date, rng.start)
      return { endpoint, roundL: same(date, lo) || dow === 0, roundR: same(date, hi) || dow === 6 }
    }

    const paint = () => {
      cells.forEach(({ el, date }) => {
        el.className = "cal-day"
        if (same(date, today)) el.classList.add("is-today")
        const info = bandInfo(date)
        if (info) {
          el.classList.add("in-band")
          if (info.endpoint) el.classList.add("is-selected")
          if (info.roundL) el.classList.add("band-l")
          if (info.roundR) el.classList.add("band-r")
        } else if (!range && same(date, selected)) {
          el.classList.add("is-selected")
        }
        el.setAttribute("aria-selected", el.classList.contains("is-selected") ? "true" : "false")
      })
      // one tab stop per calendar: the focused date, else the selection, else today
      const stop =
        cells.find((c) => same(c.date, focusDate)) ||
        cells.find((c) => c.el.classList.contains("is-selected")) ||
        cells.find((c) => same(c.date, today)) ||
        cells[0]
      cells.forEach((c) => { c.el.tabIndex = c === stop ? 0 : -1 })
    }

    // Arrow keys move a day/week, Home/End to week edges, PageUp/PageDown a
    // month (Shift: a year); the view follows focus across months.
    const moveFocus = (nd) => {
      focusDate = nd
      const first = view
      const lastEnd = new Date(view.getFullYear(), view.getMonth() + monthCount, 0)
      if (nd < first) { view = new Date(nd.getFullYear(), nd.getMonth(), 1); render() }
      else if (nd > lastEnd) { view = addMonths(new Date(nd.getFullYear(), nd.getMonth(), 1), -(monthCount - 1)); render() }
      if (range && rng.start && !rng.end) hover = nd
      paint()
      const cell = cells.find((c) => same(c.date, nd))
      if (cell) cell.el.focus()
    }
    container.addEventListener("keydown", (e) => {
      const cell = cells.find((c) => c.el === e.target)
      if (!cell) return
      const d = cell.date
      const rtl = getComputedStyle(container).direction === "rtl"
      let nd = null
      switch (e.key) {
        case "ArrowLeft": nd = addDays(d, rtl ? 1 : -1); break
        case "ArrowRight": nd = addDays(d, rtl ? -1 : 1); break
        case "ArrowUp": nd = addDays(d, -7); break
        case "ArrowDown": nd = addDays(d, 7); break
        case "Home": nd = addDays(d, -d.getDay()); break
        case "End": nd = addDays(d, 6 - d.getDay()); break
        case "PageUp": nd = shiftMonths(d, e.shiftKey ? -12 : -1); break
        case "PageDown": nd = shiftMonths(d, e.shiftKey ? 12 : 1); break
        default: return
      }
      e.preventDefault()
      moveFocus(nd)
    })

    const navBtn = (glyph, step, pos) => {
      const b = document.createElement("button")
      b.type = "button"
      b.className = "btn btn-ghost btn-square btn-sm absolute top-0 z-10 " + pos
      b.setAttribute("aria-label", step < 0 ? "Previous month" : "Next month")
      b.textContent = glyph
      b.addEventListener("click", (e) => {
        // stopPropagation so a parent popover's outside-click handler doesn't fire
        // after the re-render detaches the clicked button (which would close it)
        e.stopPropagation()
        view.setMonth(view.getMonth() + step)
        render()
      })
      return b
    }

    const renderMonth = (base) => {
      const wrap = document.createElement("div")
      const cap = document.createElement("div")
      cap.className = "mb-2 text-center text-sm font-medium"
      cap.textContent = months[base.getMonth()] + " " + base.getFullYear()
      wrap.appendChild(cap)
      const grid = document.createElement("div")
      grid.className = "cal-grid"
      grid.setAttribute("role", "grid")
      grid.setAttribute("aria-label", cap.textContent)
      const fullDays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
      ;["Su","Mo","Tu","We","Th","Fr","Sa"].forEach((d, i) => {
        const w = document.createElement("div")
        w.className = "cal-weekday"; w.textContent = d
        w.setAttribute("role", "columnheader"); w.setAttribute("aria-label", fullDays[i])
        grid.appendChild(w)
      })
      const firstDay = new Date(base.getFullYear(), base.getMonth(), 1).getDay()
      const days = new Date(base.getFullYear(), base.getMonth() + 1, 0).getDate()
      for (let i = 0; i < firstDay; i++) grid.appendChild(document.createElement("div"))
      for (let d = 1; d <= days; d++) {
        const date = new Date(base.getFullYear(), base.getMonth(), d)
        const cell = document.createElement("button")
        cell.type = "button"; cell.className = "cal-day"; cell.textContent = d
        cell.setAttribute("role", "gridcell")
        cell.setAttribute("aria-label", date.toLocaleDateString(undefined, { weekday: "long", year: "numeric", month: "long", day: "numeric" }))
        cell.addEventListener("click", () => {
          focusDate = date
          if (range) {
            if (!rng.start || rng.end) { rng.start = date; rng.end = null; hover = null }
            else if (date < rng.start) { rng.end = rng.start; rng.start = date }
            else { rng.end = date }
            paint()
            if (opts.onSelect) opts.onSelect({ start: rng.start, end: rng.end })
          } else {
            selected = date; paint()
            if (opts.onSelect) opts.onSelect(date)
          }
        })
        if (range) {
          cell.addEventListener("mouseenter", () => {
            if (rng.start && !rng.end) { hover = date; paint() }
          })
        }
        cells.push({ el: cell, date })
        grid.appendChild(cell)
      }
      wrap.appendChild(grid)
      return wrap
    }

    const render = () => {
      container.replaceChildren()
      cells = []
      const outer = document.createElement("div")
      outer.className = "relative"
      const row = document.createElement("div")
      row.className = "flex flex-col gap-4 sm:flex-row"
      for (let i = 0; i < monthCount; i++) row.appendChild(renderMonth(addMonths(view, i)))
      outer.append(navBtn("‹", -1, "left-1"), row, navBtn("›", 1, "right-1"))
      container.appendChild(outer)
      paint()
    }

    if (range) container.addEventListener("mouseleave", () => { if (hover) { hover = null; paint() } })
    render()
    return {
      // replace the range (range mode) and show its first month
      setRange(start, end) {
        rng.start = start || null; rng.end = end || null; hover = null
        focusDate = rng.start
        if (rng.start) view = new Date(rng.start.getFullYear(), rng.start.getMonth(), 1)
        render()
      },
      setSelected(date) {
        selected = date || null; focusDate = selected
        if (selected) view = new Date(selected.getFullYear(), selected.getMonth(), 1)
        render()
      },
      focus() {
        const cell = container.querySelector('.cal-day[tabindex="0"]')
        if (cell) cell.focus()
      },
    }
  }

  const parseIsoDate = (v) => {
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(v || "")
    return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null
  }
  const isoDate = (d) =>
    d ? d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0") : ""

  // A trigger + popover panel whose open state survives LiveView patches: the
  // server always renders the panel `hidden`, so sync() re-applies `isOpen`.
  // Esc and an outside click close it; a keyboard open focuses `onOpenFocus`.
  function popoverState(root, trigger, panel, hooks) {
    let isOpen = false
    const sync = () => {
      panel.classList.toggle("hidden", !isOpen)
      trigger.setAttribute("aria-haspopup", "dialog")
      trigger.setAttribute("aria-expanded", String(isOpen))
    }
    const set = (o, viaKeyboard) => {
      if (o === isOpen) return
      isOpen = o
      sync()
      if (!o && hooks.onClose) hooks.onClose()
      if (o && viaKeyboard && hooks.onOpenFocus) hooks.onOpenFocus()
    }
    root.addEventListener("click", (e) => {
      if (e.target.closest("[data-" + hooks.prefix + "-trigger]")) set(!isOpen, e.detail === 0)
    })
    root.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && isOpen) {
        e.preventDefault(); e.stopPropagation()
        set(false); root.querySelector("[data-" + hooks.prefix + "-trigger]").focus()
      }
    })
    document.addEventListener("click", (e) => { if (isOpen && !root.contains(e.target)) set(false) })
    sync()
    return { set, sync, isOpen: () => isOpen }
  }

  // <.date_range>: popover range picker. Optional hidden inputs
  // [data-range-start] / [data-range-end] carry ISO dates (YYYY-MM-DD) and
  // dispatch input + change once a full range is committed (a day pair or a
  // [data-daterange-preset]). A half-picked range is dropped on close.
  function initDaterange(root) {
    if (root.__sdRange) return root.__sdRange
    const q = (s) => root.querySelector(s)
    const calEl = q("[data-calendar-range]")
    if (!calEl) return null
    const placeholder = root.dataset.placeholder ?? q("[data-daterange-label]").textContent.trim()
    const md = (d) => d.toLocaleDateString(undefined, { month: "short", day: "numeric" })
    const mdy = (d) => d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })
    const server = serverValue(() => (root.dataset.start || "") + "/" + (root.dataset.end || ""))
    const fromKey = (k) => { const [s, e] = k.split("/"); return { start: parseIsoDate(s), end: parseIsoDate(e) } }
    let committed = fromKey(server.initial)
    if (!committed.start) {
      committed = {
        start: parseIsoDate((q("[data-range-start]") || {}).value),
        end: parseIsoDate((q("[data-range-end]") || {}).value),
      }
    }
    let draft = null // { start } while the second day is pending

    const render = () => {
      pop.sync()
      const label = q("[data-daterange-label]")
      const r = draft || committed
      label.classList.toggle("text-muted-foreground", !r.start)
      label.textContent = !r.start ? placeholder : r.end ? md(r.start) + " – " + mdy(r.end) : md(r.start) + " – …"
      const s = q("[data-range-start]"), e = q("[data-range-end]")
      if (s) s.value = isoDate(committed.start)
      if (e) e.value = isoDate(committed.end)
    }
    const commit = (start, end) => {
      draft = null
      committed = { start, end }
      pop.set(false)
      render()
      const key = isoDate(start) + "/" + isoDate(end)
      server.sent(key)
      const target = q("[data-range-start]") || q("[data-range-end]")
      if (target) emitChange(target)
      root.dispatchEvent(new CustomEvent("range-change", { bubbles: true, detail: { start: isoDate(start), end: isoDate(end) } }))
    }

    const cal = buildCalendar(calEl, {
      mode: "range",
      months: Number(root.dataset.months) || 2,
      start: committed.start,
      end: committed.end,
      onSelect: (sel) => {
        if (sel.start && sel.end) commit(sel.start, sel.end)
        else { draft = { start: sel.start, end: null }; render() }
      },
    })
    const pop = popoverState(root, q("[data-daterange-trigger]"), q("[data-daterange-panel]"), {
      prefix: "daterange",
      onOpenFocus: () => cal.focus(),
      onClose: () => { if (draft) { draft = null; cal.setRange(committed.start, committed.end); render() } },
    })
    root.addEventListener("click", (e) => {
      const b = e.target.closest("[data-daterange-preset]")
      if (!b) return
      let start = parseIsoDate(b.dataset.start), end = parseIsoDate(b.dataset.end)
      const days = Number(b.dataset.days)
      if (days > 0) {
        const now = new Date()
        end = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        start = new Date(end.getFullYear(), end.getMonth(), end.getDate() - (days - 1))
      }
      if (!start || !end) return
      cal.setRange(start, end)
      commit(start, end)
      q("[data-daterange-trigger]").focus()
    })
    render()
    const api = {
      refresh() {
        const changed = server.changed()
        if (changed !== null) {
          committed = fromKey(changed); draft = null
          cal.setRange(committed.start, committed.end)
        }
        render()
      },
    }
    root.__sdRange = api
    return api
  }

  // Inline range calendar (<.range_calendar>). Optional hidden inputs
  // [data-range-start] / [data-range-end] carry ISO dates (YYYY-MM-DD) for
  // forms; they dispatch input + change so LiveView phx-change fires. A
  // "range-change" event with { start, end } bubbles from the root as well.
  function initRangeCalendar(root) {
    if (root.dataset.rcInit) return
    root.dataset.rcInit = "1"
    const mount = root.querySelector("[data-range-calendar-grid]") || root
    const startIn = root.querySelector("[data-range-start]")
    const endIn = root.querySelector("[data-range-end]")
    const set = (input, value) => {
      if (!input || input.value === value) return
      input.value = value
      emitChange(input)
    }
    buildCalendar(mount, {
      mode: "range",
      months: Number(root.dataset.months) || 1,
      start: parseIsoDate((startIn && startIn.value) || root.dataset.start),
      end: parseIsoDate((endIn && endIn.value) || root.dataset.end),
      onSelect: (sel) => {
        set(startIn, isoDate(sel.start))
        set(endIn, isoDate(sel.end))
        root.dispatchEvent(new CustomEvent("range-change", { bubbles: true, detail: { start: isoDate(sel.start), end: isoDate(sel.end) } }))
      },
    })
  }

  function initDatepicker(root) {
    if (root.__sdDate) return root.__sdDate
    const label = root.querySelector("[data-datepicker-label]")
    const calEl = root.querySelector("[data-datepicker-panel] [data-calendar]")
    if (!label || !calEl) return null
    let text = null
    const render = () => {
      pop.sync()
      if (text) { label.textContent = text; label.classList.remove("text-muted-foreground") }
    }
    const cal = buildCalendar(calEl, {
      onSelect: (d) => {
        text = d.toLocaleDateString(undefined, { year: "numeric", month: "long", day: "numeric" })
        pop.set(false)
        render()
        root.querySelector("[data-datepicker-trigger]").focus()
      },
    })
    const pop = popoverState(root, root.querySelector("[data-datepicker-trigger]"), root.querySelector("[data-datepicker-panel]"), {
      prefix: "datepicker",
      onOpenFocus: () => cal.focus(),
    })
    render()
    root.__sdDate = { refresh: render }
    return root.__sdDate
  }

  // SHOWCASE ONLY: renders a fixed demo dataset for the docs gallery. In a real
  // app use ShadcnDaisyui.CoreComponents.table/1 with LiveView-driven sorting,
  // filtering, and pagination (phx-click events) instead of this hook.
  function initDataTable(root) {
    const data = [
      { status: "Success", email: "ken99@example.com", amount: 316 },
      { status: "Success", email: "abe45@example.com", amount: 242 },
      { status: "Processing", email: "monserrat44@example.com", amount: 837 },
      { status: "Failed", email: "carmella@example.com", amount: 721 },
      { status: "Success", email: "jason78@example.com", amount: 450 },
      { status: "Processing", email: "sara.cruz@example.com", amount: 129 },
      { status: "Success", email: "will.smith@example.com", amount: 512 },
      { status: "Failed", email: "noah99@example.com", amount: 98 },
    ]
    const body = root.querySelector("[data-dt-body]")
    const info = root.querySelector("[data-dt-info]")
    const filterEl = root.querySelector("[data-dt-filter]")
    const prev = root.querySelector("[data-dt-prev]")
    const next = root.querySelector("[data-dt-next]")
    const resetBtn = root.querySelector("[data-dt-reset]")
    const facetWrap = root.querySelector("[data-dt-facet]")
    const facetTrigger = root.querySelector("[data-dt-facet-trigger]")
    const facetPanel = root.querySelector("[data-dt-facet-panel]")
    const facetList = root.querySelector("[data-dt-facet-list]")
    const facetBadges = root.querySelector("[data-dt-facet-badges]")
    const facetClear = root.querySelector("[data-dt-facet-clear]")
    const facetClearBtn = root.querySelector("[data-dt-facet-clear-btn]")
    const pageSize = 5
    let page = 0, sortKey = null, sortDir = 1, q = ""
    const facet = new Set()
    const badgeClass = (s) => (s === "Success" ? "badge-secondary" : s === "Failed" ? "badge-error" : "badge-outline")
    const counts = {}; data.forEach((r) => { counts[r.status] = (counts[r.status] || 0) + 1 })
    const statuses = Object.keys(counts)
    const el = (tag, cls, text) => {
      const n = document.createElement(tag)
      if (cls) n.className = cls
      if (text != null) n.textContent = text
      return n
    }

    const setIcons = () => {
      root.querySelectorAll("th[data-dt-sort]").forEach((th) => {
        const active = th.dataset.dtSort === sortKey
        th.setAttribute("aria-sort", !active ? "none" : sortDir === 1 ? "ascending" : "descending")
        const ic = th.querySelector("[data-dt-sort-icon]")
        if (!ic) return
        const name = !active ? "hero-chevron-up-down" : sortDir === 1 ? "hero-arrow-up" : "hero-arrow-down"
        ic.className = name + " size-3.5 " + (active ? "opacity-100" : "opacity-50")
        ic.setAttribute("aria-hidden", "true")
      })
    }

    const render = () => {
      let rows = data.filter((r) => r.email.toLowerCase().includes(q) && (facet.size === 0 || facet.has(r.status)))
      if (sortKey) rows.sort((a, b) => (a[sortKey] > b[sortKey] ? 1 : a[sortKey] < b[sortKey] ? -1 : 0) * sortDir)
      const pages = Math.max(1, Math.ceil(rows.length / pageSize))
      page = Math.min(page, pages - 1)
      body.replaceChildren()
      rows.slice(page * pageSize, page * pageSize + pageSize).forEach((r) => {
        const tr = document.createElement("tr")
        const td1 = document.createElement("td")
        td1.appendChild(el("span", "badge " + badgeClass(r.status), r.status))
        tr.append(td1, el("td", "truncate", r.email), el("td", "text-right tabular-nums", "$" + r.amount.toFixed(2)))
        body.appendChild(tr)
      })
      info.textContent = rows.length + " row(s) · page " + (page + 1) + " of " + pages
      prev.disabled = page === 0
      next.disabled = page >= pages - 1
      setIcons()
    }

    const updateBadges = () => {
      facetBadges.replaceChildren()
      if (facet.size === 0) { facetBadges.className = "hidden"; return }
      facetBadges.className = "flex items-center gap-1"
      facetBadges.appendChild(el("span", "mx-1 h-4 w-px bg-border"))
      if (facet.size > 2) {
        facetBadges.appendChild(el("span", "badge badge-secondary rounded-sm px-1 font-normal", facet.size + " selected"))
      } else {
        facet.forEach((v) => facetBadges.appendChild(el("span", "badge badge-secondary rounded-sm px-1 font-normal", v)))
      }
    }
    const updateReset = () => { resetBtn.classList.toggle("hidden", q === "" && facet.size === 0) }
    const renderFacet = () => {
      facetList.replaceChildren()
      statuses.forEach((s) => {
        const li = document.createElement("li")
        const btn = el("button", "combo-item"); btn.type = "button"
        btn.append(
          el("span", "facet-check" + (facet.has(s) ? " is-on" : ""), facet.has(s) ? "✓" : ""),
          el("span", null, s),
          el("span", "ml-auto font-mono text-xs text-muted-foreground", counts[s])
        )
        btn.addEventListener("click", () => {
          if (facet.has(s)) facet.delete(s); else facet.add(s)
          page = 0; render(); renderFacet(); updateBadges(); updateReset()
        })
        li.appendChild(btn); facetList.appendChild(li)
      })
      facetClear.classList.toggle("hidden", facet.size === 0)
    }

    root.querySelectorAll("th[data-dt-sort]").forEach((th) => {
      th.setAttribute("tabindex", "0")
      th.setAttribute("aria-sort", "none")
      th.classList.add("cursor-pointer")
      const sort = () => {
        const k = th.dataset.dtSort
        if (sortKey === k) sortDir = -sortDir
        else { sortKey = k; sortDir = 1 }
        render()
      }
      th.addEventListener("click", sort)
      th.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") { e.preventDefault(); sort() }
      })
    })
    filterEl.addEventListener("input", () => { q = filterEl.value.toLowerCase(); page = 0; render(); updateReset() })
    prev.addEventListener("click", () => { if (page > 0) { page--; render() } })
    next.addEventListener("click", () => { page++; render() })
    facetTrigger.addEventListener("click", () => facetPanel.classList.toggle("hidden"))
    document.addEventListener("click", (e) => { if (!facetWrap.contains(e.target)) facetPanel.classList.add("hidden") })
    facetClearBtn.addEventListener("click", () => { facet.clear(); page = 0; render(); renderFacet(); updateBadges(); updateReset() })
    resetBtn.addEventListener("click", () => {
      facet.clear(); q = ""; filterEl.value = ""; page = 0
      render(); renderFacet(); updateBadges(); updateReset(); facetPanel.classList.add("hidden")
    })

    renderFacet(); render()
  }

  function initCarousel(carousel) {
    const wrap = carousel.parentElement
    carousel.setAttribute("role", "group")
    carousel.setAttribute("aria-roledescription", "carousel")
    if (!carousel.getAttribute("aria-label")) carousel.setAttribute("aria-label", "Carousel")
    const prev = wrap.querySelector("[data-carousel-prev]")
    const next = wrap.querySelector("[data-carousel-next]")
    if (next) {
      if (!next.getAttribute("aria-label")) next.setAttribute("aria-label", "Next slide")
      next.addEventListener("click", () => carousel.scrollBy({ left: carousel.clientWidth, behavior: "smooth" }))
    }
    if (prev) {
      if (!prev.getAttribute("aria-label")) prev.setAttribute("aria-label", "Previous slide")
      prev.addEventListener("click", () => carousel.scrollBy({ left: -carousel.clientWidth, behavior: "smooth" }))
    }
  }


// ---- Public API -----------------------------------------------------------

// Switch the active theme without the light↔dark colour fade flickering.
//
// The CSS only zeroes out transition-duration while <html> carries the
// `theme-transition` class. This helper adds that class, swaps `data-theme` in
// the same tick (so the new theme paints with transitions disabled — no
// flicker), then drops the class on the next frame so hover/focus transitions
// resume. Pass null / "system" to clear the attribute (follow the OS).
//
//   import { setTheme } from "shadcn-daisyui"
//   setTheme("shadcn-dark")
//
// In LiveView, wire it to the standard phx:set-theme event:
//   window.addEventListener("phx:set-theme", (e) => setTheme(e.target.dataset.phxTheme))
export function setTheme(theme) {
  const el = document.documentElement
  el.classList.add("theme-transition")
  if (!theme || theme === "system") el.removeAttribute("data-theme")
  else el.setAttribute("data-theme", theme)
  // Re-enable transitions only after the swapped theme has painted.
  requestAnimationFrame(() =>
    requestAnimationFrame(() => el.classList.remove("theme-transition"))
  )
}

// Wire every component found under `root` (default: whole document). For dead
// views / plain HTML. Safe to call once on page load.
export function initShadcnDaisyui(root) {
  root = root || document
  root.querySelectorAll("[data-combobox]").forEach(initCombobox)
  root.querySelectorAll("[data-select]").forEach(initSelect)
  root.querySelectorAll("[data-command]").forEach(initCommand)
  root.querySelectorAll("[data-otp]").forEach(initOtp)
  root.querySelectorAll("[data-datepicker]").forEach(initDatepicker)
  root.querySelectorAll("[data-daterange]").forEach(initDaterange)
  root.querySelectorAll("[data-range-calendar]").forEach(initRangeCalendar)
  root.querySelectorAll("[data-calendar]").forEach((el) => { if (!el.dataset.built) buildCalendar(el) })
  root.querySelectorAll("[data-datatable]").forEach(initDataTable)
  root.querySelectorAll("[data-carousel]").forEach(initCarousel)
  root.querySelectorAll("[data-resizable]").forEach(initResizable)
  initContextMenu()
  initDock(root)
}

// Phoenix LiveView hooks. Attach with phx-hook="ShadcnCombobox" etc.
export const Hooks = {
  // updated(): a patch re-renders the server markup (closed panel, server
  // label); refresh() re-applies the client state and adopts server changes.
  ShadcnCombobox: { mounted() { this.api = initCombobox(this.el) }, updated() { this.api && this.api.refresh() } },
  ShadcnSelect: { mounted() { this.api = initSelect(this.el) }, updated() { this.api && this.api.refresh() } },
  ShadcnCommand: { mounted() { initCommand(this.el) } },
  ShadcnOtp: { mounted() { initOtp(this.el) } },
  ShadcnContextMenu: { mounted() { initContextMenu() } },
  ShadcnCalendar: { mounted() { if (!this.el.dataset.built) buildCalendar(this.el) } },
  ShadcnDatePicker: { mounted() { this.api = initDatepicker(this.el) }, updated() { this.api && this.api.refresh() } },
  ShadcnDateRange: { mounted() { this.api = initDaterange(this.el) }, updated() { this.api && this.api.refresh() } },
  ShadcnRangeCalendar: { mounted() { initRangeCalendar(this.el) } },
  ShadcnToaster: {
    mounted() {
      toasterSection()
      this.handleEvent("shadcn:toast", (payload) => toastFromServer(payload, this))
    },
  },
  ShadcnDataTable: { mounted() { initDataTable(this.el) } },
  ShadcnCarousel: { mounted() { initCarousel(this.el) } },
  ShadcnResizable: { mounted() { initResizable(this.el) } },
}

export { toast, showToast }
