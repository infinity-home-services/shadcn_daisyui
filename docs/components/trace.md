# Trace

What an assistant did or is doing: steps, tool calls, sources and plans, one row each, that open to show the detail.

shadcn/ui's Trace. Done rows are muted, a running row's title shimmers (and its glyph pulses, as a working sparkle), pending rows are dimmed, errors are destructive - so the title has to say it too ("Running mix test", "Failed to send"). A row with <:detail> is a disclosure button (aria-expanded, a chevron) and needs an id; rows nest. One delegated listener toggles it (no hook), and the reader's choice survives LiveView patches.

## Usage guidance

Use when:

- An assistant's working steps while it answers (a sparkle on the current one, a check on the done ones)
- Tool calls with their input and output, the sources an answer used, a plan's steps
- A finished turn: one "Worked through 4 steps" row that opens to the steps

Don't use for:

- A bare spinner or "Thinking…" that hides the real work - show the steps
- Filler steps that aren't real work - every row is something the assistant did
- An activity feed or audit log - use <.table_card> or <.item> rows
- A wizard's progress - use the steps recipe

Sizing: Rows 8px apart, text-sm muted, 16px icons, 8px between icon and title. Detail is indented 7px with a 1px line on its left and 16px of padding.

Responsive: Titles truncate to one line at any width; descriptions (a duration, a count) never do. Detail wraps.

iOS: A VStack of HStacks: an SF Symbol (checkmark, or sparkles with .symbolEffect(.variableColor.iterative) while running) and the text; a DisclosureGroup for rows with detail.

## Specs

| Part | Description |
| --- | --- |
| Trace | A list of rows, 8px apart. |
| Icon | 16px glyph, spinner or favicon; hidden from readers. |
| Title | One line, truncated; shimmers while running. |
| Description | 70% muted, tabular figures; never truncates. |
| Disclosure | The row as a button with a chevron (90° open). |
| Detail | Indented, 1px line on its left; rows nest. |

| Property | Value |
| --- | --- |
| Row | text-sm, muted-foreground, gap 0.5rem |
| Icon | 1rem |
| Rows apart | 0.5rem |
| Detail | margin 0.5rem 0 0.25rem 7px, padding-left 1rem |
| Open / close | grid rows 0fr → 1fr + opacity, 180ms ease-out |
| Pending | opacity 0.6 |

Tokens used: `muted-foreground`, `foreground`, `destructive`, `border-color`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move between link and disclosure rows |
| Enter / Space | Open or close a row's detail; follow a link |

Role / ARIA: A list; each row a list item. A plain row is text (not a tab stop); a source is a link; a row with detail is a button with aria-expanded and aria-controls naming its detail. Icons are aria-hidden, so the title is the name.

Focus: Links and disclosure buttons take the 3px ring for the keyboard. Closed detail is hidden (visibility), so its links are out of the tab order.

Screen reader: Status is shown by colour and motion only: word the title to say it. A new-tab link adds "(opens in a new tab)". In a message scroller each new row is announced once.

Touch target: Disclosure rows are the row's own width; in touch-first layouts leave 8px around them or use a larger text size so the line is at least 24px tall.

Reduced motion: No shimmer, no pulse, no chevron turn or open animation; the title still says what's happening.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
struct StepList: View {
    let steps: [Step]   // id, text, done - only real work, never filler

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(steps) { step in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: step.done ? "checkmark" : "sparkles")
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: !step.done)
                        .font(.caption.weight(.semibold))
                        .frame(width: 16)
                        .accessibilityHidden(true)
                    Text(step.text)
                        .font(.subheadline)
                        .foregroundStyle(step.done ? .secondary : .primary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.25), value: steps)
    }
}

// under a finished answer
Text("From the customer file and the conversation.")
    .font(.caption).foregroundStyle(.secondary)
```

While the assistant works, show what it is actually doing - one row per real step, a check when it's done and a moving sparkle on the current one - instead of a spinner. Under the answer, say where it came from ("From the customer file and the conversation."). Rows with detail are a DisclosureGroup; .symbolEffect stops under Reduce Motion.

## Props

| Name | Type | Default |
| --- | --- | --- |
| :line | slot: status icon description href navigate patch target | - |
| status | running \| pending \| error (done when unset) | nil |
| icon | heroicon name | nil |
| description | short text after the title | nil |
| trace_line | a row with slots (inner block of <.trace>) | - |
| trace_line id | string (required with :detail) | nil |
| trace_line open | boolean (how it starts) | false |
| :icon :description :detail | trace_line slots | - |

## Steps

HEEx:

```heex
<.trace>
  <:line :for={s <- @steps} status={s.status} icon={if s.status == "running", do: "hero-sparkles", else: "hero-check"}>
    {s.text}
  </:line>
