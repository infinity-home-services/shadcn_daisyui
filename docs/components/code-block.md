# Code Block

Code, logs, payloads and diffs in a monospaced block with an optional header, line numbers and a copy button.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Rendered on the server with no syntax highlighting: the text is escaped and shown in the theme's monospace font. For colour, highlight on the server and pass one Phoenix.HTML.raw/1 fragment per line (e.g. Makeup.highlight_inner_html/1 on each line) with your own token CSS. Build lines in Elixir: a literal { inside a HEEx attribute opens an expression. Copy copies every line's plain text (no numbers, no markers) or copy_text, then shows a check for 2s, announces "Copied" and dispatches code-block:copied. Line numbers and diff markers are CSS generated content, so selecting the code never picks them up. Extra header buttons use class="code-block-action" (aria-pressed for a toggle such as wrap).

## Usage guidance

Use when:

- Text people read or copy exactly: a webhook or API payload, an integration log, an import error report
- A before/after change in a record's history - lines with :removed / :added
- Code in an AI chat reply - size="sm" inside the message

Don't use for:

- A short value inside a sentence - use inline code: <code class="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">
- Data people scan, sort or compare - use a table or a list
- Text people edit - use a textarea

Sizing: Default: text-sm monospace (line-height 1.625) with 16px padding in a 1px rounded-lg border. size="sm": text-xs with 12px padding, for output inside a card, a sheet or a chat reply. Cap long output with content_class (e.g. max-h-72) so it scrolls inside the block.

Responsive: Long lines scroll sideways inside the block, never the page, and the edges fade while there is more to see; wrap logs and prose-like output instead. The header title truncates. Without a header the copy button floats at the top end, always visible on touch screens.

iOS: Monospaced Text in a ScrollView with .textSelection(.enabled), and a copy button that writes UIPasteboard and announces "Copied".

## Specs

| Part | Description |
| --- | --- |
| Block | The bordered surface; data-variant and data-size set its tone and scale. |
| Header (optional) | The title (filename or label, optional icon, truncates) and the actions. |
| Actions | Copy plus any :actions buttons; without a header they float at the top end. |
| Content | The <pre> scroll region: one span per line, a gutter of numbers, + / − markers. |
| Footer (optional) | A row under the code: Show more, Download. |

| Property | Value |
| --- | --- |
| Block | 1px var(--input) border, var(--radius-lg); transparent (dark: input at 30%); destructive: destructive/30 border, destructive text |
| Text | 0.875rem monospace, line-height 1.625 (sm: 0.75rem) |
| Padding | 1rem; 0.5rem between header and code, code and footer (sm: 0.75rem, 0.375rem under the header) |
| Header | title 0.875rem / 500 (sm 0.75rem), 1rem icon with a 6px gap (sm 0.875rem), 8px gap to the actions |
| Copy button | 1.5rem ghost icon button, 0.875rem icon, 44px hit area on touch |
| Floating actions | 0.75rem from the top and end (sm 0.5rem), on var(--background) with a 1px foreground/10 ring |
| Gutter | right-aligned numbers, min 1.5rem, 0.75rem from the text, muted-foreground |
| Diff lines | added: var(--muted) + "+"; removed: destructive/10 + "−" in destructive; highlighted: var(--muted) |
| Edge fade | min(12%, 2.5rem), over the first and last 6rem of scroll, only while there is more |
| Focus | 3px ring around the block, var(--ring) border |

Tokens used: `input`, `foreground`, `muted`, `muted-foreground`, `destructive`, `background`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Moves to the copy button (and any actions), then the code |
| Arrow keys / Page Up / Page Down | Scroll the focused code |
| Enter / Space | Copy, on the copy button |

Role / ARIA: The code is a <pre role="region" tabindex="0" dir="ltr"> named by the title (aria-labelledby) or label (default "Code"). Copy is a <button> labelled "Copy" (then "Copied"); its icons are aria-hidden; a polite live region announces "Copied".

Focus: The focused code region rings the whole block (3px ring, ring-coloured border). Floating actions appear while focus is inside the block.

