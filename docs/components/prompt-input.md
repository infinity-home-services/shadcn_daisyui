# Prompt Input

The chat composer: a field that grows with what you type, Send that turns into Stop while the reply streams, attachments and suggestion chips.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Enter sends and Shift+Enter adds a line - never while an input method is composing (Japanese, Chinese, Korean input). Send is aria-disabled while there's nothing to send; the field clears as soon as the message is on its way (reset your form in phx-submit too). While busy the button is Stop: it pushes on_stop, and Enter waits. With upload, the paperclip is a label around the hidden live_file_input (Enter or Space opens the picker), files dropped on the field or pasted into it go to the same upload, and each one is an <.attachment> tile above the text. A suggestion chip is <.bubble as="button">: its value goes in the field and is sent (send={false} only fills it). Hook: ShadcnPromptInput.

## Usage guidance

Use when:

- The message box of any chat or AI assistant
- Asking an assistant from a record page (a sheet with a scroller and this under it)

Don't use for:

- Ordinary long text in a form (notes, a description) - use <.textarea>
- Search boxes - use <.command> or the table toolbar's search
- A hand-rolled textarea with an Enter handler or a Send/Stop swap - this is the one composer

Sizing: The field is shadcn's: 1px input border, rounded-md, text-sm, 8px 12px padding, at least 4rem tall, growing to 12rem before it scrolls. 36px icon buttons 8px from the edges; chips 8px apart, 12px above.

Responsive: Full width of the chat column at every width; the toolbar buttons get a 44px hit area on touch screens, and the keyboard's return key reads Send (enterkeyhint).

iOS: A TextField(axis: .vertical) with .lineLimit(1...6) and .submitLabel(.send), Send (.borderedProminent) that becomes Stop (.bordered) while busy, and capsule suggestion buttons in a flow layout above.

## Specs

| Part | Description |
| --- | --- |
| Suggestions | Outline bubble buttons that wrap, 8px apart. |
| Box | The field's border and fill; the drop target. |
| Attachments | Attachment tiles in a row that scrolls. |
| Text | Grows with its content, 4rem to 12rem. |
| Toolbar | Attach, your tools, then Send / Stop. |

| Property | Value |
| --- | --- |
| Box | 1px var(--input), var(--radius-md), shadow-xs |
| Text | text-sm, 0.5rem 0.75rem, 4rem → 12rem, then scrolls |
| Buttons | 36px icon buttons, 0.5rem from the edges |
| Focus ring | 3px var(--ring) @ 50% on the box |
| Drag | var(--primary) border on var(--accent) |
| Send, nothing to send | opacity 0.5 (aria-disabled) |

Tokens used: `input`, `ring`, `primary`, `secondary`, `accent`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter | Send (not while composing, not while busy) |
| Shift+Enter | New line |
| Tab | Attach, your tools, Send / Stop |
| Enter / Space | On attach: open the file picker |

Role / ARIA: A textarea named by label ("Message"), enterkeyhint=send; Send and Stop are one button whose name changes ("Send" / "Stop"), so focus stays on it; the attach button is a label around the file input (named "Attach files"); suggestions are a group of buttons; attached files are a list.

Focus: The ring is on the whole box while the text has focus. After sending, focus stays in (or returns to) the field.

Screen reader: Send reads as dimmed (aria-disabled) while there's nothing to send. Upload errors are read from a polite live region and describe the field.

Touch target: Toolbar buttons are 36px with a 44px hit area on touch screens; chips are text-sm bubbles at least 36px tall.

Reduced motion: Only colour changes; nothing moves.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
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
```

Send becomes Stop while the assistant is busy and asking waits until it's done. Clear the field as soon as a question is sent and keep the keyboard up. Suggestion chips send their text in one tap. Attach with PhotosPicker or .fileImporter and show the files as rows above the field.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| field | Phoenix.HTML.FormField | nil |
| name / value | instead of field | nil |
| placeholder | string | nil |
| label | string (the field's name) | Message |
| busy | boolean: the button is Stop | false |
| on_stop | event \| JS | "stop" |
| upload | Phoenix.LiveView.UploadConfig | nil |
| on_cancel / error_text / target | as <.dropzone> | nil |
| disabled | boolean | false |
| :suggestion | slot: value, send, variant, phx-click | - |
| :tools | slot: controls beside attach | - |

## Default

HEEx:

```heex
<.form for={@form} id="chat-form" phx-change="validate" phx-submit="send">
  <.prompt_input id="composer" field={@form[:text]} placeholder="Ask anything…" />
