defmodule ShadcnDaisyui.JS.SelectRerenderBrowserTest do
  # Does <.select> keep its chosen value across LiveView re-renders? In
  # headless Chrome with the real theme CSS and JS (same harness as the other
  # *_browser_test files). A re-render is patched in the way LiveView's
  # morphdom does it - the existing elements kept, their attributes, text and
  # input values set from the server's markup - then updated() runs. The
  # server's markup comes from the component, rendered with what the server
  # thinks the value is.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components, only: [select: 1]

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

  defp fruit(value, counts \\ 1) do
    assigns = %{value: value, counts: counts}

    render(~H"""
    <.select id="fruit" name="fruit" value={@value} placeholder="Pick a fruit">
      <:option value="apple" count={@counts}>Apple</:option>
      <:option value="banana" count={@counts}>Banana</:option>
      <:option value="cherry" count={@counts}>Cherry</:option>
    </.select>
    """)
  end

  defp sort(value) do
    assigns = %{value: value}

    render(~H"""
    <.select id="sort" name="sort" value={@value}>
      <:option value="">Default order</:option>
      <:option value="name:asc">Name</:option>
      <:option value="total:desc">Total</:option>
    </.select>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    templates =
      [
        {"fruit-nil-2", fruit(nil, 2)},
        {"fruit-nil-3", fruit(nil, 3)},
        {"fruit-banana", fruit("banana", 3)},
        {"fruit-cherry", fruit("cherry", 3)},
        {"fruit-empty", fruit("", 3)},
        {"sort-blank", sort("")},
        {"sort-name", sort("name:asc")}
      ]
      |> Enum.map_join("\n", fn {k, v} -> ~s(<template id="tpl-#{k}">#{v}</template>) end)

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css} .hidden { display: none; }</style></head>
    <body>
    <form id="f">#{fruit(nil)}#{sort("")}</form>
    #{templates}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    #{js}
    const $ = (id) => document.getElementById(id)
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook=ShadcnSelect]")) {
      const hook = Object.assign(Object.create(Hooks.ShadcnSelect), { el })
      hook.mounted()
      hooks[el.id] = hook
    }
    // morphdom, as far as these patches go: keep the elements, set their
    // attributes, text and input values from the server's markup
    const morph = (from, to) => {
      if (from.nodeType === 3) { if (from.data !== to.data) from.data = to.data; return }
      for (const a of [...from.attributes]) if (!to.hasAttribute(a.name)) from.removeAttribute(a.name)
      for (const a of [...to.attributes]) if (from.getAttribute(a.name) !== a.value) from.setAttribute(a.name, a.value)
      if (from.tagName === "INPUT" && from.value !== to.value) from.value = to.value
      const fc = [...from.childNodes], tc = [...to.childNodes]
      if (fc.length !== tc.length || fc.some((n, i) => n.nodeType !== tc[i].nodeType || n.nodeName !== tc[i].nodeName)) {
        from.replaceChildren(...tc.map((n) => n.cloneNode(true)))
        return
      }
      fc.forEach((n, i) => morph(n, tc[i]))
    }
    const patch = (id, tpl) => {
      morph($(id), $("tpl-" + tpl).content.firstElementChild)
      hooks[id].updated()
    }
    const label = (id) => $(id).querySelector("[data-select-label]").textContent.trim()
    const input = (id) => $(id).querySelector("[data-select-input]").value
    const pick = (id, value) => {
      $(id).querySelector("[data-select-trigger]").click()
      $(id).querySelector('[data-select-item][data-value="' + value + '"]').click()
    }
    const changes = []
    $("f").addEventListener("change", (e) => changes.push(e.target.name + "=" + e.target.value))
    const state = (id) => ({ label: label(id), input: input(id) })
    const r = {}

    // a select the server doesn't track: the pick survives unrelated re-renders
    pick("fruit", "banana")
    r.picked = { ...state("fruit"), changes: [...changes] }
    patch("fruit", "fruit-nil-2")
    r.unrelated = state("fruit")
    patch("fruit", "fruit-nil-3")
    r.unrelated_again = state("fruit")

    // the server takes the pick (an echo), then sets its own value, then clears it
    patch("fruit", "fruit-banana")
    r.echo = state("fruit")
    patch("fruit", "fruit-cherry")
    r.server_value = state("fruit")
    pick("fruit", "apple")
    patch("fruit", "fruit-cherry") // a re-render of the old value: the pick stays
    r.stale = state("fruit")
    patch("fruit", "fruit-empty")
    r.server_clear = state("fruit")

    // a "" option is the blank choice: shown while blank, and a pick survives
    r.sort_initial = state("sort")
    pick("sort", "name:asc")
    patch("sort", "sort-blank") // not processed yet: the pick stays
    r.sort_picked = state("sort")
    patch("sort", "sort-name") // the echo
    r.sort_echo = state("sort")
    patch("sort", "sort-blank") // Clear all on the server: back to the default
    r.sort_reset = state("sort")
    pick("sort", "total:desc")
    pick("sort", "")
    r.sort_pick_blank = { ...state("sort"), last_change: changes[changes.length - 1] }

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
    {out, 0} = System.cmd(@node, [script, @chrome, file, profile])
    JSON.decode!(out)
  end

  setup_all do
    %{"errors" => errors, "r" => r} = run_in_chrome()
    %{errors: errors, r: r}
  end

  test "no script errors", %{errors: errors} do
    assert errors == []
  end

  test "a pick posts and survives re-renders that don't know about it", %{r: r} do
    assert r["picked"] == %{
             "label" => "Banana",
             "input" => "banana",
             "changes" => ["fruit=banana"]
           }

    assert r["unrelated"] == %{"label" => "Banana", "input" => "banana"}
    assert r["unrelated_again"] == %{"label" => "Banana", "input" => "banana"}
  end

  test "the server's own value wins; its echo and stale renders don't undo a pick", %{r: r} do
    assert r["echo"] == %{"label" => "Banana", "input" => "banana"}
    assert r["server_value"] == %{"label" => "Cherry", "input" => "cherry"}
    assert r["stale"] == %{"label" => "Apple", "input" => "apple"}
    assert r["server_clear"] == %{"label" => "Pick a fruit", "input" => ""}
  end

  test "a value=\"\" option is the blank choice and follows re-renders too", %{r: r} do
    assert r["sort_initial"] == %{"label" => "Default order", "input" => ""}
    assert r["sort_picked"] == %{"label" => "Name", "input" => "name:asc"}
    assert r["sort_echo"] == %{"label" => "Name", "input" => "name:asc"}
    assert r["sort_reset"] == %{"label" => "Default order", "input" => ""}

    assert r["sort_pick_blank"] == %{
             "label" => "Default order",
             "input" => "",
             "last_change" => "sort="
           }
  end
end
