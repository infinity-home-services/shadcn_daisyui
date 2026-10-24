defmodule ShadcnDaisyui.JS.PromptInputBrowserTest do
  # <.prompt_input> in headless Chrome with the real theme CSS and JS (same
  # harness as the other *_browser_test files). The forms have no LiveSocket:
  # a submit listener records what each one would send (and stops the page
  # navigating), which is what LiveView's phx-submit reads too. Typing is a
  # value write plus an input event; keys are KeyboardEvents (untrusted, so
  # they never insert text themselves). Busy is the server's re-render: the
  # busy markup's attributes copied onto the elements, then updated(), as a
  # LiveView patch does it. One composer is set up with CSS field-sizing
  # reported missing, to exercise the script's own auto-grow.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.Conversation, only: [prompt_input: 1]

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

  defp composer(id, opts) do
    assigns = %{
      id: id,
      busy: Keyword.get(opts, :busy, false),
      upload: Keyword.get(opts, :upload)
    }

    render(~H"""
    <.prompt_input id={@id} name="text" placeholder="Ask anything…" busy={@busy} upload={@upload}>
      <:suggestion value="Which orders are overdue?">Overdue orders</:suggestion>
      <:suggestion value="Draft a reminder to " send={false}>Draft a reminder</:suggestion>
    </.prompt_input>
    """)
  end

  defp markup do
    upload = %Phoenix.LiveView.UploadConfig{
      name: :files,
      ref: "phx-files",
      accept: "image/*,.pdf",
      max_entries: 3,
      max_file_size: 8_000_000
    }

    """
    <div style="width: 480px; display: grid; gap: 24px; padding: 16px">
      <form id="f-main">#{composer("main", [])}</form>
      <form id="f-busy">#{composer("busy", busy: true)}</form>
      <form id="f-fallback">#{composer("fallback", [])}</form>
      <form id="f-files">#{composer("files", upload: upload)}</form>
    </div>
    <template id="busy-markup">#{composer("main", busy: true)}</template>
    <template id="idle-markup">#{composer("main", [])}</template>
    """
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
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    const $ = (id) => document.getElementById(id)
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = (n = 3) => new Promise((r) => { const f = () => (--n ? requestAnimationFrame(f) : r()); requestAnimationFrame(f) })
    const css = (el, prop) => getComputedStyle(el).getPropertyValue(prop)
    const probe = document.createElement("div")
    document.body.appendChild(probe)
    const color = (token) => { probe.style.color = "var(" + token + ")"; return getComputedStyle(probe).color }
    const sent = []
    document.addEventListener("submit", (e) => { e.preventDefault(); sent.push({ form: e.target.id, text: new FormData(e.target).get("text") }) })
    const field = (id) => $(id + "-input")
    const submit = (id) => $(id + "-submit")
    const type = (id, text) => { const f = field(id); f.value = text; f.dispatchEvent(new Event("input", { bubbles: true })) }
    const key = (id, init) => {
      const e = new KeyboardEvent("keydown", Object.assign({ key: "Enter", bubbles: true, cancelable: true }, init))
      field(id).dispatchEvent(e)
      return e.defaultPrevented
    }
    const r = {}

    // the fallback composer: set up while CSS field-sizing is "missing"
    const supports = CSS.supports
    CSS.supports = (prop, value) => prop === "field-sizing" ? false : supports.call(CSS, prop, value)
    const fallbackHook = Object.assign(Object.create(Hooks.ShadcnPromptInput), { el: $("fallback") })
    fallbackHook.mounted()
    CSS.supports = supports
    // the main composer through the LiveView hook (patched to busy below)
    const mainHook = Object.assign(Object.create(Hooks.ShadcnPromptInput), { el: $("main") })
    mainHook.mounted()
    initShadcnDaisyui()
    await frames()

    // ---- metrics: shadcn's field ----
    const box = $("main").querySelector("[data-slot=prompt-input-box]")
    r.metrics = {
      radius: css(box, "border-top-left-radius"),
      border: css(box, "border-top-color"),
      input: color("--input"),
      fontSize: css(field("main"), "font-size"),
      padding: [css(field("main"), "padding-top"), css(field("main"), "padding-left")],
      height: field("main").offsetHeight,
      buttonSize: [submit("main").offsetWidth, submit("main").offsetHeight],
      gap: Math.round(box.getBoundingClientRect().top - $("main").querySelector("[data-slot=prompt-input-suggestions]").getBoundingClientRect().bottom),
    }
    field("main").focus()
    await sleep(250) // past the 150ms border transition
    r.focusRing = { border: css(box, "border-top-color"), ring: color("--ring"), shadow: css(box, "box-shadow") !== "none" }

    // ---- empty: Send does nothing ----
    r.empty = { disabled: submit("main").getAttribute("aria-disabled"), opacity: css(submit("main"), "opacity") }
    r.emptyEnter = key("main")
    submit("main").click()
    await sleep(20)
    r.emptySent = sent.length

    // ---- typing enables Send; Shift+Enter and composing don't send ----
    type("main", "Which orders are overdue?")
    r.typed = submit("main").getAttribute("aria-disabled")
    r.shiftEnter = key("main", { shiftKey: true })
    r.composing = key("main", { isComposing: true })
    r.ime229 = key("main", { keyCode: 229 })
    await sleep(20)
    r.notSent = sent.length

    // ---- Enter sends, then the field clears and keeps focus ----
    r.enter = key("main")
    r.sentText = sent.length ? sent[sent.length - 1] : null
    r.beforeClear = field("main").value
    await sleep(20)
    r.afterSend = { value: field("main").value, disabled: submit("main").getAttribute("aria-disabled"), focused: document.activeElement === field("main") }

    // ---- the Send button sends too ----
    type("main", "And the paid ones?")
    submit("main").focus()
    submit("main").click()
    await sleep(20)
    r.clickSent = { last: sent[sent.length - 1], count: sent.length, value: field("main").value, focused: document.activeElement === field("main") }

    // ---- auto-grow: CSS field-sizing, 4rem to 12rem, then it scrolls ----
    type("main", "")
    await frames(2)
    const h0 = field("main").offsetHeight
    type("main", "one\\ntwo\\nthree\\nfour")
    await frames(2)
    const h4 = field("main").offsetHeight
    type("main", Array.from({ length: 30 }, (_, i) => "line " + i).join("\\n"))
    await frames(2)
    r.grow = { h0, h4, max: field("main").offsetHeight, scrolls: field("main").scrollHeight > field("main").clientHeight, overflow: css(field("main"), "overflow-y") }
    type("main", "")

    // ---- the same without field-sizing: the script sets the height ----
    const fb = field("fallback")
    const fh0 = fb.offsetHeight
    type("fallback", "one\\ntwo\\nthree\\nfour")
    const fh4 = fb.offsetHeight
    type("fallback", Array.from({ length: 30 }, (_, i) => "line " + i).join("\\n"))
    r.fallback = { h0: fh0, h4: fh4, max: fb.offsetHeight, inline: fb.style.height !== "" }
    // a LiveView patch drops the inline height; updated() puts it back
    fb.style.height = ""
    fallbackHook.updated()
    r.fallbackPatched = fb.offsetHeight

    // ---- busy (the server's re-render): Send becomes Stop ----
    const patch = (tpl) => {
      const next = $(tpl).content.querySelector("#main")
      const copy = (from, to) => {
        for (const a of [...to.attributes]) if (!from.hasAttribute(a.name) && a.name !== "aria-disabled") to.removeAttribute(a.name)
        for (const a of from.attributes) if (a.name !== "aria-disabled") to.setAttribute(a.name, a.value)
      }
      copy(next, $("main"))
      copy(next.querySelector("#main-submit"), submit("main"))
      submit("main").innerHTML = next.querySelector("#main-submit").innerHTML
      mainHook.updated()
    }
    type("main", "")
    patch("busy-markup")
    r.busy = {
      type: submit("main").type,
      label: submit("main").getAttribute("aria-label"),
      disabled: submit("main").getAttribute("aria-disabled"),
      stopIcon: !!submit("main").querySelector(".hero-stop-solid"),
    }
    type("main", "Next question")
    const busyCount = sent.length
    r.busyEnter = key("main")
    submit("main").click()
    await sleep(20)
    r.busySent = sent.length - busyCount
    r.busyKept = field("main").value
    // the reply finished: Send again, and the waiting text can go
    patch("idle-markup")
    r.idle = { type: submit("main").type, label: submit("main").getAttribute("aria-label"), disabled: submit("main").getAttribute("aria-disabled") }
    key("main")
    await sleep(20)
    r.afterBusy = sent[sent.length - 1]

    // ---- a composer rendered busy ----
    type("busy", "")
    r.renderedBusy = { type: submit("busy").type, disabled: submit("busy").getAttribute("aria-disabled") }

    // ---- suggestions: fill and send, or only fill ----
    const chips = $("main").querySelectorAll("[data-prompt-suggestion]")
    const count = sent.length
    chips[0].click()
    await sleep(20)
    r.chipSend = { sent: sent.length - count, text: sent[sent.length - 1].text, value: field("main").value }
    let inputs = 0
    field("main").addEventListener("input", () => inputs++)
    chips[1].click()
    await sleep(20)
    r.chipFill = { sent: sent.length - count, value: field("main").value, inputs, focused: document.activeElement === field("main"), caret: field("main").selectionStart }

    // ---- an upload: files pasted or dragged in go to it ----
    const fileInput = $("phx-files")
    const tracked = []
    fileInput.addEventListener("track-uploads", (e) => tracked.push([...e.detail.files].map((f) => f.name)))
    const dt = new DataTransfer()
    dt.items.add(new File(["x"], "photo.png", { type: "image/png" }))
    const paste = new ClipboardEvent("paste", { clipboardData: dt, bubbles: true, cancelable: true })
    field("files").dispatchEvent(paste)
    const textPaste = new ClipboardEvent("paste", { clipboardData: new DataTransfer(), bubbles: true, cancelable: true })
    field("files").dispatchEvent(textPaste)
    r.paste = { tracked, prevented: paste.defaultPrevented, textPrevented: textPaste.defaultPrevented }
    const filesBox = $("files").querySelector("[data-slot=prompt-input-box]")
    const drag = new DataTransfer()
    drag.items.add(new File(["x"], "a.pdf", { type: "application/pdf" }))
    filesBox.dispatchEvent(new DragEvent("dragenter", { bubbles: true, cancelable: true, dataTransfer: drag }))
    await sleep(200)
    r.dragging = { on: filesBox.hasAttribute("data-dragging"), border: css(filesBox, "border-top-color"), primary: color("--primary") }
    filesBox.dispatchEvent(new DragEvent("dragleave", { bubbles: true, cancelable: true, dataTransfer: drag }))
    r.dragLeft = filesBox.hasAttribute("data-dragging")
    const attach = $("files").querySelector("[data-slot=prompt-input-attach]")
    r.attach = { label: attach.textContent.trim(), inputHidden: fileInput.offsetWidth <= 1, accept: fileInput.accept }

    mainHook.destroyed()
    r.destroyed = !$("main").__sdPrompt

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

  test "shadcn's field metrics, and the ring while the text has focus", %{r: r} do
    m = r["metrics"]
    assert m["radius"] == "8px"
    assert m["border"] == m["input"]
    assert m["fontSize"] == "14px"
    assert m["padding"] == ["8px", "12px"]
    assert m["height"] == 64
    assert m["buttonSize"] == [36, 36]
    assert m["gap"] == 12
    assert r["focusRing"]["border"] == r["focusRing"]["ring"]
    assert r["focusRing"]["shadow"]
  end

  test "an empty field can't be sent", %{r: r} do
    assert r["empty"] == %{"disabled" => "true", "opacity" => "0.5"}
    assert r["emptyEnter"] == true
    assert r["emptySent"] == 0
  end

  test "Shift+Enter and an input method's Enter don't send", %{r: r} do
    assert r["typed"] == nil
    assert r["shiftEnter"] == false
    assert r["composing"] == false
    assert r["ime229"] == false
    assert r["notSent"] == 0
  end

  test "Enter sends, then the field clears and keeps focus", %{r: r} do
    assert r["enter"] == true
    assert r["sentText"] == %{"form" => "f-main", "text" => "Which orders are overdue?"}
    # still there while the form is read
    assert r["beforeClear"] == "Which orders are overdue?"

    assert r["afterSend"] == %{"value" => "", "disabled" => "true", "focused" => true}
  end

  test "the Send button sends and gives focus back to the field", %{r: r} do
    assert r["clickSent"]["last"] == %{"form" => "f-main", "text" => "And the paid ones?"}
    assert r["clickSent"]["count"] == 2
    assert r["clickSent"]["value"] == ""
    assert r["clickSent"]["focused"]
  end

  test "the field grows with its text from 4rem to 12rem, then scrolls", %{r: r} do
    assert r["grow"]["h0"] == 64
    # four 20px lines and 16px of padding
    assert r["grow"]["h4"] == 96
    assert r["grow"]["max"] == 192
    assert r["grow"]["scrolls"]
    assert r["grow"]["overflow"] == "auto"
  end

  test "without CSS field-sizing the script grows it the same way", %{r: r} do
    assert r["fallback"] == %{"h0" => 64, "h4" => 96, "max" => 192, "inline" => true}
    assert r["fallbackPatched"] == 192
  end

  test "busy: the button is Stop, and nothing sends", %{r: r} do
    assert r["busy"] == %{
             "type" => "button",
             "label" => "Stop",
             "disabled" => nil,
             "stopIcon" => true
           }

    assert r["busyEnter"] == true
    assert r["busySent"] == 0
    assert r["busyKept"] == "Next question"

    assert r["idle"] == %{"type" => "submit", "label" => "Send", "disabled" => nil}
    assert r["afterBusy"] == %{"form" => "f-main", "text" => "Next question"}
    assert r["renderedBusy"] == %{"type" => "button", "disabled" => nil}
  end

  test "a suggestion sends its text, or only fills the field", %{r: r} do
    assert r["chipSend"] == %{"sent" => 1, "text" => "Which orders are overdue?", "value" => ""}

    assert r["chipFill"] == %{
             "sent" => 1,
             "value" => "Draft a reminder to ",
             "inputs" => 1,
             "focused" => true,
             "caret" => 20
           }
  end

  test "pasted and dragged files go to the upload", %{r: r} do
    assert r["paste"] == %{
             "tracked" => [["photo.png"]],
             "prevented" => true,
             "textPrevented" => false
           }

    assert r["dragging"]["on"]
    assert r["dragging"]["border"] == r["dragging"]["primary"]
    refute r["dragLeft"]

    assert r["attach"] == %{
             "label" => "Attach files",
             "inputHidden" => true,
             "accept" => "image/*,.pdf"
           }
  end

  test "destroyed() lets go", %{r: r} do
    assert r["destroyed"]
  end
end
