defmodule ShadcnDaisyui.JS.DropdownMenuBrowserTest do
  # <.dropdown_menu> opt-in items in headless Chrome with the real theme CSS and
  # JS (same harness as toolbar_colors_browser_test.exs): destructive text and
  # hover tint (destructive/10, /20 in dark, a light island inside a dark page
  # resolving against its own theme), disabled at 50% with no pointer events,
  # and close_on_select blurring the menu while a plain menu keeps focus.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
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

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp menu(id, close_on_select) do
    assigns = %{id: id, close: close_on_select}

    render(~H"""
    <.dropdown_menu id={@id} close_on_select={@close}>
      <:trigger>Actions</:trigger>
      <:item id={"#{@id}-edit"}>Edit</:item>
      <:item id={"#{@id}-remove"} variant="destructive" confirm="Remove X?">Remove</:item>
      <:item id={"#{@id}-off"} variant="destructive" disabled>Archive</:item>
    </.dropdown_menu>
    """)
  end

  defp run_in_chrome(html_theme, body) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="#{html_theme}">
    <head><meta charset="utf-8"><style>#{css}</style></head>
    <body>
    #{body}
    <script type="module">
    #{js}
    window.confirm = () => true
    const cs = (el) => getComputedStyle(el)
    const probe = (scope, value) => {
      const i = document.createElement("i")
      i.style.backgroundColor = value
      scope.appendChild(i)
      const c = cs(i).backgroundColor
      i.remove()
      return c
    }
    // the hover/focus fill rule, read from the stylesheet (headless can't hover)
    const rules = [...document.styleSheets].flatMap((s) => [...s.cssRules])
      .flatMap((r) => r.cssRules ? [...r.cssRules] : [r])
    const hoverRule = rules.find((r) => r.selectorText && r.selectorText.includes('[data-variant="destructive"]') && r.selectorText.includes(":hover"))
    const colors = {}
    for (const scope of document.querySelectorAll("[data-scope]")) {
      const remove = scope.querySelector("[id$=-remove]"), off = scope.querySelector("[id$=-off]")
      const edit = scope.querySelector("[id$=-edit]")
      colors[scope.dataset.scope] = {
        remove_fg: cs(remove).color,
        off_fg: cs(off).color,
        off_opacity: cs(off).opacity,
        off_events: cs(off).pointerEvents,
        edit_opacity: cs(edit).opacity,
        destructive: probe(scope, "var(--destructive)"),
        hover: probe(scope, "var(--menu-destructive-hover)"),
        light_tint: probe(scope, "color-mix(in oklab, var(--destructive) 10%, transparent)"),
        dark_tint: probe(scope, "color-mix(in oklab, var(--destructive) 20%, transparent)"),
      }
    }
    const inside = (id) => document.getElementById(id).contains(document.activeElement)
    const choose = (id) => {
      document.querySelector("#" + id + " ul").focus()
      const before = inside(id)
      document.getElementById(id + "-remove").click()
      return { before, after: inside(id) }
    }
    window.__result = JSON.stringify({
      colors,
      hover_rule: hoverRule && hoverRule.style.backgroundColor,
      closing: choose("closing"),
      plain: choose("plain"),
    })
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

  defp body(island_theme) do
    ~s(<section data-scope="page">#{menu("closing", true)}#{menu("plain", false)}</section>) <>
      ~s(<section data-scope="island" data-theme="#{island_theme}">#{menu("island", false)}</section>)
  end

  defp assert_colors(c, tint, name) do
    msg = "#{name}: #{inspect(c, pretty: true)}"
    assert c["remove_fg"] == c["destructive"], msg
    assert c["hover"] == c[tint], msg
    # disabled keeps the variant's colors, at 50%, and takes no clicks
    assert c["off_fg"] == c["destructive"], msg
    assert c["off_opacity"] == "0.5", msg
    assert c["off_events"] == "none", msg
    assert c["edit_opacity"] == "1", msg
  end

  test "light page with a dark island" do
    r = run_in_chrome("shadcn", body("shadcn-dark"))

    assert r["hover_rule"] == "var(--menu-destructive-hover)"
    assert_colors(r["colors"]["page"], "light_tint", "light page")
    assert_colors(r["colors"]["island"], "dark_tint", "dark island")
  end

  test "dark page with a light island" do
    r = run_in_chrome("shadcn-dark", body("shadcn"))

    assert_colors(r["colors"]["page"], "dark_tint", "dark page")
    assert_colors(r["colors"]["island"], "light_tint", "light island")
  end

  test "close_on_select blurs the menu after a choice; a plain menu keeps focus" do
    r = run_in_chrome("shadcn", body("shadcn-dark"))

    assert r["closing"] == %{"before" => true, "after" => false}
    assert r["plain"] == %{"before" => true, "after" => true}
  end
end
