// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/shadcn_daisyui_demo"
import topbar from "../vendor/topbar"
// interactive components from the shadcn_daisyui package (copied by its install task)
import { initShadcnDaisyui, Hooks as ShadcnHooks, toast, showToast } from "../../../priv/static/shadcn-daisyui.js"
// docs-site only: the interactive theme creator on /docs/themes
import { initThemeCreator } from "./theme_creator"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...ShadcnHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Styled confirmations: data-confirm (dropdown / command items' `confirm`,
// links, buttons) asks in the package's alert dialog instead of the browser's
// confirm(), on the docs pages and the LiveView lab pages alike.
import { initConfirmDialog } from "../../../priv/static/shadcn-daisyui.js"
initConfirmDialog()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

// shadcn_daisyui toast API on window, for poking at it from the console
window.toast = toast
window.showToast = showToast

// Keep the docs sidebar's scroll position across full-page navigations, while the
// main content still loads at the top. (Dead-view navigation reloads the page, which
// would otherwise reset the sidebar to the top on every click.)
const persistSidebarScroll = () => {
  const el = document.querySelector("[data-docs-sidebar]")
  if (!el) return
  const KEY = "docs-sidebar-scroll"
  const stored = sessionStorage.getItem(KEY)
  if (stored !== null) el.scrollTop = parseInt(stored, 10) || 0
  const save = () => sessionStorage.setItem(KEY, el.scrollTop)
  el.addEventListener("scroll", save, {passive: true})
  window.addEventListener("pagehide", save)
}

// Platform filter (Web | iOS | All) on the guideline pages. The chosen view is
// kept on <html data-platform-view> so CSS can hide [data-platform] blocks, and
// persisted across pages in localStorage.
const initPlatformToggle = () => {
  const KEY = "docs-platform-view"
  const apply = (view) => {
    document.documentElement.setAttribute("data-platform-view", view)
    document.querySelectorAll("[data-platform-toggle] [data-platform-choice]").forEach((btn) => {
      btn.classList.toggle("tab-active", btn.dataset.platformChoice === view)
    })
  }
  apply(localStorage.getItem(KEY) || "all")
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-platform-choice]")
    if (!btn) return
    localStorage.setItem(KEY, btn.dataset.platformChoice)
    apply(btn.dataset.platformChoice)
  })
}

// Docs previews carry no inline handlers (so the site works under a strict
// script-src CSP); these delegated listeners do what onclick= used to.

// Toast previews: <button data-toast="Saved" data-toast-type="success"
// data-toast-description="…" data-toast-position="top-left"
// data-toast-action="Undo" data-toast-cancel="Dismiss" data-toast-rich
// data-toast-close data-toast-invert data-toast-icon="hero-…">.
// data-toast-promise="Event" runs the promise demo; data-toast-custom="tpl-id"
// shows that <template>'s first element as a headless toast.
document.addEventListener("click", (e) => {
  const b = e.target.closest("[data-toast], [data-toast-promise], [data-toast-custom]")
  if (!b) return
  const d = b.dataset
  if (d.toastPromise !== undefined) {
    toast.promise(() => new Promise((r) => setTimeout(() => r({name: d.toastPromise}), 2000)), {
      loading: "Loading...",
      success: (x) => `${x.name} has been created`,
      error: "Error",
    })
    return
  }
  if (d.toastCustom !== undefined) {
    toast.custom((id) => {
      const card = document.getElementById(d.toastCustom).content.firstElementChild.cloneNode(true)
      card.querySelector("[data-close]")?.addEventListener("click", () => toast.dismiss(id))
      return card
    })
    return
  }
  const opts = {}
  if (d.toastDescription) opts.description = d.toastDescription
  if (d.toastPosition) opts.position = d.toastPosition
  if (d.toastAction) opts.action = {label: d.toastAction, onClick: () => {}}
  if (d.toastCancel) opts.cancel = {label: d.toastCancel, onClick: () => {}}
  if (d.toastRich !== undefined) opts.richColors = true
  if (d.toastClose !== undefined) opts.closeButton = true
  if (d.toastInvert !== undefined) opts.invert = true
  if (d.toastIcon) opts.icon = `<span class="${d.toastIcon}" data-sonner-heroicon aria-hidden="true"></span>`
  ;(d.toastType ? toast[d.toastType] : toast)(d.toast, opts)
})

// Range-calendar booking preview: show the submitted range instead of posting.
document.addEventListener("submit", (e) => {
  const form = e.target.closest("[data-demo-booking]")
  if (!form) return
  e.preventDefault()
  const f = new FormData(form)
  toast("Booked", {description: `${f.get("booking[check_in]")} → ${f.get("booking[check_out]")}`})
})