</.form>

def handle_event("send", %{"prompt" => %{"text" => text}}, socket) do
  # … start the reply, then reset the form for the next question
  {:noreply, assign(socket, form: to_form(%{"text" => ""}, as: :prompt))}
end
```

```html
<form class="w-full max-w-md" data-demo-prompt>
  <div id="prompt-demo" data-slot="prompt-input">
    <div data-slot="prompt-input-box" data-dropzone-area>
      <textarea id="prompt-demo-input" name="text" data-slot="prompt-input-textarea" rows="1" placeholder="Ask anything…" aria-label="Message" enterkeyhint="send">
      </textarea>
      <div data-slot="prompt-input-toolbar">
        <button type="submit" id="prompt-demo-submit" data-slot="prompt-input-submit" data-state="idle" class="btn btn-square btn-primary" aria-label="Send" title="Send" aria-disabled="true">
          <span class="hero-arrow-up size-4" aria-hidden="true"></span>
        </button>
      </div>
    </div>
  </div>
</form>
```

## Suggestions

HEEx:

```heex
<.prompt_input id="composer" field={@form[:text]} placeholder="Ask anything…">
  <:suggestion :if={@new_chat?} value="Which orders are overdue?">Overdue orders</:suggestion>
  <:suggestion :if={@new_chat?} value="Who are our biggest customers?">Biggest customers</:suggestion>
  <:suggestion :if={@new_chat?} value="Draft a reminder to " send={false}>Draft a reminder…</:suggestion>
</.prompt_input>
```

```html
<form class="w-full max-w-md" data-demo-prompt>
  <div id="prompt-suggest-demo" data-slot="prompt-input">
    <div data-slot="prompt-input-suggestions" role="group" aria-label="Suggestions">
      <div data-slot="bubble" data-variant="outline" data-align="start">
        <button type="button" data-slot="bubble-content" data-prompt-suggestion="Which orders are overdue?">
          Overdue orders
        </button>
      </div>
      <div data-slot="bubble" data-variant="outline" data-align="start">
        <button type="button" data-slot="bubble-content" data-prompt-suggestion="Who are our biggest customers?">
          Biggest customers
        </button>
      </div>
      <div data-slot="bubble" data-variant="outline" data-align="start">
        <button type="button" data-slot="bubble-content" data-prompt-suggestion="Draft a reminder to " data-send="false">
          Draft a reminder…
        </button>
      </div>
    </div>
    <div data-slot="prompt-input-box" data-dropzone-area>
      <textarea id="prompt-suggest-demo-input" name="text" data-slot="prompt-input-textarea" rows="1" placeholder="Ask anything…" aria-label="Message" enterkeyhint="send">
      </textarea>
      <div data-slot="prompt-input-toolbar">
        <button type="submit" id="prompt-suggest-demo-submit" data-slot="prompt-input-submit" data-state="idle" class="btn btn-square btn-primary" aria-label="Send" title="Send" aria-disabled="true">
          <span class="hero-arrow-up size-4" aria-hidden="true"></span>
        </button>
      </div>
    </div>
  </div>
</form>
```

## Busy

HEEx:

```heex
<%!-- while the reply streams: the button is Stop --%>
<.prompt_input id="composer" field={@form[:text]} busy={@reply != nil} on_stop="stop" />

def handle_event("stop", _params, socket),
  do: {:noreply, socket |> cancel_async(:reply) |> assign(reply: nil)}
```

```html
<form class="w-full max-w-md" data-demo-prompt>
  <div id="prompt-busy-demo" data-slot="prompt-input" data-busy>
    <div data-slot="prompt-input-box" data-dropzone-area>
      <textarea id="prompt-busy-demo-input" name="text" data-slot="prompt-input-textarea" rows="1" placeholder="Ask anything…" aria-label="Message" enterkeyhint="send">
      </textarea>
      <div data-slot="prompt-input-toolbar">
        <button type="button" id="prompt-busy-demo-submit" data-slot="prompt-input-submit" data-state="busy" class="btn btn-square btn-secondary" aria-label="Stop" title="Stop" phx-click="stop">
          <span class="hero-stop-solid size-4" aria-hidden="true"></span>
        </button>
      </div>
    </div>
  </div>
