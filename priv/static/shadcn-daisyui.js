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
    hostToasts() // toasts follow into the new modal, above it
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

// Sheet / drawer scroll edges: while content is scrolled under the header or
// footer, the dialog gets data-scroll-top / data-scroll-bottom and the theme
// draws a 1px line there. Bodies are found when their dialog opens (focus moves
// into it on showModal, whichever way it was opened) and then watched with a
// ResizeObserver - on the body (open, viewport) and its content wrapper (a
// LiveView patch that grows or shrinks it) - plus one capturing scroll listener.
// The components keep both attributes across patches (JS.ignore_attributes).
const OVERLAY_BODY = ":scope > .sheet-body, :scope > .drawer-body"
function syncScrollEdges(body) {
  const d = body.parentElement
  if (!d) return
  const top = body.scrollTop > 0.5
  const bottom = body.scrollHeight - body.clientHeight - body.scrollTop > 1
  if (d.hasAttribute("data-scroll-top") !== top) d.toggleAttribute("data-scroll-top", top)
  if (d.hasAttribute("data-scroll-bottom") !== bottom) d.toggleAttribute("data-scroll-bottom", bottom)
}
if (typeof window !== "undefined" && !window.__shadcnScrollEdges) {
  window.__shadcnScrollEdges = true
  const watched = new WeakSet()
  const ro = typeof ResizeObserver !== "undefined"
    ? new ResizeObserver((entries) => {
        for (const e of entries) {
          const body = e.target.matches(".sheet-body, .drawer-body") ? e.target : e.target.parentElement
          if (body) syncScrollEdges(body)
        }
      })
    : null
  const watch = (d) => {
    const body = d && d.querySelector(OVERLAY_BODY)
    if (!body) return
    syncScrollEdges(body)
    if (!ro) return
    if (!watched.has(body)) { watched.add(body); ro.observe(body) }
    const content = body.firstElementChild
    if (content && !watched.has(content)) { watched.add(content); ro.observe(content) }
  }
  const dialogOf = (el) => el instanceof Element && el.closest("dialog.sheet, dialog.drawer-bottom")
  document.addEventListener("focusin", (e) => watch(dialogOf(e.target)))
  document.addEventListener("toggle", (e) => watch(dialogOf(e.target)), true)
  window.addEventListener("shadcn:show-modal", (e) => watch(dialogOf(e.target)))
  document.addEventListener("scroll", (e) => {
    const t = e.target
    if (t instanceof Element && t.matches(".sheet-body, .drawer-body")) syncScrollEdges(t)
  }, { capture: true, passive: true })
}

// <.reveal>: `<button data-reveal-toggle="id">` opens/closes the reveal with that
// id (flips its data-open, mirrors aria-expanded on every toggle for it). One
// delegated listener, so it is CSP-safe and works in dead views and LiveView.
if (typeof window !== "undefined" && !window.__shadcnRevealToggle) {
  window.__shadcnRevealToggle = true
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-reveal-toggle]")
    const el = btn && document.getElementById(btn.dataset.revealToggle)
    if (!el) return
    const open = !el.hasAttribute("data-open")
    el.toggleAttribute("data-open", open)
    document.querySelectorAll("[data-reveal-toggle]").forEach((b) => {
      if (b.dataset.revealToggle !== el.id) return
      b.setAttribute("aria-expanded", String(open))
      if (!b.hasAttribute("aria-controls")) b.setAttribute("aria-controls", el.id)
    })
  })
}

