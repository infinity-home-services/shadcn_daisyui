defmodule ShadcnDaisyui.JS.CodeBlockBrowserTest do
  # <.code_block> in headless Chrome with the real theme CSS and JS (same
  # harness as the other *_browser_test files). The page has no LiveSocket, so
  # initShadcnDaisyui() wires the copy buttons as in a dead view, and
  # navigator.clipboard is replaced by a recorder. Skipped when Node or
  # Chrome/Chromium is missing (set CHROME to point at one).
  use ExUnit.Case, async: true

  import Phoenix.Component
  import ShadcnDaisyui.Components.CodeBlock

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

  @csv "sku,qty,price\nA-100,2,9.50\n\nB-200,<none>,4 & 5\n"
  @long "2026-10-24T10:42:07Z ERROR webhook delivery failed: POST https://hooks.example.com/orders returned 502 Bad Gateway after 3 retries (request id 7f3c9a)"

  defp render(template), do: template |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp markup do
    assigns = %{csv: @csv, long: @long, log: Enum.map_join(1..30, "\n", &"line #{&1}")}

    render(~H"""
    <div style="width: 420px; display: grid; gap: 16px; padding: 16px">
      <.code_block
        id="numbered"
        title="orders-2026-10-24-final-export-for-the-warehouse-team-with-a-very-long-name.csv"
        code={@csv}
        line_numbers
        start_line={9}
        highlight={[11]}
      />
      <.code_block
        id="diff"
        line_numbers
        lines={[
          ~s({),
          {:removed, ~s(  "status": "open",)},
          {:added, ~s(  "status": "paid",)},
          {"highlighted", ~s(  "total": "1240.00")},
          ~s(})
        ]}
      />
      <.code_block
        id="html"
        lines={[
          Phoenix.HTML.raw(~s(<span class="k">def</span> run, do: <span class="a">:ok</span>)),
          "",
          {:added, Phoenix.HTML.raw(~s(<span class="s">"done"</span>))}
        ]}
      />
      <.code_block id="override" code="secret-ish display" copy_text="what gets copied" title="Token" />
      <.code_block id="long" code={@long} />
      <.code_block id="capped" code={@log} />
      <.code_block id="wrapped" code={@long} wrap />
      <.code_block id="short" code="ok" />
      <.code_block id="error" variant="destructive" size="sm" title="Error" code="** (RuntimeError) boom" />
      <.code_block id="nocopy" code="x" copy={false} />
      <.code_block id="fallback" code="x" copy_text="refused by the clipboard" />
    </div>
    """)
  end

  defp run_in_chrome do
    css = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.css"))
    js = File.read!(Path.join(@root, "priv/static/shadcn-daisyui.js"))

    page = """
    <!doctype html>
    <html data-theme="shadcn">
    <head><meta charset="utf-8"><style>#{css}</style>
    <style>*, ::before, ::after { box-sizing: border-box; } body { margin: 0; font-family: sans-serif; } #capped-content { max-height: 80px; }</style></head>
    <body>
    #{markup()}
    <script type="module">
    const errors = []
    window.addEventListener("error", (e) => errors.push(String(e.message)))
    window.addEventListener("unhandledrejection", (e) => errors.push(String(e.reason)))
    // record what gets copied instead of touching the real clipboard; one text
    // is refused (as in an iframe without clipboard-write), so the copy falls
    // back to a selected textarea and execCommand("copy")
    const copied = []
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: (text) => text === "refused by the clipboard"
          ? Promise.reject(new DOMException("Write permission denied.", "NotAllowedError"))
          : (copied.push(text), Promise.resolve()),
      },
    })
    const legacy = []
    const execCommand = document.execCommand.bind(document)
    document.execCommand = (cmd, ...args) => {
      if (cmd !== "copy") return execCommand(cmd, ...args)
      const el = document.activeElement
      legacy.push({ tag: el.tagName, text: el.value.slice(el.selectionStart, el.selectionEnd) })
      return true
    }
    #{js}
    initShadcnDaisyui()
    const $ = (id) => document.getElementById(id)
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
    const frames = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))
    const css = (el, prop, pseudo) => getComputedStyle(el, pseudo || null).getPropertyValue(prop)
    const probe = document.createElement("div")
    document.body.appendChild(probe)
    const color = (value) => { probe.style.backgroundColor = value; return getComputedStyle(probe).backgroundColor }
    const copyBtn = (id) => $(id).querySelector('[data-slot="code-block-copy"]')
    const selectCode = (id) => {
      const s = getSelection()
      s.removeAllRanges()
      const range = document.createRange()
      range.selectNodeContents($(id + "-content").querySelector("code"))
      s.addRange(range)
      const text = s.toString()
      s.removeAllRanges()
      return text
    }
    const r = {}

    // ---- copy: the plain text, no numbers or markers ----
    const events = []
    document.addEventListener("code-block:copied", (e) => events.push([e.target.id, e.detail.text]))
    copyBtn("numbered").click()
    await sleep(30)
    const btn = copyBtn("numbered")
    r.copied_state = {
      copied: btn.hasAttribute("data-copied"),
      label: btn.getAttribute("aria-label"),
      status: $("numbered-status").textContent,
      live: $("numbered-status").getAttribute("aria-live"),
      copyIcon: css(btn.querySelector('[data-icon="copy"]'), "display"),
      checkIcon: css(btn.querySelector('[data-icon="copied"]'), "display"),
    }
    copyBtn("diff").click()
    copyBtn("html").click()
    copyBtn("override").click()
    await sleep(30)
    r.copied = [...copied]
    r.events = [...events]
    r.nocopy = !copyBtn("nocopy") && !$("nocopy-status")
    copyBtn("fallback").focus()
    copyBtn("fallback").click()
    await sleep(30)
    r.fallback = {
      legacy,
      copied: copyBtn("fallback").hasAttribute("data-copied"),
      focusBack: document.activeElement === copyBtn("fallback"),
      leftover: document.querySelectorAll("textarea").length,
    }

    // ---- a selection skips the gutter and the markers, keeps blank lines ----
    r.selection = { numbered: selectCode("numbered"), diff: selectCode("diff"), html: selectCode("html") }

    // ---- numbers and markers are generated content ----
    const lines = (id) => [...$(id).querySelectorAll('[data-slot="code-block-line"]')]
    r.before = lines("numbered").map((l) => css(l, "content", "::before"))
    r.after = lines("diff").map((l) => css(l, "content", "::after"))
    r.gutter_select = css(lines("numbered")[0], "user-select", "::before")
    // the gutter widens to the widest number: every line's text starts at the same x
    r.content_x = lines("numbered").map((l) => Math.round(l.querySelector('[data-slot="code-block-line-content"]').getBoundingClientRect().left))
    r.number_right = lines("numbered").map((l) => Math.round(l.getBoundingClientRect().left))
    // tints reach the block's sides (the line runs edge to edge)
    const pre = $("numbered-content")
    const hl = lines("numbered")[2]
    r.edge = { pre: Math.round(pre.getBoundingClientRect().left), line: Math.round(hl.getBoundingClientRect().left), width: Math.round(hl.getBoundingClientRect().width), preWidth: pre.clientWidth }
    r.tints = {
      highlighted: css(hl, "background-color"),
      added: css(lines("diff")[2], "background-color"),
      removed: css(lines("diff")[1], "background-color"),
      plain: css(lines("diff")[0], "background-color"),
      muted: color("var(--muted)"),
      destructive10: color("color-mix(in oklab, var(--destructive) 10%, transparent)"),
      removedMarker: css(lines("diff")[1], "color", "::after"),
      destructive: color("var(--destructive)"),
    }
    r.variants = lines("diff").map((l) => l.dataset.variant || null)

    // ---- the scroll region: labelled, focusable, rings the block ----
    const long = $("long-content")
    r.region = {
      role: long.getAttribute("role"),
      tabindex: long.tabIndex,
      label: long.getAttribute("aria-label"),
      labelledby: pre.getAttribute("aria-labelledby"),
      title: $("numbered-title").textContent.trim(),
      dir: long.getAttribute("dir"),
      overflowX: long.scrollWidth > long.clientWidth,
      whiteSpace: css(long, "white-space"),
      font: css(long, "font-family"),
    }
    long.focus()
    r.region.focused = document.activeElement === long
    r.region.ring = css($("long"), "box-shadow")
    probe.style.boxShadow = "var(--ring-shadow)"
    r.region.ring_shadow = getComputedStyle(probe).boxShadow

    // ---- the edges fade only while there is more to scroll to ----
    // each edge's fade size, resolved to px against a 400px box (12% = 48px, capped at 40px)
    const ruler = document.createElement("div")
    ruler.style.cssText = "position: relative; width: 400px"
    const tick = document.createElement("div")
    ruler.appendChild(tick)
    document.body.appendChild(ruler)
    const px = (v) => { tick.style.width = v; return Math.round(tick.getBoundingClientRect().width) }
    const fades = (el) => ["s", "e", "t", "b"].map((k) => px(css(el, "--code-block-fade-" + k)))
    await frames()
    r.fade = { short: fades($("short-content")), long_start: fades(long) }
    long.scrollLeft = long.scrollWidth
    await frames()
    r.fade.long_end = fades(long)
    const capped = $("capped-content")
    r.fade.capped_top = fades(capped)
    capped.scrollTop = 30
    await frames()
    r.fade.capped_mid = fades(capped)
    r.fade.mask = css(long, "mask-image").includes("linear-gradient")

    // ---- wrap: long lines wrap, nothing to scroll sideways ----
    const wrapped = $("wrapped-content")
    r.wrap = { whiteSpace: css(wrapped, "white-space"), overflowX: wrapped.scrollWidth > wrapped.clientWidth, tall: wrapped.querySelector('[data-slot="code-block-line"]').getBoundingClientRect().height > 30 }

    // ---- header: the title truncates; floating actions show on focus ----
    const title = $("numbered-title")
    r.title = { overflow: css(title, "text-overflow"), nowrap: css(title, "white-space"), clipped: title.scrollWidth > title.clientWidth }
    const floating = $("short").querySelector('[data-slot="code-block-actions"]')
    r.floating = { position: css(floating, "position"), rest: css(floating, "opacity") }
    copyBtn("short").focus()
    await sleep(200)
    r.floating.focused = css(floating, "opacity")
    r.copy_size = [css(copyBtn("short"), "width"), css(copyBtn("short"), "height")]

    // ---- destructive / sm ----
    r.error = { color: css($("error"), "color"), border: css($("error"), "border-top-color"), destructive: color("var(--destructive)"), border30: color("color-mix(in oklab, var(--destructive) 30%, transparent)"), font: css($("error-content"), "font-size"), pad: css($("error-content"), "padding-left") }
    r.default_font = css($("long-content"), "font-size")

    // ---- after 2s the check turns back into the copy icon ----
    await sleep(2100)
    r.reset = { copied: btn.hasAttribute("data-copied"), label: btn.getAttribute("aria-label"), status: $("numbered-status").textContent }

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

  @csv_text "sku,qty,price\nA-100,2,9.50\n\nB-200,<none>,4 & 5"
  @diff_text ~s({\n  "status": "open",\n  "status": "paid",\n  "total": "1240.00"\n})
  @html_text ~s(def run, do: :ok\n\n"done")

  test "Copy copies the plain text: no numbers or markers, blank lines kept, markup stripped",
       %{r: r} do
    assert r["copied"] == [@csv_text, @diff_text, @html_text, "what gets copied"]

    assert r["events"] == [
             ["numbered", @csv_text],
             ["diff", @diff_text],
             ["html", @html_text],
             ["override", "what gets copied"]
           ]

    assert r["nocopy"] == true
  end

  test "a refused clipboard falls back to a selected textarea, then focus comes back",
       %{r: r} do
    assert r["fallback"] == %{
             "legacy" => [%{"tag" => "TEXTAREA", "text" => "refused by the clipboard"}],
             "copied" => true,
             "focusBack" => true,
             "leftover" => 0
           }
  end

  test "after a copy the button shows its check and the live region says Copied, for 2s",
       %{r: r} do
    assert r["copied_state"] == %{
             "copied" => true,
             "label" => "Copied",
             "status" => "Copied",
             "live" => "polite",
             "copyIcon" => "none",
             "checkIcon" => "block"
           }

    assert r["reset"] == %{"copied" => false, "label" => "Copy", "status" => ""}
  end

  test "a selection across the block skips the gutter and the markers, keeps blank lines",
       %{r: r} do
    assert r["selection"] == %{
             "numbered" => @csv_text,
             "diff" => @diff_text,
             "html" => @html_text
           }
  end

  test "line numbers and markers are generated content: numbers silent, markers named",
       %{r: r} do
    assert r["before"] == [~s("9" / ""), ~s("10" / ""), ~s("11" / ""), ~s("12" / "")]

    assert r["after"] == [
             "none",
             ~s("−" / "Removed"),
             ~s("+" / "Added"),
             "none",
             "none"
           ]

    assert r["gutter_select"] == "none"
    assert r["variants"] == [nil, "removed", "added", "highlighted", nil]
  end

  test "the gutter fits the widest number and the tints run edge to edge", %{r: r} do
    assert [x | _] = r["content_x"]
    assert Enum.uniq(r["content_x"]) == [x]
    assert r["edge"]["line"] == r["edge"]["pre"]
    assert r["edge"]["width"] == r["edge"]["preWidth"]
  end

  test "highlighted and added lines tint muted, removed destructive/10 with a destructive marker",
       %{r: r} do
    t = r["tints"]
    assert t["highlighted"] == t["muted"]
    assert t["added"] == t["muted"]
    assert t["removed"] == t["destructive10"]
    assert t["plain"] == "rgba(0, 0, 0, 0)"
    assert t["removedMarker"] == t["destructive"]
  end

  test "the scroll region is a labelled, focusable region that rings the block", %{r: r} do
    region = r["region"]
    assert region["role"] == "region"
    assert region["tabindex"] == 0
    assert region["label"] == "Code"
    assert region["labelledby"] == "numbered-title"
    assert region["title"] =~ "orders-2026-10-24"
    assert region["dir"] == "ltr"
    assert region["whiteSpace"] == "pre"
    assert region["overflowX"] == true
    assert region["font"] =~ "monospace"
    assert region["focused"] == true
    assert region["ring"] == region["ring_shadow"]
  end

  test "the edges fade only while there is more to scroll to", %{r: r} do
    fade = r["fade"]
    assert fade["mask"] == true
    # [start, end, top, bottom], px
    assert fade["short"] == [0, 0, 0, 0]
    assert fade["long_start"] == [0, 40, 0, 0]
    assert fade["long_end"] == [40, 0, 0, 0]
    assert fade["capped_top"] == [0, 0, 0, 40]
    assert [0, 0, mid, 40] = fade["capped_mid"]
    assert mid > 0 and mid < 40
  end

  test "wrap wraps long lines instead of scrolling sideways", %{r: r} do
    assert r["wrap"] == %{"whiteSpace" => "pre-wrap", "overflowX" => false, "tall" => true}
  end

  test "the header title truncates; floating actions show on focus; 24px copy button",
       %{r: r} do
    assert r["title"] == %{"overflow" => "ellipsis", "nowrap" => "nowrap", "clipped" => true}
    assert r["floating"] == %{"position" => "absolute", "rest" => "0", "focused" => "1"}
    assert r["copy_size"] == ["24px", "24px"]
  end

  test "destructive: destructive text on a destructive/30 border; sm: 12px text and padding",
       %{r: r} do
    e = r["error"]
    assert e["color"] == e["destructive"]
    assert e["border"] == e["border30"]
    assert e["font"] == "12px"
    assert e["pad"] == "12px"
    assert r["default_font"] == "14px"
  end
end