Screen reader: Line numbers are silent (CSS alt text ""); diff markers read "Added" / "Removed" (set --code-block-added-label / --code-block-removed-label to translate). Highlighted lines are visual only: say why in the text around the block ("Row 42 has no email domain").

Touch target: The 24px copy button has a 44px hit area on touch screens, where floating actions stay visible.

Reduced motion: The floating actions' 150ms fade is dropped; the edge fade follows the scroll position, not time.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
struct CodeBlock: View {
    let title: String?
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let title {
                    Label(title, systemImage: "doc.text")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    copied = true
                    AccessibilityNotification.Announcement("Copied").post()
                    Task { try? await Task.sleep(for: .seconds(2)); copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(copied ? "Copied" : "Copy")
            }
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
    }
}
```

Monospaced Text in a ScrollView (horizontal; [.horizontal, .vertical] with a maxHeight for a long log), .textSelection(.enabled) so people can select part of it, and a copy button that writes UIPasteboard and announces "Copied". For a diff, one HStack per line in a LazyVStack: a +/− Text with .accessibilityLabel("Added" / "Removed") and a tinted .background. ShareLink suits a long log better than copy.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| code | string (split into lines, HTML-escaped) | nil |
| lines | [string \| {variant, text} \| Phoenix.HTML.raw/1] - variant: added \| removed \| highlighted | [] |
| title | string (filename or label) | nil |
| icon | string (heroicon class) | nil |
| label | string (names the scroll region) | title, or "Code" |
| variant | default \| destructive | default |
| size | default \| sm | default |
| line_numbers | boolean | false |
| start_line | integer | 1 |
| highlight | [integer \| Range] (line numbers) | [] |
| wrap | boolean | false |
| copy | boolean | true |
| copy_text | string (what Copy copies) | the lines' text |
| copy_label / copied_label | string | "Copy" / "Copied" |
| content_class | any (on the scroll region, e.g. max-h-72) | nil |
| class | any | nil |
| :actions | slot (buttons before Copy, class code-block-action) | - |
| :footer | slot (a row under the code) | - |

## Payload with a filename

HEEx:

```heex
<.code_block id="webhook-payload" title="payload.json" icon="hero-document-text" code={@payload} />
```

```html
<div id="webhook-payload" data-slot="code-block" data-variant="default" data-size="default">
  <div data-slot="code-block-header">
    <div id="webhook-payload-title" data-slot="code-block-title">
      <span class="hero-document-text" aria-hidden="true"></span>payload.json
    </div>
    <div data-slot="code-block-actions">
      <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
        <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
        <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
      </button>
    </div>
  </div>
  <pre id="webhook-payload-content" data-slot="code-block-content" role="region" aria-labelledby="webhook-payload-title" tabindex="0" dir="ltr"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">{</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;event&quot;: &quot;order.paid&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;id&quot;: &quot;evt_8f2c41&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;created_at&quot;: &quot;2026-10-24T14:02:11Z&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;data&quot;: {</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    &quot;order&quot;: &quot;#1042&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    &quot;customer&quot;: &quot;Blue Harbor Inn&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    &quot;total&quot;: &quot;1240.00&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    &quot;currency&quot;: &quot;USD&quot;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  }</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">}</span></span></code></pre>
  <span id="webhook-payload-status" class="sr-only" aria-live="polite" data-code-block-status></span>
</div>
```

## Line numbers

HEEx:

```heex
<p class="text-sm text-muted-foreground">Row 42 has no email domain.</p>
<.code_block
  id="import-rows"
  title="people.csv"
  icon="hero-table-cells"
  code={@rows}
  line_numbers
  start_line={40}
  highlight={[42]}