</form>
```

## Attachments

HEEx:

```heex
<%!-- allow_upload(:files, accept: ~w(image/* .pdf), max_entries: 3, auto_upload: true) --%>
<.prompt_input
  id="composer"
  field={@form[:text]}
  upload={@uploads.files}
  on_cancel="cancel-upload"
/>

def handle_event("cancel-upload", %{"ref" => ref}, socket),
  do: {:noreply, cancel_upload(socket, :files, ref)}
```

```html
<form class="w-full max-w-md" data-demo-prompt>
  <div id="prompt-files-demo" data-slot="prompt-input" data-dropzone="upload">
    <div data-slot="prompt-input-box" data-dropzone-area>
      <div data-slot="prompt-input-attachments" role="list" aria-label="Attached files">
        <div role="listitem">
          <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" id="prompt-files-demo-0">
            <div data-slot="attachment-media" data-variant="icon">
              <span class="hero-check" aria-hidden="true"></span>
            </div>
            <div data-slot="attachment-content">
              <span data-slot="attachment-title">roof-measurements.pdf</span>
              <span data-slot="attachment-description">
                Uploaded · 1.8 MB
              </span>
            </div>
            <div data-slot="attachment-actions">
              <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove roof-measurements.pdf" title="Remove roof-measurements.pdf" phx-click="cancel-upload" phx-value-ref="0">
                <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
              </button>
            </div>
          </div>
        </div>
        <div role="listitem">
          <div data-slot="attachment" data-state="uploading" data-size="default" data-orientation="horizontal" id="prompt-files-demo-1">
            <div data-slot="attachment-media" data-variant="icon">
              <span class="loading loading-spinner loading-sm" aria-hidden="true"></span>
            </div>
            <div data-slot="attachment-content">
              <span data-slot="attachment-title">invoice-1034.pdf</span>
              <span data-slot="attachment-description">
                Uploading · 62%
              </span>
            </div>
            <div data-slot="attachment-actions">
              <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Cancel invoice-1034.pdf" title="Cancel invoice-1034.pdf" phx-click="cancel-upload" phx-value-ref="1">
                <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
              </button>
            </div>
          </div>
        </div>
      </div>
      <textarea id="prompt-files-demo-input" name="text" data-slot="prompt-input-textarea" rows="1" aria-label="Message" enterkeyhint="send">
        Is this invoice paid?</textarea>
      <div data-slot="prompt-input-toolbar">
        <label data-slot="prompt-input-attach" class="btn btn-ghost btn-square" title="Attach files">
          <input id="phx-demo-files" type="file" name="files" accept="image/*,.pdf" data-phx-auto-upload multiple>
          <span class="hero-paper-clip size-4" aria-hidden="true"></span>
          <span class="sr-only">Attach files</span>
        </label>
        <button type="submit" id="prompt-files-demo-submit" data-slot="prompt-input-submit" data-state="idle" class="btn btn-square btn-primary" aria-label="Send" title="Send">
          <span class="hero-arrow-up size-4" aria-hidden="true"></span>
        </button>
      </div>
    </div>
    <div id="prompt-files-demo-errors" data-slot="prompt-input-errors" aria-live="polite">
    </div>
  </div>
</form>
```

## Disabled

HEEx:

```heex
<.prompt_input id="composer" field={@form[:text]} placeholder="The assistant is offline" disabled />
```

```html
<form class="w-full max-w-md" data-demo-prompt>
  <div id="prompt-off-demo" data-slot="prompt-input" data-disabled>
    <div data-slot="prompt-input-box" data-dropzone-area>
      <textarea id="prompt-off-demo-input" name="text" data-slot="prompt-input-textarea" rows="1" placeholder="The assistant is offline" aria-label="Message" enterkeyhint="send" disabled>
      </textarea>
      <div data-slot="prompt-input-toolbar">
        <button type="submit" id="prompt-off-demo-submit" data-slot="prompt-input-submit" data-state="idle" class="btn btn-square btn-primary" aria-label="Send" title="Send" aria-disabled="true" disabled>
          <span class="hero-arrow-up size-4" aria-hidden="true"></span>
        </button>
      </div>
    </div>
  </div>
</form>
```
