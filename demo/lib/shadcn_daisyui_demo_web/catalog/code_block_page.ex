defmodule ShadcnDaisyuiDemoWeb.Catalog.CodeBlockPage do
  @moduledoc """
  The catalog page for `<.code_block>`: payloads, logs, import errors and
  record-history diffs. Like `ShadcnDaisyuiDemoWeb.Catalog.DataPages`, each
  example's `code` is rendered from the real component at runtime (through
  `DataPages.code/1`, minus the LiveView-only attributes), so the code tab is
  the markup the component renders today, as a plain-HTML recipe that works
  with `initShadcnDaisyui()`. Everything renders from fixed, made-up data.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components,
    only: [card: 1, card_body: 1, card_title: 1, card_description: 1]

  import ShadcnDaisyui.Components.CodeBlock

  alias ShadcnDaisyuiDemoWeb.Catalog.DataPages

  # Modules whose markup the examples render: a change to any of them (or to
  # this module, or to DataPages' rendering) rebuilds the page.
  @sources [__MODULE__, DataPages, ShadcnDaisyui.Components, ShadcnDaisyui.Components.CodeBlock]

  @doc "The page, built once per code version (see `DataPages.all/0`)."
  def all do
    key = {__MODULE__, Enum.map(@sources, & &1.module_info(:md5))}

    case :persistent_term.get(key, nil) do
      nil ->
        pages = [code_block()]
        :persistent_term.put(key, pages)
        pages

      pages ->
        pages
    end
  end

  # ---------------------------------------------------------------------------
  # Fixed, made-up data
  # ---------------------------------------------------------------------------

  @payload ~S"""
  {
    "event": "order.paid",
    "id": "evt_8f2c41",
    "created_at": "2026-10-24T14:02:11Z",
    "data": {
      "order": "#1042",
      "customer": "Blue Harbor Inn",
      "total": "1240.00",
      "currency": "USD"
    }
  }
  """

  @rows ~S"""
  pat.lee@blueharbor.example,Pat,Lee,Sales
  sam.okafor@maple.example,Sam,Okafor,Support
  jordan.diaz@summit,Jordan,Diaz,Sales
  riley.chen@lakeside.example,Riley,Chen,
  morgan.ito@copper.example,Morgan,Ito,Billing
  """

  @change [
    ~s({),
    {:removed, ~s(  "status": "open",)},
    {:added, ~s(  "status": "paid",)},
    {:removed, ~s(  "paid_at": null,)},
    {:added, ~s(  "paid_at": "2026-10-24T14:02:11Z",)},
    ~s(  "total": "1240.00"),
    ~s(})
  ]

  @log ~S"""
  2026-10-24 14:02:09 INFO  sync started: 3 integrations, 1,204 records queued since the last successful run at 13:47:02
  2026-10-24 14:02:10 INFO  accounting: pushed 48 invoices (12 created, 36 updated) in 1.4s
  2026-10-24 14:02:11 WARN  accounting: invoice #4471 skipped - customer "Maple & Co." has no tax region; set one and the next sync picks it up
  2026-10-24 14:02:12 INFO  shipping: 112 labels fetched, 3 tracking numbers changed since the last sync
  2026-10-24 14:02:14 ERROR crm: POST https://api.example.com/v2/contacts returned 429 Too Many Requests; retrying in 30s (attempt 2 of 5)
  2026-10-24 14:02:44 INFO  crm: 87 contacts updated after the retry
  2026-10-24 14:02:45 INFO  sync finished in 36s: 1,201 records synced, 1 skipped, 2 retried
  """

  @trace ~S"""
  ** (Ecto.InvalidChangesetError) could not perform insert because changeset is invalid.

  Errors

      %{email: [{"has already been taken", [constraint: :unique]}]}

      (ecto 3.13.2) lib/ecto/repo/schema.ex:1114: Ecto.Repo.Schema.insert!/4
      (my_app 0.1.0) lib/my_app/imports/people.ex:58: MyApp.Imports.People.insert_row/2
  """

  @response ~S"""
  <html>
  <head><title>502 Bad Gateway</title></head>
  <body>
  <center><h1>502 Bad Gateway</h1></center>
  </body>
  </html>
  """

  # ---------------------------------------------------------------------------
  # The page
  # ---------------------------------------------------------------------------

  defp code_block do
    %{
      slug: "code-block",
      title: "Code Block",
      description:
        "Code, logs, payloads and diffs in a monospaced block with an optional header, line numbers and a copy button.",
      hook: true,
      guidance: %{
        use_when: [
          "Text people read or copy exactly: a webhook or API payload, an integration log, an import error report",
          "A before/after change in a record's history - lines with :removed / :added",
          "Code in an AI chat reply - size=\"sm\" inside the message"
        ],
        avoid_when: [
          "A short value inside a sentence - use inline code: <code class=\"rounded bg-muted px-1.5 py-0.5 font-mono text-sm\">",
          "Data people scan, sort or compare - use a table or a list",
          "Text people edit - use a textarea"
        ],
        sizing:
          "Default: text-sm monospace (line-height 1.625) with 16px padding in a 1px rounded-lg border. size=\"sm\": text-xs with 12px padding, for output inside a card, a sheet or a chat reply. Cap long output with content_class (e.g. max-h-72) so it scrolls inside the block.",
        responsive:
          "Long lines scroll sideways inside the block, never the page, and the edges fade while there is more to see; wrap logs and prose-like output instead. The header title truncates. Without a header the copy button floats at the top end, always visible on touch screens.",
        ios:
          "Monospaced Text in a ScrollView with .textSelection(.enabled), and a copy button that writes UIPasteboard and announces \"Copied\"."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "code", type: "string (split into lines, HTML-escaped)", default: "nil"},
        %{
          name: "lines",
          type:
            "[string | {variant, text} | Phoenix.HTML.raw/1] - variant: added | removed | highlighted",
          default: "[]"
        },
        %{name: "title", type: "string (filename or label)", default: "nil"},
        %{name: "icon", type: "string (heroicon class)", default: "nil"},
        %{name: "label", type: "string (names the scroll region)", default: "title, or \"Code\""},
        %{name: "variant", type: "default | destructive", default: "default"},
        %{name: "size", type: "default | sm", default: "default"},
        %{name: "line_numbers", type: "boolean", default: "false"},
        %{name: "start_line", type: "integer", default: "1"},
        %{name: "highlight", type: "[integer | Range] (line numbers)", default: "[]"},
        %{name: "wrap", type: "boolean", default: "false"},
        %{name: "copy", type: "boolean", default: "true"},
        %{name: "copy_text", type: "string (what Copy copies)", default: "the lines' text"},
        %{name: "copy_label / copied_label", type: "string", default: ~s("Copy" / "Copied")},
        %{
          name: "content_class",
          type: "any (on the scroll region, e.g. max-h-72)",
          default: "nil"
        },
        %{name: "class", type: "any", default: "nil"},
        %{
          name: ":actions",
          type: "slot (buttons before Copy, class code-block-action)",
          default: "-"
        },
        %{name: ":footer", type: "slot (a row under the code)", default: "-"}
      ],
      notes:
        "Rendered on the server with no syntax highlighting: the text is escaped and shown in the theme's monospace font. For colour, highlight on the server and pass one Phoenix.HTML.raw/1 fragment per line (e.g. Makeup.highlight_inner_html/1 on each line) with your own token CSS. Build lines in Elixir: a literal { inside a HEEx attribute opens an expression. Copy copies every line's plain text (no numbers, no markers) or copy_text, then shows a check for 2s, announces \"Copied\" and dispatches code-block:copied. Line numbers and diff markers are CSS generated content, so selecting the code never picks them up. Extra header buttons use class=\"code-block-action\" (aria-pressed for a toggle such as wrap).",
      specs: %{
        anatomy: [
          %{
            part: "Block",
            description:
              "The bordered surface; data-variant and data-size set its tone and scale."
          },
          %{
            part: "Header (optional)",
            description:
              "The title (filename or label, optional icon, truncates) and the actions."
          },
          %{
            part: "Actions",
            description:
              "Copy plus any :actions buttons; without a header they float at the top end."
          },
          %{
            part: "Content",
            description:
              "The <pre> scroll region: one span per line, a gutter of numbers, + / − markers."
          },
          %{part: "Footer (optional)", description: "A row under the code: Show more, Download."}
        ],
        measurements: [
          %{
            property: "Block",
            value:
              "1px var(--input) border, var(--radius-lg); transparent (dark: input at 30%); destructive: destructive/30 border, destructive text"
          },
          %{
            property: "Text",
            value: "0.875rem monospace, line-height 1.625 (sm: 0.75rem)"
          },
          %{
            property: "Padding",
            value:
              "1rem; 0.5rem between header and code, code and footer (sm: 0.75rem, 0.375rem under the header)"
          },
          %{
            property: "Header",
            value:
              "title 0.875rem / 500 (sm 0.75rem), 1rem icon with a 6px gap (sm 0.875rem), 8px gap to the actions"
          },
          %{
            property: "Copy button",
            value: "1.5rem ghost icon button, 0.875rem icon, 44px hit area on touch"
          },
          %{
            property: "Floating actions",
            value:
              "0.75rem from the top and end (sm 0.5rem), on var(--background) with a 1px foreground/10 ring"
          },
          %{
            property: "Gutter",
            value: "right-aligned numbers, min 1.5rem, 0.75rem from the text, muted-foreground"
          },
          %{
            property: "Diff lines",
            value:
              "added: var(--muted) + \"+\"; removed: destructive/10 + \"−\" in destructive; highlighted: var(--muted)"
          },
          %{
            property: "Edge fade",
            value:
              "min(12%, 2.5rem), over the first and last 6rem of scroll, only while there is more"
          },
          %{property: "Focus", value: "3px ring around the block, var(--ring) border"}
        ],
        tokens: [
          "input",
          "foreground",
          "muted",
          "muted-foreground",
          "destructive",
          "background",
          "ring"
        ]
      },
      accessibility: %{
        roles:
          "The code is a <pre role=\"region\" tabindex=\"0\" dir=\"ltr\"> named by the title (aria-labelledby) or label (default \"Code\"). Copy is a <button> labelled \"Copy\" (then \"Copied\"); its icons are aria-hidden; a polite live region announces \"Copied\".",
        keyboard: [
          %{keys: "Tab", action: "Moves to the copy button (and any actions), then the code"},
          %{keys: "Arrow keys / Page Up / Page Down", action: "Scroll the focused code"},
          %{keys: "Enter / Space", action: "Copy, on the copy button"}
        ],
        focus:
          "The focused code region rings the whole block (3px ring, ring-coloured border). Floating actions appear while focus is inside the block.",
        screen_reader:
          "Line numbers are silent (CSS alt text \"\"); diff markers read \"Added\" / \"Removed\" (set --code-block-added-label / --code-block-removed-label to translate). Highlighted lines are visual only: say why in the text around the block (\"Row 42 has no email domain\").",
        touch_target:
          "The 24px copy button has a 44px hit area on touch screens, where floating actions stay visible.",
        reduced_motion:
          "The floating actions' 150ms fade is dropped; the edge fade follows the scroll position, not time."
      },
      swiftui: %{
        code: ~S"""
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
        """,
        notes:
          "Monospaced Text in a ScrollView (horizontal; [.horizontal, .vertical] with a maxHeight for a long log), .textSelection(.enabled) so people can select part of it, and a copy button that writes UIPasteboard and announces \"Copied\". For a diff, one HStack per line in a LazyVStack: a +/− Text with .accessibilityLabel(\"Added\" / \"Removed\") and a tinted .background. ShareLink suits a long log better than copy."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Payload with a filename",
          heex: ~S"""
          <.code_block id="webhook-payload" title="payload.json" icon="hero-document-text" code={@payload} />
          """,
          center: false,
          code: payload_code()
        },
        %{
          title: "Line numbers",
          heex: ~S"""
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
          """,
          center: false,
          code: rows_code()
        },
        %{
          title: "Diff",
          heex: ~S"""
          <%!-- In the LiveView (a literal { inside a HEEx attribute would open an expression):
            change = [~s({), {:removed, ~s(  "status": "open",)}, {:added, ~s(  "status": "paid",)}, ..., ~s(})] --%>
          <.code_block id="order-change" title="Order #1042 · status changed" icon="hero-clock" lines={@change} />
          """,
          center: false,
          code: diff_code()
        },
        %{
          title: "Wrapped log output",
          heex: ~S"""
          <.code_block id="sync-log" title="Sync log" icon="hero-command-line" code={@log} wrap content_class="max-h-56">
            <:footer>
              <span class="text-xs">Showing the last 7 of 1,204 lines</span>
              <a href={~p"/integrations/sync/log"} class="btn btn-ghost btn-xs ml-auto">Download full log</a>
            </:footer>
          </.code_block>
          """,
          center: false,
          code: log_code()
        },
        %{
          title: "Error output",
          heex: ~S"""
          <.code_block
            id="import-error"
            variant="destructive"
            title="Import failed"
            icon="hero-exclamation-triangle"
            code={@trace}
          />
          """,
          center: false,
          code: trace_code()
        },
        %{
          title: "Small, inside a card",
          heex: ~S"""
          <.card>
            <.card_body>
              <.card_title>Last delivery</.card_title>
              <.card_description>POST https://hooks.example.com/orders · 502 Bad Gateway · 2 min ago</.card_description>
              <.code_block id="delivery-response" size="sm" title="Response body" code={@response} class="mt-4" />
            </.card_body>
          </.card>
          """,
          center: false,
          code: card_code()
        }
      ]
    }
  end

  # The component's markup without LiveView-only attributes.
  defp code(rendered),
    do: rendered |> DataPages.code() |> String.replace(~s( phx-update="ignore"), "")

  defp payload_code do
    assigns = %{payload: @payload}

    code(~H"""
    <.code_block id="webhook-payload" title="payload.json" icon="hero-document-text" code={@payload} />
    """)
  end

  defp rows_code do
    assigns = %{rows: @rows}

    code(~H"""
    <div class="flex w-full flex-col gap-3">
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
    </div>
    """)
  end

  defp diff_code do
    assigns = %{change: @change}

    code(~H"""
    <.code_block
      id="order-change"
      title="Order #1042 · status changed"
      icon="hero-clock"
      lines={@change}
    />
    """)
  end

  defp log_code do
    assigns = %{log: @log}

    code(~H"""
    <.code_block
      id="sync-log"
      title="Sync log"
      icon="hero-command-line"
      code={@log}
      wrap
      content_class="max-h-56"
    >
      <:footer>
        <span class="text-xs">Showing the last 7 of 1,204 lines</span>
        <a href="#sync-log" class="btn btn-ghost btn-xs ml-auto">Download full log</a>
      </:footer>
    </.code_block>
    """)
  end

  defp trace_code do
    assigns = %{trace: @trace}

    code(~H"""
    <.code_block
      id="import-error"
      variant="destructive"
      title="Import failed"
      icon="hero-exclamation-triangle"
      code={@trace}
    />
    """)
  end

  defp card_code do
    assigns = %{response: @response}

    code(~H"""
    <.card class="w-full max-w-lg">
      <.card_body>
        <.card_title>Last delivery</.card_title>
        <.card_description>
          POST https://hooks.example.com/orders · 502 Bad Gateway · 2 min ago
        </.card_description>
        <.code_block
          id="delivery-response"
          size="sm"
          title="Response body"
          code={@response}
          class="mt-4"
        />
      </.card_body>
    </.card>
    """)
  end
end
