defmodule ShadcnDaisyui.JS.ComboboxCreateBrowserTest do
  # <.combobox create> in headless Chrome with the real theme CSS and JS (same
  # harness as fit_rows_browser_test.exs): the Add row appears only for text no
  # option label matches exactly, is the only row when nothing matches, is
  # reachable by arrow keys, and choosing it selects + posts the text, pushes
  # `on_create`, and survives a LiveView patch. Multiple ticks it and stays open.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components, only: [combobox: 1]

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

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp single(value \\ nil) do
    assigns = %{value: value}

    render(~H"""
    <form id="single-form">
      <.combobox id="insurer" name="insurer" value={@value} create on_create="add_insurer" create_max={20}>
        <:option value="State Farm">State Farm</:option>
        <:option value="Allstate">Allstate</:option>
        <:option value="Progressive">Progressive</:option>
      </.combobox>
    </form>
    """)
  end

  defp multi do
    assigns = %{}

    render(~H"""
    <.combobox id="tags" name="tags" multiple create value={["vip"]}>
      <:option value="vip">VIP</:option>
      <:option value="referral">Referral</:option>
    </.combobox>
    """)
  end

  defp late do
    assigns = %{}

    render(~H"""
    <.combobox id="late" name="late" create on_create="add_late">
      <:option value="a">Apple</:option>
    </.combobox>
    """)
  end

  defp plain do
    assigns = %{}

    render(~H"""
    <.combobox id="plain" name="plain">
      <:option value="a">Apple</:option>
    </.combobox>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css}</style></head>
    <body>
    #{single()}
    #{multi()}
    #{plain()}
    <div id="late-wrap">#{late()}</div>
    <template id="patched">#{single("Acme Mutual")}</template>
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    #{js}
    const pushed = []
    // a page that also runs the dead-view init before LiveView mounts the hooks
    initShadcnDaisyui(document.getElementById("late-wrap"))
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook=ShadcnCombobox]")) {
      const hook = Object.assign(Object.create(Hooks.ShadcnCombobox), {
        el, pushEvent: (event, payload) => pushed.push({ event, payload }),
      })
      hook.mounted()
      hooks[el.id] = hook
    }
    const $ = (id) => document.getElementById(id)
    const part = (id, name) => $(id).querySelector("[data-combobox-" + name + "]")
    const shown = (el) => !!el && !el.closest(".hidden")
    const type = (id, text) => {
      const s = part(id, "search")
      s.value = text
      s.dispatchEvent(new Event("input", { bubbles: true }))
    }
    const key = (id, k) =>
      part(id, "search").dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true }))
    const open = (id) => { if (!shown(part(id, "panel"))) part(id, "trigger").click() }
    const rows = (id) =>
      [...$(id).querySelectorAll("[role=option]")].filter(shown).map((r) => r.textContent.trim())
    const label = (id) => part(id, "label").textContent.trim()
    const create = (id) => part(id, "create")
    const changes = []
    document.addEventListener("change", (e) => changes.push(e.target.name + "=" + e.target.value))
    const comboChanges = []
    document.addEventListener("combobox-change", (e) => comboChanges.push(e.detail.value))
    const r = {}

    open("insurer")
    type("insurer", "  Acme Mutual ")
    r.nothing_matches = {
      rows: rows("insurer"),
      empty: shown(part("insurer", "empty")),
      active: part("insurer", "search").getAttribute("aria-activedescendant") === create("insurer").id,
      role: create("insurer").getAttribute("role"),
      plus: !!create("insurer").querySelector(".hero-plus"),
    }
    type("insurer", "state farm")
    r.exact = { rows: rows("insurer"), add: shown(create("insurer")) }
    type("insurer", "  STATE FARM  ")
    r.exact_padded = { add: shown(create("insurer")) }
    type("insurer", "   ")
    r.blank = { add: shown(create("insurer")) }
    type("insurer", "x".repeat(21))
    r.too_long = { add: shown(create("insurer")) }

    // "al" matches Allstate (and Progressive? no): Add is the last row
    type("insurer", "al")
    r.partial = { rows: rows("insurer") }
    key("insurer", "ArrowDown")
    r.partial.arrow_active =
      part("insurer", "search").getAttribute("aria-activedescendant") === create("insurer").id
    key("insurer", "ArrowUp")
    key("insurer", "ArrowUp")
    r.partial.wrapped_active =
      part("insurer", "search").getAttribute("aria-activedescendant") === create("insurer").id

    type("insurer", "  Acme Mutual ")
    key("insurer", "Enter")
    r.chosen = {
      open: shown(part("insurer", "panel")),
      label: label("insurer"),
      input: part("insurer", "input").value,
      changes: [...changes],
      combo: [...comboChanges],
      pushed: [...pushed],
      focus_on_trigger: document.activeElement === part("insurer", "trigger"),
    }
    open("insurer")
    const row = $("insurer").querySelector('[data-value="Acme Mutual"]')
    r.reopened = { rows: rows("insurer"), selected: row && row.getAttribute("aria-selected") }
    key("insurer", "Escape")

    // a LiveView patch re-renders the server's markup, then updated() runs
    $("insurer").replaceWith(document.getElementById("patched").content.querySelector("#insurer").cloneNode(true))
    hooks.insurer.el = $("insurer")
    // the hook keeps its api on the old element; mount fresh like LiveView would on a new node
    hooks.insurer.mounted()
    hooks.insurer.updated()
    r.patched = { label: label("insurer"), created_rows: $("insurer").querySelectorAll("[data-created]").length }

    // multiple: Add ticks and keeps the list open, search cleared
    open("tags")
    type("tags", "Walk-in")
    part("tags", "create").click()
    r.multiple = {
      open: shown(part("tags", "panel")),
      search: part("tags", "search").value,
      values: [...$("tags").querySelectorAll("[data-combobox-value]")].map((i) => i.value),
      checked: [...$("tags").querySelectorAll('[role=option][aria-selected="true"]')].map((o) => o.textContent.trim()),
      label: label("tags"),
    }
    // the patch drops the client-added row; updated() puts it back, still ticked
    $("tags").querySelectorAll("[data-created]").forEach((b) => b.parentElement.remove())
    hooks.tags.updated()
    r.multiple.after_update = [...$("tags").querySelectorAll('[role=option][aria-selected="true"]')].map((o) => o.textContent.trim())

    // without create: no Add row, the empty state as before
    open("plain")
    type("plain", "zzz")
    r.plain = { rows: rows("plain"), empty: shown(part("plain", "empty")), add: !!create("plain") }

    // initialised by initShadcnDaisyui() first: the hook mounted later still pushes
    pushed.length = 0
    open("late")
    type("late", "Banana")
    key("late", "Enter")
    r.late = { pushed: [...pushed], label: label("late") }

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

  test "nothing matching: Add is the only row, replaces empty, and is active", %{r: r} do
    assert r["nothing_matches"] == %{
             "rows" => [~s(Add "Acme Mutual")],
             "empty" => false,
             "active" => true,
             "role" => "option",
             "plus" => true
           }
  end

  test "an exact label match (case and spaces ignored) never offers Add", %{r: r} do
    assert r["exact"] == %{"rows" => ["State Farm"], "add" => false}
    assert r["exact_padded"]["add"] == false
  end

  test "blank text and text over create_max never offer Add", %{r: r} do
    assert r["blank"]["add"] == false
    assert r["too_long"]["add"] == false
  end

  test "a partial match lists Add last, reachable by arrow keys", %{r: r} do
    assert r["partial"]["rows"] == ["Allstate", ~s(Add "al")]
    assert r["partial"]["arrow_active"] == true
    assert r["partial"]["wrapped_active"] == true
  end

  test "choosing Add selects, posts and pushes the trimmed text, then closes", %{r: r} do
    c = r["chosen"]
    assert c["open"] == false
    assert c["label"] == "Acme Mutual"
    assert c["input"] == "Acme Mutual"
    assert c["changes"] == ["insurer=Acme Mutual"]
    assert c["combo"] == ["Acme Mutual"]

    assert c["pushed"] == [
             %{
               "event" => "add_insurer",
               "payload" => %{"id" => "insurer", "value" => "Acme Mutual"}
             }
           ]

    assert c["focus_on_trigger"] == true
    assert "Acme Mutual" in r["reopened"]["rows"]
    assert r["reopened"]["selected"] == "true"
  end

  test "the server's markup for an added value keeps the label after a patch", %{r: r} do
    assert r["patched"] == %{"label" => "Acme Mutual", "created_rows" => 1}
  end

  test "multiple: Add ticks the value, keeps the list open and clears the search", %{r: r} do
    m = r["multiple"]
    assert m["open"] == true
    assert m["search"] == ""
    assert m["values"] == ["vip", "Walk-in"]
    assert m["checked"] == ["VIP", "Walk-in"]
    assert m["label"] == "VIP, Walk-in"
    assert m["after_update"] == ["VIP", "Walk-in"]
  end

  test "a hook mounted after initShadcnDaisyui() still pushes on_create", %{r: r} do
    assert r["late"] == %{
             "label" => "Banana",
             "pushed" => [
               %{"event" => "add_late", "payload" => %{"id" => "late", "value" => "Banana"}}
             ]
           }
  end

  test "a combobox without create keeps the empty state", %{r: r} do
    assert r["plain"] == %{"rows" => [], "empty" => true, "add" => false}
  end
end
