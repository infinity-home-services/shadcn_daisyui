defmodule ShadcnDaisyui.JS.DropzoneBrowserTest do
  # <.dropzone> and the file input fix, in headless Chrome with the real theme
  # CSS and JS (same harness as the other *_browser_test files). Drags are
  # DragEvents carrying a DataTransfer with real File objects; the page has no
  # LiveSocket, so initShadcnDaisyui() wires the zones as in a dead view.
  # Skipped when Node or Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.FormComponents, only: [dropzone: 1]

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

  defp markup do
    assigns = %{
      upload: %Phoenix.LiveView.UploadConfig{
        name: :people_csv,
        ref: "phx-up",
        accept: ".csv",
        max_entries: 1,
        max_file_size: 1_000_000
      }
    }

    render(~H"""
    <div style="width: 480px; display: grid; gap: 16px; padding: 16px">
      <input id="fi" type="file" class="file-input w-full" />
      <input id="fi-core" type="file" class="input w-full" />
      <input id="fi-ghost" type="file" class="file-input file-input-ghost" />
      <input id="fi-sm" type="file" class="file-input file-input-sm" />
      <input id="fi-lg" type="file" class="file-input file-input-lg" />
      <input id="fi-off" type="file" class="file-input" disabled />
      <input id="fi-bad" type="file" class="file-input" aria-invalid="true" />
      <input id="fi-core-bad" type="file" class="input input-error" />
      <input id="text-bad" class="input input-error" />
      <.dropzone id="live" upload={@upload} />
      <.dropzone id="off" upload={@upload} disabled />
      <form id="one-form"><.dropzone id="one" name="doc" accept=".pdf" /></form>
      <form id="many-form"><.dropzone id="many" name="docs" accept=".pdf,image/*" multiple /></form>
    </div>
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
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    #{js}
    initShadcnDaisyui()
    const $ = (id) => document.getElementById(id)
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const css = (el, prop, pseudo) => getComputedStyle(el, pseudo || null).getPropertyValue(prop)
    // a token's computed colour, as the browser resolves it on a probe
    const probe = document.createElement("div")
    document.body.appendChild(probe)
    const color = (token) => { probe.style.color = "var(" + token + ")"; return getComputedStyle(probe).color }
    const area = (id) => $(id).querySelector("[data-dropzone-area]")
    const file = (name, type) => new File(["x"], name, { type })
    const drag = (target, type, files, items) => {
      const dt = new DataTransfer()
      ;(files || []).forEach((f) => dt.items.add(f))
      if (items) dt.setData("text/plain", items)
      const e = new DragEvent(type, { bubbles: true, cancelable: true, dataTransfer: dt })
      target.dispatchEvent(e)
      // (Chrome ignores dropEffect writes outside a real drag session, so only
      // whether the event was cancelled is observable here)
      return e.defaultPrevented
    }
    const r = {}

    // ---- the file input: shadcn's plain "Choose file" text, 12px in ----
    const metrics = (el) => ({
      padStart: css(el, "padding-inline-start"),
      height: css(el, "height"),
      btnMarginStart: css(el, "margin-inline-start", "::file-selector-button"),
      btnMarginEnd: css(el, "margin-inline-end", "::file-selector-button"),
      btnHeight: css(el, "height", "::file-selector-button"),
      btnBg: css(el, "background-color", "::file-selector-button"),
      btnBorder: css(el, "border-top-width", "::file-selector-button"),
      btnShadow: css(el, "box-shadow", "::file-selector-button"),
      btnWeight: css(el, "font-weight", "::file-selector-button"),
      btnSize: css(el, "font-size", "::file-selector-button"),
      btnColor: css(el, "color", "::file-selector-button"),
    })
    r.fi = metrics($("fi"))
    r.fi_core = metrics($("fi-core"))
    r.foreground = color("--foreground")
    r.ghost = { border: css($("fi-ghost"), "border-top-color"), bg: css($("fi-ghost"), "background-color") }
    r.sizes = { sm: [css($("fi-sm"), "height"), css($("fi-sm"), "height", "::file-selector-button")], lg: [css($("fi-lg"), "height"), css($("fi-lg"), "height", "::file-selector-button")] }
    r.disabled = { opacity: css($("fi-off"), "opacity"), bg: css($("fi-off"), "background-color"), fi_bg: css($("fi"), "background-color") }
    r.destructive = color("--destructive")
    r.invalid = [css($("fi-bad"), "border-top-color"), css($("fi-core-bad"), "border-top-color"), css($("text-bad"), "border-top-color")]

    // ---- the zone at rest ----
    r.rest = { style: css(area("live"), "border-top-style"), color: css(area("live"), "border-top-color"), border: color("--border-color"), minHeight: css(area("live"), "min-height") }
    r.mouseTitle = getComputedStyle($("live").querySelector(".dropzone-mouse")).display
    r.touchTitle = getComputedStyle($("live").querySelector(".dropzone-touch")).display

    // ---- dragging files over it: data-dragging, primary border on accent ----
    const z = area("live")
    const child = z.querySelector(".dropzone-title")
    drag(z, "dragenter", [file("a.csv", "text/csv")])
    r.over = drag(z, "dragover", [file("a.csv", "text/csv")])
    await sleep(220)
    r.dragging = { on: z.hasAttribute("data-dragging"), border: css(z, "border-top-color"), bg: css(z, "background-color") }
    r.primary = color("--primary")
    r.accent = color("--accent")
    // crossing into a child: enter the child, then leave the zone - still over it
    drag(child, "dragenter", [file("a.csv", "text/csv")])
    drag(z, "dragleave", [file("a.csv", "text/csv")])
    r.over_child = z.hasAttribute("data-dragging")
    drag(child, "dragleave", [file("a.csv", "text/csv")])
    r.left = z.hasAttribute("data-dragging")
    // dragging text isn't a file drag
    drag(z, "dragenter", [], "hello")
    r.text_drag = z.hasAttribute("data-dragging")
    drag(z, "dragleave", [], "hello")

    // a LiveView upload's drop is LiveView's: the browser doesn't open the
    // file, and the input is left alone
    drag(z, "dragenter", [file("a.csv", "text/csv")])
    r.live_drop = { prevented: drag(z, "drop", [file("a.csv", "text/csv")]), files: $("phx-up").files.length, dragging: z.hasAttribute("data-dragging") }

    // ---- disabled: no highlight, the drop refused ----
    const off = area("off")
    drag(off, "dragenter", [file("a.csv", "text/csv")])
    r.off = { dragging: off.hasAttribute("data-dragging"), over: drag(off, "dragover", [file("a.csv", "text/csv")]), drop: drag(off, "drop", [file("a.csv", "text/csv")]), opacity: css(off, "opacity") }

    // ---- a plain form takes the drop: accepted files only, input + change ----
    const fired = []
    $("one-form").addEventListener("input", () => fired.push("input"))
    $("one-form").addEventListener("change", () => fired.push("change"))
    const one = area("one")
    const oneInput = $("one-input")
    drag(one, "drop", [file("photo.png", "image/png")])
    r.one_rejected = { files: oneInput.files.length, fired: [...fired] }
    drag(one, "drop", [file("a.pdf", "application/pdf"), file("b.pdf", "application/pdf")])
    r.one = { files: [...oneInput.files].map((f) => f.name), fired: [...fired], chosen: $("one-chosen").textContent, hidden: $("one-chosen").hidden, rootChosen: $("one").hasAttribute("data-chosen") }
    drag(one, "drop", [file("c.pdf", "application/pdf")])
    r.one_replaced = [...oneInput.files].map((f) => f.name)

    const many = area("many")
    const manyInput = $("many-input")
    drag(many, "drop", [file("a.pdf", "application/pdf"), file("notes.txt", "text/plain")])
    drag(many, "drop", [file("p.png", "image/png")])
    r.many = { files: [...manyInput.files].map((f) => f.name), chosen: $("many-chosen").textContent }
    $("many-form").reset()
    await sleep(20)
    r.reset = { files: manyInput.files.length, hidden: $("many-chosen").hidden, rootChosen: $("many").hasAttribute("data-chosen") }

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

  test "a file input keeps its 12px padding; Choose file is plain text flush at the start",
       %{r: r} do
    for m <- [r["fi"], r["fi_core"]] do
      assert m["padStart"] == "12px"
      assert m["height"] == "36px"
      assert m["btnMarginStart"] == "0px"
      assert m["btnMarginEnd"] == "8px"
      assert m["btnHeight"] == "28px"
      assert m["btnBg"] == "rgba(0, 0, 0, 0)"
      assert m["btnBorder"] == "0px"
      assert m["btnShadow"] == "none"
      assert m["btnWeight"] == "500"
      assert m["btnSize"] == "14px"
      assert m["btnColor"] == r["foreground"]
    end
  end

  test "file input ghost, sizes, disabled and error states", %{r: r} do
    assert r["ghost"] == %{"border" => "rgba(0, 0, 0, 0)", "bg" => "rgba(0, 0, 0, 0)"}
    assert r["sizes"] == %{"sm" => ["32px", "24px"], "lg" => ["40px", "32px"]}
    # 50% of its own colours, not daisyUI's grey wash
    assert r["disabled"]["opacity"] == "0.5"
    assert r["disabled"]["bg"] == r["disabled"]["fi_bg"]
    assert r["invalid"] == List.duplicate(r["destructive"], 3)
  end

  test "the zone rests with a dashed border and the pointer wording", %{r: r} do
    assert r["rest"]["style"] == "dashed"
    assert r["rest"]["color"] == r["rest"]["border"]
    assert r["rest"]["minHeight"] == "128px"
    assert r["mouseTitle"] == "inline"
    assert r["touchTitle"] == "none"
  end

  test "dragging files over it: data-dragging, a primary border on the accent fill", %{r: r} do
    assert r["over"] == true
    assert r["dragging"]["on"] == true
    assert r["dragging"]["border"] == r["primary"]
    assert r["dragging"]["bg"] == r["accent"]
    assert r["over_child"] == true
    assert r["left"] == false
    assert r["text_drag"] == false
  end

  test "a LiveView upload's drop is left to LiveView, without the browser opening the file",
       %{r: r} do
    assert r["live_drop"] == %{"prevented" => true, "files" => 0, "dragging" => false}
  end

  test "a disabled zone neither lights up nor takes the drop", %{r: r} do
    assert r["off"]["dragging"] == false
    assert r["off"]["over"] == true
    assert r["off"]["drop"] == true
    assert r["off"]["opacity"] == "0.5"
  end

  test "a plain form's zone puts accepted drops on its input and names them", %{r: r} do
    assert r["one_rejected"] == %{"files" => 0, "fired" => []}

    assert r["one"] == %{
             "files" => ["a.pdf"],
             "fired" => ["input", "change"],
             "chosen" => "a.pdf",
             "hidden" => false,
             "rootChosen" => true
           }

    assert r["one_replaced"] == ["c.pdf"]
  end

  test "multiple adds to the chosen files; a form reset clears them", %{r: r} do
    assert r["many"] == %{"files" => ["a.pdf", "p.png"], "chosen" => "a.pdf, p.png"}
    assert r["reset"] == %{"files" => 0, "hidden" => true, "rootChosen" => false}
  end
end
