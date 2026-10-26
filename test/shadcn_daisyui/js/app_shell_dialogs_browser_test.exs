defmodule ShadcnDaisyui.JS.AppShellDialogsBrowserTest do
  # Dialogs that are direct children of an <.app_shell> page, in headless
  # Chrome (1280x900) with the real theme CSS and JS (same harness as the
  # other *_browser_test files). The page keeps its children to a 48rem
  # reading width; a <dialog> (dialog, alert dialog, sheet, drawer, command)
  # must not get it: open, each sizes and places itself against the window
  # as it does outside the shell, and closed it adds no gap. The cascade is
  # Tailwind's: the layer order is declared first, and daisyUI's .modal
  # geometry stands in at the lowest layer, so only the theme's own rules
  # decide whether the reading width reaches a modal.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Shell
  import ShadcnDaisyui.Components.Overlay
  import ShadcnDaisyui.CoreComponents, only: [page_header: 1]

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

  # Tailwind's layer order, the bits of preflight the layout depends on, and
  # daisyUI's .modal geometry: a full-window grid that centres its box, there
  # (fixed, hidden) even while closed
  @base """
  @layer theme, base, components, utilities;
  *, ::before, ::after { box-sizing: border-box; } body { margin: 0; }
  @layer components {
    .modal { position: fixed; inset: 0; margin: 0; padding: 0; border: 0; display: grid;
      place-items: center; width: 100%; max-width: none; height: 100%; max-height: none;
      visibility: hidden; pointer-events: none; }
    .modal[open] { visibility: visible; pointer-events: auto; }
  }
  """

  @nav [
    %{
      label: nil,
      items: [%{id: "orders", label: "Orders", path: "#orders", icon: "hero-shopping-cart"}]
    }
  ]

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp shell(opts) do
    assigns = %{nav: @nav, wide: opts[:wide] || false, fill: opts[:fill] || false}

    render(~H"""
    <.app_shell nav={@nav} active="orders" wide={@wide} fill={@fill} person={%{name: "Pat Lee", email: "pat@example.com"}}>
      <.page_header>Orders</.page_header>
      <div id="before">Before the dialogs</div>
      <.dialog id="d" show on_close="close">
        <:title>Server dialog</:title>
        Opened on mount, straight inside the page.
      </.dialog>
      <.alert_dialog id="a">
        <:title>Discard changes?</:title>
        <:action variant="destructive">Discard</:action>
      </.alert_dialog>
      <.sheet id="s"><:title>Filters</:title>Body</.sheet>
      <.drawer id="r"><:title>Move goal</:title>Body</.drawer>
      <.command id="c" label="Jump" shortcut={nil}><:item>One</:item></.command>
      <div id="after">After the dialogs</div>
    </.app_shell>
    """)
  end

  defp run_in_chrome(opts) do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{@base}#{css}</style></head>
    <body>
    #{shell(opts)}
    <script type="module">
    #{js}
    const $ = (id) => document.getElementById(id)
    const frame = () => new Promise((r) => requestAnimationFrame(() => r()))
    // wait out the running enter/exit transitions
    const settle = async () => {
      await frame()
      await Promise.all(document.getAnimations()
        .filter((a) => a.timeline === document.timeline && a.effect && a.effect.getComputedTiming().endTime !== Infinity)
        .map((a) => a.finished.catch(() => {})))
      await frame()
    }
    const box = (el) => {
      const r = el.getBoundingClientRect()
      return { left: Math.round(r.left), right: Math.round(r.right), width: Math.round(r.width), top: Math.round(r.top), bottom: Math.round(r.bottom) }
    }
    const gap = () => Math.round($("after").getBoundingClientRect().top - $("before").getBoundingClientRect().bottom)
    const measure = (d) => ({ box: box(d), maxWidth: getComputedStyle(d).maxWidth, modal: d.matches(":modal") })

    const r = { window: { width: document.documentElement.clientWidth, height: document.documentElement.clientHeight } }
    await settle()
    // `show`: open on load, as the reported page had it
    r.d = { open: $("d").open, ...measure($("d")), box_inside: box($("d").querySelector(".modal-box")) }
    r.gap_open = gap()
    $("d").close()
    await settle()
    r.gap_closed = gap()
    r.before_width = Math.round($("before").getBoundingClientRect().width)

    for (const id of ["a", "s", "r", "c"]) {
      $(id).showModal()
      await settle()
      r[id] = measure($(id))
      if (id === "a") r.a.box_inside = box($(id).querySelector(".modal-box"))
      $(id).close()
      await settle()
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

  defp assert_window_dialogs(r) do
    w = r["window"]["width"]
    msg = inspect(r, pretty: true)

    # a modal opened from the page spans the window, its box centred
    assert r["d"]["open"], msg

    for id <- ~w(d a) do
      assert r[id]["modal"], msg
      assert r[id]["maxWidth"] != "768px", msg
      assert r[id]["box"]["left"] == 0 and r[id]["box"]["width"] == w, msg
      inside = r[id]["box_inside"]
      assert_in_delta (inside["left"] + inside["right"]) / 2, w / 2, 1, msg
    end

    # the sheet keeps its own 24rem at the window's right edge
    assert r["s"]["box"]["width"] == 384, msg
    assert r["s"]["box"]["right"] == w, msg
    # the drawer spans the window's width; the command palette is 40rem, centred
    assert r["r"]["box"]["left"] == 0 and r["r"]["box"]["width"] == w, msg
    assert r["c"]["box"]["width"] == 640, msg
    assert_in_delta (r["c"]["box"]["left"] + r["c"]["box"]["right"]) / 2, w / 2, 1, msg

    # open or closed, the dialogs between two paragraphs add no gap: one 16px
    assert r["gap_open"] == 16, msg
    assert r["gap_closed"] == 16, msg
  end

  test "a page with the reading width: its dialogs still open over the whole window" do
    r = run_in_chrome([])

    # the reading width still applies to the page's other children
    assert r["before_width"] == 768
    assert_window_dialogs(r)
  end

  test "a wide page" do
    r = run_in_chrome(wide: true)

    assert r["before_width"] > 768
    assert_window_dialogs(r)
  end

  test "a fill page" do
    r = run_in_chrome(wide: true, fill: true)

    assert_window_dialogs(r)
  end

  test "a fill page with the reading width" do
    r = run_in_chrome(fill: true)

    assert r["before_width"] == 768
    assert_window_dialogs(r)
  end
end
