defmodule ShadcnDaisyui.JS.SignInBrowserTest do
  # The sign-in page in headless Chrome with the real theme CSS and
  # shadcn-daisyui.js (same harness as sheet_sections_browser_test.exs). Each
  # size is an iframe of that width, so the page's media queries see it:
  # phones edge to edge, tablets a card (on the picture when there is one),
  # desktops the panel and the form. And the development sign-in's sections
  # stay hidden across a reload once hidden.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.SignIn, only: [sign_in_page: 1]

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

  # a 1x1 picture, so nothing is fetched
  @pixel "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="

  defp markup(image) do
    assigns = %{image: image}

    render(~H"""
    <.sign_in_page app_name="Acme" org="Acme Inc." tagline="Orders in one place." href="#" image={@image}>
      <:development label="Sign in as a role"><button id="role">Admin</button></:development>
      <:development label="Sign in as someone already here"><button id="person">Pat</button></:development>
    </.sign_in_page>
    """)
  end

  # a JS string literal that can sit inside this <script> (no "</script>" in it)
  defp js_string(html), do: html |> JSON.encode!() |> String.replace("</", "<\\/")

  # the page one iframe shows: the theme, the markup, the package's JS
  defp frame(markup, css, js, extra_css \\ "") do
    """
    <!doctype html><html data-theme="shadcn"><head><meta charset="utf-8">
    <style>#{css} body { margin: 0 } #{extra_css}</style></head><body>#{markup}
    <script type="module">#{js}</script></body></html>
    """
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))
    plain = frame(markup(nil), css, js)
    pictured = frame(markup(@pixel), css, js)
    # a brand theme's accent
    accent = ".sign-in { --sign-in-accent: rgb(44, 178, 223) }"
    accented = frame(markup(@pixel), css, js, accent)
    accented_plain = frame(markup(nil), css, js, accent)
    # a brand scope's primary (data-brand), and a brand's app icon colour
    branded = frame(markup(nil), css, js, ".sign-in { --primary: rgb(44, 178, 223) }")
    iconed = frame(markup(nil), css, js, ":root { --app-icon: rgb(1, 2, 3) }")

    page = """
    <!doctype html>
    <html><head><meta charset="utf-8"></head>
    <body>
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    const docs = {
      plain: #{js_string(plain)}, pictured: #{js_string(pictured)},
      accented: #{js_string(accented)}, accentedPlain: #{js_string(accented_plain)},
      branded: #{js_string(branded)}, iconed: #{js_string(iconed)}
    }
    const wait = (ms) => new Promise((r) => setTimeout(r, ms))
    const load = (doc, w, h) => new Promise((resolve) => {
      const f = document.createElement("iframe")
      f.style.cssText = `width:${w}px;height:${h}px;border:0;display:block`
      f.addEventListener("load", () => resolve(f), { once: true })
      f.srcdoc = docs[doc]
      document.body.appendChild(f)
    })
    const reload = (f, doc) => new Promise((resolve) => {
      f.addEventListener("load", () => resolve(f), { once: true })
      f.srcdoc = docs[doc] + "<!-- again -->"
    })
    const look = (f) => {
      const d = f.contentDocument, w = f.contentWindow
      const cs = (sel) => w.getComputedStyle(d.querySelector(sel))
      const box = (sel) => d.querySelector(sel).getBoundingClientRect()
      return {
        aside: cs(".sign-in-aside").display,
        asidePosition: cs(".sign-in-aside").position,
        asideWidth: Math.round(box(".sign-in-aside").width),
        asideContent: cs(".sign-in-aside-content").display,
        panelBorder: cs(".sign-in-panel").borderTopWidth,
        panelWidth: Math.round(box(".sign-in-panel").width),
        pageWidth: d.documentElement.clientWidth,
        headerMark: cs(".sign-in-header > .sign-in-mark").display,
        footerOrg: cs(".sign-in-footer-org").display,
        button: Math.round(box("#sign-in-microsoft").height),
        nameFill: cs(".sign-in-app-name").color,
        nameGradient: cs(".sign-in-app-name").backgroundImage,
        buttonFill: cs("#sign-in-microsoft").backgroundColor,
        buttonText: cs("#sign-in-microsoft").color,
        pageText: cs(".sign-in-main").color,
        tileFill: cs(".sign-in-header > .sign-in-mark").backgroundColor,
        finePointer: w.matchMedia("(pointer: fine)").matches,
      }
    }
    const out = {}
    try { localStorage.removeItem("shadcn:sign-in-hidden") } catch (_e) {}

    out.phone = look(await load("plain", 390, 844))
    out.tablet = look(await load("plain", 820, 1180))
    out.tabletPictured = look(await load("pictured", 820, 1180))
    out.desktop = look(await load("pictured", 1440, 900))
    out.accented = look(await load("accented", 1440, 900))
    out.accentedPlain = look(await load("accentedPlain", 1440, 900))
    out.branded = look(await load("branded", 390, 844))
    out.iconed = look(await load("iconed", 390, 844))

    // hide a section, then the page loads again: still hidden, the rest open
    const f = await load("plain", 390, 844)
    const section = (k) => f.contentDocument.querySelector(`[data-sign-in-section="${k}"]`)
    section("sign-in-as-a-role").open = false
    await wait(50)
    out.storedAfterHide = localStorage.getItem("shadcn:sign-in-hidden")
    await reload(f, "plain")
    await wait(50)
    out.afterReload = {
      role: section("sign-in-as-a-role").open,
      person: section("sign-in-as-someone-already-here").open,
      development: section("development").open,
    }
    // shown again: forgotten
    section("sign-in-as-a-role").open = true
    await wait(50)
    out.storedAfterShow = localStorage.getItem("shadcn:sign-in-hidden")

    out.errors = errors
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
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  test "one page at three sizes, and hidden development sections stay hidden" do
    r = run_in_chrome()

    assert r["errors"] == []

    # phone: no panel, no card, the mark over the title, a 44px button
    assert r["phone"]["aside"] == "none"
    assert r["phone"]["panelBorder"] == "0px"
    assert r["phone"]["headerMark"] == "grid"
    assert r["phone"]["footerOrg"] != "none"
    assert r["phone"]["button"] == 44
    # edge to edge inside the 16px gutters
    assert r["phone"]["panelWidth"] == r["phone"]["pageWidth"] - 32

    # tablet: the form in a 28rem card; with a picture, the picture fills the page behind it
    assert r["tablet"]["aside"] == "none"
    assert r["tablet"]["panelBorder"] == "1px"
    assert r["tablet"]["panelWidth"] == 448
    assert r["tablet"]["button"] == 44
    assert r["tabletPictured"]["aside"] == "block"
    assert r["tabletPictured"]["asidePosition"] == "fixed"
    assert r["tabletPictured"]["asideContent"] == "none"

    # desktop: the panel is half the window, the form plain beside it
    assert r["desktop"]["aside"] == "flex"
    assert r["desktop"]["asideWidth"] == 720
    assert r["desktop"]["asideContent"] == "flex"
    assert r["desktop"]["panelBorder"] == "0px"
    assert r["desktop"]["headerMark"] == "none"
    assert r["desktop"]["footerOrg"] == "none"
    assert r["desktop"]["nameFill"] == "rgba(0, 0, 0, 0)"
    assert r["desktop"]["button"] == if(r["desktop"]["finePointer"], do: 40, else: 44)

    # the application's name takes the theme's accent over the picture, and
    # only there (without one the panel is the brand colour itself)
    assert r["accented"]["nameGradient"] =~ "rgb(44, 178, 223)"
    refute r["desktop"]["nameGradient"] =~ "rgb(44, 178, 223)"
    refute r["accentedPlain"]["nameGradient"] =~ "rgb(44, 178, 223)"

    # Sign in with Microsoft is neutral whatever the brand: the page's text
    # colour with the page colour on it; the brand colours the app's icon
    assert r["phone"]["buttonFill"] == r["phone"]["pageText"]
    assert r["branded"]["buttonFill"] == r["branded"]["pageText"]
    refute r["branded"]["buttonFill"] == "rgb(44, 178, 223)"
    assert r["branded"]["tileFill"] == "rgb(44, 178, 223)"
    assert r["iconed"]["tileFill"] == "rgb(1, 2, 3)"

    # remembered in this browser
    assert r["storedAfterHide"] == ~s(["sign-in-as-a-role"])

    assert r["afterReload"] == %{"role" => false, "person" => true, "development" => true}
    assert r["storedAfterShow"] == "[]"
  end
end
