# Message Scroller

The scrolling transcript of a chat: opens at the latest message, follows a streaming reply while you're at the bottom, and keeps your place when older messages load.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

shadcn/ui's Message Scroller. The ShadcnMessageScroller hook opens it at default_position (hidden until it's there, so it never flashes the top), follows growing content only while you're at the live edge (a wheel, touch, a scroll key or the scrollbar lets go; scrolling back down or the button picks it up again), moves a new anchored turn near the top with 64px of the row above still showing (and makes room under it for the reply), and keeps the row you're reading in place when rows are added above (a stream insert at: 0). It waits for a size, so it works in a sheet that opens later. Dispatch shadcn:scroll-to with detail: %{to: "end" | "start" | row_dom_id} to jump.

## Usage guidance

Use when:

- Every chat or AI-assistant transcript: messages in, a reply streaming
- Support threads and comment streams that grow at the bottom

Don't use for:

- A short, finished exchange on a record page - a <.message_group> needs no scroller
- Lists you sort or filter - use <.data_table>
- A hand-rolled overflow-y-auto div with scrollTop code - this is the one transcript scroller

Sizing: Fills its parent: give the parent a height (in <.app_shell fill> it takes the space between the page header and the composer). 32px between rows; the scroll button is 36px, centred 16px from the bottom.

Responsive: The same at every width; the rows decide their own layout. On phones the composer sits under it and the dock under that.

iOS: A ScrollView over a LazyVStack with .defaultScrollAnchor(.bottom); .scrollPosition(id:) keeps your place and jumps.

## Specs

| Part | Description |
| --- | --- |
| Frame | Fills its parent; holds the viewport and the buttons. |
| Viewport | role=region, labelled, tabindex 0: the one scroll region. |
| Log | role=log, aria-relevant=additions, aria-busy. |
| Row | One per message, keyed by id; anchors mark turns. |
| Above / below | A load-earlier button, a typing marker. |
| Scroll button | Outline icon button; inert when inactive. |

| Property | Value |
| --- | --- |
| Row gap | 2rem (gap-8) |
| Scrollbar | thin, stable gutter, overscroll contained |
| Bottom fade | last 2rem while there is more below |
| Anchor peek | 64px of the row above a new turn |
| Scroll button | 36px, 1rem from the edge, centred |
| Button motion | in: 200ms ease-out; out: 400ms ease-in, 95%, slid its own height |

Tokens used: `background`, `border-color`, `foreground`, `muted`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus the transcript (the ring shows inside it) |
| ↑ ↓ / Page Up / Page Down | Scroll; scrolling up stops following |
| Home / End | First / latest message |
| Enter / Space | On the scroll button: go to the latest message |

Role / ARIA: The viewport is a labelled region ("Messages", or label) and a tab stop, so the keyboard can scroll it. The rows are in a role=log live region with aria-relevant=additions: new messages are announced once; aria-busy holds the announcement of a streaming reply until it's done.

Focus: The scroll button is inert and out of the tab order while there's nothing below; if it had focus when it went away, focus returns to the transcript.

Screen reader: Each new message is read once; a streaming reply is read when aria-busy turns false. The button's name is "Scroll to latest message".

Touch target: The scroll button is 36px; a touch on the transcript never gets yanked back to the bottom while the finger is down.

Reduced motion: Jumps (the button, a new turn) are instant instead of smooth, and the button appears without sliding.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
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
```

Keep the transcript bottom-anchored with .defaultScrollAnchor(.bottom): new messages and the working step list stay in view while you're at the bottom. Scroll a question you just sent to the top. Load history above with .scrollPosition(id:) so the visible message stays put, and post an accessibility announcement when a reply finishes.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| items | list \| LiveView stream (required) | - |
| item_id | fn item -> dom id | stream ids / "id-item.id" |
| anchor | fn item -> boolean (turn anchors) | nil |
| busy | boolean (aria-busy while a reply streams) | false |
| default_position | end \| start \| last-anchor | end |
| follow | boolean | true |
| peek | px of the previous row above a new anchor | 64 |
| label | string (the viewport's name) | Messages |
| button | end \| start \| both \| none | end |
| :let={item} | inner block: one row | - |
| :above / :below | slots inside the log | - |

## Default

HEEx:

```heex
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
```

```html
<div class="card h-96 w-full max-w-md overflow-hidden">
  <div id="scroller-demo" data-slot="message-scroller" data-default-position="end" data-follow="true" data-peek="64" data-pending-scroll>
    <div id="scroller-demo-viewport" data-slot="message-scroller-viewport" role="region" aria-label="Messages" tabindex="0" data-pending-scroll>
      <div data-slot="message-scroller-content" role="log" aria-relevant="additions" aria-busy="false" class="p-4">
        <div id="scroller-demo-items" data-slot="message-scroller-items">
          <div id="scroller-demo-1" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Which orders are overdue?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-2" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Four orders are overdue, $6,104.80 in all. The oldest is #1034 for Riverside Dental.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-3" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Who handles Riverside Dental?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-4" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Pat Lee does. They&#39;ve paid within a week of a reminder every time this year.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-5" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Draft a reminder for them.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-6" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Here&#39;s a draft: &quot;Hi, a quick reminder that invoice #1034 for $1,512.80 was due on Oct 9. You can pay it from the link below. Thanks!&quot;
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-7" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Make it a little warmer.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="scroller-demo-8" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    &quot;Hi Dana, hope the week&#39;s going well. Just a friendly nudge that invoice #1034 ($1,512.80) was due on Oct 9 - the payment link is below. Thank you!&quot;
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div data-slot="message-scroller-spacer" aria-hidden="true">
      </div>
    </div>
    <button type="button" id="scroller-demo-to-end" data-slot="message-scroller-button" data-direction="end" data-active="false" aria-controls="scroller-demo-viewport" title="Scroll to latest message" inert tabindex="-1" class="btn btn-outline btn-square">
      <span class="hero-arrow-down size-4" aria-hidden="true"></span>
      <span class="sr-only">Scroll to latest message</span>
    </button>
  </div>
