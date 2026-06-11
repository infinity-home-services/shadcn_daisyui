// shadcn-daisyui — interactive components.
// Two ways to use:
//   • Dead views / plain HTML:  import { initShadcnDaisyui } from "shadcn-daisyui"; initShadcnDaisyui()
//   • Phoenix LiveView:         import { Hooks } from "shadcn-daisyui"; new LiveSocket(..., { hooks: { ...Hooks } })
// The matching CSS is shadcn-daisyui.css.

// Counter for generating unique ids when a component root has none (needed for
// ARIA relationships like aria-controls / aria-activedescendant).
let a11yUid = 0

function showToast(variant) {
  const host = document.getElementById("toast-host")
  if (!host) return
  const el = document.createElement("div")
  el.className =
    "alert flex w-80 max-w-[90vw] items-center justify-between gap-4 border border-base-300 bg-popover shadow-lg"
  el.style.animation = "shadcn-toast-in .28s cubic-bezier(.21,1.02,.73,1)"

  const body = document.createElement("div")
  body.className = "space-y-0.5"
  const title = document.createElement("p")
  title.className = "text-sm font-medium"
  title.textContent = variant === "success" ? "Changes saved" : "Event has been created"
  const desc = document.createElement("p")
  desc.className = "text-sm text-muted-foreground"
  desc.textContent = "Sunday, December 03 at 9:00 AM"
  body.appendChild(title)
  body.appendChild(desc)

  const action = document.createElement("button")
  action.className = "btn btn-sm btn-outline"
  action.textContent = "Undo"

  const dismiss = () => {
    el.style.animation = "shadcn-toast-out .2s ease forwards"
    setTimeout(() => el.remove(), 200)
  }
  action.onclick = dismiss
  el.appendChild(body)
  el.appendChild(action)
  host.appendChild(el)
  setTimeout(dismiss, 3500)
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

  function initCombobox(root) {
    const trigger = root.querySelector("[data-combobox-trigger]")
    const panel = root.querySelector("[data-combobox-panel]")
    const search = root.querySelector("[data-combobox-search]")
    const label = root.querySelector("[data-combobox-label]")
    const empty = root.querySelector("[data-combobox-empty]")
    const list = root.querySelector("[data-combobox-list]")
    const items = [...root.querySelectorAll(".combo-item")]

    // a11y: name the widget, expose listbox + option roles and selection state
    if (!root.id) root.id = "sd-cb-" + (++a11yUid)
    const listId = root.id + "-list"
    if (list) { list.id = listId; list.setAttribute("role", "listbox") }
    trigger.setAttribute("aria-haspopup", "listbox")
    trigger.setAttribute("aria-expanded", "false")
    trigger.setAttribute("aria-controls", listId)
    if (search) {
      search.setAttribute("role", "combobox")
      search.setAttribute("aria-controls", listId)
      search.setAttribute("aria-expanded", "true")
      search.setAttribute("aria-autocomplete", "list")
      if (!search.getAttribute("aria-label")) search.setAttribute("aria-label", "Search options")
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
      items.forEach((it) => it.classList.remove("bg-accent", "text-accent-foreground"))
      if (!vis.length) { active = -1; search && search.removeAttribute("aria-activedescendant"); return }
      active = (i + vis.length) % vis.length
      const el = vis[active]
      el.classList.add("bg-accent", "text-accent-foreground")
      el.scrollIntoView({ block: "nearest" })
      search && search.setAttribute("aria-activedescendant", el.id)
    }
    const open = (o) => {
      panel.classList.toggle("hidden", !o)
      trigger.setAttribute("aria-expanded", String(o))
      if (o) { search.value = ""; filter(""); setActive(0); search.focus() }
    }
    const filter = (q) => {
      const ql = q.toLowerCase()
      let n = 0
      items.forEach((it) => {
        const m = it.dataset.value.toLowerCase().includes(ql)
        it.parentElement.classList.toggle("hidden", !m)
        if (m) n++
      })
      empty.classList.toggle("hidden", n > 0)
      setActive(0)
    }
    const choose = (it) => {
      label.textContent = it.dataset.value
      label.classList.remove("text-muted-foreground")
      items.forEach((x) => {
        x.setAttribute("aria-selected", "false")
        const c = x.querySelector("svg"); if (c) c.classList.add("opacity-0")
      })
      it.setAttribute("aria-selected", "true")
      const chk = it.querySelector("svg"); if (chk) chk.classList.remove("opacity-0")
      open(false)
      trigger.focus()
    }
    trigger.addEventListener("click", () => open(panel.classList.contains("hidden")))
    search.addEventListener("input", () => filter(search.value))
    search.addEventListener("keydown", (e) => {
      if (e.key === "ArrowDown") { e.preventDefault(); setActive(active + 1) }
      else if (e.key === "ArrowUp") { e.preventDefault(); setActive(active - 1) }
      else if (e.key === "Enter") { e.preventDefault(); const v = visible(); if (v[active]) choose(v[active]) }
      else if (e.key === "Escape") { open(false); trigger.focus() }
    })
    items.forEach((it) => it.addEventListener("click", () => choose(it)))
    document.addEventListener("click", (e) => { if (!root.contains(e.target)) open(false) })
  }

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
    dialog.addEventListener("click", (e) => { if (e.target === dialog) dialog.close() })
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
    let view = opts.selected ? new Date(opts.selected) : new Date()
    view.setDate(1)
    let selected = opts.selected || null     // single mode
    const rng = { start: opts.start || null, end: opts.end || null } // range mode
    let hover = null                         // tentative end while picking a range
    let cells = []                           // { el, date } for in-place repaint
    const today = new Date()
    const months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    const same = (a, b) =>
      a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    const addMonths = (d, n) => new Date(d.getFullYear(), d.getMonth() + n, 1)

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
    }

    const navBtn = (glyph, step, pos) => {
      const b = document.createElement("button")
      b.type = "button"
      b.className = "btn btn-ghost btn-square btn-sm absolute top-0 z-10 " + pos
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
  }

  function initDaterange(root) {
    const trigger = root.querySelector("[data-daterange-trigger]")
    const panel = root.querySelector("[data-daterange-panel]")
    const label = root.querySelector("[data-daterange-label]")
    const calEl = panel.querySelector("[data-calendar-range]")
    const md = (d) => d.toLocaleDateString(undefined, { month: "short", day: "numeric" })
    const mdy = (d) => d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })
    buildCalendar(calEl, {
      mode: "range",
      months: 2,
      onSelect: (sel) => {
        if (sel.start && sel.end) {
          label.textContent = md(sel.start) + " – " + mdy(sel.end)
          label.classList.remove("text-muted-foreground")
          panel.classList.add("hidden")
        } else if (sel.start) {
          label.textContent = md(sel.start) + " – …"
          label.classList.remove("text-muted-foreground")
        }
      },
    })
    trigger.setAttribute("aria-haspopup", "dialog")
    const sync = () => trigger.setAttribute("aria-expanded", String(!panel.classList.contains("hidden")))
    sync()
    trigger.addEventListener("click", () => { panel.classList.toggle("hidden"); sync() })
    document.addEventListener("click", (e) => { if (!root.contains(e.target)) { panel.classList.add("hidden"); sync() } })
  }

  function initDatepicker(root) {
    const trigger = root.querySelector("[data-datepicker-trigger]")
    const panel = root.querySelector("[data-datepicker-panel]")
    const label = root.querySelector("[data-datepicker-label]")
    const calEl = panel.querySelector("[data-calendar]")
    buildCalendar(calEl, {
      onSelect: (d) => {
        label.textContent = d.toLocaleDateString(undefined, { year: "numeric", month: "long", day: "numeric" })
        label.classList.remove("text-muted-foreground")
        panel.classList.add("hidden")
      },
    })
    trigger.setAttribute("aria-haspopup", "dialog")
    const sync = () => trigger.setAttribute("aria-expanded", String(!panel.classList.contains("hidden")))
    sync()
    trigger.addEventListener("click", () => { panel.classList.toggle("hidden"); sync() })
    document.addEventListener("click", (e) => { if (!root.contains(e.target)) { panel.classList.add("hidden"); sync() } })
  }

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
      facetBadges.appendChild(el("span", "mx-1 h-4 w-px bg-base-300"))
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

