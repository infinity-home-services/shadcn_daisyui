defmodule ShadcnDaisyui.JS.FitRowsBrowserTest do
  # Mounts the real <.chip_row> / <.tab_nav> markup with the real
  # shadcn-daisyui.js in headless Chrome and checks what the hooks did.
  # No npm dependencies: the page is a file:// document with the CSS and the
  # JS module inlined, and test/support/chrome_eval.mjs (plain Node) drives
  # Chrome over the DevTools pipe and prints what the page reports.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Display, only: [chip_row: 1]
  import ShadcnDaisyui.Components.Navigation, only: [tab_nav: 1]

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
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui.js")
  @external_resource Path.join(@root, "priv/static/shadcn-daisyui.css")

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # Renders `fixtures` (each `{id, width_px, html}`) into a page, mounts every
  # hook the way LiveView does (mounted, then updated as after a patch), and
  # returns %{"errors" => [...], "rows" => %{id => state}, "probe" => ...}.
  # `probe` is an async JS body run after the rows settle; what it returns
  # comes back as "probe".
  defp run_in_chrome(fixtures, probe \\ "return null") do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    body =
      Enum.map_join(fixtures, "\n", fn {id, width, html} ->
        ~s(<div data-fixture="#{id}" style="width: #{width}px">#{html}</div>)
      end)

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css}</style></head>
    <body>
    #{body}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const hooks = { "ShadcnChipRow": Hooks.ShadcnChipRow, "ShadcnTabNav": Hooks.ShadcnTabNav }
    const mounted = [...document.querySelectorAll("[phx-hook]")].map((el) => {
      const hook = Object.assign(Object.create(hooks[el.getAttribute("phx-hook")]), { el })
      try { hook.mounted() } catch (e) { errors.push(String(e)) }
      return hook
    })
    // a LiveView patch calls updated() on every hook
    for (const hook of mounted) { try { hook.updated() } catch (e) { errors.push(String(e)) } }
    // let ResizeObserver and fonts.ready re-fit too
    await document.fonts.ready
    await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    await new Promise((r) => setTimeout(r, 50))
    const shown = (el) => !el.closest("[hidden]")
    const rows = {}
    for (const { el } of mounted) {
      const trigger = el.querySelector("[data-chip-row-trigger]")
      const more = el.querySelector("[data-chip-row-more], [data-tab-nav-more]")
      rows[el.id] = {
        ready: el.hasAttribute("data-ready"),
        squeezed: el.hasAttribute("data-squeezed"),
        collapsed: el.hasAttribute("data-collapsed"),
        chips: el.querySelectorAll("[data-chip]").length,
        visibleChips: [...el.querySelectorAll("[data-chip]")].filter(shown).length,
        visibleCopies: [...el.querySelectorAll("[data-chip-copy]")].filter((c) => !c.hidden).length,
        moreShown: !!more && shown(more),
        count: trigger ? trigger.getAttribute("data-count") : null,
        visibleTabs: [...el.querySelectorAll("[data-tab-nav-item]")].filter(shown).length,
      }
    }
    let probe = null
    try { probe = await (async () => { #{probe} })() } catch (e) { errors.push(String(e)) }
    window.__result = JSON.stringify({ errors, rows, probe })
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

  defp chip_row_html(id, labels) do
    assigns = %{id: id, labels: labels}

    render(~H"""
    <.chip_row id={@id} aria-label="Filters">
      <:chip :for={l <- @labels} value={l}>{l}</:chip>
    </.chip_row>
    """)
  end

  defp tab_nav_html(id) do
    assigns = %{id: id}

    render(~H"""
    <.tab_nav id={@id} aria-label="Queues">
      <:tab href="#all" count={128}>All leads</:tab>
      <:tab href="#call" active count={17}>Needs a call</:tab>
      <:tab href="#quoted" count={42}>Quoted</:tab>
      <:tab href="#won" count={9}>Won</:tab>
      <:tab href="#lost" count={30}>Lost</:tab>
    </.tab_nav>
    """)
  end

  @labels ~w(Status:open Owner:pat Region:north Priority:high Source:web Type:repair Stage:quoted Tag:vip)

  test "a chip row mounts and patches without errors, with and without overflow" do
    result =
      run_in_chrome([
        {"wide", 1200, chip_row_html("wide", Enum.take(@labels, 3))},
        {"narrow", 260, chip_row_html("narrow", @labels)}
      ])

    assert result["errors"] == []

    wide = result["rows"]["wide"]
    assert wide["ready"]
    assert wide["visibleChips"] == 3
    refute wide["moreShown"]
    refute wide["squeezed"]
    refute wide["collapsed"]

    narrow = result["rows"]["narrow"]
    assert narrow["ready"]
    hidden = narrow["chips"] - narrow["visibleChips"]
    assert narrow["chips"] == 8
    assert hidden > 0
    assert narrow["moreShown"]
    assert narrow["count"] == "+#{hidden}"
    # the popover lists exactly the chips the row hid
    assert narrow["visibleCopies"] == hidden
    refute narrow["collapsed"]
  end

  test "a tab nav folds everything into its menu only when too narrow" do
    result =
      run_in_chrome([
        {"tabs-wide", 1200, tab_nav_html("tabs-wide")},
        {"tabs-narrow", 120, tab_nav_html("tabs-narrow")}
      ])

    assert result["errors"] == []
    assert result["rows"]["tabs-wide"]["visibleTabs"] == 5
    refute result["rows"]["tabs-wide"]["collapsed"]
    assert result["rows"]["tabs-narrow"]["collapsed"]
    assert result["rows"]["tabs-narrow"]["visibleTabs"] == 0
  end

  test "removing a chip fades it out in place, slides the rest, then recounts +N" do
    probe = ~S"""
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const row = document.getElementById("anim")
    const state = () => ({
      chips: [...row.querySelectorAll("[data-chip]")].map((c) => ({
        value: c.dataset.value,
        hidden: c.hidden,
        exiting: c.hasAttribute("data-chip-exiting"),
        position: getComputedStyle(c).position,
      })),
      count: row.querySelector("[data-chip-row-trigger]").dataset.count,
      slides: row.getAnimations({ subtree: true }).filter((a) => "translate" in a.effect.getKeyframes()[0]).length,
    })
    const before = state()
    row.querySelector("[data-chip] [data-chip-remove]").click()
    await sleep(40)
    const during = state()
    await sleep(300)
    return { before, during, after: state() }
    """

    result =
      run_in_chrome([{"anim", 300, chip_row_html("anim", Enum.take(@labels, 6))}], probe)

    assert result["errors"] == []
    %{"before" => before, "during" => during, "after" => settled} = result["probe"]
    hidden_before = Enum.count(before["chips"], & &1["hidden"])
    assert hidden_before > 0
    assert before["count"] == "+#{hidden_before}"

    # the removed chip leaves the flow and fades; the next one slides over
    [first | _] = during["chips"]
    assert first["exiting"] and first["position"] == "absolute"
    assert during["slides"] > 0
    # +N waits for the exit
    assert during["count"] == before["count"]

    # then it is gone and the row re-fits
    assert length(settled["chips"]) == length(before["chips"]) - 1
    refute Enum.any?(settled["chips"], & &1["exiting"])
    hidden_after = Enum.count(settled["chips"], & &1["hidden"])
    assert settled["count"] == "+#{hidden_after}"
  end
end