// <.dropdown_menu close_on_select>: choosing an item closes the menu. The menu
// is open while focus is inside it (daisyUI :focus-within), so blur it. One
// delegated listener: CSP-safe, dead views and LiveView alike. Disabled items
// have pointer-events: none, so their clicks never land here.
if (typeof window !== "undefined" && !window.__shadcnDropdownClose) {
  window.__shadcnDropdownClose = true
  document.addEventListener("click", (e) => {
    const item = e.target instanceof Element && e.target.closest(".dropdown-content li > :is(a, button)")
    const menu = item && item.closest(".dropdown[data-close-on-select]")
    if (!menu || item.getAttribute("aria-disabled") === "true") return
    const active = document.activeElement
    if (active instanceof HTMLElement && menu.contains(active)) active.blur()
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

const sonner = { toasts: [], seq: 0, hotkey: false, layer: null, modals: [] }

// <.toaster> renders a <section data-sonner-section> that only carries the
// options (and the LiveView hook). The toasts live in a JS-owned
// <div popover="manual" data-sonner-layer> in the browser's top layer, so no
// z-index can cover them. An open modal <dialog> makes everything outside it
// inert (unclickable, unfocusable) - even a popover painted above it - so
// while a modal is open the layer moves INSIDE the topmost one (into its
// [data-toast-host], which is phx-update="ignore" so LiveView patches leave it
// alone) and is shown again, which also re-raises it above that modal.
function toasterSection() {
  let section = document.querySelector("[data-sonner-section]")
  if (!section) {
    section = document.createElement("section")
    section.setAttribute("data-sonner-section", "")
    section.hidden = true
    document.body.appendChild(section)
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

function toasterLayer() {
  if (!sonner.layer) {
    const layer = document.createElement("div")
    layer.setAttribute("data-sonner-layer", "")
    layer.setAttribute("popover", "manual")
    layer.setAttribute("role", "region")
    layer.setAttribute("aria-label", "Notifications alt+T")
    layer.setAttribute("aria-live", "polite")
    layer.setAttribute("aria-relevant", "additions text")
    layer.setAttribute("aria-atomic", "false")
    // Clicking a toast never moves focus (it stays in the page or the open
    // modal, so Esc still closes the modal). Swipe uses pointer events.
    layer.addEventListener("mousedown", (e) => e.preventDefault())
    sonner.layer = layer
  }
  hostToasts()
  return sonner.layer
}

// Track open modal dialogs in the order they opened (the last is on top).
function syncModals() {
  const open = [...document.querySelectorAll("dialog[open]")].filter((d) => d.matches(":modal"))
  sonner.modals = sonner.modals.filter((d) => open.includes(d))
  open.forEach((d) => { if (!sonner.modals.includes(d)) sonner.modals.push(d) })
}

// Put the layer in the topmost modal (or <body>) and keep it showing. Moving
// a popover hides it, and showing it again puts it on top of the top layer.
function hostToasts() {
  const layer = sonner.layer
  if (!layer || typeof layer.showPopover !== "function") return
  syncModals()
  const top = sonner.modals[sonner.modals.length - 1]
  const host = top
    ? [...top.querySelectorAll("[data-toast-host]")].find((h) => h.closest("dialog") === top) || top
    : document.body
  if (layer.parentNode !== host) host.appendChild(layer)
  if (!layer.matches(":popover-open")) layer.showPopover()
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
  let ol = toasterLayer().querySelector('[data-sonner-toaster][data-position="' + position + '"]')
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
  toasterLayer().appendChild(ol)
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
  t.timer = setTimeout(() => dismissToast(t.id, "auto"), t.remaining)
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
  el.setAttribute("role", t.type === "error" ? "alert" : "status")
  el.setAttribute("aria-live", t.type === "error" || t.important ? "assertive" : "polite")
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
      closeButton: data.closeButton != null ? data.closeButton : existing.closeButton,
      onDismiss: data.onDismiss,
      onAutoClose: data.onAutoClose,
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
    onDismiss: data.onDismiss,
    onAutoClose: data.onAutoClose,
    position,
    ol,
    remaining: null,
  }
  const el = document.createElement("li")
  el.setAttribute("data-sonner-toast", "")
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

// `how`: "auto" (timer ran out -> onAutoClose), "silent" (no callback), or
// omitted (closed by the user or toast.dismiss() -> onDismiss), as in sonner.
function dismissToast(id, how) {
  const targets = id == null ? sonner.toasts.slice() : sonner.toasts.filter((t) => t.id === id)
  targets.forEach((t) => {
    if (t.removed) return
    t.removed = true
    clearTimeout(t.timer)
    const cb = how === "auto" ? t.onAutoClose : how === "silent" ? null : t.onDismiss
    if (cb) cb(t)
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
toast.dismiss = (id) => dismissToast(id)
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

// LiveView: ShadcnDaisyui.Components.push_toast/3 pushes "shadcn:toast",
// which LiveView dispatches on window as "phx:shadcn:toast"; one window
// listener renders it. (The <.toaster> sits in the root layout, outside every
// LiveView, where LiveView may never mount its hook and a hook's pushEvent has
// no view to reach.) An action with an `event` is pushed to the main view.
function pushToastEvent(event, value) {
  const main = document.querySelector("[data-phx-main]") || document.querySelector("[data-phx-session]")
  const socket = sonner.liveSocket || window.liveSocket
  if (main && socket) socket.execJS(main, JSON.stringify([["push", { event, value }]]))
}

if (typeof window !== "undefined" && !window.__shadcnServerToasts) {
  window.__shadcnServerToasts = true
  window.addEventListener("phx:shadcn:toast", (e) => toastFromServer(e.detail))
}

function toastFromServer(payload) {
  const p = payload || {}
  const wrap = (spec) =>
    spec && {
      label: spec.label,
      onClick: () => { if (spec.event) pushToastEvent(spec.event, spec.value || {}) },
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

// ---- Flash as Sonner ---------------------------------------------------------
// <.flash> (ShadcnDaisyui.CoreComponents) renders a [data-flash] element that
// stays the source of truth: LiveView owns it, so it can't move into an open
// modal. While this module is loaded it is hidden (html[data-sonner-flash])
// and shown as a toast instead - in the toast layer, so it sits above sheets
// and dialogs and stays clickable. Info flashes clear after their duration
// (paused on hover/focus), errors stay. Closing or timing out clicks the
// flash's own close button, whose phx-click pushes lv:clear-flash.
const flashes = new Map() // el -> { key, observer }

function flashVisible(el) {
  return el.isConnected && !el.hidden && el.style.display !== "none"
}

function syncFlash(el) {
  let f = flashes.get(el)
  if (!f) {
    f = { key: null }
    f.observer = new MutationObserver(() => syncFlash(el))
    f.observer.observe(el, { attributes: true, attributeFilter: ["hidden", "style"], childList: true, subtree: true, characterData: true })
    flashes.set(el, f)
  }
  const id = "flash:" + el.id
  if (!flashVisible(el)) {
    if (!el.isConnected) { f.observer.disconnect(); flashes.delete(el) }
    if (f.key != null) dismissToast(id, "silent")
    f.key = null
    return
  }
  const text = (sel) => { const n = el.querySelector(sel); return n ? n.textContent.trim() : "" }
  const title = text("[data-flash-title]")
  const message = text("[data-flash-message]")
  const type = el.dataset.type === "error" ? "error" : "success"
  const key = [type, title, message].join("\u0000")
  if (key === f.key) return
  f.key = key
  const close = () => { const b = el.querySelector("[data-flash-close]"); if (b) b.click() }
  createToast(title || message, {
    id,
    type,
    description: title ? message : undefined,
    duration: type === "error" ? Infinity : Number(el.dataset.duration) || 5000,
    position: el.dataset.position,
    closeButton: true,
    onDismiss: close,
    onAutoClose: close,
  })
}

function syncFlashes() {
  flashes.forEach((_f, el) => { if (!el.isConnected) syncFlash(el) })
  document.querySelectorAll("[data-flash][id]").forEach(syncFlash)
}

// One observer keeps both in step with the page: a dialog opening or closing
// (the `open` attribute flips before the next paint, whoever called
// showModal) re-hosts the toast layer; LiveView patches add/remove flashes
// or drop a layer that sat in a dialog without a toast host.
if (typeof window !== "undefined" && typeof MutationObserver !== "undefined" && !window.__shadcnToastLayer) {
  window.__shadcnToastLayer = true
  const start = () => {
    document.documentElement.setAttribute("data-sonner-flash", "")
    syncFlashes()
    new MutationObserver((records) => {
      let dialogs = false
      let nodes = false
      for (const r of records) {
        if (r.type === "attributes") dialogs = true
        else nodes = true
      }
      if (sonner.layer && (dialogs || !sonner.layer.isConnected || !sonner.layer.matches(":popover-open"))) hostToasts()
      if (nodes) syncFlashes()
    }).observe(document.documentElement, { subtree: true, childList: true, attributes: true, attributeFilter: ["open"] })
    // dialog toggle/close don't bubble; listen in the capture phase
    document.addEventListener("toggle", (e) => { if (e.target instanceof HTMLDialogElement) hostToasts() }, true)
    document.addEventListener("close", (e) => { if (e.target instanceof HTMLDialogElement) hostToasts() }, true)
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start)
  else start()
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
      const t = document.createElement("span")
      t.className = "truncate"
      t.textContent = chosen.length ? chosen.slice(0, multiple ? 2 : 1).map(text).join(", ") : placeholder
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
    // composedPath: opening re-renders the label, so a click on the placeholder
    // text has a detached target by now - it still counts as inside
    document.addEventListener("click", (e) => { if (isOpen && !e.composedPath().includes(root)) open(false) })

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
    document.addEventListener("click", (e) => { if (isOpen && !e.composedPath().includes(root)) set(false) })
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

  // <.time_picker>: hour / minute (/ second) / AM-PM listbox columns in a
  // popover. State is { h, m, s } in 24-hour time; render() writes it to the
  // label, the options and the optional [data-timepicker-input] (ISO HH:MM or
  // HH:MM:SS), so refresh() can restore it after a patch. Every pick commits
  // and dispatches input + change. Up/Down pick in a column, Left/Right move
  // between columns, Enter closes.
  function initTimepicker(root) {
    if (root.__sdTime) return root.__sdTime
    const q = (s) => root.querySelector(s)
    const trigger = q("[data-timepicker-trigger]"), panel = q("[data-timepicker-panel]")
    if (!trigger || !panel) return null
    const twelve = root.dataset.hourCycle !== "24"
    const withSeconds = root.hasAttribute("data-seconds")
    const placeholder = root.dataset.placeholder ?? q("[data-timepicker-label]").textContent.trim()
    const pad = (n) => String(n).padStart(2, "0")
    const parse = (v) => {
      const m = /^(\d{2}):(\d{2})(?::(\d{2}))?/.exec(v || "")
      return m ? { h: +m[1], m: +m[2], s: +(m[3] || 0) } : null
    }
    const iso = (t) => (t ? pad(t.h) + ":" + pad(t.m) + (withSeconds ? ":" + pad(t.s) : "") : "")
    const h12 = (h) => (h % 12 === 0 ? 12 : h % 12)
    const label = (t) =>
      (twelve ? h12(t.h) : pad(t.h)) + ":" + pad(t.m) + (withSeconds ? ":" + pad(t.s) : "") +
      (twelve ? (t.h < 12 ? " AM" : " PM") : "")
    // The option value each column shows as selected for a time.
    const part = (key, t) =>
      key === "h" ? String(twelve ? h12(t.h) : t.h)
        : key === "m" ? String(t.m)
        : key === "s" ? String(t.s)
        : t.h < 12 ? "AM" : "PM"
    const cols = () => [...root.querySelectorAll("[data-time-col]")]
    const options = (col) => [...col.querySelectorAll("[role=option]")]
    const server = serverValue(() => root.dataset.value || "")
    let value = parse(server.initial) || parse((q("[data-timepicker-input]") || {}).value)

    const render = () => {
      pop.sync()
      const l = q("[data-timepicker-label]")
      l.textContent = value ? label(value) : placeholder
      l.classList.toggle("text-muted-foreground", !value)
      const input = q("[data-timepicker-input]")
      if (input) input.value = iso(value)
      cols().forEach((col) => {
        const sel = value && part(col.dataset.timeCol, value)
        const opts = options(col)
        const stop = opts.find((o) => o.dataset.value === sel) || opts[0]
        opts.forEach((o) => {
          o.setAttribute("aria-selected", String(o.dataset.value === sel))
          o.tabIndex = o === stop ? 0 : -1
        })
      })
    }
    // Scroll each column so its selected option sits at the top (on open).
    const alignColumns = () =>
      cols().forEach((col) => {
        const sel = col.querySelector("[aria-selected=true]")
        col.scrollTop = sel ? sel.offsetTop - col.firstElementChild.offsetTop : 0
      })
    const pick = (key, raw) => {
      const t = value ? { ...value } : { h: 0, m: 0, s: 0 }
      if (key === "h") {
        const n = +raw
        t.h = twelve ? (n % 12) + (t.h >= 12 ? 12 : 0) : n
      } else if (key === "m") t.m = +raw
      else if (key === "s") t.s = +raw
      else if (raw === "AM" && t.h >= 12) t.h -= 12
      else if (raw === "PM" && t.h < 12) t.h += 12
      value = t
      render()
      const key2 = iso(value)
      server.sent(key2)
      const input = q("[data-timepicker-input]")
      if (input) emitChange(input)
      root.dispatchEvent(new CustomEvent("time-change", { bubbles: true, detail: { value: key2 } }))
    }

    const pop = popoverState(root, trigger, panel, {
      prefix: "timepicker",
      onOpenFocus: () => {
        alignColumns()
        const c = cols()[0]
        if (c) c.querySelector("[tabindex='0']").focus({ preventScroll: true })
      },
    })
    // After popoverState's own root listener, so a pointer open sees isOpen.
    root.addEventListener("click", (e) => {
      if (e.target.closest("[data-timepicker-trigger]") && pop.isOpen()) alignColumns()
    })
    root.addEventListener("click", (e) => {
      const o = e.target.closest("[data-time-col] [role=option]")
      if (!o) return
      pick(o.closest("[data-time-col]").dataset.timeCol, o.dataset.value)
      o.scrollIntoView({ block: "nearest" })
    })
    panel.addEventListener("keydown", (e) => {
      const o = e.target.closest("[role=option]")
      if (!o) return
      const col = o.closest("[data-time-col]"), opts = options(col), i = opts.indexOf(o)
      const all = cols(), c = all.indexOf(col)
      let next = null
      if (e.key === "ArrowDown") next = opts[Math.min(i + 1, opts.length - 1)]
      else if (e.key === "ArrowUp") next = opts[Math.max(i - 1, 0)]
      else if (e.key === "Home") next = opts[0]
      else if (e.key === "End") next = opts[opts.length - 1]
      else if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
        const to = all[c + (e.key === "ArrowRight" ? 1 : -1)]
        if (to) { e.preventDefault(); to.querySelector("[tabindex='0']").focus() }
        return
      } else if (e.key === "Enter") {
        e.preventDefault()
        if (o.getAttribute("aria-selected") !== "true") pick(col.dataset.timeCol, o.dataset.value)
        pop.set(false); trigger.focus()
        return
      } else if (e.key === " ") {
        e.preventDefault(); pick(col.dataset.timeCol, o.dataset.value)
        return
      } else return
      e.preventDefault()
      pick(col.dataset.timeCol, next.dataset.value)
      next.focus()
      next.scrollIntoView({ block: "nearest" })
    })
    render()
    const api = {
      refresh() {
        const changed = server.changed()
        if (changed !== null) value = parse(changed)
        render()
      },
    }
    root.__sdTime = api
    return api
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
    document.addEventListener("click", (e) => { if (!e.composedPath().includes(facetWrap)) facetPanel.classList.add("hidden") })
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


// ---- Width-aware overflow: tab nav + chip row ------------------------------
// Both rows render every item twice: once in the row and once (hidden) in the
// overflow panel. Fitting only flips `hidden` on the two copies and never
// moves server-rendered nodes, so LiveView patches stay safe (the components
// mark those attributes with JS.ignore_attributes so a patch doesn't reset
// them, and the hooks re-fit in updated()). Measuring and applying run in one
// synchronous pass inside the ResizeObserver callback or updated(), before the
// browser paints, so the row never visibly jumps.

const outerW = (el) => el.getBoundingClientRect().width
function contentW(el) {
  const cs = getComputedStyle(el)
  return el.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight)
}
const rowGap = (el) => parseFloat(getComputedStyle(el).columnGap) || 0

// Which items stay in the row (indexes, ascending). Items keep their order
// while they fit; once some don't, the overflow control (moreW wide) takes
// their place. `pinned` (the active tab) always stays: it swaps out the last
// visible items until it fits. `moreAlways`: the overflow control shows anyway
// (it holds extra entries), so it always takes its space.
function fitRow({ widths, avail, gap, moreW, moreAlways, pinned }) {
  const span = (idx) => idx.reduce((s, i) => s + widths[i], 0) + gap * Math.max(0, idx.length - 1)
  const withMore = (idx) => span(idx) + (idx.length ? gap : 0) + moreW
  const fits = (w) => w <= avail + 0.5 // sub-pixel widths
  const all = widths.map((_, i) => i)
  if (fits(moreAlways ? withMore(all) : span(all))) return all
  const vis = []
  for (const i of all) {
    if (!fits(withMore([...vis, i]))) break
    vis.push(i)
  }
  if (pinned >= 0 && !vis.includes(pinned)) {
    while (vis.length && !fits(withMore([...vis, pinned]))) vis.pop()
    vis.push(pinned)
  }
  return vis
}

// A trigger + panel inside `root` (the More menu, the +N popover). Listeners
// are delegated and nodes are looked up on use, so a patch that replaces them
// keeps working; sync() re-applies the open state after a patch.
function disclosure(root, sel, { flipTo, horizontal, pick }) {
  let isOpen = false
  const get = (s) => root.querySelector(s)
  const items = () => [...root.querySelectorAll(sel.item)].filter((el) => el.offsetParent !== null)
  const sync = () => {
    const t = get(sel.trigger)
    const p = get(sel.panel)
    if (!t || !p) return
    t.setAttribute("aria-expanded", String(isOpen))
    p.hidden = !isOpen
    if (!isOpen) return
    // keep the panel on screen: flip its alignment when it would overflow
    p.removeAttribute("data-align")
    const r = p.getBoundingClientRect()
    if (r.left < 8 || r.right > document.documentElement.clientWidth - 8) p.setAttribute("data-align", flipTo)
  }
  const set = (open, focus) => {
    isOpen = open
    sync()
    if (!open || !focus) return
    const list = items()
    const el = focus === "last" ? list[list.length - 1] : list[0]
    if (el) el.focus()
  }
  // e.detail === 0: keyboard activation (Enter / Space) - move into the panel.
  // Choosing a `pick` entry (a menu link; patch links don't reload) closes it.
  root.addEventListener("click", (e) => {
    if (e.target.closest(sel.trigger)) set(!isOpen, e.detail === 0 && "first")
    else if (isOpen && pick && e.target.closest(sel.panel) && e.target.closest(pick)) {
      set(false)
      if (e.detail === 0) { const t = get(sel.trigger); if (t) t.focus() }
    }
  })
  root.addEventListener("keydown", (e) => {
    if (e.target.closest(sel.trigger)) {
      if (e.key === "ArrowDown") { e.preventDefault(); set(true, "first") }
      else if (e.key === "ArrowUp") { e.preventDefault(); set(true, "last") }
      else if (e.key === "Escape" && isOpen) { e.preventDefault(); e.stopPropagation(); set(false) }
      return
    }
    if (!isOpen || !e.target.closest(sel.panel)) return
    const list = items()
    const i = list.indexOf(document.activeElement)
    const go = (j) => { e.preventDefault(); if (list.length) list[(j + list.length) % list.length].focus() }
    if (e.key === "ArrowDown" || (horizontal && e.key === "ArrowRight")) go(i + 1)
    else if (e.key === "ArrowUp" || (horizontal && e.key === "ArrowLeft")) go(i < 0 ? list.length - 1 : i - 1)
    else if (e.key === "Home") go(0)
    else if (e.key === "End") go(list.length - 1)
    else if (e.key === "Escape") {
      // stopPropagation: don't also close a surrounding sheet / dialog
      e.preventDefault(); e.stopPropagation(); set(false)
      const t = get(sel.trigger)
      if (t) t.focus()
    }
  })
  root.addEventListener("focusout", (e) => {
    if (isOpen && e.relatedTarget && !e.relatedTarget.closest(sel.wrap)) set(false)
  })
  // composedPath: a click that removes its own target (a chip's ×) still counts as inside
  document.addEventListener("click", (e) => {
    const wrap = get(sel.wrap)
    if (isOpen && !(wrap && e.composedPath().includes(wrap))) set(false)
  })
  return { sync, set, isOpen: () => isOpen }
}

// <.tab_nav>: link tabs; the ones that don't fit move into the More menu.
function initTabNav(root) {
  if (root.__sdTabNav) return root.__sdTabNav
  const q = (s) => root.querySelector(s)
  const qa = (s) => [...root.querySelectorAll(s)]
  const menu = disclosure(root, {
    wrap: "[data-tab-nav-more]",
    trigger: "[data-tab-nav-trigger]",
    panel: "[data-tab-nav-menu]",
    item: "[data-tab-nav-menu] a",
  }, { flipTo: "start", pick: "a" })

  function fit() {
    const list = q(".tab-nav-list")
    const tabsEl = q("[data-tab-nav-tabs]")
    const more = q("[data-tab-nav-more]")
    if (!list || !tabsEl || !more || !root.offsetWidth) return
    const items = qa("[data-tab-nav-item]")
    const extras = !!q("[data-tab-nav-entry]")
    const focused = document.activeElement
    // measure everything at its natural width (same task, nothing paints)
    root.removeAttribute("data-squeezed")
    root.removeAttribute("data-collapsed")
    items.forEach((el) => { el.hidden = false })
    more.hidden = false
    const cs = getComputedStyle(list)
    const chrome = parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight) +
      parseFloat(cs.borderLeftWidth) + parseFloat(cs.borderRightWidth)
    const avail = contentW(root) - chrome
    const gap = rowGap(tabsEl)
    const widths = items.map(outerW)
    const moreW = outerW(more)
    const pinned = items.findIndex((el) => el.classList.contains("tab-active"))
    let vis = fitRow({ widths, avail, gap, moreW, moreAlways: extras, pinned })
    // the active tab and More don't fit side by side: fold every tab into the
    // menu, and the trigger names the active tab (CSS swaps its label)
    const needsMore = extras || items.length > 1
    const collapsed = pinned >= 0 && needsMore && widths[pinned] + gap + moreW > avail + 0.5
    if (collapsed) vis = []
    const shown = new Set(vis)
    // apply
    items.forEach((el, i) => { el.hidden = !shown.has(i) })
    qa("[data-tab-nav-copy]").forEach((el) => { el.hidden = shown.has(Number(el.dataset.index)) })
    const overflowed = vis.length < items.length
    const ov = q("[data-tab-nav-overflow]")
    if (ov) ov.hidden = !overflowed
    const sep = q("[data-tab-nav-sep]")
    if (sep) sep.hidden = !(overflowed && extras)
    more.hidden = !(overflowed || extras)
    const used = vis.reduce((s, i) => s + widths[i], 0) + gap * Math.max(0, vis.length - 1) +
      (more.hidden ? 0 : moreW + (vis.length ? gap : 0))
    root.toggleAttribute("data-collapsed", collapsed)
    root.toggleAttribute("data-squeezed", !collapsed && used > avail + 0.5)
    root.setAttribute("data-ready", "")
    if (more.hidden && menu.isOpen()) menu.set(false)
    menu.sync()
    // a focused tab that just moved into the menu hands focus to More
    if (focused && focused.matches("[data-tab-nav-item]") && focused.hidden && !more.hidden) {
      q("[data-tab-nav-trigger]").focus()
    }
  }

  // arrows across the visible tabs and the More trigger (Tab works as usual)
  root.addEventListener("keydown", (e) => {
    const cur = e.target.closest("[data-tab-nav-item], [data-tab-nav-trigger]")
    if (!cur || !["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key)) return
    const stops = qa("[data-tab-nav-item], [data-tab-nav-trigger]").filter((el) => !el.closest("[hidden]"))
    const rtl = getComputedStyle(root).direction === "rtl"
    const i = stops.indexOf(cur)
    const step = (e.key === "ArrowRight") !== rtl ? 1 : -1
    const j = e.key === "Home" ? 0 : e.key === "End" ? stops.length - 1 : (i + step + stops.length) % stops.length
    e.preventDefault()
    stops[j].focus()
  })

  const ro = typeof ResizeObserver !== "undefined" ? new ResizeObserver(() => fit()) : null
  if (ro) ro.observe(root)
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(fit)
  fit()
  const api = { refresh: fit, destroy() { if (ro) ro.disconnect() } }
  root.__sdTabNav = api
  return api
}

// <.chip_row> motion - the micro tier, transform and opacity only (WAAPI, so
// it needs no inline styles in markup and stays CSP-safe). A chip added after
// mount scales and fades in (0.9 -> 1, CHIP_MS ease-out); a removed one leaves
// the flow at once (absolute, where it stood) and scales and fades out while
// the chips after it slide into its place (FLIP on `translate`). Removed nodes
// stay CHIP_HOLD - the length of a <.reveal> collapse - with the row holding
// its height, so a reveal that closes in the same patch shrinks around the
// fading chip. LiveView keeps them through their phx-remove transition (the
// component renders it); in dead views the hook does. The +N count is frozen
// until the exits end. Reduced motion: no scale, no slide, instant.
const CHIP_MS = 150
const CHIP_HOLD = 180
const reducedMotion = () =>
  typeof matchMedia === "function" && matchMedia("(prefers-reduced-motion: reduce)").matches
const canAnimate = () => typeof Element.prototype.animate === "function" && !reducedMotion()
// layout width, ignoring a running scale animation
function layoutW(el) {
  const w = outerW(el)
  const s = parseFloat(getComputedStyle(el).scale)
  return s > 0 ? w / s : w
}

// <.chip_row>: removable chips; the ones that don't fit collapse into "+N".
function initChipRow(root) {
  if (root.__sdChipRow) return root.__sdChipRow
  const q = (s) => root.querySelector(s)
  const qa = (s) => [...root.querySelectorAll(s)]
  const pop = disclosure(root, {
    wrap: "[data-chip-row-more]",
    trigger: "[data-chip-row-trigger]",
    panel: "[data-chip-row-panel]",
    item: "[data-chip-row-panel] [data-chip-copy]:not([data-chip-exiting]) [data-chip-remove]",
  }, { flipTo: "end", horizontal: true })
  // where focus goes after a removal: { copy, pos } (position among the visible chips)
  let refocus = null

  const MOVERS = "[data-chip], [data-chip-copy], [data-chip-row-more], [data-chip-row-actions]"
  const known = new WeakSet() // nodes already rendered (no enter animation)
  const pos = new WeakMap() // node -> { x, y, shown }: its layout box at the last sync
  const slides = new WeakMap() // node -> its running FLIP animation
  const exiting = new Map() // node -> true when the hook removes it (dead views)
  let holdTimer = null
  let scheduled = false
  let ready = false

  const setCount = (trigger, n) => {
    trigger.setAttribute("data-count", "+" + n)
    trigger.setAttribute("aria-label", (trigger.dataset.moreLabel || "Show {count} more").replace("{count}", n))
  }
  const leaving = (el) => el.hasAttribute("data-chip-exiting")
  const live = (sel) => qa(sel).filter((el) => !leaving(el))
  const visible = (sel) => live(sel).filter((el) => !el.closest("[hidden]"))

  function fit() {
    const more = q("[data-chip-row-more]")
    const trigger = q("[data-chip-row-trigger]")
    if (!more || !trigger || !root.offsetWidth) return
    const chips = live("[data-chip]")
    const actions = live("[data-chip-row-actions]")[0]
    root.removeAttribute("data-squeezed")
    chips.forEach((el) => { el.hidden = false })
    more.hidden = false
    setCount(trigger, chips.length) // the widest label this row can need
    const gap = rowGap(root)
    const avail = contentW(root) - (actions ? layoutW(actions) + gap : 0)
    const widths = chips.map(layoutW)
    const moreW = outerW(more)
    const vis = fitRow({ widths, avail, gap, moreW, moreAlways: false, pinned: -1 })
    const shown = new Set(vis)
    chips.forEach((el, i) => { el.hidden = !shown.has(i) })
    const visibleIdx = new Set(vis.map((i) => chips[i].dataset.index))
    live("[data-chip-copy]").forEach((el) => { el.hidden = visibleIdx.has(el.dataset.index) })
    const rest = chips.length - vis.length
    setCount(trigger, rest)
    more.hidden = rest === 0
    const used = vis.reduce((s, i) => s + widths[i], 0) + gap * Math.max(0, vis.length - 1) +
      (rest ? moreW + (vis.length ? gap : 0) : 0)
    root.toggleAttribute("data-squeezed", used > avail + 0.5)
    root.setAttribute("data-ready", "")
    if (more.hidden && pop.isOpen()) pop.set(false)
    pop.sync()
  }

  // After a removal, focus the chip that took the removed one's place (or the
  // one before it), else +N, else the last chip, else the first action.
  function restoreFocus() {
    if (!refocus) return
    const a = document.activeElement
    if (a && a !== document.body && root.contains(a) && !a.closest("[data-chip-exiting]")) { refocus = null; return }
    const { copy, pos: at } = refocus
    refocus = null
    const pick = (list) => list[Math.min(at, list.length - 1)]
    const rowBtns = visible("[data-chip]").map((el) => el.querySelector("[data-chip-remove]")).filter(Boolean)
    const copyBtns = pop.isOpen()
      ? visible("[data-chip-copy]").map((el) => el.querySelector("[data-chip-remove]")).filter(Boolean)
      : []
    const trigger = q("[data-chip-row-trigger]")
    const actions = live("[data-chip-row-actions]")[0]
    const target = (copy ? pick(copyBtns) : pick(rowBtns)) ||
      (trigger && !trigger.closest("[hidden]") && trigger) ||
      rowBtns[rowBtns.length - 1] ||
      (actions && actions.querySelector("button, a[href], input, select"))
    if (target) target.focus()
  }

  // Remember where every chip, +N and the actions sit (offset box: layout,
  // not the animated position) - the "first" of FLIP for the next change.
  function measure() {
    qa(MOVERS).forEach((el) => {
      if (leaving(el)) return
      known.add(el)
      pos.set(el, { x: el.offsetLeft, y: el.offsetTop, shown: !el.closest("[hidden]") })
    })
  }

  function slide(el, from) {
    let dx = from.x - el.offsetLeft
    let dy = from.y - el.offsetTop
    if (!dx && !dy) return
    const running = slides.get(el)
    if (running) {
      // start from where it is now, mid-slide
      const [tx = 0, ty = 0] = (getComputedStyle(el).translate.match(/-?[\d.]+/g) || []).map(Number)
      dx += tx
      dy += ty
      running.cancel()
    }
    const a = el.animate([{ translate: `${dx}px ${dy}px` }, { translate: "0px 0px" }], { duration: CHIP_MS, easing: "ease-out" })
    slides.set(el, a)
    a.onfinish = () => { if (slides.get(el) === a) slides.delete(el) }
  }

  const enter = (el) =>
    el.animate([{ scale: 0.9, opacity: 0 }, { scale: 1, opacity: 1 }], { duration: CHIP_MS, easing: "ease-out" })

  // A chip, chip copy or the actions leaving. `own`: the hook removes the node
  // (dead views); otherwise LiveView does, after its phx-remove transition.
  function exit(el, own) {
    if (leaving(el)) return
    el.setAttribute("data-chip-exiting", "")
    el.inert = true // out of the tab order and the a11y tree right away
    if (el.closest("[hidden]") || !canAnimate()) {
      el.hidden = true
      if (own) el.remove()
      return
    }
    exiting.set(el, own)
    hold()
    const from = pos.get(el)
    const at = from && from.shown ? from : { x: el.offsetLeft, y: el.offsetTop }
    const cs = getComputedStyle(el)
    const start = {
      scale: cs.scale === "none" ? "1" : cs.scale,
      opacity: cs.opacity,
      translate: cs.translate === "none" ? "0px 0px" : cs.translate,
    }
    const w = layoutW(el)
    el.getAnimations().forEach((a) => a.cancel())
    slides.delete(el)
    Object.assign(el.style, { position: "absolute", left: at.x + "px", top: at.y + "px", width: w + "px", margin: "0" })
    el.animate([start, { scale: 0.9, opacity: 0, translate: start.translate }], {
      duration: CHIP_MS,
      easing: "ease-out",
      fill: "forwards",
    })
  }

  // Keep the row's height while chips fade out of the flow; release it (and
  // re-fit, so +N recounts) once the last exit is over.
  function hold() {
    if (!holdTimer) {
      const ul = q("[data-chip-row-chips]")
      for (const el of [root, ul]) if (el) el.style.minHeight = getComputedStyle(el).height
    }
    clearTimeout(holdTimer)
    holdTimer = setTimeout(release, CHIP_HOLD)
  }
  function release() {
    holdTimer = null
    exiting.forEach((own, el) => {
      el.hidden = true
      if (own) el.remove()
    })
    exiting.clear()
    const ul = q("[data-chip-row-chips]")
    for (const el of [root, ul]) if (el) el.style.minHeight = ""
    sync(true)
  }

  // Apply a change: re-fit (unless chips are still fading out), then animate
  // what moved or arrived since the last measure.
  function sync(animate) {
    scheduled = false
    if (!exiting.size) fit()
    restoreFocus()
    if (animate && ready && canAnimate()) {
      qa(MOVERS).forEach((el) => {
        if (leaving(el) || el.closest("[hidden]")) return
        const from = pos.get(el)
        // new nodes, and chips the re-fit pulled out of +N, fade in
        if (!known.has(el) || (from && !from.shown && el.hasAttribute("data-chip"))) enter(el)
        else if (from && from.shown) slide(el, from)
      })
    }
    measure()
  }
  const schedule = () => {
    if (scheduled) return
    scheduled = true
    queueMicrotask(() => { if (scheduled) sync(true) })
  }

  root.addEventListener("click", (e) => {
    // data-chip-row-clear (e.g. a "Clear all" action): cancelable chip-clear
    const clear = e.target.closest("[data-chip-row-clear]")
    if (clear) {
      const allowed = root.dispatchEvent(new CustomEvent("chip-clear", { bubbles: true, cancelable: true }))
      if (clear.hasAttribute("phx-click") || !allowed) return
      measure()
      live("[data-chip], [data-chip-copy]").forEach((el) => exit(el, true))
      sync(true)
      return
    }
    const btn = e.target.closest("[data-chip-remove]")
    if (!btn) return
    const chip = btn.closest("[data-chip], [data-chip-copy]")
    if (leaving(chip)) return
    const copy = chip.hasAttribute("data-chip-copy")
    refocus = { copy, pos: visible(copy ? "[data-chip-copy]" : "[data-chip]").indexOf(chip) }
    const ev = new CustomEvent("chip-remove", {
      bubbles: true,
      cancelable: true,
      detail: { value: chip.dataset.value == null ? null : chip.dataset.value, index: Number(chip.dataset.index) },
    })
    const allowed = root.dispatchEvent(ev)
    // LiveView (phx-click) removes it on the server; its phx-remove starts the exit
    if (btn.hasAttribute("phx-click")) return
    if (!allowed) { refocus = null; return }
    measure()
    live("[data-chip], [data-chip-copy]")
      .filter((el) => el.dataset.index === chip.dataset.index)
      .forEach((el) => exit(el, true))
    sync(true)
  })

  // LiveView: a chip (or the actions) the patch removed runs its phx-remove,
  // which dispatches chip-exit right after the hook's updated()
  root.addEventListener("chip-exit", (e) => {
    const el = e.target.closest && e.target.closest("[data-chip], [data-chip-copy], [data-chip-row-actions]")
    if (!el || !root.contains(el)) return
    exit(el, false)
    schedule()
  })

  // dead views: chips added or removed by other scripts animate too
  const mo = typeof MutationObserver !== "undefined" ? new MutationObserver(schedule) : null
  if (mo) mo.observe(root, { childList: true, subtree: true })
  const ro = typeof ResizeObserver !== "undefined" ? new ResizeObserver(() => sync(false)) : null
  if (ro) ro.observe(root)
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => sync(false))
  sync(false)
  ready = true
  const api = {
    refresh: () => sync(true),
    beforeUpdate: measure,
    updated: schedule,
    destroy() {
      if (ro) ro.disconnect()
      if (mo) mo.disconnect()
      clearTimeout(holdTimer)
    },
  }
  root.__sdChipRow = api
  return api
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
  root.querySelectorAll("[data-timepicker]").forEach(initTimepicker)
  root.querySelectorAll("[data-range-calendar]").forEach(initRangeCalendar)
  root.querySelectorAll("[data-calendar]").forEach((el) => { if (!el.dataset.built) buildCalendar(el) })
  root.querySelectorAll("[data-datatable]").forEach(initDataTable)
  root.querySelectorAll("[data-carousel]").forEach(initCarousel)
  root.querySelectorAll("[data-resizable]").forEach(initResizable)
  root.querySelectorAll("[data-tab-nav]").forEach(initTabNav)
  root.querySelectorAll("[data-chip-row]").forEach(initChipRow)
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
  ShadcnTimePicker: { mounted() { this.api = initTimepicker(this.el) }, updated() { this.api && this.api.refresh() } },
  ShadcnRangeCalendar: { mounted() { initRangeCalendar(this.el) } },
  // Optional since 0.12: server toasts arrive through a window listener.
  ShadcnToaster: { mounted() { toasterSection() } },
  ShadcnDataTable: { mounted() { initDataTable(this.el) } },
  ShadcnCarousel: { mounted() { initCarousel(this.el) } },
  ShadcnResizable: { mounted() { initResizable(this.el) } },
  // updated(): re-fit after a patch (labels, counts, the active tab or the
  // chips may have changed); destroyed(): stop observing the row's width.
  ShadcnTabNav: {
    mounted() { this.api = initTabNav(this.el) },
    updated() { this.api && this.api.refresh() },
    destroyed() { this.api && this.api.destroy() },
  },
  // ShadcnChipRow also animates the patch: beforeUpdate() records where the
  // chips sit, updated() slides / fades them from there.
  ShadcnChipRow: {
    mounted() { this.api = initChipRow(this.el) },
    beforeUpdate() { this.api && this.api.beforeUpdate() },
    updated() { this.api && this.api.updated() },
    destroyed() { this.api && this.api.destroy() },
  },
}

// Any mounted package hook hands over the LiveSocket (toast action events use it).
Object.values(Hooks).forEach((hook) => {
  const mounted = hook.mounted
  hook.mounted = function () {
    if (!sonner.liveSocket) sonner.liveSocket = this.liveSocket
    return mounted.call(this)
  }
})

export { toast, showToast }
