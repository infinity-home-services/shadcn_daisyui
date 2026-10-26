defmodule ShadcnDaisyui.JS.AppShellNavScrollBrowserTest do
  # The <.app_shell> sidebar's navigation (#main-nav) keeps its scroll
  # position from page to page, in headless Chrome (1280x900) with the real
  # theme CSS and JS (same harness as the other *_browser_test files). A
  # LiveView navigation replaces the whole shell: the page does what
  # LiveView's replaceMain does - an empty clone of the main element replaces
  # it, then the join patch fills it, in the same task - with each page's
  # shell in a <template>. Each check runs in the first animation frame after
  # the swap, before that frame paints; the nav asks for smooth scrolling, so
  # a position that isn't there yet would have animated. Results never cross
  # a page load through storage: the full-page-load case sets the stored
  # position before the package loads instead of reloading.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Shell

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

  # the bits of Tailwind's preflight the layout depends on, and a nav that
  # asks for smooth scrolling
  @base "*, ::before, ::after { box-sizing: border-box; } body { margin: 0; } .app-shell-nav { scroll-behavior: smooth; }"

  # five groups of seven items, p01..p35: taller than the window. In the
  # nav's content the item p<n> (group g, row k) starts at
  # 16 + g * 296 + 32 + k * 36 and is 32px tall.
  @nav for g <- 0..4,
           do: %{
             label: "Group #{g + 1}",
             items:
               for k <- 0..6 do
                 id = "p" <> String.pad_leading("#{g * 7 + k + 1}", 2, "0")
                 %{id: id, label: "Page #{id}", path: "##{id}", icon: "hero-document"}
               end
           }

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp shell(active) do
    assigns = %{nav: @nav, active: active}

    render(~H"""
    <.app_shell nav={@nav} active={@active} person={%{name: "Pat Lee", email: "pat@example.com"}}>
      <:header><.app_shell_heading icon="hero-cube" title="Acme" /></:header>
      <p>Page {@active}</p>
    </.app_shell>
    """)
  end

  defp run_in_chrome(first, pages, head, test) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))
    templates = Enum.map_join(pages, "\n", &~s(<template id="page-#{&1}">#{shell(&1)}</template>))

    html = """
    <!doctype html>
    <html data-theme="shadcn">
    <head>
    <meta charset="utf-8">
    <script>#{head}</script>
    <style>#{@base}#{css}</style>
    </head>
    <body>
    <div id="phx-main" data-phx-main>#{shell(first)}</div>
    #{templates}
    <script type="module">
    #{js}
    const $ = (id) => document.getElementById(id)
    const frame = () => new Promise((r) => requestAnimationFrame(() => r()))
    const out = {}
    // LiveView's replaceMain: the empty clone goes in, the join patch fills it
    const navigate = (id) => {
      const old = $("phx-main")
      const fresh = old.cloneNode(false)
      old.replaceWith(fresh)
      fresh.append($("page-" + id).content.cloneNode(true))
    }
    // where the nav is, and where an item sits in it (its top and bottom
    // against the nav's edges), in the frame about to paint
    const at = (id) => {
      const nav = $("main-nav")
      const n = nav.getBoundingClientRect()
      const r = $("nav-" + id).getBoundingClientRect()
      return { top: nav.scrollTop, fromTop: Math.round(r.top - n.top), toBottom: Math.round(n.bottom - r.bottom) }
    }
    // a scroll lands in its scroll event a frame or two later
    const scrolled = async (top) => { $("main-nav").scrollTo({ top, behavior: "instant" }); await frame(); await frame() }
    #{test}
    window.__result = JSON.stringify(out)
    </script>
    </body>
    </html>
    """

    dir = Path.join(System.tmp_dir!(), "sd-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    file = Path.join(dir, "page.html")
    File.write!(file, html)

    script = Path.join(@root, "test/support/chrome_eval.mjs")
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  test "a navigation keeps the nav's scroll, and shows an active item that's out of view" do
    r =
      run_in_chrome("p03", ~w(p08 p34 p01 p12 p33), "", ~S"""
      const nav = $("main-nav")
      out.first = { top: nav.scrollTop, max: nav.scrollHeight - nav.clientHeight, height: nav.clientHeight }
      await scrolled(300)
      out.stored = sessionStorage.getItem("shadcn:sidebar-scroll")

      // p08 is in view at 300: the position stays as it was
      navigate("p08")
      await frame()
      out.kept = { ...at("p08"), newNav: $("main-nav") !== nav, current: $("nav-p08").getAttribute("aria-current") }
      await frame()
      // p34 is below the fold: just enough to show it, 16px (the nav's
      // padding) clear of the bottom edge
      navigate("p34")
      await frame()
      out.below = at("p34")
      await frame(); await frame()
      // p01 is above it: just enough the other way
      navigate("p01")
      await frame()
      out.above = at("p01")
      await frame(); await frame()

      // the rail doesn't scroll; the position comes back when it expands
      await scrolled(400)
      window.dispatchEvent(new CustomEvent("shadcn:toggle-sidebar"))
      await frame(); await frame()
      out.rail = { sidebar: document.documentElement.dataset.sidebar, top: $("main-nav").scrollTop, overflow: getComputedStyle($("main-nav")).overflowY }
      // a page change in the rail, then Cmd/Ctrl+B expands it: p12 is in view at 400
      navigate("p12")
      await frame(); await frame()
      document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "b", metaKey: true, bubbles: true, cancelable: true }))
      out.expanded = { sidebar: document.documentElement.dataset.sidebar, ...at("p12") }
      await frame()
      out.expandedFrame = at("p12")
      // collapsed again, a page whose item is out of view at 400: expanding shows it
      window.dispatchEvent(new CustomEvent("shadcn:toggle-sidebar"))
      navigate("p33")
      await frame(); await frame()
      window.dispatchEvent(new CustomEvent("shadcn:toggle-sidebar"))
      await frame()
      out.expandedReveal = at("p33")
      out.storedAfter = sessionStorage.getItem("shadcn:sidebar-scroll")
      """)

    msg = inspect(r, pretty: true)
    # taller than the window: the nav scrolls
    assert r["first"]["top"] == 0, msg
    assert r["first"]["max"] > 600, msg
    assert r["stored"] == "300", msg

    assert r["kept"] == %{
             "top" => 300,
             "fromTop" => 344 - 300,
             "toBottom" => r["first"]["height"] - (344 - 300) - 32,
             "newNav" => true,
             "current" => "page"
           },
           msg

    # p34 (group 4, row 5) ends at 1444 in the nav's content
    assert r["below"]["toBottom"] == 16, msg
    assert r["below"]["top"] == 1444 + 16 - r["first"]["height"], msg
    assert r["below"]["top"] < r["first"]["max"], msg
    # p01 starts at 48
    assert r["above"]["top"] == 32 and r["above"]["fromTop"] == 16, msg

    assert r["rail"] == %{"sidebar" => "collapsed", "top" => 0, "overflow" => "visible"}, msg
    # p12 (group 1, row 4) starts at 488
    assert r["expanded"]["sidebar"] == "open", msg
    assert r["expanded"]["top"] == 400 and r["expanded"]["fromTop"] == 88, msg
    assert r["expandedFrame"]["top"] == 400, msg
    # p33 (group 4, row 4) ends at 1408
    assert r["expandedReveal"]["toBottom"] == 16, msg
    assert r["expandedReveal"]["top"] == 1408 + 16 - r["first"]["height"], msg
    assert r["storedAfter"] == "#{r["expandedReveal"]["top"]}", msg
  end

  test "a full page load in the same tab gets the stored position back as the package loads" do
    r =
      run_in_chrome(
        "p08",
        [],
        ~s|sessionStorage.setItem("shadcn:sidebar-scroll", "300")|,
        ~S"""
        // read as soon as the package has run, before the first frame
        out.atLoad = at("p08")
        """
      )

    assert r["atLoad"]["top"] == 300
    assert r["atLoad"]["fromTop"] == 44
  end

  test "a first page load shows the active item when it's below the fold" do
    r = run_in_chrome("p34", [], "", ~S|out.atLoad = at("p34")|)

    assert r["atLoad"]["toBottom"] == 16
    assert r["atLoad"]["top"] > 0
  end
end
