defmodule ShadcnDaisyui.JS.AlertDialogBrowserTest do
  # <.alert_dialog> and the styled data-confirm opt-in in headless Chrome with
  # the real theme CSS and JS (same harness as server_modal_browser_test.exs),
  # under a strict `script-src 'nonce-…'` policy: every CSP violation is
  # recorded. phoenix_html's own script is on the page for data-confirm and
  # data-method, and a window click listener after it stands in for
  # LiveView's phx-click, so it records what ran. window.confirm is stubbed to
  # record what the browser would have asked. Form submissions are recorded
  # and stopped, so the page stays.
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
  @phoenix_html Path.join(@root, "deps/phoenix_html/priv/static/phoenix_html.js")

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp body do
    assigns = %{}

    render(~H"""
    <button id="opener" type="button">Opener</button>
    <.alert_dialog id="delete" on_close="delete_closed">
      <:title>Delete Q3 report?</:title>
      <:description>This permanently deletes the report.</:description>
      <:action id="delete-go" variant="destructive" phx-click="delete">Delete</:action>
    </.alert_dialog>
    <.alert_dialog id="keep">
      <:title>Delete Q4 report?</:title>
      <:action id="keep-go" variant="destructive" phx-click="delete_keep" close={false}>
        Delete
      </:action>
    </.alert_dialog>
    <.dialog id="plain"><:title>A plain dialog</:title></.dialog>

    <button id="native" type="button" phx-click="native_click" data-confirm="Native?">Native</button>
    <button id="rm" type="button" phx-click="remove" data-confirm="Remove Acme Marketing from Pat?">
      <span id="rm-label">Remove</span>
    </button>
    <.dropdown_menu id="menu">
      <:trigger>Actions</:trigger>
      <:item
        id="menu-remove"
        phx-click="remove_member"
        variant="destructive"
        confirm="Remove Acme Marketing from Pat?"
      >
        Remove
      </:item>
    </.dropdown_menu>
    <button
      id="archive"
      type="button"
      phx-click="archive"
      data-confirm="Archive Q3 report?"
      data-confirm-description="You can restore it from the archive."
      data-confirm-action="Archive"
      data-confirm-cancel="Keep it"
    >
      Archive
    </button>
    <a id="hash-link" href="#confirmed-hash" data-confirm="Jump to the end?">Jump</a>
    <a
      id="method-link"
      href="/items/1"
      data-method="delete"
      data-to="/items/1"
      data-csrf="t0k3n"
      data-confirm="Delete item 1?"
    >
      Delete item
    </a>
    <form id="send-form" action="/send" method="post">
      <button id="send" type="submit" class="btn btn-error" data-confirm="Send the invoice?">Send</button>
    </form>
    <.command id="palette" shortcut={nil}>
      <:item id="pal-plain" phx-click="plain">Plain</:item>
      <:item id="pal-add" phx-click="add_back" confirm="Add Pat back?">Add Pat back</:item>
    </.command>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Security-Policy" content="script-src 'nonce-t3st'; object-src 'none'; base-uri 'self'">
    <style>#{css}</style>
    </head>
    <body>
    #{body()}
    <script nonce="t3st">
    window.__violations = []
    document.addEventListener("securitypolicyviolation", (e) => window.__violations.push(e.effectiveDirective + " " + (e.sample || e.blockedURI)))
    </script>
    <script nonce="t3st">#{File.read!(@phoenix_html)}</script>
    <script type="module" nonce="t3st">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const settle = () => sleep(30)
    const $ = (id) => document.getElementById(id)
    // stands in for LiveView's window click listener (after phoenix_html's)
    const ran = []
    window.addEventListener("click", (e) => {
      const t = e.target instanceof Element && e.target.closest("[phx-click]")
      if (t) ran.push(t.getAttribute("phx-click"))
    })
    // what the browser's confirm() would have asked
    const asked = []
    window.confirm = (msg) => { asked.push(msg); return false }
    // form submissions (a submit button, phoenix_html's data-method form)
    const submits = []
    document.addEventListener("submit", (e) => {
      const f = e.target
      const m = f.querySelector("[name=_method]")
      submits.push({ action: new URL(f.action).pathname, method: m ? m.value : f.method })
      e.preventDefault()
    }, true)
    // a dialog's close event is queued as a task: wait for it (and what follows it)
    const closing = (d, act) => new Promise((res) => {
      d.addEventListener("close", () => setTimeout(res, 0), { once: true })
      act()
    })
    const open = (d) => d.dispatchEvent(new CustomEvent("shadcn:show-modal", { bubbles: true }))
    const focused = () => document.activeElement && (document.activeElement.id || document.activeElement.outerHTML.slice(0, 60))
    const text = (id) => ($(id) ? $(id).textContent.trim() : null)
    // a click on the page behind an open modal: what's at the point gets it
    const backdropClick = () => {
      const el = document.elementFromPoint(5, 5)
      el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1, clientX: 5, clientY: 5 }))
      return el
    }
    const r = {}

    // ---- <.alert_dialog> ----------------------------------------------------
    const d = $("delete")
    const cancelOf = (dlg) => dlg.querySelector("[data-alert-dialog-cancel]")
    $("opener").focus()
    open(d)
    r.opened = {
      open: d.open,
      modal: d.matches(":modal"),
      role: d.getAttribute("role"),
      name: text(d.getAttribute("aria-labelledby")),
      description: text(d.getAttribute("aria-describedby")),
      focus_on_cancel: document.activeElement === cancelOf(d),
    }
    await closing(d, () => cancelOf(d).click())
    r.cancelled = { open: d.open, ran: [...ran], focus: focused(), value: d.returnValue }

    ran.length = 0
    open(d)
    await closing(d, () => d.requestClose())
    r.esc = { open: d.open, ran: [...ran], focus: focused() }

    // a backdrop click leaves it open, with or without an app shell on the page
    ran.length = 0
    open(d)
    const hit = backdropClick()
    await settle()
    r.backdrop = { hit: hit === d, open: d.open }
    const shell = document.createElement("div")
    shell.className = "app-shell"
    document.body.appendChild(shell)
    backdropClick()
    await settle()
    r.backdrop_shell = { open: d.open, ran: [...ran] }
    // (control: on an app shell page a plain dialog does close on a backdrop click)
    open($("plain"))
    await closing($("plain"), () => backdropClick())
    r.control = $("plain").open
    shell.remove()

    // the action runs its phx-click and closes it (which runs on_close)
    open(d) // (still open, unless a backdrop click closed it)
    await settle()
    ran.length = 0
    await closing(d, () => $("delete-go").click())
    r.action = { open: d.open, ran: [...ran], value: d.returnValue }

    // close={false}: the action runs, the dialog stays for the server to close
    ran.length = 0
    open($("keep"))
    $("keep-go").click()
    await settle()
    r.keep = { open: $("keep").open, ran: [...ran] }
    await closing($("keep"), () => $("keep").dispatchEvent(new CustomEvent("shadcn:hide-modal", { bubbles: true })))

    // ---- data-confirm before the opt-in: the browser's confirm() ------------
    ran.length = 0
    $("native").click()
    r.native = { asked: [...asked], ran: [...ran], dialog: !!$("shadcn-confirm") }
    asked.length = 0

    // ---- opted in ------------------------------------------------------------
    initShadcnDaisyui({ confirm: true })
    initConfirmDialog() // a second call adds nothing
    const c = () => $("shadcn-confirm")
    const action = () => c().querySelector("[data-alert-dialog-action]")
    const cancel = () => c().querySelector("[data-alert-dialog-cancel]")
    const shown = () => ({
      open: c().open,
      role: c().getAttribute("role"),
      title: text(c().getAttribute("aria-labelledby")),
      described: c().getAttribute("aria-describedby"),
      description: c().querySelector(".alert-dialog-description").hidden ? null : text("shadcn-confirm-description"),
      action: action().textContent,
      action_class: action().className,
      cancel: cancel().textContent,
      focus_on_cancel: document.activeElement === cancel(),
    })

    ran.length = 0
    $("rm").focus()
    $("rm-label").click()
    r.rm_asked = { ...shown(), ran: [...ran], asked: [...asked] }
    await closing(c(), () => cancel().click())
    r.rm_cancelled = { open: c().open, ran: [...ran], asked: [...asked], focus: focused() }
    $("rm-label").click()
    await closing(c(), () => action().click())
    r.rm_confirmed = { ran: [...ran], asked: [...asked], attr: $("rm").getAttribute("data-confirm") }

    // a destructive dropdown item gets a destructive action; Esc is a no
    ran.length = 0
    $("menu-remove").click()
    r.menu_asked = shown()
    await closing(c(), () => c().requestClose())
    r.menu_esc = { open: c().open, ran: [...ran] }
    $("menu-remove").click()
    await closing(c(), () => action().click())
    r.menu_confirmed = { ran: [...ran], asked: [...asked] }

    // per-element description and labels, back to the defaults on the next one
    ran.length = 0
    $("archive").click()
    r.archive_asked = shown()
    await closing(c(), () => cancel().click())
    $("rm").click()
    r.next_asked = shown()
    await closing(c(), () => cancel().click())
    r.archive_ran = [...ran]

    // a plain link follows its href once confirmed
    $("hash-link").click()
    await settle()
    r.hash_before = location.hash
    await closing(c(), () => action().click())
    await settle()
    r.hash_after = location.hash

    // phoenix_html's data-method link and a submit button run as before
    $("method-link").click()
    await closing(c(), () => action().click())
    $("send").click()
    r.send_asked = shown()
    await closing(c(), () => action().click())
    r.submits = { submits: [...submits], asked: [...asked] }

    // the command palette: open under the question; closes once confirmed
    ran.length = 0
    $("palette").showModal()
    $("pal-add").click()
    const cb = cancel().getBoundingClientRect()
    const top = document.elementFromPoint(cb.x + cb.width / 2, cb.y + cb.height / 2) === cancel()
    r.pal_asked = { palette: $("palette").open, confirm: c().open, top, ran: [...ran] }
    await closing(c(), () => cancel().click())
    r.pal_cancelled = { palette: $("palette").open, ran: [...ran] }
    $("pal-add").click()
    await closing(c(), () => action().click())
    r.pal_confirmed = { palette: $("palette").open, ran: [...ran], asked: [...asked] }

    // confirmDialog(): a promise of the answer; a second question supersedes the first
    const p1 = confirmDialog("Programmatic?", { action: "Yes, do it", variant: "destructive" })
    r.programmatic = shown()
    await closing(c(), () => action().click())
    r.p1 = await p1
    const p2 = confirmDialog("Escape me?")
    await closing(c(), () => c().requestClose())
    r.p2 = await p2
    const p3 = confirmDialog("First?")
    const p4 = confirmDialog("Second?")
    r.p3 = await p3
    r.superseded = shown()
    await closing(c(), () => cancel().click())
    r.p4 = await p4
    r.single = document.querySelectorAll("#shadcn-confirm").length

    // the policy is on: an inline handler added now is blocked (and reported)
    await settle()
    const before = window.__violations.length
    const canary = document.createElement("button")
    canary.setAttribute("onclick", "window.__canary = true")
    document.body.appendChild(canary)
    canary.click()
    for (let i = 0; i < 50 && window.__violations.length === before; i++) await sleep(20)
    r.canary = { ran: !!window.__canary, reported: window.__violations.length > before }
    const violations = window.__violations.slice(0, before)
    window.__result = JSON.stringify({ errors, violations, r })
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
    %{"errors" => errors, "violations" => violations, "r" => r} = run_in_chrome()
    %{errors: errors, violations: violations, r: r}
  end

  test "no script errors and no CSP violations", %{errors: errors, violations: violations, r: r} do
    assert errors == []
    assert violations == []
    # the policy is enforced: the page's inline onclick canary was blocked
    assert r["canary"] == %{"ran" => false, "reported" => true}
  end

  test "opens as a modal alertdialog, named and described, focus on Cancel", %{r: r} do
    assert r["opened"] == %{
             "open" => true,
             "modal" => true,
             "role" => "alertdialog",
             "name" => "Delete Q3 report?",
             "description" => "This permanently deletes the report.",
             "focus_on_cancel" => true
           }
  end

  test "Cancel closes it without the action, runs on_close and returns focus", %{r: r} do
    assert r["cancelled"] == %{
             "open" => false,
             "ran" => ["delete_closed"],
             "focus" => "opener",
             "value" => "cancel"
           }
  end

  test "Esc cancels", %{r: r} do
    assert r["esc"] == %{"open" => false, "ran" => ["delete_closed"], "focus" => "opener"}
  end

  test "a backdrop click doesn't close it, app shell or not", %{r: r} do
    assert r["backdrop"] == %{"hit" => true, "open" => true}
    assert r["backdrop_shell"] == %{"open" => true, "ran" => []}
    # the same click closes a plain dialog on an app shell page
    assert r["control"] == false
  end

  test "the action runs and closes it; close={false} keeps it open", %{r: r} do
    assert r["action"] == %{
             "open" => false,
             "ran" => ["delete", "delete_closed"],
             "value" => "confirm"
           }

    assert r["keep"] == %{"open" => true, "ran" => ["delete_keep"]}
  end

  test "without the opt-in, data-confirm is the browser's confirm()", %{r: r} do
    assert r["native"] == %{"asked" => ["Native?"], "ran" => [], "dialog" => false}
  end

  test "opted in, data-confirm asks in the alert dialog, not confirm()", %{r: r} do
    assert r["rm_asked"] == %{
             "open" => true,
             "role" => "alertdialog",
             "title" => "Remove Acme Marketing from Pat?",
             "described" => nil,
             "description" => nil,
             "action" => "Continue",
             "action_class" => "btn btn-primary",
             "cancel" => "Cancel",
             "focus_on_cancel" => true,
             "ran" => [],
             "asked" => []
           }
  end

  test "Cancel does nothing and gives focus back", %{r: r} do
    assert r["rm_cancelled"] == %{"open" => false, "ran" => [], "asked" => [], "focus" => "rm"}
  end

  test "Confirm replays the click once; data-confirm stays on the element", %{r: r} do
    assert r["rm_confirmed"] == %{
             "ran" => ["remove"],
             "asked" => [],
             "attr" => "Remove Acme Marketing from Pat?"
           }
  end

  test "a destructive item gets a destructive action; Esc is a no", %{r: r} do
    assert r["menu_asked"]["action_class"] == "btn btn-error"
    assert r["menu_asked"]["title"] == "Remove Acme Marketing from Pat?"
    assert r["menu_esc"] == %{"open" => false, "ran" => []}
    assert r["menu_confirmed"] == %{"ran" => ["remove_member"], "asked" => []}
  end

  test "per-element description and labels; the next question starts fresh", %{r: r} do
    assert %{
             "title" => "Archive Q3 report?",
             "described" => "shadcn-confirm-description",
             "description" => "You can restore it from the archive.",
             "action" => "Archive",
             "cancel" => "Keep it",
             "action_class" => "btn btn-primary"
           } = r["archive_asked"]

    assert %{
             "title" => "Remove Acme Marketing from Pat?",
             "described" => nil,
             "description" => nil,
             "action" => "Continue",
             "cancel" => "Cancel"
           } = r["next_asked"]

    assert r["archive_ran"] == []
  end

  test "links, data-method links and submit buttons run once confirmed", %{r: r} do
    assert r["hash_before"] == ""
    assert r["hash_after"] == "#confirmed-hash"
    assert r["send_asked"]["action_class"] == "btn btn-error"

    assert r["submits"] == %{
             "submits" => [
               %{"action" => "/items/1", "method" => "delete"},
               %{"action" => "/send", "method" => "post"}
             ],
             "asked" => []
           }
  end

  test "a palette item asks over the open palette, which closes only once confirmed", %{r: r} do
    assert r["pal_asked"] == %{"palette" => true, "confirm" => true, "top" => true, "ran" => []}
    assert r["pal_cancelled"] == %{"palette" => true, "ran" => []}
    assert r["pal_confirmed"] == %{"palette" => false, "ran" => ["add_back"], "asked" => []}
  end

  test "confirmDialog() resolves with the answer", %{r: r} do
    assert %{
             "title" => "Programmatic?",
             "action" => "Yes, do it",
             "action_class" => "btn btn-error"
           } =
             r["programmatic"]

    assert r["p1"] == true
    assert r["p2"] == false
    assert r["p3"] == false
    assert r["superseded"]["title"] == "Second?"
    assert r["p4"] == false
    assert r["single"] == 1
  end
end