// Wire every component found under `root` (default: whole document). For dead
// views / plain HTML. Safe to call once on page load.
export function initShadcnDaisyui(root) {
  root = root || document
  root.querySelectorAll("[data-combobox]").forEach(initCombobox)
  root.querySelectorAll("[data-command]").forEach(initCommand)
  root.querySelectorAll("[data-otp]").forEach(initOtp)
  root.querySelectorAll("[data-datepicker]").forEach(initDatepicker)
  root.querySelectorAll("[data-daterange]").forEach(initDaterange)
  root.querySelectorAll("[data-calendar]").forEach((el) => { if (!el.dataset.built) buildCalendar(el) })
  root.querySelectorAll("[data-datatable]").forEach(initDataTable)
  root.querySelectorAll("[data-carousel]").forEach(initCarousel)
  root.querySelectorAll("[data-resizable]").forEach(initResizable)
  initContextMenu()
  initDock(root)
}

// Phoenix LiveView hooks. Attach with phx-hook="ShadcnCombobox" etc.
export const Hooks = {
  ShadcnCombobox: { mounted() { initCombobox(this.el) } },
  ShadcnCommand: { mounted() { initCommand(this.el) } },
  ShadcnOtp: { mounted() { initOtp(this.el) } },
  ShadcnContextMenu: { mounted() { initContextMenu() } },
  ShadcnCalendar: { mounted() { if (!this.el.dataset.built) buildCalendar(this.el) } },
  ShadcnDatePicker: { mounted() { initDatepicker(this.el) } },
  ShadcnDateRange: { mounted() { initDaterange(this.el) } },
  ShadcnDataTable: { mounted() { initDataTable(this.el) } },
  ShadcnCarousel: { mounted() { initCarousel(this.el) } },
  ShadcnResizable: { mounted() { initResizable(this.el) } },
}

export { showToast }
