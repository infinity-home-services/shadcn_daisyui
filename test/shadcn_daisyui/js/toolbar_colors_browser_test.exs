defmodule ShadcnDaisyui.JS.ToolbarColorsBrowserTest do
  # A toolbar (tabs, tab nav More trigger, search input, select trigger, outline
  # button, outline dropdown trigger) in headless Chrome with the real theme CSS
  # (same harness as fit_rows_browser_test.exs). Compares computed colors with
  # shadcn's default (Vega) style: each expected value is resolved by a probe
  # element in the same theme, so the test checks the recipe (bg-input/30,
  # text-foreground/60, ...) rather than hard-coded OKLCH strings.
  # Each page also nests the other theme, so a light island inside a dark page
  # (and the reverse) must resolve against its own theme.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Navigation, only: [tab_nav: 1]
  import ShadcnDaisyui.Components.Overlay, only: [dropdown_menu: 1]
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

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp toolbar(id) do
    assigns = %{id: id}

    render(~H"""
    <div role="tablist" class="tabs tabs-box">
      <input type="radio" name={@id} class="tab" aria-label="All" checked data-part="tab-active" />
      <input type="radio" name={@id} class="tab" aria-label="Active" data-part="tab-inactive" />
    </div>
    <.tab_nav id={"#{@id}-nav"}>
      <:tab href="#all">All</:tab>
      <:menu_item href="#saved" active>Saved view</:menu_item>
    </.tab_nav>
    <input class="input" placeholder="Search" data-part="input" />
    <.select id={"#{@id}-select"} placeholder="Status">
      <:option value="open">Open</:option>
    </.select>
    <button type="button" class="btn btn-outline" data-part="outline">Filter</button>
    <.dropdown_menu>
      <:trigger>View</:trigger>
      <:item>Table</:item>
    </.dropdown_menu>
    <button type="button" class="btn btn-primary">New</button>
    """)
  end

  # Expected values per theme, as the shadcn recipe expressions.
  @light %{
    foreground: "var(--foreground)",
    list_bg: "var(--muted)",
    active_bg: "var(--background)",
    active_border: "transparent",
    inactive_fg: "color-mix(in oklab, var(--foreground) 60%, transparent)",
    outline_bg: "var(--background)",
    outline_border: "var(--border-color)",
    outline_hover: "var(--muted)",
    field_bg: "transparent",
    field_border: "var(--input)"
  }
  @dark %{
    foreground: "var(--foreground)",
    list_bg: "var(--muted)",
    active_bg: "color-mix(in oklab, var(--input) 30%, transparent)",
    active_border: "var(--input)",
    inactive_fg: "var(--muted-foreground)",
    outline_bg: "color-mix(in oklab, var(--input) 30%, transparent)",
    outline_border: "var(--input)",
    outline_hover: "color-mix(in oklab, var(--input) 50%, transparent)",
    field_bg: "color-mix(in oklab, var(--input) 30%, transparent)",
    field_border: "var(--input)"
  }

  defp panel(id, theme_attr, expected) do
    probes =
      Enum.map_join(expected, "", fn {k, v} ->
        ~s(<i data-probe="#{k}" style="background-color: #{v}"></i>)
      end)

    probes =
      probes <>
        ~s|<i data-probe="hover_token" style="background-color: var(--outline-hover)"></i>|

    ~s(<section data-panel="#{id}" #{theme_attr}>#{toolbar(id)}<div hidden>#{probes}</div></section>)
  end

  defp run_in_chrome(html_theme, panels) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))

    page = """
    <!doctype html>
    <html data-theme="#{html_theme}">
    <head><meta charset="utf-8">
    <!-- daisyUI's base .tab rule (the plugin isn't loaded here): native radios
         otherwise keep appearance:auto and report a currentColor border -->
    <style>@layer utilities { .tab { appearance: none; } }</style>
    <style>#{css}</style></head>
    <body>
    #{Enum.join(panels)}
    <script type="module">
    const cs = (el) => getComputedStyle(el)
    const panels = {}
    for (const p of document.querySelectorAll("[data-panel]")) {
      const q = (sel) => p.querySelector(sel)
      const expected = {}
      for (const i of p.querySelectorAll("[data-probe]")) expected[i.dataset.probe] = cs(i).backgroundColor
      const list = q(".tabs-box"), active = q("[data-part=tab-active]"), inactive = q("[data-part=tab-inactive]")
      const more = q("[data-tab-nav-trigger]"), outline = q("[data-part=outline]")
      const dropdown = q(".dropdown > .btn"), input = q("[data-part=input]"), trigger = q("[data-select-trigger]")
      panels[p.dataset.panel] = {
        expected,
        actual: {
          list_bg: cs(list).backgroundColor,
          list_height: cs(list).height,
          tab_height: cs(active).height,
          active_bg: cs(active).backgroundColor,
          active_border: cs(active).borderTopColor,
          active_fg: cs(active).color,
          inactive_border: cs(inactive).borderTopColor,
          inactive_fg: cs(inactive).color,
          more_bg: cs(more).backgroundColor,
          more_border: cs(more).borderTopColor,
          outline_bg: cs(outline).backgroundColor,
          outline_border: cs(outline).borderTopColor,
          dropdown_bg: cs(dropdown).backgroundColor,
          dropdown_border: cs(dropdown).borderTopColor,
          input_bg: cs(input).backgroundColor,
          input_border: cs(input).borderTopColor,
          trigger_bg: cs(trigger).backgroundColor,
          trigger_border: cs(trigger).borderTopColor,
        },
      }
    }
    // the hover fill comes from the token, not a hard-coded colour
    const hover = [...document.styleSheets].flatMap((s) => [...s.cssRules])
      .flatMap((r) => r.cssRules ? [...r.cssRules] : [r])
      .find((r) => r.selectorText === ".btn-outline:hover")
    window.__result = JSON.stringify({ panels, hover: hover && hover.style.backgroundColor })
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

  defp assert_toolbar(%{"expected" => e, "actual" => a}, name) do
    msg = "#{name}: #{inspect(a, pretty: true)}"

    # tabs: h-9 p-[3px] list, h-[calc(100%-1px)] triggers
    assert a["list_bg"] == e["list_bg"], msg
    assert a["list_height"] == "36px", msg
    assert a["tab_height"] == "29px", msg
    assert a["active_bg"] == e["active_bg"], msg
    assert a["active_border"] == e["active_border"], msg
    assert a["active_fg"] == e["foreground"], msg
    assert a["inactive_border"] == "rgba(0, 0, 0, 0)", msg
    assert a["inactive_fg"] == e["inactive_fg"], msg
    # the tab nav's More trigger (holding the active view) is an active tab
    assert a["more_bg"] == e["active_bg"], msg
    assert a["more_border"] == e["active_border"], msg

    # outline button and the outline dropdown trigger
    for part <- ["outline", "dropdown"] do
      assert a["#{part}_bg"] == e["outline_bg"], msg
      assert a["#{part}_border"] == e["outline_border"], msg
    end

    assert e["hover_token"] == e["outline_hover"], msg

    # fields and the custom select trigger
    for part <- ["input", "trigger"] do
      assert a["#{part}_bg"] == e["field_bg"], msg
      assert a["#{part}_border"] == e["field_border"], msg
    end
  end

  test "light page with a dark island matches shadcn's light and dark toolbar" do
    result =
      run_in_chrome("shadcn", [
        panel("page", "", @light),
        panel("island", ~s(data-theme="shadcn-dark"), @dark)
      ])

    assert result["hover"] == "var(--outline-hover)"
    assert_toolbar(result["panels"]["page"], "light page")
    assert_toolbar(result["panels"]["island"], "dark island")
  end

  test "dark page with a light island matches shadcn's dark and light toolbar" do
    result =
      run_in_chrome("shadcn-dark", [
        panel("page", "", @dark),
        panel("island", ~s(data-theme="shadcn"), @light)
      ])

    assert_toolbar(result["panels"]["page"], "dark page")
    assert_toolbar(result["panels"]["island"], "light island")
  end
end
