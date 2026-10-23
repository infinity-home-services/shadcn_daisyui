defmodule ShadcnDaisyui.JS.AppShellBrowserTest do
  # <.app_shell>, <.page_header> and the <.command> palette in headless Chrome
  # with the real theme CSS and JS (same harness as the other *_browser_test
  # files; no Tailwind or daisyUI, so only the package's own rules apply).
  # LiveView's JS.dispatch fires its event on the clicked element, bubbling;
  # the pages do the same. A page that navigates (Enter in the palette, Esc
  # back, a reload) hands its results to the next page through sessionStorage.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Shell
  import ShadcnDaisyui.Components.Overlay, only: [command: 1]
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1, sticky_top: 1]

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

  # the documented pre-paint line (mix shadcn_daisyui.install writes it)
  @prepaint ~s|document.documentElement.dataset.sidebar = localStorage.getItem("shadcn:sidebar") === "collapsed" ? "collapsed" : "open"|

  # the bits of Tailwind's preflight the layout depends on
  @preflight "*, ::before, ::after { box-sizing: border-box; } body { margin: 0; }"

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  @nav [
    %{
      label: nil,
      items: [%{id: "home", label: "Home", path: "target.html#home", icon: "hero-home"}]
    },
    %{
      label: "Sales",
      items: [
        %{id: "orders", label: "Orders", path: "target.html#orders", icon: "hero-shopping-cart"},
        %{id: "customers", label: "Customers", path: "target.html#customers", icon: "hero-users"}
      ]
    }
  ]

  defp shell(inner) do
    assigns = %{nav: @nav, inner: inner}

    render(~H"""
    <.app_shell nav={@nav} active="orders" search="search" person={%{name: "Pat Lee", email: "pat@example.com"}}>
      <:header><.app_shell_heading icon="hero-cube" title="Acme" /></:header>
      <:account_item id="sign-out" href="target.html#out" destructive divider>Sign out</:account_item>
      {Phoenix.HTML.raw(@inner)}
    </.app_shell>
    """)
  end

  defp search do
    assigns = %{nav: @nav}

    render(~H"""
    <.command id="search" label="Search" placeholder="Search pages">
      <:item
        :for={item <- Enum.flat_map(@nav, & &1.items)}
        id={"search-" <> item.id}
        group="Pages"
        navigate={item.path}
      >
        {item.label}
      </:item>
      <:item id="search-team" group="Teams" form="team-form" name="team" value="ops">Operations</:item>
    </.command>
    <.command id="switcher" label="Switch" shortcut={nil}><:item>Acme</:item></.command>
    <.command id="jumper" label="Jump" shortcut="j"><:item>Somewhere</:item></.command>
    """)
  end

  defp page(body, test) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    """
    <!doctype html>
    <html data-theme="shadcn">
    <head>
    <meta charset="utf-8">
    <script>#{@prepaint}</script>
    <style>#{@preflight}#{css} .hidden { display: none; }</style>
    </head>
    <body>
    <script>window.__atParse = document.documentElement.dataset.sidebar</script>
    #{body}
    <script type="module">
    #{js}
    const wait = (ms) => new Promise((r) => setTimeout(r, ms))
    const key = (target, init) => {
      const e = new KeyboardEvent("keydown", { bubbles: true, cancelable: true, ...init })
      target.dispatchEvent(e)
      return e.defaultPrevented
    }
    const out = JSON.parse(sessionStorage.getItem("out") || "{}")
    const save = () => sessionStorage.setItem("out", JSON.stringify(out))
    #{test}
    </script>
    </body>
    </html>
    """
  end

  # target.html: where links land; reports what the page before it saved
  @target """
  <!doctype html>
  <html><head><meta charset="utf-8"></head><body>
  <script>
  window.__result = JSON.stringify({ ...JSON.parse(sessionStorage.getItem("out") || "{}"), landed: location.hash })
  </script>
  </body></html>
  """

  defp run_in_chrome(html) do
    dir = Path.join(System.tmp_dir!(), "sd-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    file = Path.join(dir, "page.html")
    File.write!(file, html)
    File.write!(Path.join(dir, "target.html"), @target)

    script = Path.join(@root, "test/support/chrome_eval.mjs")
    profile = Path.join(dir, "profile")

    {out, 0} =
      ShadcnDaisyui.ChromeSlots.run(fn -> System.cmd(@node, [script, @chrome, file, profile]) end)

    JSON.decode!(out)
  end

  test "the sidebar collapses to the rail, is remembered across a reload, and Cmd/Ctrl+B toggles it" do
    body = shell(~s(<input id="field">))

    r =
      run_in_chrome(
        page(body, ~S"""
        initShadcnDaisyui()
        const root = document.documentElement
        const sidebar = document.getElementById("sidebar")
        const width = () => Math.round(sidebar.getBoundingClientRect().width)
        const label = () => getComputedStyle(document.querySelector("#nav-orders .app-shell-label")).display
        if (!sessionStorage.getItem("reloaded")) {
          out.first = { atParse: window.__atParse, width: width(), label: label(), stored: localStorage.getItem("shadcn:sidebar") }
          // the "Collapse sidebar" row: phx-click={JS.dispatch("shadcn:toggle-sidebar")}
          document.getElementById("sidebar-toggle").dispatchEvent(new CustomEvent("shadcn:toggle-sidebar", { bubbles: true }))
          await wait(400)
          out.collapsed = { attr: root.dataset.sidebar, width: width(), label: label(), stored: localStorage.getItem("shadcn:sidebar") }
          sessionStorage.setItem("reloaded", "1")
          save()
          location.reload()
        } else {
          // set before the body parsed, so the first paint is already the rail
          out.reloaded = { atParse: window.__atParse, width: width(), label: label() }
          out.cmdB = { prevented: key(document.body, { key: "b", metaKey: true }), attr: root.dataset.sidebar }
          out.ctrlB = { prevented: key(document.body, { key: "b", ctrlKey: true }), attr: root.dataset.sidebar }
          out.inField = { prevented: key(document.getElementById("field"), { key: "b", metaKey: true }), attr: root.dataset.sidebar }
          out.plainB = { prevented: key(document.body, { key: "b" }), attr: root.dataset.sidebar }
          out.stored = localStorage.getItem("shadcn:sidebar")
          window.__result = JSON.stringify(out)
        }
        """)
      )

    assert r["first"] == %{
             "atParse" => "open",
             "width" => 256,
             "label" => "block",
             "stored" => nil
           }

    assert r["collapsed"] == %{
             "attr" => "collapsed",
             "width" => 48,
             "label" => "none",
             "stored" => "collapsed"
           }

    assert r["reloaded"] == %{"atParse" => "collapsed", "width" => 48, "label" => "none"}
    assert r["cmdB"] == %{"prevented" => true, "attr" => "open"}
    assert r["ctrlB"] == %{"prevented" => true, "attr" => "collapsed"}
    # typing in a field (Cmd+B is bold there) and a plain B do nothing
    assert r["inField"] == %{"prevented" => false, "attr" => "collapsed"}
    assert r["plainB"] == %{"prevented" => false, "attr" => "collapsed"}
    assert r["stored"] == "collapsed"
  end

  test "Cmd/Ctrl+K opens the search, which filters, and Enter navigates" do
    # a second ⌘K palette earlier on the page: the last one opens, and ⌘K closes it again
    assigns = %{}
    early = render(~H|<.command id="early" label="Early"><:item>Early</:item></.command>|)

    body =
      shell("") <>
        early <> search() <> ~s(<dialog id="other">Other</dialog><form id="team-form"></form>)

    r =
      run_in_chrome(
        page(body, ~S"""
        // LiveView mounts each palette through the hook
        const hooks = [...document.querySelectorAll("[data-command]")].map((el) => {
          const ctx = { el }
          Hooks.ShadcnCommand.mounted.call(ctx)
          return ctx
        })
        const search = document.getElementById("search")
        const input = document.getElementById("search-search")
        const shown = () => [...search.querySelectorAll("[data-command-item]")]
          .filter((i) => !i.parentElement.classList.contains("hidden")).map((i) => i.id)
        const type = (q) => { input.value = q; input.dispatchEvent(new Event("input", { bubbles: true })) }
        const selected = () => { const el = search.querySelector('[aria-selected="true"]'); return el && el.id }

        out.prevented = key(document.body, { key: "k", metaKey: true })
        out.opened = search.open
        out.focused = document.activeElement === input
        out.switcherOpen = document.getElementById("switcher").open
        out.earlyOpen = document.getElementById("early").open
        key(document.body, { key: "k", metaKey: true })
        out.secondCmdKCloses = !search.open
        // Ctrl+K, with another dialog open: that one closes first
        document.getElementById("other").showModal()
        key(document.body, { key: "k", ctrlKey: true })
        out.ctrlK = { opened: search.open, otherClosed: !document.getElementById("other").open }
        out.all = shown()
        type("cust")
        out.filtered = { shown: shown(), groups: [...search.querySelectorAll("[data-group]")]
          .filter((g) => !g.classList.contains("hidden")).map((g) => g.textContent.trim()), selected: selected() }
        type("zzz")
        out.empty = !search.querySelector("[data-command-empty]").classList.contains("hidden")
        type("o")
        key(input, { key: "ArrowDown" })
        out.arrow = { shown: shown(), selected: selected() }
        search.close()
        // a palette with no shortcut never opens from the keyboard; ⌘J opens "jumper"
        key(document.body, { key: "j", metaKey: true })
        out.jumper = document.getElementById("jumper").open
        document.getElementById("jumper").close()
        // LiveView navigation destroys the hook: the key listener goes with it
        hooks.find((h) => h.el.id === "jumper").el.remove()
        Hooks.ShadcnCommand.destroyed.call(hooks.find((h) => h.el.id === "jumper"))
        out.jumperAfterDestroy = key(document.body, { key: "j", metaKey: true })
        out.switcherNeverOpened = !document.getElementById("switcher").open && !document.getElementById("early").open
        // the search buttons: JS.dispatch("shadcn:show-dialog", to: "#search")
        search.dispatchEvent(new CustomEvent("shadcn:show-dialog", { bubbles: true }))
        out.showDialog = search.open && document.activeElement === input
        type("cust")
        save()
        key(input, { key: "Enter" })
        """)
      )

    assert r["prevented"] == true
    assert r["opened"] == true
    assert r["focused"] == true
    assert r["switcherOpen"] == false
    assert r["earlyOpen"] == false
    assert r["secondCmdKCloses"] == true
    assert r["ctrlK"] == %{"opened" => true, "otherClosed" => true}
    assert r["all"] == ~w(search-home search-orders search-customers search-team)

    assert r["filtered"] == %{
             "shown" => ["search-customers"],
             "groups" => ["Pages"],
             "selected" => "search-customers"
           }

    assert r["empty"] == true
    # "o": Home, Orders, Customers, Operations; ArrowDown moves to the second
    assert r["arrow"] == %{
             "shown" => ~w(search-home search-orders search-customers search-team),
             "selected" => "search-orders"
           }

    assert r["jumper"] == true
    assert r["jumperAfterDestroy"] == false
    assert r["switcherNeverOpened"] == true
    assert r["showDialog"] == true
    # Enter clicked the selected item, a navigate link
    assert r["landed"] == "#customers"
  end

  test "the page header pins and gets data-stuck once #main scrolls; Esc goes back" do
    assigns = %{
      crumbs: [
        %{label: "Sales"},
        %{label: "Orders", path: "target.html#orders"},
        %{label: "#1042"}
      ]
    }

    header =
      render(~H"""
      <.page_header crumbs={@crumbs}>#1042</.page_header>
      <div style="height: 3000px">Long page</div>
      """)

    body =
      shell(header <> ~s(<input id="field">)) <>
        ~s(<dialog id="plain" class="modal"><div class="modal-box">Hi</div></dialog>) <>
        ~s(<dialog id="panel" class="sheet">Sheet</dialog>)

    r =
      run_in_chrome(
        page(body, ~S"""
        initShadcnDaisyui()
        const main = document.getElementById("main")
        const header = document.getElementById("page-header")
        const plain = document.getElementById("plain")
        const panel = document.getElementById("panel")
        const back = document.getElementById("page-header-back")
        let allowBack = false, backClicks = 0
        back.addEventListener("click", (e) => { backClicks++; if (!allowBack) e.preventDefault() })

        out.atTop = { stuck: header.hasAttribute("data-stuck"), top: Math.round(header.getBoundingClientRect().top) }
        main.scrollTop = 400
        await wait(100)
        out.scrolled = { stuck: header.hasAttribute("data-stuck"), top: Math.round(header.getBoundingClientRect().top),
          border: getComputedStyle(header).borderBottomColor !== "rgba(0, 0, 0, 0)" }
        main.scrollTop = 0
        await wait(100)
        out.backAtTop = !header.hasAttribute("data-stuck")

        // Esc stays put while a dialog is open, in a field, or with a modifier
        plain.showModal()
        key(document.body, { key: "Escape" })
        plain.close()
        key(document.getElementById("field"), { key: "Escape" })
        key(document.body, { key: "Escape", metaKey: true })
        out.blockedBackClicks = backClicks

        // open dialogs close when LiveView starts navigating to another page -
        // not on a reconnect, a rejoin, a patch or phx-page-loading
        plain.showModal(); panel.showModal()
        for (const kind of ["error", "initial", "patch", "element"])
          window.dispatchEvent(new CustomEvent("phx:page-loading-start", { detail: { kind } }))
        out.keptOpen = plain.open && panel.open
        window.dispatchEvent(new CustomEvent("phx:page-loading-start", { detail: { kind: "redirect" } }))
        out.closedOnNavigation = !plain.open && !panel.open
        // a plain dialog closes on a backdrop click (on the dialog, outside its box), not inside it
        plain.showModal()
        plain.querySelector(".modal-box").dispatchEvent(new MouseEvent("click", { bubbles: true, detail: 1 }))
        out.boxClickKeepsOpen = plain.open
        plain.dispatchEvent(new MouseEvent("click", { bubbles: true, detail: 1, clientX: 2, clientY: 2 }))
        out.backdropCloses = !plain.open

        allowBack = true
        save()
        key(document.body, { key: "Escape" })
        """)
      )

    # at the top of #main, over its 24px top padding; pinned there while it scrolls, with a line under it
    assert r["atTop"] == %{"stuck" => false, "top" => 0}
    assert r["scrolled"] == %{"stuck" => true, "top" => 0, "border" => true}
    assert r["backAtTop"] == true
    assert r["blockedBackClicks"] == 0
    assert r["keptOpen"] == true
    assert r["closedOnNavigation"] == true
    assert r["boxClickKeepsOpen"] == true
    assert r["backdropCloses"] == true
    assert r["landed"] == "#orders"
  end

  test "outside the shell a sticky top follows the document's scroll" do
    assigns = %{}

    body =
      render(~H"""
      <.sticky_top id="toolbar">Tools</.sticky_top>
      <div style="height: 3000px">Long page</div>
      """)

    r =
      run_in_chrome(
        page(body, ~S"""
        initShadcnDaisyui()
        const bar = document.getElementById("toolbar")
        out.before = bar.hasAttribute("data-stuck")
        window.scrollTo(0, 300)
        await wait(100)
        out.after = bar.hasAttribute("data-stuck")
        window.__result = JSON.stringify(out)
        """)
      )

    assert r == %{"before" => false, "after" => true}
  end

  test "on a phone: no sidebar; the pinned top row, the dock and the page header below the row" do
    assigns = %{}

    header =
      render(~H"""
      <.page_header crumbs={[%{label: "Orders", path: "#"}, %{label: "#1042"}]}>#1042</.page_header>
      <div style="height: 3000px">Long page</div>
      """)

    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    # a 375px-wide iframe is a phone-sized viewport for the media queries
    phone =
      ~s(<!doctype html><html data-theme="shadcn"><head><meta charset="utf-8"><style>#{@preflight}#{css}</style></head><body>) <>
        shell(header) <> "</body></html>"

    body =
      ~s(<iframe id="phone" style="width: 375px; height: 700px; border: 0" srcdoc="#{phone |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()}"></iframe>)

    r =
      run_in_chrome(
        page(body, ~S"""
        const frame = document.getElementById("phone")
        await new Promise((r) => { const ready = () => frame.contentDocument && frame.contentDocument.getElementById("main") ? r() : setTimeout(ready, 20); ready() })
        const d = frame.contentDocument
        const display = (id) => getComputedStyle(d.getElementById(id)).display
        const top = (id) => Math.round(d.getElementById(id).getBoundingClientRect().top)
        out.display = { sidebar: display("sidebar"), phoneHeader: display("phone-header"), crumbs: display("page-header-crumbs") }
        d.getElementById("main").scrollTop = 600
        await wait(100)
        // the top row pinned at the very top (72px tall), the page header right under it
        out.pinned = { phoneHeader: top("phone-header"), pageHeader: top("page-header") }
        window.__result = JSON.stringify(out)
        """)
      )

    assert r["display"] == %{"sidebar" => "none", "phoneHeader" => "flex", "crumbs" => "none"}
    assert r["pinned"] == %{"phoneHeader" => 0, "pageHeader" => 72}
  end
end
