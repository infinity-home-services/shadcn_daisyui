defmodule ShadcnDaisyui.JS.TableCardRowsBrowserTest do
  # <.table_card> row heights in headless Chrome (1280px wide, so rows sit
  # side by side) with the real theme CSS and JS (same harness as the other
  # *_browser_test files). A row of text, a row with a badge, with a ⋯ menu,
  # with a small button and the :empty row are one height; the controls keep
  # their size, stay centred and end clear of the row lines (room for the
  # 3px focus ring); two lines of text still make a row taller. Touch is
  # checked by applying the theme's own (pointer: coarse) table card rules:
  # each button's hit area is 44px and stays inside its row. daisyUI's
  # button, badge and dropdown display rules, Tailwind's layer order and
  # preflight, and the heroicon's box stand in, as the harness has neither.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Record, only: [table_card: 1]
  import ShadcnDaisyui.Components.Overlay, only: [dropdown_menu: 1]

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
  @layer theme, base, components, utilities;
  @layer base {
    *, ::before, ::after { box-sizing: border-box; margin: 0; padding: 0; border: 0 solid; }
    html { line-height: 1.5; } button { font: inherit; color: inherit; background: none; }
  }
  @layer utilities {
    .btn { display: inline-flex; align-items: center; justify-content: center; vertical-align: middle; }
    .badge { display: inline-flex; align-items: center; justify-content: center; vertical-align: middle; }
    .dropdown { position: relative; display: inline-block; }
    .dropdown-content { position: absolute; visibility: hidden; }
    [class*="hero-"] { display: inline-block; vertical-align: middle; width: 1rem; height: 1rem; background-color: currentColor; }
    .grid { display: grid; } .grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); } .items-start { align-items: start; } .gap-4 { gap: 1rem; }
    .cols-test { grid-template-columns: minmax(0, 1fr) 6rem 5rem; }
  }
  """

  @rows [
    %{id: "text", name: "Pat Lee", control: nil},
    %{id: "badge", name: "Sam Ortiz", control: :badge},
    %{id: "menu", name: "Robin Park", control: :menu},
    %{id: "sm", name: "Alex Kim", control: :sm},
    %{id: "xs", name: "Jo Diaz", control: :xs},
    %{id: "button", name: "Lee Chen", control: :button},
    %{id: "two-lines", name: "Morgan Hale", control: :two_lines}
  ]

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  # the same rows twice: stacked on phones but side by side from 40rem (the
  # harness is wider), and `grid` (side by side at every width)
  defp body do
    assigns = %{rows: @rows}

    render(~H"""
    <div class="grid grid-cols-3 items-start gap-4">
      <.people id="stack" rows={@rows} />
      <.people id="grid" rows={@rows} grid="cols-test" />
      <.table_card id="nobody" title="Nobody" rows={[]}>
        <:col :let={r} label="Name">{r.name}</:col>
        <:col :let={r} label="Role">{r.role}</:col>
        <:col :let={_r}></:col>
        <:empty>No one yet.</:empty>
      </.table_card>
    </div>
    """)
  end

  defp people(assigns) do
    assigns = assign_new(assigns, :grid, fn -> nil end)

    ~H"""
    <.table_card id={@id} title="People" rows={@rows} row_id={&"#{@id}-#{&1.id}"} grid={@grid}>
        <:col :let={r} label="Name">
          {r.name}<div :if={r.control == :two_lines}>A second line</div>
        </:col>
        <:col :let={r} label="Role">
          <span :if={r.control == :badge} id={"#{@id}-the-badge"} class="badge badge-secondary">Lead</span>
          <span :if={r.control != :badge}>Member</span>
        </:col>
        <:col :let={r}>
          <.dropdown_menu
            :if={r.control == :menu}
            id={"#{@id}-the-menu"}
            trigger_class="btn btn-ghost btn-square btn-sm"
            chevron={false}
            aria-label="Actions"
            align="end"
          >
            <:trigger><span class="hero-ellipsis-horizontal size-4"></span></:trigger>
            <:item>Edit</:item>
          </.dropdown_menu>
          <button :if={r.control == :sm} id={"#{@id}-the-sm"} type="button" class="btn btn-outline btn-sm">Edit</button>
          <button :if={r.control == :xs} id={"#{@id}-the-xs"} type="button" class="btn btn-outline btn-xs">Edit</button>
          <button :if={r.control == :button} id={"#{@id}-the-button"} type="button" class="btn btn-outline">Edit</button>
        </:col>
      </.table_card>
    """
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{@base}#{css}</style></head>
    <body>
    #{body()}
    <script type="module">
    #{js}
    const $ = (id) => document.getElementById(id)
    const rect = (el) => el.getBoundingClientRect()
    // a row's padding box (its line under it is outside clientHeight)
    const rowOf = (el) => el.closest("[role=row]")
    const fit = (el) => {
      const row = rowOf(el)
      const r = rect(el), rr = rect(row)
      return {
        height: Math.round(r.height * 10) / 10,
        above: Math.round((r.top - rr.top) * 10) / 10,
        below: Math.round((rr.top + row.clientHeight - r.bottom) * 10) / 10,
      }
    }
    const layouts = ["stack", "grid"]
    const kinds = ["badge", "menu", "sm", "xs", "button"]
    const control = (layout, k) => k === "menu"
      ? $(layout + "-the-menu").querySelector("[role=button]")
      : $(layout + "-the-" + k)
    const measure = () => {
      const out = {}
      const empty = $("nobody").querySelector(".table-card-empty")
      for (const layout of layouts) {
        const m = out[layout] = { rows: {}, controls: {} }
        for (const row of $(layout).querySelectorAll("[role=rowgroup]:last-child > [role=row]")) m.rows[row.id.replace(layout + "-", "")] = row.clientHeight
        m.rows.empty = empty.clientHeight
        for (const k of kinds) m.controls[k] = fit(control(layout, k))
        // the empty row starts level with the first row of the card beside it
        m.empty_offset = Math.round(rect(empty).top - rect($(layout + "-text")).top)
      }
      return out
    }
    const empty = $("nobody").querySelector(".table-card-empty"), row = $("stack-text")
    const r = {
      fine: measure(),
      padding: { row: getComputedStyle(row).padding, empty: getComputedStyle(empty).padding },
    }
    // touch: the theme's (pointer: coarse) table card rules, applied here
    const coarse = [...document.styleSheets].flatMap((s) => [...s.cssRules])
      .flatMap((x) => x.cssRules ? [...x.cssRules] : [x])
      .filter((x) => x.conditionText === "(pointer: coarse)" && x.cssText.includes("table-card"))
      .flatMap((x) => [...x.cssRules].map((c) => c.cssText))
    const touch = new CSSStyleSheet()
    coarse.forEach((t) => touch.insertRule("@layer utilities { " + t + " }", touch.cssRules.length))
    document.adoptedStyleSheets = [touch]
    r.coarse_rules = coarse.length
    r.touch = measure()
    // each button's hit area (its ::after): at least 44px each way, inside its row
    r.hit = {}
    for (const k of kinds) {
      if (k === "badge") continue
      const el = control("grid", k), a = getComputedStyle(el, "::after"), b = rect(el), rr = rect(rowOf(el))
      // the ::after's insets count from the button's padding box
      const pt = b.top + el.clientTop, pl = b.left + el.clientLeft
      const top = pt + parseFloat(a.top), bottom = pt + el.clientHeight - parseFloat(a.bottom)
      const left = pl + parseFloat(a.left), right = pl + el.clientWidth - parseFloat(a.right)
      r.hit[k] = {
        height: Math.round(bottom - top), width: Math.round(right - left),
        inside: top >= rr.top - 0.01 && bottom <= rr.top + rowOf(el).clientHeight + 0.01,
      }
    }
    window.__result = JSON.stringify(r)
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

  defp assert_one_height(m, msg) do
    text = m["rows"]["text"]
    # 12px padding round one 21px line
    assert text == 45, msg

    for id <- ~w(badge menu sm xs button empty) do
      assert m["rows"][id] == text, "#{id}: #{msg}"
    end

    assert m["rows"]["two-lines"] > text, msg
    assert m["empty_offset"] == 0, msg

    # full size (.btn's min-height holds btn-sm and btn-xs at 36px), centred,
    # and clear of the row lines by more than the 3px focus ring
    sizes = %{"badge" => 24, "menu" => 36, "sm" => 36, "xs" => 36, "button" => 36}

    for {k, height} <- sizes do
      c = m["controls"][k]
      assert c["height"] == height, "#{k}: #{msg}"
      assert_in_delta c["above"], c["below"], 0.5, "#{k}: #{msg}"
      assert c["above"] >= 4, "#{k}: #{msg}"
    end
  end

  test "rows are one height with or without a small control; the empty row matches them" do
    r = run_in_chrome()
    msg = inspect(r, pretty: true)

    # the empty row has a row's padding
    assert r["padding"]["empty"] == r["padding"]["row"], msg
    assert r["padding"]["row"] == "12px 24px", msg

    for layout <- ~w(stack grid), do: assert_one_height(r["fine"][layout], "#{layout}: #{msg}")
  end

  test "touch: 44px hit areas inside the row, and still one height" do
    r = run_in_chrome()
    msg = inspect(r, pretty: true)

    assert r["coarse_rules"] > 0, msg
    for layout <- ~w(stack grid), do: assert_one_height(r["touch"][layout], "#{layout}: #{msg}")

    for {k, hit} <- r["hit"] do
      assert hit["height"] >= 44 and hit["width"] >= 44, "#{k}: #{msg}"
      assert hit["inside"], "#{k}: #{msg}"
    end
  end
end
