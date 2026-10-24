defmodule ShadcnDaisyuiDemoWeb.Catalog.ChatPages do
  @moduledoc """
  Catalog pages for the AI chat parts: `<.message_scroller>`, `<.trace>`
  and `<.prompt_input>`, in the Conversation group. Their design metadata
  (specs, accessibility, SwiftUI) is inline here.

  As in `Catalog.DataPages`, each example's `code` is rendered from the real
  component (`~H` + `DataPages.code/1`: the LiveView-only attributes
  stripped, re-indented), so the code tab is the markup the component
  renders today and the preview runs on `initShadcnDaisyui()`. The docs
  site's `app.js` stands in for the server in two previews: the chat
  preview's form answers with a made-up streaming reply, and the composer
  previews say what they would send.

  Built once per code version (see `all/0`).
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components.Conversation
  import ShadcnDaisyui.Components.CodeBlock, only: [code_block: 1]
  import ShadcnDaisyui.CoreComponents, only: [button: 1]

  alias ShadcnDaisyuiDemoWeb.Catalog.DataPages

  @sources [
    __MODULE__,
    DataPages,
    ShadcnDaisyui.Components.Conversation,
    ShadcnDaisyui.Components.CodeBlock,
    ShadcnDaisyui.Components.Display,
    ShadcnDaisyui.FormComponents,
    ShadcnDaisyui.CoreComponents
  ]

  @doc "The three pages, cached in `:persistent_term` per code version."
  def all do
    key = {__MODULE__, Enum.map(@sources, & &1.module_info(:md5))}

    case :persistent_term.get(key, nil) do
      nil ->
        pages = [message_scroller(), trace(), prompt_input()]
        :persistent_term.put(key, pages)
        pages

      pages ->
        pages
    end
  end

  # ---------------------------------------------------------------------------
  # Fixed, made-up conversation
  # ---------------------------------------------------------------------------

  @turns [
    {"Which orders are overdue?",
     "Four orders are overdue, $6,104.80 in all. The oldest is #1034 for Riverside Dental."},
    {"Who handles Riverside Dental?",
     "Pat Lee does. They've paid within a week of a reminder every time this year."},
    {"Draft a reminder for them.",
     "Here's a draft: \"Hi, a quick reminder that invoice #1034 for $1,512.80 was due on Oct 9. You can pay it from the link below. Thanks!\""},
    {"Make it a little warmer.",
     "\"Hi Dana, hope the week's going well. Just a friendly nudge that invoice #1034 ($1,512.80) was due on Oct 9 - the payment link is below. Thank you!\""}
  ]

  defp messages(turns) do
    turns
    |> Enum.with_index()
    |> Enum.flat_map(fn {{q, a}, i} ->
      [%{id: 2 * i + 1, user?: true, text: q}, %{id: 2 * i + 2, user?: false, text: a}]
    end)
  end

  attr(:m, :map, required: true)

  defp row(%{m: %{user?: true}} = assigns) do
    ~H"""
    <.message align="end">
      <.bubble>{@m.text}</.bubble>
    </.message>
    """
  end

  defp row(assigns) do
    ~H"""
    <.message>
      <:header>Assistant</:header>
      <.bubble variant="ghost">{@m.text}</.bubble>
    </.message>
    """
  end

  # an upload snapshot for the composer's attachments example
  defp demo_upload(entries) do
    %Phoenix.LiveView.UploadConfig{
      name: :files,
      ref: "phx-demo-files",
      accept: "image/*,.pdf",
      max_entries: 3,
      max_file_size: 8_000_000,
      entries: entries,
      auto_upload?: true
    }
  end

  defp demo_entry(ref, name, size, type, opts) do
    struct!(
      Phoenix.LiveView.UploadEntry,
      [
        ref: ref,
        upload_ref: "phx-demo-files",
        client_name: name,
        client_size: size,
        client_type: type,
        valid?: true
      ] ++ opts
    )
  end

  # a LiveView upload's markup, as a snapshot: its LiveView wiring is dropped
  defp upload_code(rendered) do
    rendered
    |> DataPages.code()
    |> String.replace(~r/ (?:data-phx-[a-z-]+|phx-drop-target)="[^"]*"/, "")
  end

  # ---------------------------------------------------------------------------
  # Message scroller
  # ---------------------------------------------------------------------------

  defp message_scroller do
    %{
      slug: "message-scroller",
      title: "Message Scroller",
      description:
        "The scrolling transcript of a chat: opens at the latest message, follows a streaming reply while you're at the bottom, and keeps your place when older messages load.",
      hook: true,
      guidance: %{
        use_when: [
          "Every chat or AI-assistant transcript: messages in, a reply streaming",
          "Support threads and comment streams that grow at the bottom"
        ],
        avoid_when: [
          "A short, finished exchange on a record page - a <.message_group> needs no scroller",
          "Lists you sort or filter - use <.data_table>",
          "A hand-rolled overflow-y-auto div with scrollTop code - this is the one transcript scroller"
        ],
        sizing:
          "Fills its parent: give the parent a height (in <.app_shell fill> it takes the space between the page header and the composer). 32px between rows; the scroll button is 36px, centred 16px from the bottom.",
        responsive:
          "The same at every width; the rows decide their own layout. On phones the composer sits under it and the dock under that.",
        ios:
          "A ScrollView over a LazyVStack with .defaultScrollAnchor(.bottom); .scrollPosition(id:) keeps your place and jumps."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "items", type: "list | LiveView stream (required)", default: "-"},
        %{name: "item_id", type: "fn item -> dom id", default: "stream ids / \"id-item.id\""},
        %{name: "anchor", type: "fn item -> boolean (turn anchors)", default: "nil"},
        %{name: "busy", type: "boolean (aria-busy while a reply streams)", default: "false"},
        %{name: "default_position", type: "end | start | last-anchor", default: "end"},
        %{name: "follow", type: "boolean", default: "true"},
        %{name: "peek", type: "px of the previous row above a new anchor", default: "64"},
        %{name: "label", type: "string (the viewport's name)", default: "Messages"},
        %{name: "button", type: "end | start | both | none", default: "end"},
        %{name: ":let={item}", type: "inner block: one row", default: "-"},
        %{name: ":above / :below", type: "slots inside the log", default: "-"}
      ],
      notes:
        "shadcn/ui's Message Scroller. The ShadcnMessageScroller hook opens it at default_position (hidden until it's there, so it never flashes the top), follows growing content only while you're at the live edge (a wheel, touch, a scroll key or the scrollbar lets go; scrolling back down or the button picks it up again), moves a new anchored turn near the top with 64px of the row above still showing (and makes room under it for the reply), and keeps the row you're reading in place when rows are added above (a stream insert at: 0). It waits for a size, so it works in a sheet that opens later. Dispatch shadcn:scroll-to with detail: %{to: \"end\" | \"start\" | row_dom_id} to jump.",
      specs: %{
        anatomy: [
          %{part: "Frame", description: "Fills its parent; holds the viewport and the buttons."},
          %{
            part: "Viewport",
            description: "role=region, labelled, tabindex 0: the one scroll region."
          },
          %{part: "Log", description: "role=log, aria-relevant=additions, aria-busy."},
          %{part: "Row", description: "One per message, keyed by id; anchors mark turns."},
          %{part: "Above / below", description: "A load-earlier button, a typing marker."},
          %{part: "Scroll button", description: "Outline icon button; inert when inactive."}
        ],
        measurements: [
          %{property: "Row gap", value: "2rem (gap-8)"},
          %{property: "Scrollbar", value: "thin, stable gutter, overscroll contained"},
          %{property: "Bottom fade", value: "last 2rem while there is more below"},
          %{property: "Anchor peek", value: "64px of the row above a new turn"},
          %{property: "Scroll button", value: "36px, 1rem from the edge, centred"},
          %{
            property: "Button motion",
            value: "in: 200ms ease-out; out: 400ms ease-in, 95%, slid its own height"
          }
        ],
        tokens: ["background", "border-color", "foreground", "muted", "ring"]
      },
      accessibility: %{
        roles:
          "The viewport is a labelled region (\"Messages\", or label) and a tab stop, so the keyboard can scroll it. The rows are in a role=log live region with aria-relevant=additions: new messages are announced once; aria-busy holds the announcement of a streaming reply until it's done.",
        keyboard: [
          %{keys: "Tab", action: "Focus the transcript (the ring shows inside it)"},
          %{keys: "↑ ↓ / Page Up / Page Down", action: "Scroll; scrolling up stops following"},
          %{keys: "Home / End", action: "First / latest message"},
          %{keys: "Enter / Space", action: "On the scroll button: go to the latest message"}
        ],
        focus:
          "The scroll button is inert and out of the tab order while there's nothing below; if it had focus when it went away, focus returns to the transcript.",
        screen_reader:
          "Each new message is read once; a streaming reply is read when aria-busy turns false. The button's name is \"Scroll to latest message\".",
        touch_target:
          "The scroll button is 36px; a touch on the transcript never gets yanked back to the bottom while the finger is down.",
        reduced_motion:
          "Jumps (the button, a new turn) are instant instead of smooth, and the button appears without sliding."
      },
      swiftui: %{
        code: ~S"""
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 32) {
                    ForEach(messages) { message in
                        MessageRow(message).id(message.id)
                    }
                    if assistant.busy { StepList(steps: assistant.steps) }
                }
                .scrollTargetLayout()
            }
            .defaultScrollAnchor(.bottom)            // open at the newest message
            .scrollPosition(id: $visibleID, anchor: .top)  // keeps your place as history loads
            .onChange(of: messages.last?.id) { _, id in
                guard let id, messages.last?.isMine == true else { return }
                withAnimation(.smooth) { proxy.scrollTo(id, anchor: .top) }  // a new question to the top
            }
        }
        """,
        notes:
          "Keep the transcript bottom-anchored with .defaultScrollAnchor(.bottom): new messages and the working step list stay in view while you're at the bottom. Scroll a question you just sent to the top. Load history above with .scrollPosition(id:) so the visible message stays put, and post an accessibility announcement when a reply finishes."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Default",
          center: true,
          heex: ~S"""
          <%!-- in a parent with a height: <.app_shell fill>, a sheet, a card --%>
          <.message_scroller
            id="chat"
            items={@streams.messages}
            anchor={fn {_id, m} -> m.role == :user end}
            busy={@streaming?}
            :let={{_id, m}}
          >
            <.message :if={m.role == :user} align="end"><.bubble>{m.text}</.bubble></.message>
            <.message :if={m.role == :assistant}>
              <:header>Assistant</:header>
              <.bubble variant="ghost">{m.text}</.bubble>
            </.message>
          </.message_scroller>
          """,
          code: scroller_default_code()
        },
        %{
          title: "Opening at the last turn",
          center: true,
          heex: ~S"""
          <%!-- a saved thread: the last question at the top, its answer under it --%>
          <.message_scroller
            id="thread"
            items={@streams.messages}
            anchor={fn {_id, m} -> m.role == :user end}
            default_position="last-anchor"
            button="both"
            :let={{_id, m}}
          >
            …
          </.message_scroller>
          """,
          code: scroller_last_anchor_code()
        },
        %{
          title: "Streaming",
          center: true,
          heex: ~S"""
          <.message_scroller id="chat" items={@streams.messages} anchor={…} busy={@reply != nil} :let={{_id, m}}>
            <:above :if={@older != []}>
              <.button variant="ghost" size="sm" phx-click="load-earlier">Load earlier messages</.button>
            </:above>
            …
          </.message_scroller>
          <.form for={@form} id="chat-form" phx-change="validate" phx-submit="send">
            <.prompt_input id="composer" field={@form[:text]} busy={@reply != nil} on_stop="stop" />
          </.form>

          def handle_event("send", %{"prompt" => %{"text" => text}}, socket) do
            question = %{id: Ecto.UUID.generate(), role: :user, text: text}
            reply = %{id: Ecto.UUID.generate(), role: :assistant, text: ""}
            lv = self()

            {:noreply,
             socket
             |> stream_insert(:messages, question)   # an anchor: it moves to the top
             |> stream_insert(:messages, reply)
             |> assign(reply: reply, form: to_form(%{"text" => ""}, as: :prompt))
             |> start_async(:reply, fn ->
               Assistant.stream(text, fn chunk -> send(lv, {:chunk, reply.id, chunk}) end)
             end)}
          end

          def handle_info({:chunk, id, chunk}, %{assigns: %{reply: %{id: id} = reply}} = socket) do
            reply = %{reply | text: reply.text <> chunk}
            {:noreply, socket |> assign(reply: reply) |> stream_insert(:messages, reply)}
          end

          def handle_info({:chunk, _id, _chunk}, socket), do: {:noreply, socket}  # after Stop

          def handle_event("load-earlier", _params, socket) do
            {older, page} = Enum.split(socket.assigns.older, -20)
            {:noreply, socket |> assign(older: older) |> stream(:messages, Enum.reverse(page), at: 0)}
          end
          """,
          code: scroller_streaming_code()
        }
      ]
    }
  end

  defp scroller_default_code do
    assigns = %{messages: messages(@turns)}

    DataPages.code(~H"""
    <div class="card h-96 w-full max-w-md overflow-hidden">
      <.message_scroller
        :let={m}
        id="scroller-demo"
        items={@messages}
        anchor={& &1.user?}
        content_class="p-4"
      >
        <.row m={m} />
      </.message_scroller>
    </div>
    """)
  end

  defp scroller_last_anchor_code do
    long =
      "Here's where the four overdue orders stand. Riverside Dental (#1034, $1,512.80) is the oldest; Pat Lee sent a reminder on Oct 16 and they usually pay within a week. Summit Outfitters (#1040, $2,075.00) is next: Jordan Diaz is waiting on a purchase order number from them. Hillcrest Motors (#1025, $1,630.00) asked for a copy of the invoice, which went out yesterday. Copper Kettle (#1021, $887.00) has been quiet; a call might work better than another email. If you'd like, I can draft the reminder for Copper Kettle, or put all four in a list for Monday's meeting."

    assigns = %{
      messages:
        messages(Enum.take(@turns, 2)) ++
          [
            %{id: 5, user?: true, text: "Where do the overdue ones stand?"},
            %{id: 6, user?: false, text: long}
          ]
    }

    DataPages.code(~H"""
    <div class="card h-80 w-full max-w-md overflow-hidden">
      <.message_scroller
        :let={m}
        id="thread-demo"
        items={@messages}
        anchor={& &1.user?}
        default_position="last-anchor"
        button="both"
        content_class="p-4"
      >
        <.row m={m} />
      </.message_scroller>
    </div>
    """)
  end

  defp scroller_streaming_code do
    assigns = %{messages: messages(Enum.take(@turns, 2))}

    DataPages.code(~H"""
    <div class="card h-[28rem] w-full max-w-md gap-3 overflow-hidden p-4">
      <.message_scroller
        :let={m}
        id="stream-demo"
        items={@messages}
        anchor={& &1.user?}
      >
        <:above>
          <div class="flex justify-center">
            <.button variant="ghost" size="sm" data-demo-chat-earlier="stream-demo">
              Load earlier messages
            </.button>
          </div>
        </:above>
        <.row m={m} />
      </.message_scroller>
      <form data-demo-chat="stream-demo">
        <.prompt_input id="stream-demo-composer" name="text" placeholder="Ask anything…" />
      </form>
    </div>
    """)
  end

  # ---------------------------------------------------------------------------
  # Trace
  # ---------------------------------------------------------------------------

  defp trace do
    %{
      slug: "trace",
      title: "Trace",
      description:
        "What an assistant did or is doing: steps, tool calls, sources and plans, one row each, that open to show the detail.",
      guidance: %{
        use_when: [
          "An assistant's working steps while it answers (a sparkle on the current one, a check on the done ones)",
          "Tool calls with their input and output, the sources an answer used, a plan's steps",
          "A finished turn: one \"Worked through 4 steps\" row that opens to the steps"
        ],
        avoid_when: [
          "A bare spinner or \"Thinking…\" that hides the real work - show the steps",
          "Filler steps that aren't real work - every row is something the assistant did",
          "An activity feed or audit log - use <.table_card> or <.item> rows",
          "A wizard's progress - use the steps recipe"
        ],
        sizing:
          "Rows 8px apart, text-sm muted, 16px icons, 8px between icon and title. Detail is indented 7px with a 1px line on its left and 16px of padding.",
        responsive:
          "Titles truncate to one line at any width; descriptions (a duration, a count) never do. Detail wraps.",
        ios:
          "A VStack of HStacks: an SF Symbol (checkmark, or sparkles with .symbolEffect(.variableColor.iterative) while running) and the text; a DisclosureGroup for rows with detail."
      },
      props: [
        %{
          name: ":line",
          type: "slot: status icon description href navigate patch target",
          default: "-"
        },
        %{name: "status", type: "running | pending | error (done when unset)", default: "nil"},
        %{name: "icon", type: "heroicon name", default: "nil"},
        %{name: "description", type: "short text after the title", default: "nil"},
        %{name: "trace_line", type: "a row with slots (inner block of <.trace>)", default: "-"},
        %{name: "trace_line id", type: "string (required with :detail)", default: "nil"},
        %{name: "trace_line open", type: "boolean (how it starts)", default: "false"},
        %{name: ":icon :description :detail", type: "trace_line slots", default: "-"}
      ],
      notes:
        "shadcn/ui's Trace. Done rows are muted, a running row's title shimmers (and its glyph pulses, as a working sparkle), pending rows are dimmed, errors are destructive - so the title has to say it too (\"Running mix test\", \"Failed to send\"). A row with <:detail> is a disclosure button (aria-expanded, a chevron) and needs an id; rows nest. One delegated listener toggles it (no hook), and the reader's choice survives LiveView patches.",
      specs: %{
        anatomy: [
          %{part: "Trace", description: "A list of rows, 8px apart."},
          %{part: "Icon", description: "16px glyph, spinner or favicon; hidden from readers."},
          %{part: "Title", description: "One line, truncated; shimmers while running."},
          %{part: "Description", description: "70% muted, tabular figures; never truncates."},
          %{part: "Disclosure", description: "The row as a button with a chevron (90° open)."},
          %{part: "Detail", description: "Indented, 1px line on its left; rows nest."}
        ],
        measurements: [
          %{property: "Row", value: "text-sm, muted-foreground, gap 0.5rem"},
          %{property: "Icon", value: "1rem"},
          %{property: "Rows apart", value: "0.5rem"},
          %{property: "Detail", value: "margin 0.5rem 0 0.25rem 7px, padding-left 1rem"},
          %{property: "Open / close", value: "grid rows 0fr → 1fr + opacity, 180ms ease-out"},
          %{property: "Pending", value: "opacity 0.6"}
        ],
        tokens: ["muted-foreground", "foreground", "destructive", "border-color", "ring"]
      },
      accessibility: %{
        roles:
          "A list; each row a list item. A plain row is text (not a tab stop); a source is a link; a row with detail is a button with aria-expanded and aria-controls naming its detail. Icons are aria-hidden, so the title is the name.",
        keyboard: [
          %{keys: "Tab", action: "Move between link and disclosure rows"},
          %{keys: "Enter / Space", action: "Open or close a row's detail; follow a link"}
        ],
        focus:
          "Links and disclosure buttons take the 3px ring for the keyboard. Closed detail is hidden (visibility), so its links are out of the tab order.",
        screen_reader:
          "Status is shown by colour and motion only: word the title to say it. A new-tab link adds \"(opens in a new tab)\". In a message scroller each new row is announced once.",
        touch_target:
          "Disclosure rows are the row's own width; in touch-first layouts leave 8px around them or use a larger text size so the line is at least 24px tall.",
        reduced_motion:
          "No shimmer, no pulse, no chevron turn or open animation; the title still says what's happening."
      },
      swiftui: %{
        code: ~S"""
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
        """,
        notes:
          "While the assistant works, show what it is actually doing - one row per real step, a check when it's done and a moving sparkle on the current one - instead of a spinner. Under the answer, say where it came from (\"From the customer file and the conversation.\"). Rows with detail are a DisclosureGroup; .symbolEffect stops under Reduce Motion."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Steps",
          heex: ~S"""
          <.trace>
            <:line :for={s <- @steps} status={s.status} icon={if s.status == "running", do: "hero-sparkles", else: "hero-check"}>
              {s.text}
            </:line>
          </.trace>
          """,
          code: trace_steps_code()
        },
        %{
          title: "Tool calls",
          heex: ~S"""
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
          """,
          code: trace_tools_code()
        },
        %{
          title: "Tool output",
          heex: ~S"""
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
          """,
          code: trace_output_code()
        },
        %{
          title: "Sources",
          heex: ~S"""
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
          """,
          code: trace_sources_code()
        },
        %{
          title: "Plan",
          heex: ~S"""
          <.trace>
            <:line icon="hero-check-circle">Find the overdue orders</:line>
            <:line status="running" description="2 of 4">Draft a reminder for each</:line>
            <:line status="pending" icon="hero-clock">Send them from Pat's address</:line>
          </.trace>
          """,
          code: trace_plan_code()
        },
        %{
          title: "Whole turn",
          heex: ~S"""
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
          """,
          code: trace_turn_code()
        }
      ]
    }
  end

  defp trace_steps_code do
    assigns = %{}

    DataPages.code(~H"""
    <div class="w-full max-w-sm">
      <.trace>
        <:line icon="hero-check">Searched 240 orders</:line>
        <:line icon="hero-check" description="4 found">Checked the overdue invoices</:line>
        <:line status="running" icon="hero-sparkles">Reading Riverside Dental's file</:line>
      </.trace>
    </div>
    """)
  end

  defp trace_tools_code do
    assigns = %{}

    DataPages.code(~H"""
    <div class="w-full max-w-sm">
      <.trace>
        <.trace_line id="tool-search" open>
          <:icon><span class="hero-magnifying-glass"></span></:icon>
          Searched orders for "overdue"
          <:description>0.4s</:description>
          <:detail>
            <.trace>
              <:line icon="hero-document-text" description="$1,512.80">#1034 Riverside Dental</:line>
              <:line icon="hero-document-text" description="$2,075.00">#1040 Summit Outfitters</:line>
            </.trace>
          </:detail>
        </.trace_line>
        <.trace_line id="tool-total">
          <:icon><span class="hero-calculator"></span></:icon>
          Added up the amounts
          <:description>$6,104.80</:description>
          <:detail>4 invoices, oldest due Oct 9.</:detail>
        </.trace_line>
        <.trace_line id="tool-send" status="error">
          <:icon><span class="hero-envelope"></span></:icon>
          Failed to send the reminder
          <:detail>The mail server refused the message: the address bounced last week.</:detail>
        </.trace_line>
      </.trace>
    </div>
    """)
  end

  @api_response """
  {
    "invoices": [
      { "number": 1034, "customer": "Riverside Dental", "due": "2026-10-09", "total": "1512.80" },
      { "number": 1040, "customer": "Summit Outfitters", "due": "2026-10-14", "total": "2075.00" }
    ],
    "count": 2
  }
  """

  defp trace_output_code do
    assigns = %{
      response: @api_response,
      error:
        "550 5.1.1 <billing@riverside-dental.example>: Recipient address rejected: mailbox unavailable (bounced Oct 17)"
    }

    DataPages.code(~H"""
    <div class="w-full max-w-md">
      <.trace>
        <.trace_line id="call-api" open>
          <:icon><span class="hero-command-line"></span></:icon>
          Called the accounting API
          <:description>0.8s</:description>
          <:detail>
            <.code_block
              id="call-api-output"
              size="sm"
              title="GET /v2/invoices?status=overdue"
              code={@response}
              content_class="max-h-48"
            />
          </:detail>
        </.trace_line>
        <.trace_line id="call-mail" status="error">
          <:icon><span class="hero-envelope"></span></:icon>
          Failed to send the reminder
          <:detail>
            <.code_block
              id="call-mail-output"
              size="sm"
              variant="destructive"
              title="SMTP 550"
              code={@error}
              wrap
            />
          </:detail>
        </.trace_line>
      </.trace>
    </div>
    """)
  end

  defp trace_sources_code do
    assigns = %{}

    DataPages.code(~H"""
    <div class="w-full max-w-md">
      <.message>
        <:header>Assistant</:header>
        <.trace>
          <.trace_line id="sources-demo">
            <:icon><span class="hero-book-open"></span></:icon>
            Used 3 sources
            <:detail>
              <.trace>
                <:line icon="hero-document-text" href="#">Order #1034</:line>
                <:line icon="hero-user" href="#">Riverside Dental</:line>
                <:line icon="hero-globe-alt" href="https://example.test/terms" target="_blank">
                  Payment terms
                </:line>
              </.trace>
            </:detail>
          </.trace_line>
        </.trace>
        <.bubble variant="ghost">
          Invoice #1034 is 15 days overdue. Riverside Dental has paid within a week of a reminder every time this year.
        </.bubble>
        <:footer>From order #1034 and the customer file.</:footer>
      </.message>
    </div>
    """)
  end

  defp trace_plan_code do
    assigns = %{}

    DataPages.code(~H"""
    <div class="w-full max-w-sm">
      <.trace>
        <:line icon="hero-check-circle">Find the overdue orders</:line>
        <:line icon="hero-check-circle">Look up who handles each customer</:line>
        <.trace_line status="running">
          <:icon><span class="loading loading-spinner"></span></:icon>
          Drafting a reminder for each
          <:description>2 of 4</:description>
        </.trace_line>
        <:line status="pending" icon="hero-clock">Send them from Pat's address</:line>
      </.trace>
    </div>
    """)
  end

  defp trace_turn_code do
    assigns = %{}

    DataPages.code(~H"""
    <div class="w-full max-w-md">
      <.message_group class="gap-6">
        <.message align="end">
          <.bubble>Which orders are overdue?</.bubble>
        </.message>
        <.message>
          <:header>Assistant</:header>
          <.trace>
            <.trace_line id="turn-demo-steps">
              <:icon><span class="hero-check-circle"></span></:icon>
              Worked through 3 steps
              <:description>4s</:description>
              <:detail>
                <.trace>
                  <:line icon="hero-check">Searched 240 orders</:line>
                  <.trace_line id="turn-demo-invoices">
                    <:icon><span class="hero-check"></span></:icon>
                    Checked 4 overdue invoices
                    <:detail>#1021, #1025, #1034, #1040</:detail>
                  </.trace_line>
                  <:line icon="hero-check">Added up the amounts</:line>
                </.trace>
              </:detail>
            </.trace_line>
          </.trace>
          <.bubble variant="ghost">
            Four orders are overdue, $6,104.80 in all. The oldest is #1034 for Riverside Dental.
          </.bubble>
          <:footer>From the orders list.</:footer>
        </.message>
      </.message_group>
    </div>
    """)
  end

  # ---------------------------------------------------------------------------
  # Prompt input
  # ---------------------------------------------------------------------------

  defp prompt_input do
    %{
      slug: "prompt-input",
      title: "Prompt Input",
      description:
        "The chat composer: a field that grows with what you type, Send that turns into Stop while the reply streams, attachments and suggestion chips.",
      hook: true,
      guidance: %{
        use_when: [
          "The message box of any chat or AI assistant",
          "Asking an assistant from a record page (a sheet with a scroller and this under it)"
        ],
        avoid_when: [
          "Ordinary long text in a form (notes, a description) - use <.textarea>",
          "Search boxes - use <.command> or the table toolbar's search",
          "A hand-rolled textarea with an Enter handler or a Send/Stop swap - this is the one composer"
        ],
        sizing:
          "The field is shadcn's: 1px input border, rounded-md, text-sm, 8px 12px padding, at least 4rem tall, growing to 12rem before it scrolls. 36px icon buttons 8px from the edges; chips 8px apart, 12px above.",
        responsive:
          "Full width of the chat column at every width; the toolbar buttons get a 44px hit area on touch screens, and the keyboard's return key reads Send (enterkeyhint).",
        ios:
          "A TextField(axis: .vertical) with .lineLimit(1...6) and .submitLabel(.send), Send (.borderedProminent) that becomes Stop (.bordered) while busy, and capsule suggestion buttons in a flow layout above."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "field", type: "Phoenix.HTML.FormField", default: "nil"},
        %{name: "name / value", type: "instead of field", default: "nil"},
        %{name: "placeholder", type: "string", default: "nil"},
        %{name: "label", type: "string (the field's name)", default: "Message"},
        %{name: "busy", type: "boolean: the button is Stop", default: "false"},
        %{name: "on_stop", type: "event | JS", default: "\"stop\""},
        %{name: "upload", type: "Phoenix.LiveView.UploadConfig", default: "nil"},
        %{name: "on_cancel / error_text / target", type: "as <.dropzone>", default: "nil"},
        %{name: "disabled", type: "boolean", default: "false"},
        %{name: ":suggestion", type: "slot: value, send, variant, phx-click", default: "-"},
        %{name: ":tools", type: "slot: controls beside attach", default: "-"}
      ],
      notes:
        "Enter sends and Shift+Enter adds a line - never while an input method is composing (Japanese, Chinese, Korean input). Send is aria-disabled while there's nothing to send; the field clears as soon as the message is on its way (reset your form in phx-submit too). While busy the button is Stop: it pushes on_stop, and Enter waits. With upload, the paperclip is a label around the hidden live_file_input (Enter or Space opens the picker), files dropped on the field or pasted into it go to the same upload, and each one is an <.attachment> tile above the text. A suggestion chip is <.bubble as=\"button\">: its value goes in the field and is sent (send={false} only fills it). Hook: ShadcnPromptInput.",
      specs: %{
        anatomy: [
          %{part: "Suggestions", description: "Outline bubble buttons that wrap, 8px apart."},
          %{part: "Box", description: "The field's border and fill; the drop target."},
          %{part: "Attachments", description: "Attachment tiles in a row that scrolls."},
          %{part: "Text", description: "Grows with its content, 4rem to 12rem."},
          %{part: "Toolbar", description: "Attach, your tools, then Send / Stop."}
        ],
        measurements: [
          %{property: "Box", value: "1px var(--input), var(--radius-md), shadow-xs"},
          %{property: "Text", value: "text-sm, 0.5rem 0.75rem, 4rem → 12rem, then scrolls"},
          %{property: "Buttons", value: "36px icon buttons, 0.5rem from the edges"},
          %{property: "Focus ring", value: "3px var(--ring) @ 50% on the box"},
          %{property: "Drag", value: "var(--primary) border on var(--accent)"},
          %{property: "Send, nothing to send", value: "opacity 0.5 (aria-disabled)"}
        ],
        tokens: ["input", "ring", "primary", "secondary", "accent", "muted-foreground"]
      },
      accessibility: %{
        roles:
          "A textarea named by label (\"Message\"), enterkeyhint=send; Send and Stop are one button whose name changes (\"Send\" / \"Stop\"), so focus stays on it; the attach button is a label around the file input (named \"Attach files\"); suggestions are a group of buttons; attached files are a list.",
        keyboard: [
          %{keys: "Enter", action: "Send (not while composing, not while busy)"},
          %{keys: "Shift+Enter", action: "New line"},
          %{keys: "Tab", action: "Attach, your tools, Send / Stop"},
          %{keys: "Enter / Space", action: "On attach: open the file picker"}
        ],
        focus:
          "The ring is on the whole box while the text has focus. After sending, focus stays in (or returns to) the field.",
        screen_reader:
          "Send reads as dimmed (aria-disabled) while there's nothing to send. Upload errors are read from a polite live region and describe the field.",
        touch_target:
          "Toolbar buttons are 36px with a 44px hit area on touch screens; chips are text-sm bubbles at least 36px tall.",
        reduced_motion: "Only colour changes; nothing moves."
      },
      swiftui: %{
        code: ~S"""
        @State private var input = ""
        @FocusState private var focused: Bool

        VStack(spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button(s) { ask(s) }
                        .buttonStyle(.bordered).buttonBorderShape(.capsule)
                }
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask anything…", text: $input, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit { ask(input) }
                if assistant.busy {
                    Button("Stop") { assistant.stop() }.buttonStyle(.bordered)
                } else {
                    Button("Send") { ask(input) }
                        .buttonStyle(.borderedProminent)
                        .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }

        func ask(_ text: String) {
            let text = text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty, !assistant.busy else { return }
            input = ""
            Task { await assistant.ask(text) }
        }
        """,
        notes:
          "Send becomes Stop while the assistant is busy and asking waits until it's done. Clear the field as soon as a question is sent and keep the keyboard up. Suggestion chips send their text in one tap. Attach with PhotosPicker or .fileImporter and show the files as rows above the field."
      },
      ios_status: :partial,
      examples: [
        %{
          title: "Default",
          heex: ~S"""
          <.form for={@form} id="chat-form" phx-change="validate" phx-submit="send">
            <.prompt_input id="composer" field={@form[:text]} placeholder="Ask anything…" />
          </.form>

          def handle_event("send", %{"prompt" => %{"text" => text}}, socket) do
            # … start the reply, then reset the form for the next question
            {:noreply, assign(socket, form: to_form(%{"text" => ""}, as: :prompt))}
          end
          """,
          code: prompt_default_code()
        },
        %{
          title: "Suggestions",
          heex: ~S"""
          <.prompt_input id="composer" field={@form[:text]} placeholder="Ask anything…">
            <:suggestion :if={@new_chat?} value="Which orders are overdue?">Overdue orders</:suggestion>
            <:suggestion :if={@new_chat?} value="Who are our biggest customers?">Biggest customers</:suggestion>
            <:suggestion :if={@new_chat?} value="Draft a reminder to " send={false}>Draft a reminder…</:suggestion>
          </.prompt_input>
          """,
          code: prompt_suggestions_code()
        },
        %{
          title: "Busy",
          heex: ~S"""
          <%!-- while the reply streams: the button is Stop --%>
          <.prompt_input id="composer" field={@form[:text]} busy={@reply != nil} on_stop="stop" />

          def handle_event("stop", _params, socket),
            do: {:noreply, socket |> cancel_async(:reply) |> assign(reply: nil)}
          """,
          code: prompt_busy_code()
        },
        %{
          title: "Attachments",
          heex: ~S"""
          <%!-- allow_upload(:files, accept: ~w(image/* .pdf), max_entries: 3, auto_upload: true) --%>
          <.prompt_input
            id="composer"
            field={@form[:text]}
            upload={@uploads.files}
            on_cancel="cancel-upload"
          />

          def handle_event("cancel-upload", %{"ref" => ref}, socket),
            do: {:noreply, cancel_upload(socket, :files, ref)}
          """,
          code: prompt_attachments_code()
        },
        %{
          title: "Disabled",
          heex: ~S"""
          <.prompt_input id="composer" field={@form[:text]} placeholder="The assistant is offline" disabled />
          """,
          code: prompt_disabled_code()
        }
      ]
    }
  end

  defp prompt_default_code do
    assigns = %{}

    DataPages.code(~H"""
    <form class="w-full max-w-md" data-demo-prompt>
      <.prompt_input id="prompt-demo" name="text" placeholder="Ask anything…" />
    </form>
    """)
  end

  defp prompt_suggestions_code do
    assigns = %{}

    DataPages.code(~H"""
    <form class="w-full max-w-md" data-demo-prompt>
      <.prompt_input id="prompt-suggest-demo" name="text" placeholder="Ask anything…">
        <:suggestion value="Which orders are overdue?">Overdue orders</:suggestion>
        <:suggestion value="Who are our biggest customers?">Biggest customers</:suggestion>
        <:suggestion value="Draft a reminder to " send={false}>Draft a reminder…</:suggestion>
      </.prompt_input>
    </form>
    """)
  end

  defp prompt_busy_code do
    assigns = %{}

    DataPages.code(~H"""
    <form class="w-full max-w-md" data-demo-prompt>
      <.prompt_input id="prompt-busy-demo" name="text" placeholder="Ask anything…" busy />
    </form>
    """)
  end

  defp prompt_attachments_code do
    entries = [
      demo_entry("0", "roof-measurements.pdf", 1_800_000, "application/pdf",
        done?: true,
        progress: 100
      ),
      demo_entry("1", "invoice-1034.pdf", 420_000, "application/pdf",
        progress: 62,
        preflighted?: true
      )
    ]

    assigns = %{upload: demo_upload(entries)}

    upload_code(~H"""
    <form class="w-full max-w-md" data-demo-prompt>
      <.prompt_input
        id="prompt-files-demo"
        name="text"
        value="Is this invoice paid?"
        upload={@upload}
        on_cancel="cancel-upload"
      />
    </form>
    """)
  end

  defp prompt_disabled_code do
    assigns = %{}

    DataPages.code(~H"""
    <form class="w-full max-w-md" data-demo-prompt>
      <.prompt_input
        id="prompt-off-demo"
        name="text"
        placeholder="The assistant is offline"
        disabled
      />
    </form>
    """)
  end
end