</div>
```

## Opening at the last turn

HEEx:

```heex
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
```

```html
<div class="card h-80 w-full max-w-md overflow-hidden">
  <div id="thread-demo" data-slot="message-scroller" data-default-position="last-anchor" data-follow="true" data-peek="64" data-pending-scroll>
    <div id="thread-demo-viewport" data-slot="message-scroller-viewport" role="region" aria-label="Messages" tabindex="0" data-pending-scroll>
      <div data-slot="message-scroller-content" role="log" aria-relevant="additions" aria-busy="false" class="p-4">
        <div id="thread-demo-items" data-slot="message-scroller-items">
          <div id="thread-demo-1" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Which orders are overdue?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="thread-demo-2" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Four orders are overdue, $6,104.80 in all. The oldest is #1034 for Riverside Dental.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="thread-demo-3" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Who handles Riverside Dental?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="thread-demo-4" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Pat Lee does. They&#39;ve paid within a week of a reminder every time this year.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="thread-demo-5" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Where do the overdue ones stand?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="thread-demo-6" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Here&#39;s where the four overdue orders stand. Riverside Dental (#1034, $1,512.80) is the oldest; Pat Lee sent a reminder on Oct 16 and they usually pay within a week. Summit Outfitters (#1040, $2,075.00) is next: Jordan Diaz is waiting on a purchase order number from them. Hillcrest Motors (#1025, $1,630.00) asked for a copy of the invoice, which went out yesterday. Copper Kettle (#1021, $887.00) has been quiet; a call might work better than another email. If you&#39;d like, I can draft the reminder for Copper Kettle, or put all four in a list for Monday&#39;s meeting.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div data-slot="message-scroller-spacer" aria-hidden="true">
      </div>
    </div>
    <button type="button" id="thread-demo-to-start" data-slot="message-scroller-button" data-direction="start" data-active="false" aria-controls="thread-demo-viewport" title="Scroll to first message" inert tabindex="-1" class="btn btn-outline btn-square">
      <span class="hero-arrow-down size-4" aria-hidden="true"></span>
      <span class="sr-only">Scroll to first message</span>
    </button>
    <button type="button" id="thread-demo-to-end" data-slot="message-scroller-button" data-direction="end" data-active="false" aria-controls="thread-demo-viewport" title="Scroll to latest message" inert tabindex="-1" class="btn btn-outline btn-square">
      <span class="hero-arrow-down size-4" aria-hidden="true"></span>
      <span class="sr-only">Scroll to latest message</span>
    </button>
  </div>
</div>
```

## Streaming

HEEx:

```heex
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
```

```html
<div class="card h-[28rem] w-full max-w-md gap-3 overflow-hidden p-4">
  <div id="stream-demo" data-slot="message-scroller" data-default-position="end" data-follow="true" data-peek="64" data-pending-scroll>
    <div id="stream-demo-viewport" data-slot="message-scroller-viewport" role="region" aria-label="Messages" tabindex="0" data-pending-scroll>
      <div data-slot="message-scroller-content" role="log" aria-relevant="additions" aria-busy="false">
        <div data-slot="message-scroller-above">
          <div class="flex justify-center">
            <button class="btn btn-ghost btn-sm" data-demo-chat-earlier="stream-demo">
              Load earlier messages
            </button>
          </div>
        </div>
        <div id="stream-demo-items" data-slot="message-scroller-items">
          <div id="stream-demo-1" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Which orders are overdue?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="stream-demo-2" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Four orders are overdue, $6,104.80 in all. The oldest is #1034 for Riverside Dental.
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="stream-demo-3" data-slot="message-scroller-item" data-scroll-anchor="true">
            <div data-slot="message" data-align="end">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="default" data-align="start">
                  <div data-slot="bubble-content">
                    Who handles Riverside Dental?
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="stream-demo-4" data-slot="message-scroller-item" data-scroll-anchor="false">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="message-header">Assistant</div>
                <div data-slot="bubble" data-variant="ghost" data-align="start">
                  <div data-slot="bubble-content">
                    Pat Lee does. They&#39;ve paid within a week of a reminder every time this year.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div data-slot="message-scroller-spacer" aria-hidden="true">
      </div>
    </div>
    <button type="button" id="stream-demo-to-end" data-slot="message-scroller-button" data-direction="end" data-active="false" aria-controls="stream-demo-viewport" title="Scroll to latest message" inert tabindex="-1" class="btn btn-outline btn-square">
      <span class="hero-arrow-down size-4" aria-hidden="true"></span>
      <span class="sr-only">Scroll to latest message</span>
    </button>
  </div>
  <form data-demo-chat="stream-demo">
    <div id="stream-demo-composer" data-slot="prompt-input">
      <div data-slot="prompt-input-box" data-dropzone-area>
        <textarea id="stream-demo-composer-input" name="text" data-slot="prompt-input-textarea" rows="1" placeholder="Ask anything…" aria-label="Message" enterkeyhint="send">
        </textarea>
        <div data-slot="prompt-input-toolbar">
          <button type="submit" id="stream-demo-composer-submit" data-slot="prompt-input-submit" data-state="idle" class="btn btn-square btn-primary" aria-label="Send" title="Send" aria-disabled="true">
            <span class="hero-arrow-up size-4" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
  </form>
</div>
```