</.trace>
```

```html
<div class="w-full max-w-sm">
  <div data-slot="trace" role="list">
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line">
        <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check"></span></span>
        <span data-slot="trace-title">
          Searched 240 orders
        </span>
      </span>
    </div>
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line">
        <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check"></span></span>
        <span data-slot="trace-title">
          Checked the overdue invoices
        </span>
        <span data-slot="trace-description">4 found</span>
      </span>
    </div>
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line" data-status="running">
        <span data-slot="trace-icon" aria-hidden="true"><span class="hero-sparkles"></span></span>
        <span data-slot="trace-title" class="shimmer">
          Reading Riverside Dental's file
        </span>
      </span>
    </div>
  </div>
</div>
```

## Tool calls

HEEx:

```heex
<.trace>
  <.trace_line id="call-1" open>
    <:icon><.icon name="hero-magnifying-glass" /></:icon>
    Searched orders for "overdue"
    <:description>0.4s</:description>
    <:detail>…</:detail>
  </.trace_line>
  <.trace_line id="call-2" status="error">
    <:icon><.icon name="hero-envelope" /></:icon>
    Failed to send the reminder
    <:detail>The mail server refused the message: the address bounced last week.</:detail>
  </.trace_line>
</.trace>
```

```html
<div class="w-full max-w-sm">
  <div data-slot="trace" role="list">
    <div role="listitem" data-slot="trace-item">
      <div id="tool-search" data-slot="trace-collapsible">
        <button type="button" id="tool-search-trigger" data-slot="trace-collapsible-trigger" aria-expanded="true" aria-controls="tool-search-detail">
          <span data-slot="trace-line">
            <span data-slot="trace-icon" aria-hidden="true"><span class="hero-magnifying-glass"></span></span>
            <span data-slot="trace-title">
              Searched orders for "overdue"
            </span>
            <span data-slot="trace-description">0.4s</span>
          </span>
          <span data-slot="trace-icon" data-chevron aria-hidden="true">
            <span class="hero-chevron-right"></span>
          </span>
        </button>
        <div id="tool-search-detail" data-slot="trace-collapsible-content">
          <div data-slot="trace-collapsible-clip">
            <div data-slot="trace-collapsible-content-inner">
              <div data-slot="trace" role="list">
                <div role="listitem" data-slot="trace-item">
                  <span data-slot="trace-line">
                    <span data-slot="trace-icon" aria-hidden="true"><span class="hero-document-text"></span></span>
                    <span data-slot="trace-title">
                      #1034 Riverside Dental
                    </span>
                    <span data-slot="trace-description">$1,512.80</span>
                  </span>
                </div>
                <div role="listitem" data-slot="trace-item">
                  <span data-slot="trace-line">
                    <span data-slot="trace-icon" aria-hidden="true"><span class="hero-document-text"></span></span>
                    <span data-slot="trace-title">
                      #1040 Summit Outfitters
                    </span>
                    <span data-slot="trace-description">$2,075.00</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div role="listitem" data-slot="trace-item">
      <div id="tool-total" data-slot="trace-collapsible">
        <button type="button" id="tool-total-trigger" data-slot="trace-collapsible-trigger" aria-expanded="false" aria-controls="tool-total-detail">
          <span data-slot="trace-line">
            <span data-slot="trace-icon" aria-hidden="true"><span class="hero-calculator"></span></span>
            <span data-slot="trace-title">
              Added up the amounts
            </span>
            <span data-slot="trace-description">$6,104.80</span>
          </span>
          <span data-slot="trace-icon" data-chevron aria-hidden="true">
            <span class="hero-chevron-right"></span>
          </span>
        </button>
        <div id="tool-total-detail" data-slot="trace-collapsible-content">
          <div data-slot="trace-collapsible-clip">
            <div data-slot="trace-collapsible-content-inner">4 invoices, oldest due Oct 9.</div>
          </div>
        </div>
      </div>
    </div>
    <div role="listitem" data-slot="trace-item">
      <div id="tool-send" data-slot="trace-collapsible">
        <button type="button" id="tool-send-trigger" data-slot="trace-collapsible-trigger" aria-expanded="false" aria-controls="tool-send-detail">
          <span data-slot="trace-line" data-status="error">
            <span data-slot="trace-icon" aria-hidden="true"><span class="hero-envelope"></span></span>
            <span data-slot="trace-title">
              Failed to send the reminder
            </span>
          </span>
          <span data-slot="trace-icon" data-chevron aria-hidden="true">
            <span class="hero-chevron-right"></span>
          </span>
        </button>
        <div id="tool-send-detail" data-slot="trace-collapsible-content">
          <div data-slot="trace-collapsible-clip">
            <div data-slot="trace-collapsible-content-inner">The mail server refused the message: the address bounced last week.</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Tool output

