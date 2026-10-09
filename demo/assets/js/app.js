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
// data-toast-action="Undo">. data-toast-promise="Event" runs the promise demo.
document.addEventListener("click", (e) => {
  const b = e.target.closest("[data-toast], [data-toast-promise]")
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
  const opts = {}
  if (d.toastDescription) opts.description = d.toastDescription
  if (d.toastPosition) opts.position = d.toastPosition
  if (d.toastAction) opts.action = {label: d.toastAction, onClick: () => {}}
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
