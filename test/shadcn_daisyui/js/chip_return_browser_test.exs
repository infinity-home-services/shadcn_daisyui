defmodule ShadcnDaisyui.JS.ChipReturnBrowserTest do
  # <.chip_row> chips that LiveView removes and a later patch renders again
  # while they're still fading out (same value, so the same DOM id), in
  # headless Chrome with the real theme CSS and JS (same harness as the other
  # *_browser_test files). The patch below is LiveView 1.1 / 1.2 as far as it
  # matters here: elements are kept by id and take the server's attributes,
  # except what JS.ignore_attributes keeps; an element the new markup leaves
  # out that has phx-remove stays where it is, runs it after the hooks'
  # updated() (chip-exit, then the 180ms transition) and is removed when that
  # ends - even if a later patch rendered it again. A chip that comes back
  # must cancel its exit and stay: in the row, in the +N popover, and as a
  # stack's value.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Display, only: [chip_row: 1]

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
    *, ::before, ::after { box-sizing: border-box; } body { margin: 0; padding: 24px; font: 14px/20px sans-serif; }
    button { font: inherit; background: none; border: 0; padding: 0; }
    [hidden] { display: none !important; }
    .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
  }
  """

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # `values`: plain chips; `brands`: one stacked chip's items, first
  defp row(id, values, brands \\ []) do
    assigns = %{id: id, values: values, brands: Enum.map(brands, &%{value: &1, label: &1})}

    render(~H"""
    <.chip_row id={@id} aria_label="Filters">
      <:chip :if={@brands != []} value="brands" items={@brands}>Brands</:chip>
      <:chip :for={v <- @values} value={v}>{v}</:chip>
    </.chip_row>
    """)
  end

  defp templates(id, pairs),
    do:
      Enum.map_join(pairs, "\n", fn {name, html} ->
        ~s(<template id="#{id}-#{name}">#{html}</template>)
      end)

  defp body do
    wide = ~w(status pod owner)
    narrow = ~w(acme northwind pod zeta)

    """
    <div style="width: 900px">#{row("wide", wide)}</div>
    <div style="width: 230px; margin-top: 24px">#{row("narrow", narrow)}</div>
    <div style="width: 900px; margin-top: 24px">#{row("stack", ~w(plan), ~w(acme northwind ps))}</div>
    #{templates("wide", with: row("wide", wide), without: row("wide", wide -- ["pod"]))}
    #{templates("narrow", with: row("narrow", narrow), without: row("narrow", narrow -- ["pod"]))}
    #{templates("stack", with: row("stack", ~w(plan), ~w(acme northwind ps)), without: row("stack", ~w(plan), ~w(acme ps)))}
    """
  end

  setup_all do
    %{r: run_in_chrome()}
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css} #{@base}</style></head>
    <body>
    #{body()}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const $ = (id) => document.getElementById(id)
    const hooks = {}
    for (const el of document.querySelectorAll("[phx-hook=ShadcnChipRow]")) {
      const hook = Object.assign(Object.create(Hooks.ShadcnChipRow), { el })
      hook.mounted()
      hooks[el.id] = hook
    }
    const IGNORED = (el) => {
      if (el.matches("[data-chip-stack-list]")) return ["hidden", "inert", "style"]
      if (el.matches("[data-chip-stack-open]")) return ["aria-expanded"]
      if (el.matches("[data-chip-row-panel]")) return ["hidden", "style"]
      if (el.matches("[data-chip], [data-chip-copy], [data-chip-value], [data-chip-row-more]")) return ["hidden"]
      if (el.matches("[data-chip-row-trigger]")) return ["aria-expanded", "aria-label", "data-count"]
      if (el.matches("[data-chip-row]")) return ["data-ready"]
      return []
    }
    const pending = []
    const morph = (from, to) => {
      const keep = IGNORED(from)
      for (const a of [...from.attributes]) if (!to.hasAttribute(a.name) && !keep.includes(a.name)) from.removeAttribute(a.name)
      for (const a of [...to.attributes]) if (!keep.includes(a.name) && from.getAttribute(a.name) !== a.value) from.setAttribute(a.name, a.value)
      const old = [...from.children]
      const used = new Set()
      const next = []
      for (const n of [...to.childNodes]) {
        if (n.nodeType !== 1) { next.push(n.cloneNode(true)); continue }
        const match = n.id ? old.find((c) => c.id === n.id) : old.find((c) => !c.id && c.tagName === n.tagName && !used.has(c))
        if (match) { used.add(match); morph(match, n); next.push(match) }
        else next.push(n.cloneNode(true))
      }
      // left out: a phx-remove element stays in place until its transition ends
      old.forEach((c, i) => {
        if (used.has(c) || !c.hasAttribute("phx-remove")) return
        pending.push(c)
        const after = old.slice(i + 1).find((s) => next.includes(s))
        next.splice(after ? next.indexOf(after) : next.length, 0, c)
      })
      from.replaceChildren(...next)
    }
    const patch = (id, tpl) => {
      hooks[id].beforeUpdate()
      morph($(id), $(id + "-" + tpl).content.firstElementChild)
      hooks[id].updated()
      const removes = pending.splice(0)
      removes.forEach((el) => el.dispatchEvent(new CustomEvent("chip-exit", { bubbles: true })))
      setTimeout(() => removes.forEach((el) => el.remove()), 180)
    }
    const shown = (row) => [...$(row).querySelectorAll("[data-chip]")].filter((c) => !c.hidden && c.isConnected).map((c) => c.dataset.value)
    const state = (el) => el ? {
      connected: el.isConnected,
      hidden: el.hidden,
      exiting: el.hasAttribute("data-chip-exiting"),
      inert: el.inert,
      style: el.getAttribute("style"),
      opacity: getComputedStyle(el).opacity,
      ownRemove: Object.prototype.hasOwnProperty.call(el, "remove"),
    } : null
    const r = {}
    try {
    await document.fonts.ready
    await sleep(50)

    // back 60ms into its exit: the same node stays, in its place, fully shown,
    // and LiveView's removal 180ms after the first patch passes it by
    const pod = $("wide-chip-v-pod")
    r.before = shown("wide")
    patch("wide", "without")
    await sleep(60)
    r.mid = { exiting: pod.hasAttribute("data-chip-exiting"), opacity: Number(getComputedStyle(pod).opacity) < 1 }
    patch("wide", "with")
    await sleep(450)
    r.back = { same: $("wide-chip-v-pod") === pod, shown: shown("wide"), ...state(pod), anims: pod.getAnimations().length }

    // removed for good afterwards: it goes
    patch("wide", "without")
    await sleep(450)
    r.gone = { node: !!$("wide-chip-v-pod"), shown: shown("wide") }

    // back after LiveView removed it: a new node, shown
    patch("wide", "with")
    await sleep(300)
    r.late = { shown: shown("wide"), ...state($("wide-chip-v-pod")) }

    // out and back twice before either removal: still there
    const pod2 = $("wide-chip-v-pod")
    patch("wide", "without"); await sleep(30)
    patch("wide", "with"); await sleep(30)
    patch("wide", "without"); await sleep(30)
    patch("wide", "with"); await sleep(500)
    r.twice = { same: $("wide-chip-v-pod") === pod2, shown: shown("wide"), ...state(pod2) }

    // folded into +N: its chip and its copy come back; the count holds
    const count = () => $("narrow").querySelector("[data-chip-row-trigger]").dataset.count
    const copy = () => $("narrow-copy-v-pod")
    r.narrowBefore = { shown: shown("narrow"), count: count(), copyShown: !copy().hidden }
    patch("narrow", "without")
    await sleep(60)
    patch("narrow", "with")
    await sleep(450)
    r.narrow = { shown: shown("narrow"), count: count(), chip: state($("narrow-chip-v-pod")), copy: state(copy()) }

    // with +N open, its copy fading out in the popover comes back there
    $("narrow").querySelector("[data-chip-row-trigger]").click()
    await sleep(30)
    const panel = $("narrow").querySelector("[data-chip-row-panel]")
    const copyNode = copy()
    patch("narrow", "without")
    await sleep(60)
    const copyMid = !!copyNode && copyNode.hasAttribute("data-chip-exiting")
    patch("narrow", "with")
    await sleep(450)
    r.open = { copyMid, same: copy() === copyNode, panelOpen: !panel.hidden, count: count(), copy: state(copyNode) }
    document.body.click()

    // a stack's value back mid-exit: it stays in the stack, and the stack opens on it
    const value = $("stack-chip-v-brands-value-v-northwind")
    patch("stack", "without")
    await sleep(60)
    patch("stack", "with")
    await sleep(450)
    $("stack-chip-v-brands-open").click()
    await sleep(250)
    r.value = {
      ...state(value),
      same: $("stack-chip-v-brands-value-v-northwind") === value,
      values: [...$("stack-chip-v-brands").querySelectorAll("[data-chip-value]")].filter((v) => !v.hidden && v.isConnected).map((v) => v.dataset.value),
      count: $("stack-chip-v-brands").querySelector("[data-chip-stack-count]").textContent,
    }
    } catch (e) { errors.push(String(e) + " " + (e.stack || "")) }
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

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn ->
        System.cmd(@node, [script, @chrome, file, Path.join(dir, "profile")])
      end)

    result = JSON.decode!(out)
    assert result["errors"] == []
    result["r"]
  end

  @visible %{
    "connected" => true,
    "hidden" => false,
    "exiting" => false,
    "inert" => false,
    "style" => nil,
    "opacity" => "1",
    "ownRemove" => false
  }

  test "a chip back mid-exit keeps its node and stays, after LiveView's removal too", %{r: r} do
    assert r["before"] == ~w(status pod owner)
    assert r["mid"] == %{"exiting" => true, "opacity" => true}
    assert Map.take(r["back"], Map.keys(@visible)) == @visible, inspect(r["back"])
    assert r["back"]["same"] and r["back"]["anims"] == 0, inspect(r["back"])
    assert r["back"]["shown"] == ~w(status pod owner)
  end

  test "removed for good it goes; back later or twice over it stays", %{r: r} do
    assert r["gone"] == %{"node" => false, "shown" => ~w(status owner)}
    assert r["late"]["shown"] == ~w(status pod owner)
    assert Map.take(r["late"], Map.keys(@visible)) == @visible, inspect(r["late"])
    assert r["twice"]["same"] and r["twice"]["shown"] == ~w(status pod owner), inspect(r["twice"])
    assert Map.take(r["twice"], Map.keys(@visible)) == @visible, inspect(r["twice"])
  end

  test "folded into +N, its chip and its copy come back and the count holds", %{r: r} do
    before = r["narrowBefore"]
    refute "pod" in before["shown"]
    assert before["copyShown"]

    n = r["narrow"]
    assert n["shown"] == before["shown"] and n["count"] == before["count"], inspect(n)
    assert n["chip"]["connected"] and n["chip"]["hidden"] and not n["chip"]["exiting"], inspect(n)
    assert Map.take(n["copy"], Map.keys(@visible)) == @visible, inspect(n)

    o = r["open"]

    assert o["copyMid"] and o["same"] and o["panelOpen"] and o["count"] == before["count"],
           inspect(o)

    assert Map.take(o["copy"], Map.keys(@visible)) == @visible, inspect(o)
  end

  test "a stack's value back mid-exit stays in the stack", %{r: r} do
    v = r["value"]
    assert v["same"] and v["values"] == ~w(acme northwind ps) and v["count"] == "+2", inspect(v)
    assert Map.take(v, Map.keys(@visible)) == @visible, inspect(v)
  end
end