HEEx:

```heex
<.trace>
  <.trace_line id="call-api" open>
    <:icon><.icon name="hero-command-line" /></:icon>
    Called the accounting API
    <:description>0.8s</:description>
    <:detail>
      <.code_block id="call-api-output" size="sm" title="GET /v2/invoices?status=overdue"
        code={@response} content_class="max-h-48" />
    </:detail>
  </.trace_line>
  <.trace_line id="call-mail" status="error">
    <:icon><.icon name="hero-envelope" /></:icon>
    Failed to send the reminder
    <:detail>
      <.code_block id="call-mail-output" size="sm" variant="destructive" title="SMTP 550"
        code={@error} wrap />
    </:detail>
  </.trace_line>
</.trace>
```

```html
<div class="w-full max-w-md">
  <div data-slot="trace" role="list">
    <div role="listitem" data-slot="trace-item">
      <div id="call-api" data-slot="trace-collapsible">
        <button type="button" id="call-api-trigger" data-slot="trace-collapsible-trigger" aria-expanded="true" aria-controls="call-api-detail">
          <span data-slot="trace-line">
            <span data-slot="trace-icon" aria-hidden="true"><span class="hero-command-line"></span></span>
            <span data-slot="trace-title">
              Called the accounting API
            </span>
            <span data-slot="trace-description">0.8s</span>
          </span>
          <span data-slot="trace-icon" data-chevron aria-hidden="true">
            <span class="hero-chevron-right"></span>
          </span>
        </button>
        <div id="call-api-detail" data-slot="trace-collapsible-content">
          <div data-slot="trace-collapsible-clip">
            <div data-slot="trace-collapsible-content-inner">
              <div id="call-api-output" data-slot="code-block" data-variant="default" data-size="sm">
                <div data-slot="code-block-header">
                  <div id="call-api-output-title" data-slot="code-block-title">
                    GET /v2/invoices?status=overdue
                  </div>
                  <div data-slot="code-block-actions">
                    <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
                      <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
                      <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
                    </button>
                  </div>
                </div>
                <pre id="call-api-output-content" data-slot="code-block-content" role="region" aria-labelledby="call-api-output-title" tabindex="0" dir="ltr" class="max-h-48"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">{</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;invoices&quot;: [</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    { &quot;number&quot;: 1034, &quot;customer&quot;: &quot;Riverside Dental&quot;, &quot;due&quot;: &quot;2026-10-09&quot;, &quot;total&quot;: &quot;1512.80&quot; },</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">    { &quot;number&quot;: 1040, &quot;customer&quot;: &quot;Summit Outfitters&quot;, &quot;due&quot;: &quot;2026-10-14&quot;, &quot;total&quot;: &quot;2075.00&quot; }</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  ],</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">  &quot;count&quot;: 2</span></span><span data-slot="code-block-line"><span data-slot="code-block-line-content">}</span></span></code></pre>
                <span id="call-api-output-status" class="sr-only" aria-live="polite" data-code-block-status phx-update="ignore"></span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div role="listitem" data-slot="trace-item">
      <div id="call-mail" data-slot="trace-collapsible">
        <button type="button" id="call-mail-trigger" data-slot="trace-collapsible-trigger" aria-expanded="false" aria-controls="call-mail-detail">
          <span data-slot="trace-line" data-status="error">
            <span data-slot="trace-icon" aria-hidden="true"><span class="hero-envelope"></span></span>
            <span data-slot="trace-title">
              Failed to send the reminder
            </span>
          </span>
          <span data-slot="trace-icon" data-chevron aria-hidden="true">
            <span class="hero-chevron-right"></span>
          </span>
        </button>
        <div id="call-mail-detail" data-slot="trace-collapsible-content">
          <div data-slot="trace-collapsible-clip">
            <div data-slot="trace-collapsible-content-inner">
              <div id="call-mail-output" data-slot="code-block" data-variant="destructive" data-size="sm">
                <div data-slot="code-block-header">
                  <div id="call-mail-output-title" data-slot="code-block-title">
                    SMTP 550
                  </div>
                  <div data-slot="code-block-actions">
                    <button type="button" class="code-block-action" data-slot="code-block-copy" aria-label="Copy" data-copy-label="Copy" data-copied-label="Copied">
                      <span class="hero-square-2-stack" data-icon="copy" aria-hidden="true"></span>
                      <span class="hero-check" data-icon="copied" aria-hidden="true"></span>
                    </button>
                  </div>
                </div>
                <pre id="call-mail-output-content" data-slot="code-block-content" data-wrap role="region" aria-labelledby="call-mail-output-title" tabindex="0" dir="ltr"><code data-slot="code-block-code"><span data-slot="code-block-line"><span data-slot="code-block-line-content">550 5.1.1 &lt;billing@riverside-dental.example&gt;: Recipient address rejected: mailbox unavailable (bounced Oct 17)</span></span></code></pre>
                <span id="call-mail-output-status" class="sr-only" aria-live="polite" data-code-block-status phx-update="ignore"></span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Sources

HEEx:

```heex
<.message>
  <.trace>
    <.trace_line id="turn-4-sources">
      <:icon><.icon name="hero-book-open" /></:icon>
      Used 3 sources
      <:detail>
        <.trace>
          <:line icon="hero-document-text" navigate={~p"/orders/1034"}>Order #1034</:line>
          <:line icon="hero-user" navigate={~p"/customers/riverside-dental"}>Riverside Dental</:line>
          <:line icon="hero-globe-alt" href="https://example.test/terms" target="_blank">Payment terms</:line>
        </.trace>
      </:detail>
    </.trace_line>
  </.trace>
  <.bubble variant="ghost">…</.bubble>
  <:footer>From order #1034 and the customer file.</:footer>