// Motion guide: replay a duration sample with the Web Animations API (not
// affected by the theme-swap transition-duration override).
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-motion-play]")
  if (!btn) return
  const box = btn.closest("div").querySelector("[data-motion-box]")
  const track = box.closest(".relative")
  box.animate(
    [{transform: "translateX(0)"}, {transform: `translateX(${track.offsetWidth - box.offsetWidth - 8}px)`}],
    {duration: Number(btn.dataset.motionPlay), easing: "cubic-bezier(0.4,0,0.2,1)", fill: "forwards"},
  )
})

// Resizable previews (tab nav, chip row): the width slider narrows the
// preview so the overflow is visible without resizing the window.
document.addEventListener("input", (e) => {
  const range = e.target.closest("[data-demo-width]")
  if (!range) return
  const frame = range.closest("label").nextElementSibling
  frame.style.width = `${range.value}%`
  range.parentElement.querySelector("[data-demo-width-out]").textContent = `${range.value}%`
})

// Chip row "Add and remove" preview: the dead-view stand-in for a LiveView
// that adds filters. It appends a chip and its popover copy (the hook's
// MutationObserver animates them in) and drives the surrounding reveal the
// way `open={@filters != []}` would: open on add, closed when the last chip
// or Clear all removes everything.
const DEMO_FILTERS = [
  ["todo", "Status: Todo"], ["high", "Priority: High"], ["bug", "Label: Bug"],
  ["me", "Assignee: Me"], ["frontend", "Label: Frontend"], ["week", "Created: Last 7 days"],
]
const demoChip = (rowId, kind, index, value, label) => {
  const li = document.createElement("li")
  li.id = `${rowId}-${kind}-v-${value}`
  li.className = "badge chip badge-secondary"
  li.dataset.index = index
  li.dataset.value = value
  li.setAttribute(kind === "copy" ? "data-chip-copy" : "data-chip", "")
  if (kind === "copy") li.hidden = true
  const text = document.createElement("span")
  text.id = `${li.id}-label`
  text.className = "chip-label"
  text.textContent = label
  const btn = document.createElement("button")
  btn.type = "button"
  btn.id = `${li.id}-remove`
  btn.className = "chip-remove"
  btn.setAttribute("aria-label", "Remove")
  btn.setAttribute("aria-labelledby", `${btn.id} ${text.id}`)
  btn.setAttribute("data-chip-remove", "")
  const icon = document.createElement("span")
  icon.className = "hero-x-mark size-3"
  icon.setAttribute("aria-hidden", "true")
  btn.append(icon)
  li.append(text, btn)
  return li
}
const liveChips = (row) => row.querySelectorAll("[data-chip]:not([data-chip-exiting])")
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-demo-chip-add]")
  if (!btn) return
  const row = document.getElementById(btn.dataset.demoChipAdd)
  const taken = new Set([...liveChips(row)].map((c) => c.dataset.value))
  const next = DEMO_FILTERS.find(([value]) => !taken.has(value) && !document.getElementById(`${row.id}-chip-v-${value}`))
  if (!next) return
  const index = Math.max(-1, ...[...row.querySelectorAll("[data-index]")].map((c) => Number(c.dataset.index))) + 1
  row.querySelector("[data-chip-row-chips]").append(demoChip(row.id, "chip", index, ...next))
  row.querySelector("[data-chip-row-panel] ul").append(demoChip(row.id, "copy", index, ...next))
  document.getElementById(`${row.id}-reveal`).setAttribute("data-open", "")
})
document.addEventListener("chip-remove", (e) => {
  const reveal = document.getElementById(`${e.target.id}-reveal`)
  if (reveal && liveChips(e.target).length <= 1) reveal.removeAttribute("data-open")
})
document.addEventListener("chip-clear", (e) => {
  const reveal = document.getElementById(`${e.target.id}-reveal`)
  if (reveal) reveal.removeAttribute("data-open")
})

