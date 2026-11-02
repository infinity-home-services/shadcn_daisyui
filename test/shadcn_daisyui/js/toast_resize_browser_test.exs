defmodule ShadcnDaisyui.JS.ToastResizeBrowserTest do
  # A toast's stored height follows its width, in headless Chrome with the real
  # shadcn-daisyui.js and .css (same harness as sonner_browser_test.exs). The
  # stored height is what a hovered stack applies, so each step resizes, then
  # hovers, and checks the toast keeps the height its text needs. The page runs
  # in an iframe, whose width is a viewport for the media queries.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Display, only: [toaster: 1]
  import ShadcnDaisyui.CoreComponents, only: [flash: 1]

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
    assigns = %{flash: %{"error" => "Sign-in didn't complete. Try again."}}

    render(~H"""
    <.toaster duration={60000} />
    <div id="flash-group" aria-live="polite">
      <.flash kind={:error} flash={@flash} />
    </div>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    inner = """
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
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const frame = window.frameElement
    const resize = async (width, height = 800) => {
      frame.style.width = width + "px"
      frame.style.height = height + "px"
      await frames()
      await frames()
    }
    const byText = (text) => [...document.querySelectorAll("[data-sonner-toast]")].find((li) => li.textContent.includes(text))
    const stored = (li) => parseFloat(li.style.getPropertyValue("--initial-height"))
    const hover = (ol, on) => ol.dispatchEvent(new MouseEvent(on ? "mouseenter" : "mouseleave", { clientX: on ? 0 : 50, clientY: 0 }))

    // resize, read the height the text needs (a collapsed front toast is auto),
    // then hover: longer than the height transition, so a stale height shows
    const step = async (li, width, height) => {
      const ol = li.closest("[data-sonner-toaster]")
      await resize(width, height)
      const natural = li.offsetHeight
      const out = { natural, stored: stored(li), toastWidth: li.offsetWidth, listWidth: ol.offsetWidth }
      hover(ol, true)
      await wait(450)
      out.hovered = li.offsetHeight
      hover(ol, false)
      await wait(450)
      return out
    }

    const out = {}

    // the report: a flash shown in a sliver of a window, then widened
    await resize(40)
    const flash = byText("Sign-in didn't complete")
    await until(() => flash.dataset.mounted === "true")
    out.sliver = await step(flash, 40)
    out.desktop = await step(flash, 1280)
    toast.dismiss()
    await until(() => !document.querySelector("[data-sonner-toast]"))

    // the list keeps its width across the breakpoint (100% of 356px, then
    // --width), but the toast inside it doesn't (100% less the offsets, then
    // --width)
    const long = "Long enough " + Array.from({ length: 120 }, (_, i) => "word" + i).join(" ")
    await resize(356)
    toast(long)
    const wrapped = byText("Long enough")
    await until(() => wrapped.dataset.mounted === "true")
    out.below = await step(wrapped, 356)
    out.above = await step(wrapped, 610)

    // rotation: the sides swap, staying under the breakpoint
    out.portrait = await step(wrapped, 320, 568)
    out.landscape = await step(wrapped, 568, 320)
    toast.dismiss()
    await until(() => !document.querySelector("[data-sonner-toast]"))

    // resizing a hovered toast changes its height at once: measuring that inside
    // the observer's callback would be a ResizeObserver loop error (out.errors)
    await resize(320)
    toast(long)
    const alone = byText("Long enough")
    await until(() => alone.dataset.mounted === "true")
    hover(alone.closest("[data-sonner-toaster]"), true)
    await wait(450)
    await resize(1280)
    out.alone = { stored: stored(alone), height: alone.offsetHeight }
    hover(alone.closest("[data-sonner-toaster]"), false)
    toast.dismiss()
    await until(() => !document.querySelector("[data-sonner-toast]"))

    // resizing an expanded stack: every height, and the offsets and the front
    // height built from them, move with it
    await resize(320)
    toast("Behind")
    toast(long)
    const front = byText("Long enough")
    const behind = byText("Behind")
    await until(() => front.dataset.mounted === "true")
    const ol = front.closest("[data-sonner-toaster]")
    hover(ol, true)
    await wait(450)
    const stack = () => ({
      front: front.offsetHeight,
      frontStored: stored(front),
      frontHeightVar: parseFloat(ol.style.getPropertyValue("--front-toast-height")),
      behindOffset: parseFloat(behind.style.getPropertyValue("--offset")),
    })
    out.stackNarrow = stack()
    await resize(1280)
    await wait(450)
    out.stackWide = stack()
    hover(ol, false)

    // a toast that has left is no longer watched
    toast.dismiss()
    await until(() => !document.querySelector("[data-sonner-toast]"))
    await resize(500)

    await wait(50)
    out.errors = errors
    parent.__result = JSON.stringify(out)
    </script>
    </body>
    </html>
    """

    srcdoc = inner |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    page = """
    <!doctype html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="margin: 0">
    <iframe id="viewport" style="width: 40px; height: 800px; border: 0" srcdoc="#{srcdoc}"></iframe>
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

  # the toast stores the height it renders at, and hovering doesn't change it
  defp assert_keeps_height(step) do
    assert_in_delta step["stored"], step["natural"], 1
    assert_in_delta step["hovered"], step["natural"], 1
  end

  test "a toast's stored height follows its width" do
    r = run_in_chrome()

    assert r["errors"] == []

    # a flash shown in a sliver of a window, then widened to a desktop
    assert r["sliver"]["natural"] > 200
    assert_keeps_height(r["sliver"])
    assert r["desktop"]["natural"] < 100
    assert_keeps_height(r["desktop"])

    # across the breakpoint the list doesn't change width, the toast does
    assert r["below"]["listWidth"] == 356
    assert r["above"]["listWidth"] == 356
    assert r["below"]["toastWidth"] == 324
    assert r["above"]["toastWidth"] == 356
    assert r["below"]["natural"] > r["above"]["natural"]
    assert_keeps_height(r["below"])
    assert_keeps_height(r["above"])

    # rotation
    assert r["portrait"]["natural"] > r["landscape"]["natural"]
    assert_keeps_height(r["portrait"])
    assert_keeps_height(r["landscape"])

    # a hovered toast resized
    assert_in_delta r["alone"]["stored"], r["alone"]["height"], 1

    # an expanded stack resized: heights, offsets and the front height
    for key <- ["stackNarrow", "stackWide"] do
      s = r[key]
      assert_in_delta s["frontStored"], s["front"], 1
      assert_in_delta s["frontHeightVar"], s["front"], 1
      assert_in_delta s["behindOffset"], s["front"] + 14, 1
    end

    assert r["stackNarrow"]["front"] > r["stackWide"]["front"]
  end
end