</.message>
```

```html
<div class="w-full max-w-md">
  <div data-slot="message" data-align="start">
    <div data-slot="message-content">
      <div data-slot="message-header">Assistant</div>
      <div data-slot="trace" role="list">
        <div role="listitem" data-slot="trace-item">
          <div id="sources-demo" data-slot="trace-collapsible">
            <button type="button" id="sources-demo-trigger" data-slot="trace-collapsible-trigger" aria-expanded="false" aria-controls="sources-demo-detail">
              <span data-slot="trace-line">
                <span data-slot="trace-icon" aria-hidden="true"><span class="hero-book-open"></span></span>
                <span data-slot="trace-title">
                  Used 3 sources
                </span>
              </span>
              <span data-slot="trace-icon" data-chevron aria-hidden="true">
                <span class="hero-chevron-right"></span>
              </span>
            </button>
            <div id="sources-demo-detail" data-slot="trace-collapsible-content">
              <div data-slot="trace-collapsible-clip">
                <div data-slot="trace-collapsible-content-inner">
                  <div data-slot="trace" role="list">
                    <div role="listitem" data-slot="trace-item">
                      <a href="#" data-slot="trace-link">
                        <span data-slot="trace-line">
                          <span data-slot="trace-icon" aria-hidden="true"><span class="hero-document-text"></span></span>
                          <span data-slot="trace-title">
                            Order #1034
                          </span>
                        </span>
                      </a>
                    </div>
                    <div role="listitem" data-slot="trace-item">
                      <a href="#" data-slot="trace-link">
                        <span data-slot="trace-line">
                          <span data-slot="trace-icon" aria-hidden="true"><span class="hero-user"></span></span>
                          <span data-slot="trace-title">
                            Riverside Dental
                          </span>
                        </span>
                      </a>
                    </div>
                    <div role="listitem" data-slot="trace-item">
                      <a href="https://example.test/terms" target="_blank" data-slot="trace-link">
                        <span data-slot="trace-line">
                          <span data-slot="trace-icon" aria-hidden="true"><span class="hero-globe-alt"></span></span>
                          <span data-slot="trace-title">
                            Payment terms
                            <span class="sr-only"> (opens in a new tab)</span>
                          </span>
                        </span>
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div data-slot="bubble" data-variant="ghost" data-align="start">
        <div data-slot="bubble-content">
          Invoice #1034 is 15 days overdue. Riverside Dental has paid within a week of a reminder every time this year.
        </div>
      </div>
      <div data-slot="message-footer">From order #1034 and the customer file.</div>
    </div>
  </div>
</div>
```

## Plan

HEEx:

```heex
<.trace>
  <:line icon="hero-check-circle">Find the overdue orders</:line>
  <:line status="running" description="2 of 4">Draft a reminder for each</:line>
  <:line status="pending" icon="hero-clock">Send them from Pat's address</:line>