// Command "Server search" preview: the dead-view stand-in for a LiveView with
// on_search. It answers each `shadcn:command-search` the way the server would:
// 400ms later (none for the empty search on open), only for the latest text,
// with the matching rows and the text they answer as data-query. Each row is
// one action: Add, Add back (confirms first), Open, or nothing while a removal
// is scheduled (disabled).
const DEMO_PEOPLE = [
  ["Alex Morgan", "alex.morgan@example.test", "removed"], ["Casey Nguyen", "casey.nguyen@example.test"],
  ["Drew Santos", "drew.santos@example.test"], ["Jamie Ortiz", "jamie.ortiz@example.test"],
  ["Jordan Lee", "jordan.lee@example.test", "active"], ["Morgan Patel", "morgan.patel@example.test"],
  ["Pat Rivera", "pat.rivera@example.test"], ["Patricia Hale", "patricia.hale@example.test", "removed"],
  ["Riley Chen", "riley.chen@example.test", "scheduled"], ["Robin Park", "robin.park@example.test"],
  ["Sam Okafor", "sam.okafor@example.test"], ["Taylor Brooks", "taylor.brooks@example.test"],
]
const DEMO_ACTIONS = {undefined: "Add", removed: "Add back", active: "Open", scheduled: "Removal scheduled"}
const demoPersonRow = ([name, email, status]) => {
  const li = document.createElement("li")
  const btn = document.createElement("button")
  btn.type = "button"
  btn.className = "command-item"
  btn.setAttribute("data-command-item", "")
  btn.dataset.demoPerson = `${DEMO_ACTIONS[status]}: ${name}`
  if (status === "removed") btn.dataset.confirm = `Add ${name} back? They start with no roles.`
  if (status === "scheduled") btn.setAttribute("aria-disabled", "true")
  const icon = document.createElement("span")
  icon.className = "hero-user size-4"
  icon.setAttribute("aria-hidden", "true")
  const text = document.createElement("span")
  text.className = "command-item-text"
  const title = document.createElement("span")
  title.className = "command-item-title"
  title.textContent = name
  const desc = document.createElement("span")
  desc.className = "command-item-description"
  desc.textContent = email
  text.append(title, desc)
  const hint = document.createElement("span")
  hint.className = "ml-auto text-xs text-muted-foreground"
  hint.textContent = DEMO_ACTIONS[status]
  btn.append(icon, text, hint)
  li.append(btn)
  return li
}
let demoLatestSearch = null
document.addEventListener("shadcn:command-search", (e) => {
  const dialog = e.target
  if (dialog.id !== "command_people") return
  const query = e.detail.query
  demoLatestSearch = query
  setTimeout(() => {
    if (query !== demoLatestSearch) return
    const words = query.toLowerCase().split(/\s+/).filter(Boolean)
    const rows = !words.length ? [] : DEMO_PEOPLE.filter(([name, email]) => {
      const haystack = [email, ...name.toLowerCase().split(" ")]
      return words.every((w) => haystack.some((h) => h.startsWith(w)))
    })
    dialog.querySelector("[data-command-list]").replaceChildren(...rows.map(demoPersonRow))
    dialog.querySelector("[data-command-empty]").textContent = `No one matches "${query}".`
    dialog.setAttribute("data-query", query)
  }, query ? 400 : 0)
})
// on window, after phoenix_html's confirm: a declined "Add back" never gets here
window.addEventListener("click", (e) => {
  const row = e.target instanceof Element && e.target.closest("#command_people [data-demo-person]")
  if (row && row.getAttribute("aria-disabled") !== "true") setTimeout(() => toast(row.dataset.demoPerson))
})

// The app shell preview's static list page: a data table row opens the
// record (in a LiveView, dt:open goes to the server; a dead view gets this
// event instead).
document.addEventListener("shadcn:data-table", (e) => {
  if (e.detail.event !== "dt:open") return
  const row = [...e.target.querySelectorAll("[data-dt-row]")].find((r) => r.dataset.id === e.detail.payload.id)
  if (row && row.dataset.href) window.location.assign(row.dataset.href)
})

// AI chat previews (message scroller "Streaming", prompt input): the
// dead-view stand-in for a LiveView. A composer preview's form says what it
// would send. The chat preview's form appends the question (a turn anchor:
// the scroller moves it near the top) and a reply that grows a few words at
// a time while the composer is busy (its Stop ends the reply); "Load earlier
// messages" prepends older rows (the scroller keeps your place). New rows
// are copies of the rows the component rendered.
const DEMO_REPLY = "Sure. Riverside Dental's invoice #1034 for $1,512.80 has been overdue since Oct 9. " +
  "Pat Lee sent a reminder last week, and they usually pay within a few days of one. " +
  "Summit Outfitters (#1040) is waiting on a purchase order number, so I'd hold off there. " +
  "Hillcrest Motors asked for a copy of their invoice, which went out yesterday. " +
  "Want me to draft a second reminder for Riverside Dental?"
