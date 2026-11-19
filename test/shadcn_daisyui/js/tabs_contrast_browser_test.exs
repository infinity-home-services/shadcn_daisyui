defmodule ShadcnDaisyui.JS.TabsContrastBrowserTest do
  # The tab row (.tabs-box: <.tabs>, <.tab_nav>) in headless Chrome with the
  # real theme CSS: in light mode the row has its own fill
  # (--tab-list-background, a step darker than --muted) so the white active
  # tab stands out, inactive text keeps 4.5:1, dark is unchanged, and brand
  # themes inherit or override it like --chip-background.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Navigation, only: [tabs: 1]

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

  # a brand that inherits the light neutrals (as a brand's light theme
  # does), one that sets its own row, and a *-dark brand
  @brands """
  [data-theme="brand"] { --primary: oklch(0.714 0.126 226.3); }
  [data-theme="tinted"] { --tab-list-background: oklch(0.9 0.03 230); }
  [data-theme="brand-dark"] { color-scheme: dark; --background: oklch(0.145 0 0); --foreground: oklch(0.985 0 0); --muted: oklch(0.3 0 0); --muted-foreground: oklch(0.708 0 0); --input: oklch(1 0 0 / 15%); }
  """

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp run_in_chrome(theme) do
    assigns = %{}

    tabs =
      render(~H"""
      <.tabs id="t">
        <:tab label="Account" checked>Account panel</:tab>
        <:tab label="Password">Password panel</:tab>
      </.tabs>
      """)

    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))

    page = ~s"""
    <!doctype html>
    <html data-theme="#{theme}">
    <head><meta charset="utf-8"><style>#{css} #{@brands}</style></head>
    <body>
    #{tabs}
    <script type="module">
    const ctx = document.createElement("canvas").getContext("2d", { willReadFrequently: true })
    const paint = (color, under) => {
      ctx.clearRect(0, 0, 1, 1)
      if (under) { ctx.fillStyle = under; ctx.fillRect(0, 0, 1, 1) }
      ctx.fillStyle = color
      ctx.fillRect(0, 0, 1, 1)
      return [...ctx.getImageData(0, 0, 1, 1).data]
    }
    const lum = ([r, g, b]) => { const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b) }
    const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05) }
    const token = (css) => { const d = document.createElement("div"); d.style.color = css; document.body.append(d); const c = getComputedStyle(d).color; d.remove(); return c }
    const list = document.querySelector(".tabs-box")
    const [active, inactive] = [...list.querySelectorAll(".tab")].filter((t) => t.matches("input"))
    const row = getComputedStyle(list).backgroundColor
    const rowPx = paint(row)
    const activeFill = getComputedStyle(active).backgroundColor
    const out = {
      row: rowPx,
      muted: paint(token("var(--muted)")),
      activeOnRow: ratio(paint(activeFill, row), rowPx),
      activeBorder: getComputedStyle(active).borderTopColor,
      inactiveText: ratio(paint(getComputedStyle(inactive).color, row), rowPx),
      activeText: ratio(paint(getComputedStyle(active).color, row), paint(activeFill, row)),
      rowOnPage: ratio(rowPx, paint(token("var(--background)")))
    }
    window.__result = JSON.stringify(out)
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

    JSON.decode!(out)
  end

  test "light: the row is a step darker than muted, the white active tab stands out, text keeps 4.5:1" do
    for theme <- ["shadcn", "brand"] do
      r = run_in_chrome(theme)

      assert r["row"] == [229, 229, 229, 255], "#{theme}: row #{inspect(r["row"])}"
      assert r["row"] != r["muted"]
      assert r["activeOnRow"] >= 1.25, "#{theme}: active tab on the row #{r["activeOnRow"]}"
      assert r["inactiveText"] >= 4.5, "#{theme}: inactive text #{r["inactiveText"]}"
      assert r["activeText"] >= 4.5
      assert r["rowOnPage"] >= 1.25
    end
  end

  test "dark is unchanged: the row is muted, the active tab has its border" do
    for theme <- ["shadcn-dark", "brand-dark"] do
      r = run_in_chrome(theme)

      assert r["row"] == r["muted"],
             "#{theme}: row #{inspect(r["row"])} muted #{inspect(r["muted"])}"

      assert r["activeBorder"] != "rgba(0, 0, 0, 0)"
      assert r["inactiveText"] >= 4.5, "#{theme}: inactive text #{r["inactiveText"]}"
    end
  end

  test "a brand's own row fill wins" do
    r = run_in_chrome("tinted")
    refute r["row"] == [229, 229, 229, 255]
    refute r["row"] == r["muted"]
  end
end
