defmodule ShadcnDaisyui.JS.SonnerBrowserTest do
  # The toast as a port of svelte-sonner, in headless Chrome with the real
  # shadcn-daisyui.js and .css (same harness as toast_layer_browser_test.exs):
  # sonner's metrics and colours, the stack, merged updates, promise toasts,
  # which actions call onDismiss, directional swipe, the light/dark sonner
  # theme following the page, named toasters, headless toasts, icon slots and
  # the Alt+T hotkey.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Display, only: [toaster: 1]

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

  defp markup do
    assigns = %{}

    render(~H"""
    <.toaster duration={60000}>
      <:info_icon><span id="my-info-icon">i</span></:info_icon>
    </.toaster>
    <.toaster id="side-toaster" toaster_id="side" position="top-left" theme="dark" />
    <input id="field" />
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css}</style></head>
    <body>
    #{markup()}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    #{js}
    const wait = (ms) => new Promise((r) => setTimeout(r, ms))
    const until = async (ok, ms = 5000) => {
      const end = performance.now() + ms
      while (!ok()) { if (performance.now() > end) return false; await wait(16) }
      return true
    }
    const css = (el, p) => getComputedStyle(el).getPropertyValue(p)
    const byId = (id) => [...document.querySelectorAll("[data-sonner-toast]")].find((li) => li.querySelector("[data-title]")?.textContent === id)
    const clear = async () => { toast.dismiss(); await until(() => !document.querySelector("[data-sonner-toast]")) }
    const out = {}

    // sonner's look: 8px corners, #3f3f3f description, inverted 4px action,
    // close button over the top start corner
    toast("Event has been created", { description: "Sunday", action: { label: "Undo" }, closeButton: true })
    await until(() => byId("Event has been created")?.dataset.mounted === "true")
    let li = byId("Event has been created")
    const desc = li.querySelector("[data-description]")
    const action = li.querySelector("[data-button]")
    const close = li.querySelector("[data-close-button]")
    out.look = {
      radius: css(li, "border-radius"),
      padding: css(li, "padding"),
      fontSize: css(li, "font-size"),
      description: css(desc, "color"),
      actionBg: css(action, "background-color"),
      actionFg: css(action, "color"),
      toastFg: css(li, "color"),
      toastBg: css(li, "background-color"),
      actionRadius: css(action, "border-radius"),
      closeAtStart: close.getBoundingClientRect().left < li.getBoundingClientRect().left,
      width: li.getBoundingClientRect().width,
    }
    await clear()

    // the stack: newest in front, the one behind 5% smaller, 4th hidden
    for (const t of ["one", "two", "three", "four"]) toast(t)
    await until(() => byId("four")?.dataset.mounted === "true")
    await wait(450)
    out.stack = ["four", "three", "two", "one"].map((t) => [byId(t).dataset.front, byId(t).dataset.visible])
    out.behindScale = new DOMMatrix(css(byId("three"), "transform")).a
    out.tabOrder = [...document.querySelectorAll("[data-sonner-toaster]:not([data-toaster-id]) [data-sonner-toast]")].map((l) => l.querySelector("[data-title]").textContent)
    await clear()

    // an update merges: what isn't passed is kept
    toast("Draft", { id: "m", description: "kept" })
    toast.success("Saved", { id: "m" })
    li = byId("Saved")
    out.merged = [li.dataset.type, li.querySelector("[data-description]")?.textContent, document.querySelectorAll("[data-sonner-toast]").length]
    await clear()

    // promise: spinner, then the result scales in as the spinner fades out
    let settle
    const pid = toast.promise(new Promise((r) => (settle = r)), { loading: "Saving", success: (d) => d.name + " saved" })
    li = byId("Saving")
    out.promiseLoading = [li.dataset.type, li.dataset.promise, !!li.querySelector(".sonner-loader[data-visible=true] [data-sonner-spin]")]
    settle({ name: "Report" })
    await until(() => byId("Report saved"))
    li = byId("Report saved")
    out.promiseDone = [li.dataset.type, !!li.querySelector(".sonner-loader[data-visible=false]"), css(li.querySelector("[data-icon] > svg"), "animation-name"), pid]
    // a fetch Response that isn't ok is an error
    toast.promise(Promise.resolve({ ok: false, status: 500 }), { loading: "Fetching" })
    await until(() => byId("HTTP error! Status: 500"))
    out.httpError = byId("HTTP error! Status: 500").dataset.type
    await clear()

    // callbacks: action and cancel don't call onDismiss; close and dismiss() do
    const calls = []
    const cb = (name) => ({ onDismiss: () => calls.push(name + ":dismiss"), onAutoClose: () => calls.push(name + ":auto") })
    toast("act", { ...cb("act"), action: { label: "Go", onClick: () => calls.push("act:click") } })
    toast("cls", { ...cb("cls"), closeButton: true })
    toast("api", cb("api"))
    toast("auto", { ...cb("auto"), duration: 50 })
    byId("act").querySelector("[data-button]").click()
    byId("cls").querySelector("[data-close-button]").click()
    toast.dismiss(toast.getActiveToasts().find((t) => t.title === "api").id)
    await until(() => calls.includes("auto:auto"))
    out.calls = calls.sort()
    await clear()

    // swipe: the wrong way is dampened, toward the edge dismisses
    toast("swipe")
    await until(() => byId("swipe")?.dataset.mounted === "true")
    li = byId("swipe")
    const r = li.getBoundingClientRect()
    const fire = (type, x) => li.dispatchEvent(new PointerEvent(type, { bubbles: true, clientX: r.x + 100 + x, clientY: r.y + 30, pointerId: 1, button: 0 }))
    fire("pointerdown", 0); for (let i = 1; i <= 6; i++) fire("pointermove", -15 * i)
    out.dampened = li.style.getPropertyValue("--swipe-amount-x")
    fire("pointerup", -90)
    out.wrongWayKept = li.dataset.removed
    await wait(300)
    fire("pointerdown", 0); await wait(300); for (let i = 1; i <= 5; i++) fire("pointermove", 15 * i); fire("pointerup", 75)
    out.swipedOut = [li.dataset.removed, li.dataset.swipeDirection]
    await clear()

    // theme: follows the page's colour scheme; a named toaster keeps its own
    toast("light")
    toast("side", { toasterId: "side" })
    const main = () => document.querySelector("[data-sonner-toaster]:not([data-toaster-id])")
    const side = () => document.querySelector('[data-sonner-toaster][data-toaster-id="side"]')
    out.themeBefore = main().dataset.sonnerTheme
    document.documentElement.dataset.theme = "shadcn-dark"
    await until(() => main().dataset.sonnerTheme === "dark")
    out.themeAfter = main().dataset.sonnerTheme
    out.side = [side().dataset.position, side().dataset.sonnerTheme]
    document.documentElement.dataset.theme = "shadcn"
    await clear()

    // headless toast, icon slot, active toasts
    const card = document.createElement("div")
    card.id = "my-card"
    const cid = toast.custom(() => card)
    toast.info("info")
    li = byId("info")
    out.custom = [card.closest("[data-sonner-toast]")?.dataset.styled, !!document.getElementById("my-info-icon")?.closest("[data-icon]")]
    out.active = toast.getActiveToasts().map((t) => t.type).sort()
    out.customId = typeof cid
    await clear()

    // Alt+T focuses the toasts and expands them; Esc gives focus back
    document.getElementById("field").focus()
    toast("hot one"); toast("hot two")
    document.dispatchEvent(new KeyboardEvent("keydown", { altKey: true, code: "KeyT", bubbles: true }))
    await wait(0)
    out.hotkey = [document.activeElement === main(), byId("hot one").dataset.expanded]
    document.activeElement.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", code: "Escape", bubbles: true }))
    await wait(0)
    out.escape = [document.activeElement.id, byId("hot one").dataset.expanded]

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

  test "toasts look and behave like svelte-sonner" do
    r = run_in_chrome()

    assert r["errors"] == []

    look = r["look"]
    assert look["radius"] == "8px"
    assert look["padding"] == "16px"
    assert look["fontSize"] == "13px"
    assert look["width"] == 356
    # sonner's #3f3f3f, mixed from the popover colours
    assert look["description"] =~ ~r/^oklab\(0\.36\d/
    # the action button inverts the toast
    assert look["actionBg"] == look["toastFg"]
    assert look["actionFg"] == look["toastBg"]
    assert look["actionRadius"] == "4px"
    assert look["closeAtStart"]

    assert r["stack"] == [
             ["true", "true"],
             ["false", "true"],
             ["false", "true"],
             ["false", "false"]
           ]

    assert_in_delta r["behindScale"], 0.95, 0.001
    assert r["tabOrder"] == ["four", "three", "two", "one"]

    assert r["merged"] == ["success", "kept", 1]

    assert r["promiseLoading"] == ["loading", "true", true]
    assert ["success", true, "shadcn-sonner-fade-in", _] = r["promiseDone"]
    assert r["httpError"] == "error"

    assert r["calls"] == ["act:click", "api:dismiss", "auto:auto", "cls:dismiss"]

    assert r["dampened"] == "-15px"
    assert r["wrongWayKept"] == "false"
    assert r["swipedOut"] == ["true", "right"]

    assert r["themeBefore"] == "light"
    assert r["themeAfter"] == "dark"
    assert r["side"] == ["top-left", "dark"]

    assert r["custom"] == ["false", true]
    assert r["active"] == ["default", "info"]
    assert r["customId"] == "number"

    assert r["hotkey"] == [true, "true"]
    assert r["escape"] == ["field", "false"]
  end
end