/>
```

```html
<div class="flex w-full flex-col gap-3">
  <p class="text-sm text-muted-foreground">Row 42 has no email domain.</p>
  <div id="import-rows" data-slot="code-block" data-variant="default" data-size="default">
    <div data-slot="code-block-header">
      <div id="import-rows-title" data-slot="code-block-title">
        <span class="hero-table-cells" aria-hidden="true"></span>people.csv
      </div>
      <div data-slot="code-block-actions">
        <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
          <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
          <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
        </button>
      </div>
    </div>
    <pre id="import-rows-content" data-slot="code-block-content" data-numbered role="region" aria-labelledby="import-rows-title" tabindex="0" dir="ltr"><code data-slot="code-block-code"><span data-slot="code-block-line" data-line="40"><span data-slot="code-block-line-content">pat.lee@blueharbor.example,Pat,Lee,Sales</span></span><span data-slot="code-block-line" data-line="41"><span data-slot="code-block-line-content">sam.okafor@maple.example,Sam,Okafor,Support</span></span><span data-slot="code-block-line" data-variant="highlighted" data-line="42"><span data-slot="code-block-line-content">jordan.diaz@summit,Jordan,Diaz,Sales</span></span><span data-slot="code-block-line" data-line="43"><span data-slot="code-block-line-content">riley.chen@lakeside.example,Riley,Chen,</span></span><span data-slot="code-block-line" data-line="44"><span data-slot="code-block-line-content">morgan.ito@copper.example,Morgan,Ito,Billing</span></span></code></pre>
    <span id="import-rows-status" class="sr-only" aria-live="polite" data-code-block-status></span>
  </div>
</div>
```

## Diff

HEEx:

```heex
<%!-- In the LiveView (a literal { inside a HEEx attribute would open an expression):
  change = [~s({), {:removed, ~s(  "status": "open",)}, {:added, ~s(  "status": "paid",)}, ..., ~s(})] --%>
<.code_block id="order-change" title="Order #1042 · status changed" icon="hero-clock" lines={@change} />
```

```html
<div id="order-change" data-slot="code-block" data-variant="default" data-size="default">
  <div data-slot="code-block-header">
    <div id="order-change-title" data-slot="code-block-title">
      <span class="hero-clock" aria-hidden="true"></span>Order #1042 · status changed
    </div>
    <div data-slot="code-block-actions">
      <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
        <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
        <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
      </button>
    </div>
  </div>
  <pre id="order-change-content" data-slot="code-block-content" role="region" aria-labelledby="order-change-title" tabindex="0" dir="ltr"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">{</span></span><span data-slot="code-block-line" data-variant="removed"><span data-slot="code-block-line-content">  &quot;status&quot;: &quot;open&quot;,</span></span><span data-slot="code-block-line" data-variant="added"><span data-slot="code-block-line-content">  &quot;status&quot;: &quot;paid&quot;,</span></span><span data-slot="code-block-line" data-variant="removed"><span data-slot="code-block-line-content">  &quot;paid_at&quot;: null,</span></span><span data-slot="code-block-line" data-variant="added"><span data-slot="code-block-line-content">  &quot;paid_at&quot;: &quot;2026-10-24T14:02:11Z&quot;,</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;total&quot;: &quot;1240.00&quot;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">}</span></span></code></pre>
  <span id="order-change-status" class="sr-only" aria-live="polite" data-code-block-status></span>
</div>
```

## Wrapped log output

HEEx:

```heex
<.code_block id="sync-log" title="Sync log" icon="hero-command-line" code={@log} wrap content_class="max-h-56">
  <:footer>
    <span class="text-xs">Showing the last 7 of 1,204 lines</span>
    <a href={~p"/integrations/sync/log"} class="btn btn-ghost btn-xs ml-auto">Download full log</a>
  </:footer>
