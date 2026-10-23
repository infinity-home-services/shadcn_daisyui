defmodule ShadcnDaisyui.JS.ServerModalBrowserTest do
  # Modals opened and closed from the server, in headless Chrome with the real
  # theme CSS and JS (same harness as the other *_browser_test files).
  # push_show_modal/2 and push_hide_modal/2 arrive as LiveView does it: a
  # `phx:shadcn:show-modal` event on window. `show` is the `data-show`
  # attribute a re-render adds or removes. A window click listener stands in
  # for LiveView's phx-click, so it records what `on_close` ran.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Overlay

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

  defp modals do
    assigns = %{}

    render(~H"""
    <.dialog id="discard" on_close="keep_editing">
      <:title>Discard changes?</:title>
      <:actions>
        <button type="button" id="discard-cancel" class="btn btn-outline" phx-click={hide_modal("discard")}>
          Keep editing
        </button>
      </:actions>
    </.dialog>
    <.dialog id="confirm" show on_close="confirm_closed">
      <:title>Confirm</:title>
    </.dialog>
    <.sheet id="details" on_close={Phoenix.LiveView.JS.push("details_closed", target: "#owner")}>
      <:title>Details</:title>
      Body
    </.sheet>
    <.drawer id="later" show={false}>Later</.drawer>
    <.command id="palette" shortcut={nil} on_close="palette_closed">
      <:item>One</:item>
    </.command>
    <div data-phx-session="x" id="live">
      <.dialog id="mounted" show>Mounted by LiveView</.dialog>
    </div>
    <template id="late"><.dialog id="appears" show>Rendered with :if</.dialog></template>
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
    #{modals()}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    // a dialog's close event is queued as a task: let it land
    const settle = () => sleep(30)
    const $ = (id) => document.getElementById(id)
    // stands in for LiveView's window click listener
    const ran = []
    window.addEventListener("click", (e) => {
      const t = e.target instanceof Element && e.target.closest("[phx-click]")
      if (t) ran.push(t.getAttribute("phx-click"))
    })
    const push = (name, id) => window.dispatchEvent(new CustomEvent("phx:shadcn:" + name, { detail: { id } }))
    // the person closes it: Esc fires cancel, then close
    const esc = (d) => {
      const e = new Event("cancel", { cancelable: true })
      d.dispatchEvent(e)
      if (!e.defaultPrevented) d.close()
    }
    // a dialog's close event is queued as a task: wait for it (and its on_close click)
    const closing = (d, act) => new Promise((res) => {
      d.addEventListener("close", () => setTimeout(res, 0), { once: true })
      act()
    })
    const r = {}
    await settle()

    // `show` in a dead view: open on load; one inside a LiveView waits for phx-mounted
    r.on_load = { confirm: $("confirm").open, later: $("later").open, mounted: $("mounted").open, discard: $("discard").open }
    $("mounted").dispatchEvent(new CustomEvent("shadcn:show-modal", { bubbles: true }))
    r.mounted = $("mounted").open
    await closing($("mounted"), () => $("mounted").close())
    await closing($("confirm"), () => $("confirm").close())
    ran.length = 0

    // push_show_modal opens; the person closes it (on_close runs); asking again reopens
    push("show-modal", "discard")
    r.pushed = $("discard").open
    await closing($("discard"), () => esc($("discard")))
    r.person_closed = { open: $("discard").open, ran: [...ran] }
    push("show-modal", "discard")
    r.pushed_again = $("discard").open
    // a Cancel button (hide_modal) is the person closing it too
    ran.length = 0
    await closing($("discard"), () => $("discard").close())
    r.cancel_button = { open: $("discard").open, ran: [...ran] }

    // push_hide_modal closes without on_close, and a later push opens it again
    push("show-modal", "discard")
    ran.length = 0
    await closing($("discard"), () => push("hide-modal", "discard"))
    r.server_hide = { open: $("discard").open, ran: [...ran] }
    push("show-modal", "discard")
    r.after_server_hide = $("discard").open
    await closing($("discard"), () => $("discard").close())

    // `show`: data-show coming back opens it; going away closes it (no on_close)
    ran.length = 0
    $("confirm").setAttribute("data-show", "")
    await settle()
    await closing($("confirm"), () => $("confirm").removeAttribute("data-show"))
    r.flip_off = { open: $("confirm").open, ran: [...ran] }
    $("confirm").setAttribute("data-show", "")
    await settle()
    r.flip_on = $("confirm").open
    // the person closes it: on_close runs, the server turns show off, then on again
    await closing($("confirm"), () => esc($("confirm")))
    r.show_person_closed = { open: $("confirm").open, ran: [...ran] }
    ran.length = 0
    $("confirm").removeAttribute("data-show")
    await settle()
    r.show_server_off = { open: $("confirm").open, ran: [...ran] }
    $("confirm").setAttribute("data-show", "")
    await settle()
    r.show_again = $("confirm").open
    await closing($("confirm"), () => $("confirm").close())

    // a sheet's close button (hide_modal) runs its on_close JS; a drawer pushed open
    ran.length = 0
    push("show-modal", "details")
    r.sheet_open = $("details").open
    await closing($("details"), () => {
      $("details").querySelector("[aria-label=Close]").click()
      $("details").dispatchEvent(new CustomEvent("shadcn:hide-modal", { bubbles: true }))
    })
    r.sheet_closed = { open: $("details").open, ran: ran.filter((x) => x.includes("details_closed")).length }
    push("show-modal", "later")
    r.drawer = $("later").open
    await closing($("later"), () => $("later").close())

    // the command palette opens from the server and runs on_close when dismissed
    ran.length = 0
    push("show-modal", "palette")
    r.palette_open = $("palette").open
    await closing($("palette"), () => esc($("palette")))
    r.palette_closed = { open: $("palette").open, ran: [...ran] }

    // a modal rendered with :if and show opens as it appears
    document.body.appendChild($("late").content.cloneNode(true))
    await settle()
    r.appears = $("appears").open
    await closing($("appears"), () => $("appears").close())

    // an unknown id does nothing
    push("show-modal", "nope")
    push("hide-modal", "nope")
    await settle()

    window.__result = JSON.stringify({ errors, r })
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

  setup_all do
    %{"errors" => errors, "r" => r} = run_in_chrome()
    %{errors: errors, r: r}
  end

  test "no script errors", %{errors: errors} do
    assert errors == []
  end

  test "a `show` modal opens on load in a dead view; in a LiveView phx-mounted opens it", %{r: r} do
    assert r["on_load"] == %{
             "confirm" => true,
             "later" => false,
             "mounted" => false,
             "discard" => false
           }

    assert r["mounted"] == true
  end

  test "push_show_modal opens it, and again after the person closed it", %{r: r} do
    assert r["pushed"] == true
    assert r["person_closed"] == %{"open" => false, "ran" => ["keep_editing"]}
    assert r["pushed_again"] == true
    assert r["cancel_button"] == %{"open" => false, "ran" => ["keep_editing"]}
  end

  test "push_hide_modal closes it without on_close; the next push opens it", %{r: r} do
    assert r["server_hide"] == %{"open" => false, "ran" => []}
    assert r["after_server_hide"] == true
  end

  test "`show` follows the server: on opens, off closes without on_close", %{r: r} do
    assert r["flip_off"] == %{"open" => false, "ran" => []}
    assert r["flip_on"] == true
  end

  test "`show` reopens after the person closed it, once the server turned it off", %{r: r} do
    assert r["show_person_closed"] == %{"open" => false, "ran" => ["confirm_closed"]}
    assert r["show_server_off"] == %{"open" => false, "ran" => []}
    assert r["show_again"] == true
  end

  test "sheets, drawers and the command palette open from the server too", %{r: r} do
    assert r["sheet_open"] == true
    assert r["sheet_closed"] == %{"open" => false, "ran" => 1}
    assert r["drawer"] == true
    assert r["palette_open"] == true
    assert r["palette_closed"] == %{"open" => false, "ran" => ["palette_closed"]}
  end

  test "a modal rendered with :if and show opens as it appears", %{r: r} do
    assert r["appears"] == true
  end
end
