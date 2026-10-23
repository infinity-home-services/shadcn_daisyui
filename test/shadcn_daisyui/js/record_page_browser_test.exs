defmodule ShadcnDaisyui.JS.RecordPageBrowserTest do
  # The record page's parts in headless Chrome with the real theme CSS and JS
  # (same harness as the other *_browser_test files): <.section_nav> (both
  # variants) in an app-shell-like #main under a pinned <.page_header>, and
  # <.record_tabs>' arrow keys. Phone-width layout is checked in an iframe.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Record
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1]

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

  @base """
  @layer base {
    *, ::before, ::after { box-sizing: border-box; } body { margin: 0; font: 14px/20px sans-serif; }
    button, input { font: inherit; } button { background: none; border: 0; padding: 0; }
    .hidden { display: none; } .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; }
    .card { display: block; height: 320px; }
  }
  """

  @sections [
    {"customer", "Customer"},
    {"contact", "Contact"},
    {"items", "Items", "Order"},
    {"discounts", "Discounts", "Order"},
    {"shipping", "Shipping", "Delivery"},
    {"window", "Delivery window", "Delivery"},
    {"payment", "Payment", "Billing"},
    {"invoice", "Invoice", "Billing"},
    {"notes", "Notes"},
    {"files", "Files"},
    {"tags", "Tags"},
    {"history", "History"}
  ]

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp page_body do
    assigns = %{sections: @sections}

    render(~H"""
    <main id="main" class="app-shell-main" style="height: 700px">
      <div class="app-shell-page" data-wide>
        <.page_header crumbs={[%{label: "Orders", path: "#orders"}, %{label: "#1042"}]}>
          Edit order
          <:below><.section_nav id="sections-select" sections={@sections} variant="select" /></:below>
        </.page_header>
        <form id="edit-form">
          <.section_nav id="sections" sections={@sections}>
            <%!-- a short last card: the one before it can't reach the header --%>
            <section
              :for={s <- @sections}
              id={elem(s, 0)}
              class="card"
              style={elem(s, 0) == "history" && "height: 80px"}
            >
              {elem(s, 1)}
            </section>
          </.section_nav>
        </form>
        <.record_tabs id="tabs" tabs={[{"details", "Details"}, {"activity", "Activity"}, {"files", "Files"}]} active="details" />
      </div>
    </main>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    phone =
      ~s(<!doctype html><html data-theme="shadcn"><head><meta charset="utf-8"><style>#{@base}#{css}</style></head><body>) <>
        page_body() <> "</body></html>"

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{@base}#{css}</style>
    <style>#sections { max-height: 220px; } /* a side list taller than its room */</style></head>
    <body>
    #{page_body()}
    <iframe id="phone" style="width: 600px; height: 700px; border: 0"></iframe>
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const $ = (id) => document.getElementById(id)
    const r = {}
    try {
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook]")) {
      const name = el.getAttribute("phx-hook")
      if (!Hooks[name]) continue
      const hook = Object.assign(Object.create(Hooks[name]), { el, pushEvent: () => Promise.resolve({}) })
      hook.mounted()
      hooks[el.id] = hook
    }
    const formInputs = []
    $("edit-form").addEventListener("input", () => formInputs.push("input"))
    const main = $("main")
    const side = $("sections")
    const select = $("sections-select")
    const current = () => side.querySelector('[aria-current="true"]')?.dataset.section || null
    const selected = () => select.querySelector('[aria-selected="true"]')?.dataset.section || null
    const label = () => select.querySelector("[data-section-current]").textContent.trim()
    const headerBottom = () => document.querySelector("[data-sticky-top]").getBoundingClientRect().bottom
    const scrollToY = async (y) => { main.scrollTop = y; main.dispatchEvent(new Event("scroll")); await frames() }
    // a smooth scroll is over once scrollTop holds still for a while
    const settled = async () => {
      let last = -1, still = 0
      while (still < 6) { await sleep(50); if (main.scrollTop === last) still++; else { still = 0; last = main.scrollTop } }
      await sleep(250)
    }
    await frames()

    r.initial = { side: current(), select: selected(), label: label() }
    r.pinned_top = side.style.getPropertyValue("--section-nav-top")

    // the section in view: the last one whose top passed the header's bottom
    const items = $("items")
    await scrollToY(main.scrollTop + items.getBoundingClientRect().top - headerBottom() - 4)
    r.items = { side: current(), select: selected(), label: label() }
    // the side list stays pinned just under the header, level with the cards
    r.side_gap = Math.round(side.getBoundingClientRect().top - headerBottom())

    // at the bottom of the page: the last section, even if its top hasn't reached the header
    await scrollToY(main.scrollHeight)
    r.bottom = { side: current(), select: selected() }
    // the side list, scrolling on its own, brings the marked entry into view
    const marked = side.querySelector('[aria-current="true"]').getBoundingClientRect()
    const box = side.getBoundingClientRect()
    r.follows = { scrolls: side.scrollHeight > side.clientHeight, in_view: marked.top >= box.top - 1 && marked.bottom <= box.bottom + 1 }

    // choosing one: scrolls there, stays marked while passing others, gets focus
    await scrollToY(0)
    side.querySelector('[data-section="payment"]').click()
    const during = []
    for (let i = 0; i < 6; i++) { await sleep(50); during.push(current()) }
    await settled()
    r.chosen = {
      during: [...new Set(during)],
      after: current(),
      select: selected(),
      gap: Math.round($("payment").getBoundingClientRect().top - headerBottom()),
      focus: document.activeElement && document.activeElement.id,
    }

    // near the end the page can't bring a section up to the header: the
    // choice stays marked (not the last section) until the person scrolls on
    await scrollToY(0)
    side.querySelector('[data-section="tags"]').click()
    await settled()
    r.near_bottom = { marked: current(), at_bottom: main.scrollTop + main.clientHeight >= main.scrollHeight - 2 }
    await scrollToY(main.scrollTop - 400)
    await sleep(50)
    r.scrolled_on = current()

    // the select: opens, a choice scrolls there and closes it
    await scrollToY(0)
    const trigger = select.querySelector("[data-section-trigger]")
    trigger.click()
    r.select_open = { hidden: select.querySelector("[data-section-panel]").hidden, expanded: trigger.getAttribute("aria-expanded") }
    select.querySelector('[data-section="notes"]').click()
    await settled()
    r.select_chosen = {
      hidden: select.querySelector("[data-section-panel]").hidden,
      label: label(),
      side: current(),
      gap: Math.round($("notes").getBoundingClientRect().top - headerBottom()),
    }

    // over 10 sections: the filter matches section and group names
    const filter = side.querySelector("[data-section-filter]")
    const visible = () => [...side.querySelectorAll("[data-section]")].filter((a) => !a.hidden && !a.closest("[hidden]")).map((a) => a.dataset.section)
    const typeFilter = (text) => { filter.value = text; filter.dispatchEvent(new Event("input", { bubbles: true })) }
    typeFilter("pay")
    r.filter_section = visible()
    typeFilter("delivery")
    r.filter_group = visible()
    typeFilter("zzz")
    r.filter_none = { visible: visible(), none: !side.querySelector("[data-section-none]").hidden }
    typeFilter("")
    r.filter_cleared = visible().length
    r.filter_kept_from_form = formInputs.length

    // record tabs: one tab stop, arrows and Home/End move between them
    const tabs = [...$("tabs").querySelectorAll("[role=tab]")]
    tabs[0].focus()
    const key = (k) => document.activeElement.dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true }))
    key("ArrowRight"); const a1 = document.activeElement.id
    key("End"); const a2 = document.activeElement.id
    key("ArrowRight"); const a3 = document.activeElement.id
    key("Home"); const a4 = document.activeElement.id
    r.tabs = { moves: [a1, a2, a3, a4], stops: tabs.map((t) => t.tabIndex) }

    // phones: the select shows (44px options), the side list doesn't
    const ifr = $("phone")
    await new Promise((res) => { ifr.onload = res; ifr.srcdoc = $("phone-src").textContent })
    const d = ifr.contentDocument
    d.querySelector("#sections-select [data-section-panel]").hidden = false
    r.phone = {
      side: getComputedStyle(d.getElementById("sections")).display,
      select: getComputedStyle(d.getElementById("sections-select")).display,
      option: Math.round(d.querySelector("#sections-select [role=option]").getBoundingClientRect().height),
      trigger_width: Math.round(d.querySelector("#sections-select [data-section-trigger]").getBoundingClientRect().width) ===
        Math.round(d.getElementById("sections-select").getBoundingClientRect().width),
    }
    } catch (e) { errors.push(String(e && e.stack || e)) }
    window.__result = JSON.stringify({ errors, r })
    </script>
    <script type="text/plain" id="phone-src">#{phone}</script>
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

  test "the first section is current on load, in both", %{r: r} do
    assert r["initial"] == %{"side" => "customer", "select" => "customer", "label" => "Customer"}
  end

  test "the section in view is the one past the pinned header's bottom", %{r: r} do
    assert r["items"] == %{"side" => "items", "select" => "items", "label" => "Order, Items"}
  end

  test "the side list pins just under the header, level with the cards", %{r: r} do
    assert r["pinned_top"] =~ ~r/^\d+px$/
    assert r["side_gap"] == 16
  end

  test "at the bottom of the page the last section is current", %{r: r} do
    assert r["bottom"] == %{"side" => "history", "select" => "history"}
  end

  test "a side list that scrolls on its own keeps the marked entry in view", %{r: r} do
    assert r["follows"] == %{"scrolls" => true, "in_view" => true}
  end

  test "choosing a section scrolls there, keeps it marked, and focuses it", %{r: r} do
    assert r["chosen"]["during"] == ["payment"]
    assert r["chosen"]["after"] == "payment"
    assert r["chosen"]["select"] == "payment"
    assert r["chosen"]["gap"] == 16
    assert r["chosen"]["focus"] == "payment"
  end

  test "a chosen section the page can't bring up stays marked until the next scroll", %{r: r} do
    assert r["near_bottom"] == %{"marked" => "tags", "at_bottom" => true}
    refute r["scrolled_on"] == "tags"
  end

  test "the select opens, and a choice scrolls there and closes it", %{r: r} do
    assert r["select_open"] == %{"hidden" => false, "expanded" => "true"}

    assert r["select_chosen"] == %{
             "hidden" => true,
             "label" => "Notes",
             "side" => "notes",
             "gap" => 16
           }
  end

  test "the filter matches section and group names, and stays out of the form", %{r: r} do
    assert r["filter_section"] == ["payment"]
    assert r["filter_group"] == ["shipping", "window"]
    assert r["filter_none"] == %{"visible" => [], "none" => true}
    assert r["filter_cleared"] == 12
    assert r["filter_kept_from_form"] == 0
  end

  test "record tabs: arrows and Home/End move the one tab stop", %{r: r} do
    assert r["tabs"]["moves"] == ["tabs-activity", "tabs-files", "tabs-details", "tabs-details"]
    assert r["tabs"]["stops"] == [0, -1, -1]
  end

  test "phones: the select with 44px options, no side list", %{r: r} do
    assert r["phone"] == %{
             "side" => "none",
             "select" => "block",
             "option" => 44,
             "trigger_width" => true
           }
  end
end