const DEMO_EARLIER = [
  ["How many orders came in this week?", "14, three more than last week. Most are still open."],
  ["Which one is the largest?", "#1238 for Willow Creek Farm, $2,410.00."],
]
const demoChats = new Map()
const demoChatBusy = (form, on) => {
  const root = form.querySelector("[data-slot=prompt-input]")
  const btn = root.querySelector("[data-slot=prompt-input-submit]")
  root.toggleAttribute("data-busy", on)
  btn.type = on ? "button" : "submit"
  btn.dataset.state = on ? "busy" : "idle"
  btn.setAttribute("aria-label", on ? "Stop" : "Send")
  btn.title = on ? "Stop" : "Send"
  btn.classList.toggle("btn-primary", !on)
  btn.classList.toggle("btn-secondary", on)
  btn.querySelector("[class*=hero-]").className = `${on ? "hero-stop-solid" : "hero-arrow-up"} size-4`
  const log = document.getElementById(form.dataset.demoChat).querySelector("[role=log]")
  log.setAttribute("aria-busy", String(on))
  if (root.__sdPrompt) root.__sdPrompt.refresh()
}
const demoChatStop = (form) => {
  const chat = demoChats.get(form.dataset.demoChat)
  if (chat) clearInterval(chat.timer)
  demoChatBusy(form, false)
}
const demoRow = (template, id, text) => {
  const row = template.cloneNode(true)
  row.id = id
  row.querySelector("[data-slot=bubble-content]").textContent = text
  return row
}
document.addEventListener("submit", (e) => {
  const prompt = e.target.closest("[data-demo-prompt]")
  if (prompt) {
    e.preventDefault()
    const text = String(new FormData(prompt).get("text") || "").trim()
    toast("Sent", {description: text || "(attachments only)"})
    return
  }
  const form = e.target.closest("[data-demo-chat]")
  if (!form) return
  e.preventDefault()
  const text = String(new FormData(form).get("text") || "").trim()
  if (!text) return
  const scroller = document.getElementById(form.dataset.demoChat)
  const items = scroller.querySelector("[data-slot=message-scroller-items]")
  const chat = demoChats.get(scroller.id) || {seq: 0, earlier: 0}
  demoChats.set(scroller.id, chat)
  const asked = [...items.querySelectorAll("[data-scroll-anchor=true]")].pop()
  const answered = [...items.querySelectorAll("[data-scroll-anchor=false]")].pop()
  const reply = demoRow(answered, `${scroller.id}-new-${++chat.seq}`, "")
  items.append(demoRow(asked, `${scroller.id}-new-${++chat.seq}`, text), reply)
  demoChatBusy(form, true)
  const out = reply.querySelector("[data-slot=bubble-content]")
  const words = DEMO_REPLY.split(/(?<=\s)/)
  let at = 0
  clearInterval(chat.timer)
  chat.timer = setInterval(() => {
    out.textContent += words.slice(at, at + 2).join("")
    at += 2
    if (at >= words.length) demoChatStop(form)
  }, 80)
})
document.addEventListener("click", (e) => {
  const stop = e.target.closest("[data-demo-chat] [data-slot=prompt-input-submit][data-state=busy]")
  if (stop) return demoChatStop(stop.closest("[data-demo-chat]"))
  const earlier = e.target.closest("[data-demo-chat-earlier]")
  if (!earlier) return
  const scroller = document.getElementById(earlier.dataset.demoChatEarlier)
  const items = scroller.querySelector("[data-slot=message-scroller-items]")
  const chat = demoChats.get(scroller.id) || {seq: 0, earlier: 0}
  demoChats.set(scroller.id, chat)
  const [question, answer] = DEMO_EARLIER[DEMO_EARLIER.length - 1 - chat.earlier]
  const asked = items.querySelector("[data-scroll-anchor=true]")
  const answered = items.querySelector("[data-scroll-anchor=false]")
  items.prepend(demoRow(asked, `${scroller.id}-old-${++chat.seq}`, question), demoRow(answered, `${scroller.id}-old-${++chat.seq}`, answer))
  if (++chat.earlier >= DEMO_EARLIER.length) earlier.closest("[data-slot=message-scroller-above]").hidden = true
})

// Copy buttons on code blocks.
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-copy-code]")
  if (!btn) return
  navigator.clipboard.writeText(btn.closest("[data-code-block]").querySelector("pre").innerText)
  btn.classList.add("text-success")
})

// /docs/dark-mode is served under `script-src 'self' 'nonce-…'`. Report every
// CSP violation on the page into [data-csp-violations] so the proof is visible:
// the components should produce none; the deliberate onclick canary should
// produce exactly one when clicked.
document.addEventListener("securitypolicyviolation", (e) => {
  const out = document.querySelector("[data-csp-violations]")
  if (!out) return
  const n = (parseInt(out.dataset.count || "0", 10) || 0) + 1
  out.dataset.count = n
  out.querySelector("[data-csp-count]").textContent = n
  const li = document.createElement("li")
  li.textContent = `${e.effectiveDirective} blocked ${e.blockedURI || "inline"}${e.sample ? ` (${e.sample})` : ""}`
  out.querySelector("[data-csp-log]").appendChild(li)
})

const bootShadcn = () => { initShadcnDaisyui(); initThemeCreator(); persistSidebarScroll(); initPlatformToggle() }
if (document.readyState !== "loading") bootShadcn()
else document.addEventListener("DOMContentLoaded", bootShadcn)
