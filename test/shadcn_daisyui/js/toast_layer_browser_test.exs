defmodule ShadcnDaisyui.JS.ToastLayerBrowserTest do
  # Toasts and flashes above open modals, in headless Chrome with the real
  # shadcn-daisyui.js (same harness as fit_rows_browser_test.exs). A modal
  # <dialog> makes everything outside it inert, so the toast layer has to move
  # into the topmost open one; these checks hit-test the toast to prove it is
  # really clickable there, not just painted on top.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Overlay, only: [sheet: 1, dialog: 1]
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
    assigns = %{flash: %{"info" => "Profile saved", "error" => "Could not save"}}

    render(~H"""
    <.toaster />
    <div id="flash-group" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} title="Upload failed" flash={@flash} position="top-center" />
    </div>
    <.sheet id="sht"><input id="sht-input" /></.sheet>
    <.dialog id="dlg">dialog body</.dialog>
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
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const layer = () => document.querySelector("[data-sonner-layer]")
    const host = () => { const p = layer().parentElement; return p.id || p.tagName }
    // the toast's own button is what a click at its centre lands on
    const hittable = (el) => {
      const r = el.getBoundingClientRect()
      return el.contains(document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2))
    }
    // Poll a condition instead of sleeping a fixed time: with many Chromes
    // running at once the toast's enter transition can start late, leaving it
    // below the viewport after any fixed wait. Gives up (false) after 5s.
    const until = async (ok, ms = 5000) => {
      const end = performance.now() + ms
      while (!ok()) { if (performance.now() > end) return false; await wait(16) }
      return true
    }
    // a toast has finished entering: fully opaque, transform back at rest
    const settled = (t) => {
      const s = t && getComputedStyle(t)
      return !!s && s.opacity === "1" && (s.transform === "none" || s.transform === "matrix(1, 0, 0, 1, 0, 0)")
    }
    const out = {}
    await frames()
    await wait(450)

    // flashes: shown as toasts (server elements hidden), role on each toast
    out.flashToasts = [...document.querySelectorAll("[data-sonner-toast]")]
      .map((t) => [t.dataset.type, t.getAttribute("role"), t.dataset.yPosition + "-" + t.dataset.xPosition])
      .sort()
    out.flashSourceHidden = getComputedStyle(document.getElementById("flash-info")).display === "none"
    out.layerRole = layer().getAttribute("role")
    toast.dismiss()
    await wait(450)

    // a toast over an open sheet
    const sheet = document.getElementById("sht")
    sheet.showModal()
    document.getElementById("sht-input").focus()
    let undone = 0
    toast("Saved", { duration: 60000, action: { label: "Undo", onClick: () => undone++ } })
    await frames()
    await until(() => settled(document.querySelector("[data-sonner-toast]")))
    const action = document.querySelector("[data-sonner-toast] [data-button]")
    out.sheetHost = host()
    out.sheetHittable = hittable(action)
    out.layerOpen = layer().matches(":popover-open")
    action.dispatchEvent(new MouseEvent("mousedown", { bubbles: true, cancelable: true }))
    action.click()
    out.undone = undone
    out.focusStayed = document.activeElement.id === "sht-input"
    out.sheetStillOpen = sheet.open

    // a dialog opened later: the layer follows to the new top modal
    toast("Again", { duration: 60000 })
    await frames()
    await until(() => settled(document.querySelector("[data-sonner-toast][data-front=true]")))
    const dlg = document.getElementById("dlg")
    dlg.showModal()
    await wait(0)
    out.dialogHost = host()
    out.dialogHittable = await until(() => hittable(document.querySelector("[data-sonner-toast][data-front=true]")))
    dlg.close()
    await wait(0)
    out.afterDialogHost = host()
    sheet.close()
    await wait(0)
    out.afterSheetHost = host()
    out.stillOpen = layer().matches(":popover-open")
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
    {out, 0} = System.cmd(@node, [script, @chrome, file, profile])
    JSON.decode!(out)
  end

  test "toasts and flashes sit above open modals and stay clickable" do
    r = run_in_chrome()

    assert r["errors"] == []

    # flashes render as toasts: info -> success check (status), error -> alert
    assert r["flashToasts"] == [
             ["error", "alert", "top-center"],
             ["success", "status", "bottom-right"]
           ]

    assert r["flashSourceHidden"]
    assert r["layerRole"] == "region"

    # inside the open sheet's toast host, clickable, focus untouched
    assert r["sheetHost"] == "sht-toasts"
    assert r["layerOpen"]
    assert r["sheetHittable"]
    assert r["undone"] == 1
    assert r["focusStayed"]
    assert r["sheetStillOpen"]

    # follows a modal opened later, then back out as they close
    assert r["dialogHost"] == "dlg-toasts"
    assert r["dialogHittable"]
    assert r["afterDialogHost"] == "sht-toasts"
    assert r["afterSheetHost"] == "BODY"
    assert r["stillOpen"]
  end
end