</.code_block>
```

```html
<div id="sync-log" data-slot="code-block" data-variant="default" data-size="default">
  <div data-slot="code-block-header">
    <div id="sync-log-title" data-slot="code-block-title">
      <span class="hero-command-line" aria-hidden="true"></span>Sync log
    </div>
    <div data-slot="code-block-actions">
      <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
        <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
        <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
      </button>
    </div>
  </div>
  <pre id="sync-log-content" data-slot="code-block-content" data-wrap role="region" aria-labelledby="sync-log-title" tabindex="0" dir="ltr" class="max-h-56"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:09 INFO  sync started: 3 integrations, 1,204 records queued since the last successful run at 13:47:02</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:10 INFO  accounting: pushed 48 invoices (12 created, 36 updated) in 1.4s</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:11 WARN  accounting: invoice #4471 skipped - customer &quot;Maple &amp; Co.&quot; has no tax region; set one and the next sync picks it up</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:12 INFO  shipping: 112 labels fetched, 3 tracking numbers changed since the last sync</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:14 ERROR crm: POST https://api.example.com/v2/contacts returned 429 Too Many Requests; retrying in 30s (attempt 2 of 5)</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:44 INFO  crm: 87 contacts updated after the retry</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">2026-10-24 14:02:45 INFO  sync finished in 36s: 1,201 records synced, 1 skipped, 2 retried</span></span></code></pre>
  <div data-slot="code-block-footer">
    <span class="text-xs">Showing the last 7 of 1,204 lines</span>
    <a href="#sync-log" class="btn btn-ghost btn-xs ml-auto">Download full log</a>
  </div>
  <span id="sync-log-status" class="sr-only" aria-live="polite" data-code-block-status></span>
</div>
```

## Error output

HEEx:

```heex
<.code_block
  id="import-error"
  variant="destructive"
  title="Import failed"
  icon="hero-exclamation-triangle"
  code={@trace}
/>
```

```html
<div id="import-error" data-slot="code-block" data-variant="destructive" data-size="default">
  <div data-slot="code-block-header">
    <div id="import-error-title" data-slot="code-block-title">
      <span class="hero-exclamation-triangle" aria-hidden="true"></span>Import failed
    </div>
    <div data-slot="code-block-actions">
      <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
        <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
        <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
      </button>
    </div>
  </div>
  <pre id="import-error-content" data-slot="code-block-content" role="region" aria-labelledby="import-error-title" tabindex="0" dir="ltr"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">** (Ecto.InvalidChangesetError) could not perform insert because changeset is invalid.</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&#10;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">Errors</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&#10;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    %{email: [{&quot;has already been taken&quot;, [constraint: :unique]}]}</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&#10;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    (ecto 3.13.2) lib/ecto/repo/schema.ex:1114: Ecto.Repo.Schema.insert!/4</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    (my_app 0.1.0) lib/my_app/imports/people.ex:58: MyApp.Imports.People.insert_row/2</span></span></code></pre>
  <span id="import-error-status" class="sr-only" aria-live="polite" data-code-block-status></span>
</div>
```

## Small, inside a card

HEEx:

```heex
<.card>
  <.card_body>
    <.card_title>Last delivery</.card_title>
    <.card_description>POST https://hooks.example.com/orders · 502 Bad Gateway · 2 min ago</.card_description>
    <.code_block id="delivery-response" size="sm" title="Response body" code={@response} class="mt-4" />
  </.card_body>
</.card>
```

```html
<div class="card w-full max-w-lg">
  <div class="card-body">
    <h3 class="card-title">Last delivery</h3>
    <p class="text-sm text-muted-foreground">
      POST https://hooks.example.com/orders · 502 Bad Gateway · 2 min ago
    </p>
    <div id="delivery-response" data-slot="code-block" data-variant="default" data-size="sm" class="mt-4">
      <div data-slot="code-block-header">
        <div id="delivery-response-title" data-slot="code-block-title">
          Response body
        </div>
        <div data-slot="code-block-actions">
          <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
            <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
            <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
          </button>
        </div>
      </div>
      <pre id="delivery-response-content" data-slot="code-block-content" role="region" aria-labelledby="delivery-response-title" tabindex="0" dir="ltr"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">&lt;html&gt;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&lt;head&gt;&lt;title&gt;502 Bad Gateway&lt;/title&gt;&lt;/head&gt;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&lt;body&gt;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&lt;center&gt;&lt;h1&gt;502 Bad Gateway&lt;/h1&gt;&lt;/center&gt;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&lt;/body&gt;</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">&lt;/html&gt;</span></span></code></pre>
      <span id="delivery-response-status" class="sr-only" aria-live="polite" data-code-block-status></span>
    </div>
  </div>
</div>
```