</.trace>
```

```html
<div class="w-full max-w-sm">
  <div data-slot="trace" role="list">
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line">
        <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check-circle"></span></span>
        <span data-slot="trace-title">
          Find the overdue orders
        </span>
      </span>
    </div>
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line">
        <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check-circle"></span></span>
        <span data-slot="trace-title">
          Look up who handles each customer
        </span>
      </span>
    </div>
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line" data-status="pending">
        <span data-slot="trace-icon" aria-hidden="true"><span class="hero-clock"></span></span>
        <span data-slot="trace-title">
          Send them from Pat's address
        </span>
      </span>
    </div>
    <div role="listitem" data-slot="trace-item">
      <span data-slot="trace-line" data-status="running">
        <span data-slot="trace-icon" aria-hidden="true"><span class="loading loading-spinner"></span></span>
        <span data-slot="trace-title" class="shimmer">
          Drafting a reminder for each
        </span>
        <span data-slot="trace-description">2 of 4</span>
      </span>
    </div>
  </div>
</div>
```

## Whole turn

HEEx:

```heex
<.message>
  <:header>Assistant</:header>
  <.trace>
    <.trace_line id={"turn-#{@turn.id}-steps"}>
      <:icon><.icon name="hero-check-circle" /></:icon>
      Worked through {length(@turn.steps)} steps
      <:description>{@turn.seconds}s</:description>
      <:detail>
        <.trace><:line :for={s <- @turn.steps} icon="hero-check">{s}</:line></.trace>
      </:detail>
    </.trace_line>
  </.trace>
  <.bubble variant="ghost">{@turn.text}</.bubble>
  <:footer>From the orders list.</:footer>
</.message>
```

```html
<div class="w-full max-w-md">
  <div data-slot="message-group" class="gap-6">
    <div data-slot="message" data-align="end">
      <div data-slot="message-content">
        <div data-slot="bubble" data-variant="default" data-align="start">
          <div data-slot="bubble-content">
            Which orders are overdue?
          </div>
        </div>
      </div>
    </div>
    <div data-slot="message" data-align="start">
      <div data-slot="message-content">
        <div data-slot="message-header">Assistant</div>
        <div data-slot="trace" role="list">
          <div role="listitem" data-slot="trace-item">
            <div id="turn-demo-steps" data-slot="trace-collapsible">
              <button type="button" id="turn-demo-steps-trigger" data-slot="trace-collapsible-trigger" aria-expanded="false" aria-controls="turn-demo-steps-detail">
                <span data-slot="trace-line">
                  <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check-circle"></span></span>
                  <span data-slot="trace-title">
                    Worked through 3 steps
                  </span>
                  <span data-slot="trace-description">4s</span>
                </span>
                <span data-slot="trace-icon" data-chevron aria-hidden="true">
                  <span class="hero-chevron-right"></span>
                </span>
              </button>
              <div id="turn-demo-steps-detail" data-slot="trace-collapsible-content">
                <div data-slot="trace-collapsible-clip">
                  <div data-slot="trace-collapsible-content-inner">
                    <div data-slot="trace" role="list">
                      <div role="listitem" data-slot="trace-item">
                        <span data-slot="trace-line">
                          <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check"></span></span>
                          <span data-slot="trace-title">
                            Searched 240 orders
                          </span>
                        </span>
                      </div>
                      <div role="listitem" data-slot="trace-item">
                        <span data-slot="trace-line">
                          <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check"></span></span>
                          <span data-slot="trace-title">
                            Added up the amounts
                          </span>
                        </span>
                      </div>
                      <div role="listitem" data-slot="trace-item">
                        <div id="turn-demo-invoices" data-slot="trace-collapsible">
                          <button type="button" id="turn-demo-invoices-trigger" data-slot="trace-collapsible-trigger" aria-expanded="false" aria-controls="turn-demo-invoices-detail">
                            <span data-slot="trace-line">
                              <span data-slot="trace-icon" aria-hidden="true"><span class="hero-check"></span></span>
                              <span data-slot="trace-title">
                                Checked 4 overdue invoices
                              </span>
                            </span>
                            <span data-slot="trace-icon" data-chevron aria-hidden="true">
                              <span class="hero-chevron-right"></span>
                            </span>
                          </button>
                          <div id="turn-demo-invoices-detail" data-slot="trace-collapsible-content">
                            <div data-slot="trace-collapsible-clip">
                              <div data-slot="trace-collapsible-content-inner">#1021, #1025, #1034, #1040</div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div data-slot="bubble" data-variant="ghost" data-align="start">
          <div data-slot="bubble-content">
            Four orders are overdue, $6,104.80 in all. The oldest is #1034 for Riverside Dental.
          </div>
        </div>
        <div data-slot="message-footer">From the orders list.</div>
      </div>
    </div>
  </div>
</div>
```
