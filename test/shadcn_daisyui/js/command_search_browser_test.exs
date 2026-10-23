defmodule ShadcnDaisyui.JS.CommandSearchBrowserTest do
  # <.command on_search> in headless Chrome with the real theme CSS and JS (same
  # harness as fit_rows_browser_test.exs). A mock hook records what the palette
  # pushes; "the server" answers by patching in the parts a re-render changes
  # (rendered by the component, with `query` echoed) and calling updated().
  # phoenix_html's own script is on the page for data-confirm, and a window
  # click listener after it stands in for LiveView's phx-click.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Overlay, only: [command: 1]

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

  @phoenix_html Path.join(@root, "deps/phoenix_html/priv/static/phoenix_html.js")

  @rivera %{id: "1", name: "Pat Rivera", email: "pat.rivera@example.test"}
  @rows %{
    "old" => [%{id: "0", name: "Old Result", email: "old@example.test"}],
    "pa" => [@rivera, %{id: "4", name: "Pam Lee", email: "pam.lee@example.test"}],
    "pat" => [
      @rivera,
      %{id: "2", name: "Patrick Hale", email: "patrick.hale@example.test", disabled: true},
      %{
        id: "3",
        name: "Patricia Gomez",
        email: "patricia.gomez@example.test",
        confirm: "Add Patricia Gomez back? They start with no roles."
      }
    ],
    "zz" => []
  }

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp people(query) do
    assigns = %{query: query, results: Map.get(@rows, query, [])}

    render(~H"""
    <.command
      id="people"
      placeholder="Name or email"
      shortcut={nil}
      on_search="search"
      query={@query}
      search_debounce={40}
    >
      <:hint>Type a name or email.</:hint>
      <:empty>No one matches "{@query}".</:empty>
      <:item
        :for={p <- @results}
        id={"person-" <> p.id}
        description={p.email}
        phx-click="add"
        values={%{id: p.id}}
        disabled={p[:disabled]}
        confirm={p[:confirm]}
      >
        {p.name}
      </:item>
    </.command>
    """)
  end

  defp others do
    assigns = %{}

    render(~H"""
    <div id="owner">
      <.command id="scoped" shortcut={nil} on_search="search" query={nil} phx-target="#owner">
        <:item :for={_ <- []}>x</:item>
      </.command>
    </div>
    <.command id="plain" shortcut={nil}>
      <:item id="cal" phx-click="calendar">Calendar</:item>
      <:item id="calc">Calculator</:item>
      <:item id="prof">Profile</:item>
    </.command>
    <div id="dead-wrap">
      <.command id="dead" shortcut={nil} on_search="search" query={nil} search_debounce={0}>
        <:hint>Type to search.</:hint>
        <:item :for={_ <- []}>x</:item>
      </.command>
    </div>
    <div id="late-wrap">
      <.command id="late" shortcut={nil} on_search="search_late" query={nil}>
        <:item :for={_ <- []}>x</:item>
      </.command>
    </div>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    templates =
      for q <- ~w(pa pat zz), do: ~s(<template id="ans-#{q}">#{people(q)}</template>)

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css}</style></head>
    <body>
    #{people("old")}
    #{others()}
    #{Enum.join(templates)}
    <script>#{File.read!(@phoenix_html)}</script>
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const $ = (id) => document.getElementById(id)
    // stands in for LiveView's window click listener (after phoenix_html's)
    const clicked = []
    window.addEventListener("click", (e) => {
      const t = e.target instanceof Element && e.target.closest("[phx-click]")
      if (t) clicked.push(t.id)
    })
    let answer = false
    const asked = []
    window.confirm = (msg) => { asked.push(msg); return answer }

    const searches = []
    document.addEventListener("shadcn:command-search", (e) => searches.push(e.detail))
    initShadcnDaisyui($("dead-wrap"))
    initShadcnDaisyui($("late-wrap"))
    const pushed = []
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook=ShadcnCommand]")) {
      if (el.id === "dead") continue
      const hook = Object.assign(Object.create(Hooks.ShadcnCommand), {
        el,
        pushEvent: (event, payload) => { pushed.push({ event, payload }); return Promise.resolve({}) },
        pushEventTo: (target, event, payload) => { pushed.push({ target, event, payload }); return Promise.resolve([]) },
      })
      hook.mounted()
      hooks[el.id] = hook
    }

    const part = (id, name) => $(id).querySelector("[data-command-" + name + "]")
    const shown = (el) => !!el && !el.closest(".hidden")
    const rows = (id) => [...$(id).querySelectorAll("[data-command-item]")].filter(shown)
      .map((it) => (it.querySelector(".command-item-title") || it).textContent.trim())
    const activeId = (id) => part(id, "search").getAttribute("aria-activedescendant")
    const type = (id, text) => {
      const s = part(id, "search")
      s.value = text
      s.dispatchEvent(new Event("input", { bubbles: true }))
    }
    const key = (id, k) =>
      part(id, "search").dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true }))
    const status = (id) => (part(id, "status") ? part(id, "status").textContent.trim() : null)
    const queries = (id) => pushed.filter((p) => p.payload.id === id).map((p) => p.payload.query)
    // what a LiveView patch does to the palette: the server's list, hint, empty
    // and spinner markup (classes reset) and data-query, then updated()
    const patch = (id, tpl) => {
      const src = $(tpl).content.querySelector("dialog")
      const dlg = $(id)
      for (const sel of ["[data-command-list]", "[data-command-hint]", "[data-command-empty]", "[data-command-spinner]"]) {
        const from = src.querySelector(sel)
        const to = dlg.querySelector(sel)
        if (from && to) to.replaceWith(from.cloneNode(true))
      }
      const q = src.getAttribute("data-query")
      q === null ? dlg.removeAttribute("data-query") : dlg.setAttribute("data-query", q)
      hooks[id] && hooks[id].updated()
    }
    const state = (id) => ({
      rows: rows(id),
      hint: shown(part(id, "hint")),
      empty: shown(part(id, "empty")),
      spinner: shown(part(id, "spinner")),
      busy: part(id, "list").getAttribute("aria-busy"),
      list: shown(part(id, "list")),
      expanded: part(id, "search").getAttribute("aria-expanded"),
      active: activeId(id),
      status: status(id),
    })
    const r = {}

    // opening clears the input and pushes an empty search; the last session's
    // results (rendered for "old") stay hidden behind the hint
    part("people", "search").value = "old"
    $("people").showModal()
    await sleep(0)
    r.opened = {
      ...state("people"),
      input: part("people", "search").value,
      pushed: queries("people"),
      focus: document.activeElement === part("people", "search"),
    }

    // typing is busy at once; the push waits for the debounce, and only the
    // last text goes
    type("people", "pa")
    r.typing = { ...state("people"), pushed: queries("people") }
    // LiveView unlocking the dialog after a slow reply sets `open` again,
    // unchanged: not an open, so what's typed stays and nothing is pushed
    $("people").setAttribute("open", "")
    await sleep(0)
    r.unlock = { input: part("people", "search").value, pushed: queries("people") }
    type("people", "pat")
    await sleep(120)
    r.debounced = { pushed: queries("people") }

    // a reply to older text is not current; the hint stays, dimmed
    patch("people", "ans-pa")
    await sleep(200)
    clicked.length = 0
    key("people", "Enter")
    r.stale = {
      ...state("people"), open: $("people").open, clicked: [...clicked],
      hint_opacity: getComputedStyle(part("people", "hint")).opacity,
    }

    // the answer to the current text: results, first row active, announced
    patch("people", "ans-pat")
    await sleep(0)
    r.results = state("people")

    // arrows skip the disabled row and wrap
    key("people", "ArrowDown")
    const a1 = activeId("people")
    key("people", "ArrowDown")
    const a2 = activeId("people")
    key("people", "ArrowUp")
    const a3 = activeId("people")
    r.arrows = [a1, a2, a3]

    // the same answer re-rendered keeps the active row
    patch("people", "ans-pat")
    await sleep(0)
    r.rerender = { active: activeId("people"), status: status("people") }

    // confirm declined: still open, same results, no click reached LiveView
    answer = false
    clicked.length = 0
    key("people", "Enter")
    r.declined = { open: $("people").open, asked: [...asked], clicked: [...clicked], ...state("people") }

    // confirm accepted: the click runs and the palette closes
    answer = true
    asked.length = 0
    clicked.length = 0
    key("people", "Enter")
    r.accepted = { open: $("people").open, asked: [...asked], clicked: [...clicked] }

    // reopened: a fresh search, the hint, nothing announced
    pushed.length = 0
    $("people").showModal()
    await sleep(0)
    r.reopened = { ...state("people"), input: part("people", "search").value, pushed: queries("people") }

    // the server answers with nothing: the empty slot, announced
    type("people", "zz")
    r.before_answer = { empty: shown(part("people", "empty")) }
    await sleep(80)
    patch("people", "ans-zz")
    await sleep(0)
    r.empty = { ...state("people"), text: part("people", "empty").textContent.trim() }

    // typing on from no match: the empty text stays, dimmed, until the answer
    type("people", "zzz")
    await sleep(200)
    r.empty_busy = { ...state("people"), empty_opacity: getComputedStyle(part("people", "empty")).opacity }

    // a disabled row does nothing; a plain row runs and closes
    type("people", "pat")
    await sleep(80)
    patch("people", "ans-pat")
    await sleep(0)
    clicked.length = 0
    $("person-2").click()
    r.disabled = { open: $("people").open, clicked: [...clicked] }
    $("person-1").click()
    r.plain_row = { open: $("people").open, clicked: [...clicked] }

    // typing on from results: the rows stay, dimmed and inert, so the list does
    $("people").showModal()
    await sleep(0)
    type("people", "pat")
    await sleep(80)
    patch("people", "ans-pat")
    await sleep(0)
    type("people", "pat ri")
    await sleep(200)
    r.results_busy = { ...state("people"), row_opacity: getComputedStyle($("person-1")).opacity }
    $("people").close()
    await sleep(0)

    // closing drops a pending search
    $("people").showModal()
    await sleep(0)
    pushed.length = 0
    type("people", "x")
    $("people").close()
    await sleep(80)
    r.closed = { pushed: queries("people") }

    // phx-target: pushEventTo
    pushed.length = 0
    $("scoped").showModal()
    await sleep(0)
    r.scoped = pushed.filter((p) => p.payload.id === "scoped")
    $("scoped").close()

    // a hook mounted after initShadcnDaisyui() still pushes
    pushed.length = 0
    $("late").showModal()
    await sleep(0)
    r.late = pushed.filter((p) => p.payload.id === "late")
    $("late").close()

    // a dead view: the DOM event, answered by rendering items and data-query
    searches.length = 0
    $("dead").showModal()
    await sleep(0)
    type("dead", "pa")
    await sleep(20)
    r.dead_searches = searches.filter((d) => d.id === "dead").map((d) => d.query)
    part("dead", "list").innerHTML =
      '<li><button type="button" class="command-item" data-command-item>Pat Rivera</button></li>' +
      '<li><button type="button" class="command-item" data-command-item>Pam Lee</button></li>'
    $("dead").setAttribute("data-query", "pa")
    await sleep(0)
    r.dead = state("dead")
    $("dead").close()

    // without on_search: filtered here, as in v0.20.0, nothing pushed
    pushed.length = 0
    $("plain").showModal()
    await sleep(0)
    type("plain", "cal")
    r.plain_filter = { rows: rows("plain"), empty: shown(part("plain", "empty")), active: activeId("plain") }
    type("plain", "zzz")
    r.plain_empty = { rows: rows("plain"), empty: shown(part("plain", "empty")), text: part("plain", "empty").textContent.trim() }
    type("plain", "cal")
    clicked.length = 0
    key("plain", "Enter")
    r.plain_choose = { open: $("plain").open, clicked: [...clicked] }
    r.plain_parts = {
      spinner: !!part("plain", "spinner"), hint: !!part("plain", "hint"), status: !!part("plain", "status"),
      busy: part("plain", "list").getAttribute("aria-busy"), pushed: pushed.length,
      searches: searches.filter((d) => d.id === "plain").length,
    }

    window.__result = JSON.stringify({ errors, r })
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
    %{"errors" => errors, "r" => r} = run_in_chrome()
    %{errors: errors, r: r}
  end

  test "no script errors", %{errors: errors} do
    assert errors == []
  end

  test "opening clears the input, pushes an empty search and shows the hint", %{r: r} do
    assert r["opened"] == %{
             "rows" => [],
             "hint" => true,
             "empty" => false,
             "spinner" => false,
             "busy" => nil,
             "list" => false,
             "expanded" => "false",
             "active" => nil,
             "status" => "",
             "input" => "",
             "pushed" => [""],
             "focus" => true
           }
  end

  test "typing is busy at once and keeps the hint in view, with no empty list", %{r: r} do
    assert %{
             "spinner" => true,
             "busy" => "true",
             "hint" => true,
             "empty" => false,
             "list" => false,
             "expanded" => "false",
             "rows" => []
           } = r["typing"]

    assert r["typing"]["pushed"] == [""]
  end

  test "LiveView re-setting `open` on an open palette doesn't reset it", %{r: r} do
    assert r["unlock"] == %{"input" => "pa", "pushed" => [""]}
  end

  test "the search waits for the debounce and pushes only the last text", %{r: r} do
    assert r["debounced"]["pushed"] == ["", "pat"]
  end

  test "a reply to older text stays busy and can't be chosen", %{r: r} do
    assert %{"spinner" => true, "busy" => "true", "active" => nil, "status" => ""} = r["stale"]
    # still the hint, dimmed; the older reply's rows stay out of view
    assert %{"hint" => true, "hint_opacity" => "0.5", "rows" => [], "list" => false} = r["stale"]
    assert r["stale"]["open"] == true
    assert r["stale"]["clicked"] == []
  end

  test "the answer to the current text shows the results, first one active", %{r: r} do
    assert r["results"] == %{
             "rows" => ["Pat Rivera", "Patrick Hale", "Patricia Gomez"],
             "hint" => false,
             "empty" => false,
             "spinner" => false,
             "busy" => nil,
             "list" => true,
             "expanded" => "true",
             "active" => "person-1",
             "status" => "3 results"
           }
  end

  test "arrow keys skip a disabled row and wrap", %{r: r} do
    assert r["arrows"] == ["person-3", "person-1", "person-3"]
  end

  test "re-rendering the same answer keeps the active row", %{r: r} do
    assert r["rerender"] == %{"active" => "person-3", "status" => "3 results"}
  end

  test "a declined confirm keeps the palette open with the same results", %{r: r} do
    d = r["declined"]
    assert d["open"] == true
    assert d["asked"] == ["Add Patricia Gomez back? They start with no roles."]
    assert d["clicked"] == []
    assert d["rows"] == ["Pat Rivera", "Patrick Hale", "Patricia Gomez"]
    assert d["active"] == "person-3"
  end

  test "an accepted confirm runs the click and closes the palette", %{r: r} do
    assert r["accepted"] == %{
             "open" => false,
             "asked" => ["Add Patricia Gomez back? They start with no roles."],
             "clicked" => ["person-3"]
           }
  end

  test "reopening starts over", %{r: r} do
    assert %{"input" => "", "pushed" => [""], "hint" => true, "rows" => [], "status" => ""} =
             r["reopened"]
  end

  test "no match shows the empty slot only once the server answered, announced", %{r: r} do
    assert r["before_answer"]["empty"] == false

    assert r["empty"] == %{
             "rows" => [],
             "hint" => false,
             "empty" => true,
             "spinner" => false,
             "busy" => nil,
             "list" => false,
             "expanded" => "false",
             "active" => nil,
             "status" => ~s(No one matches "zz".),
             "text" => ~s(No one matches "zz".)
           }
  end

  test "typing on from no match keeps the empty text in view, dimmed", %{r: r} do
    assert %{
             "empty" => true,
             "empty_opacity" => "0.5",
             "hint" => false,
             "list" => false,
             "spinner" => true,
             "busy" => "true"
           } = r["empty_busy"]
  end

  test "typing on from results keeps the rows (and the list), dimmed", %{r: r} do
    assert %{
             "rows" => ["Pat Rivera", "Patrick Hale", "Patricia Gomez"],
             "row_opacity" => "0.5",
             "list" => true,
             "hint" => false,
             "empty" => false,
             "spinner" => true,
             "busy" => "true",
             "active" => nil
           } = r["results_busy"]
  end

  test "a disabled row does nothing; a plain row runs and closes", %{r: r} do
    assert r["disabled"] == %{"open" => true, "clicked" => []}
    assert r["plain_row"] == %{"open" => false, "clicked" => ["person-1"]}
  end

  test "closing drops a pending search", %{r: r} do
    assert r["closed"]["pushed"] == []
  end

  test "phx-target sends the search with pushEventTo", %{r: r} do
    assert r["scoped"] == [
             %{
               "target" => "#owner",
               "event" => "search",
               "payload" => %{"id" => "scoped", "query" => ""}
             }
           ]
  end

  test "a hook mounted after initShadcnDaisyui() still pushes", %{r: r} do
    assert r["late"] == [
             %{"event" => "search_late", "payload" => %{"id" => "late", "query" => ""}}
           ]
  end

  test "a dead view gets shadcn:command-search and answers with data-query", %{r: r} do
    assert r["dead_searches"] == ["", "pa"]

    assert %{"rows" => ["Pat Rivera", "Pam Lee"], "busy" => nil, "spinner" => false} = r["dead"]
    assert %{"list" => true, "expanded" => "true"} = r["dead"]
    assert r["dead"]["status"] == "2 results"
    assert r["dead"]["active"] =~ "dead-list-opt-0"
  end

  test "without on_search the palette filters here, as in v0.20.0", %{r: r} do
    assert r["plain_filter"] == %{
             "rows" => ["Calendar", "Calculator"],
             "empty" => false,
             "active" => "cal"
           }

    assert r["plain_empty"] == %{"rows" => [], "empty" => true, "text" => "No results found."}
    assert r["plain_choose"] == %{"open" => false, "clicked" => ["cal"]}

    assert r["plain_parts"] == %{
             "spinner" => false,
             "hint" => false,
             "status" => false,
             "busy" => nil,
             "pushed" => 0,
             "searches" => 0
           }
  end
end
