# Message

Displays a message in a conversation, with optional avatar, header, footer, and alignment.

## Usage guidance

Use when:

- Chat, support, and AI-assistant transcripts
- Comment threads where each entry has an author, content, and status

Don't use for:

- Notifications or activity feeds without a conversation - use <.item>
- A single system notice inside a transcript - use <.marker>

Sizing: 8px between avatar and content, 10px between parts of one message, 32px avatars. Header/footer are 12px muted text inset 12px to line up with bubble text.

Responsive: Content takes the remaining width; bubbles cap at 80% of it. On compact screens drop avatars for the current user's own (align end) messages.

iOS: A ScrollView of HStacks (avatar + VStack of bubbles), aligned leading/trailing by sender; use .defaultScrollAnchor(.bottom).

## Specs

| Part | Description |
| --- | --- |
| Message | Row with data-align (end reverses it for the current user). |
| Avatar (optional) | 32px round, bottom-aligned with the last bubble. |
| Content | Column of header, bubbles/attachments, footer. |
| Header / footer (optional) | 12px / 500 muted text, inset 12px. |

| Property | Value |
| --- | --- |
| Avatar gap | 8px |
| Content gap | 10px between parts |
| Avatar | min 32px, muted fallback background |
| Header / footer | 12px / 500 muted-foreground, 12px inline padding (0 beside ghost bubbles) |
| Group gap | 8px (use gap-6 between turns) |

Tokens used: `muted`, `muted-foreground`, `foreground`

## Accessibility

Role / ARIA: Plain containers. Wrap a live transcript in <.message_group role="log" aria-label="…"> so new messages are announced politely.

Focus: Messages aren't focusable; only controls inside them (footer actions, links) are.

Screen reader: Sender isn't conveyed by alignment alone - include the name in the header, or visually hidden text ("You said", "Olivia said") for avatar-less rows.

Touch target: Footer action buttons need a 44pt hit area on touch.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack(alignment: .bottom, spacing: 8) {
    if message.isMine { Spacer(minLength: 48) }
    if !message.isMine { AvatarView(message.author).frame(width: 32, height: 32) }
    VStack(alignment: message.isMine ? .trailing : .leading, spacing: 10) {
        Text(message.author.name).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        BubbleView(message)
    }
    if !message.isMine { Spacer(minLength: 48) }
}
```

Lay out a transcript as a ScrollView + LazyVStack with .defaultScrollAnchor(.bottom); post an accessibility announcement for incoming messages.

## Props

| Name | Type | Default |
| --- | --- | --- |
| align | start \| end | start |
| slots | :avatar :header :footer + inner content | - |
| message_group | role="log" aria-label for live transcripts | - |

## Default

HEEx:

```heex
<.message_group role="log" aria-label="Conversation" class="gap-6">
  <.message align="end">
    <:avatar><.avatar fallback="ME" class="w-8" /></:avatar>
    <.bubble>Deploying to prod real quick.</.bubble>
  </.message>
  <.message>
    <:avatar><.avatar fallback="R" class="w-8" /></:avatar>
    <.bubble variant="muted">It's 4:55 PM. On a Friday.</.bubble>
  </.message>
  <.message align="end">
    <:avatar><.avatar fallback="ME" class="w-8" /></:avatar>
    <.bubble>It's a one-line change.</.bubble>
    <:footer>Delivered</:footer>
  </.message>
  <.message>
    <:avatar><.avatar fallback="R" class="w-8" /></:avatar>
    <.bubble_group>
      <.bubble variant="muted">It's always a one-line change 😭.</.bubble>
      <.bubble variant="muted">
        Alright, let me take a look.
        <:reactions label="Reactions: thumbs up">👍</:reactions>
      </.bubble>
    </.bubble_group>
  </.message>
  <.marker status shimmer><span class="font-medium">Oliver</span> is typing...</.marker>
</.message_group>
```

```html
<div data-slot="message-group" role="log" aria-label="Conversation" class="w-full max-w-sm gap-6">
  <div data-slot="message" data-align="end">
    <div data-slot="message-avatar"><div class="avatar avatar-placeholder"><div class="w-8 rounded-full"><span class="text-xs font-medium">ME</span></div></div></div>
    <div data-slot="message-content">
      <div data-slot="bubble" data-variant="default" data-align="start"><div data-slot="bubble-content">Deploying to prod real quick.</div></div>
    </div>
  </div>
  <div data-slot="message" data-align="start">
    <div data-slot="message-avatar"><div class="avatar avatar-placeholder"><div class="w-8 rounded-full"><span class="text-xs font-medium">R</span></div></div></div>
    <div data-slot="message-content">
      <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">It's 4:55 PM. On a Friday.</div></div>
    </div>
  </div>
  <div data-slot="message" data-align="end">
    <div data-slot="message-avatar"><div class="avatar avatar-placeholder"><div class="w-8 rounded-full"><span class="text-xs font-medium">ME</span></div></div></div>
    <div data-slot="message-content">
      <div data-slot="bubble" data-variant="default" data-align="start"><div data-slot="bubble-content">It's a one-line change.</div></div>
      <div data-slot="message-footer">Delivered</div>
    </div>
  </div>
  <div data-slot="message" data-align="start">
    <div data-slot="message-avatar"><div class="avatar avatar-placeholder"><div class="w-8 rounded-full"><span class="text-xs font-medium">R</span></div></div></div>
    <div data-slot="message-content">
      <div data-slot="bubble-group">
        <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">It's always a one-line change 😭.</div></div>
        <div data-slot="bubble" data-variant="muted" data-align="start">
          <div data-slot="bubble-content">Alright, let me take a look.</div>
          <div data-slot="bubble-reactions" data-side="bottom" data-align="end" role="img" aria-label="Reactions: thumbs up">👍</div>
        </div>
      </div>
    </div>
  </div>
  <div data-slot="marker" data-variant="default" role="status">
    <span data-slot="marker-content" class="shimmer"><span class="font-medium">Oliver</span> is typing...</span>
  </div>
</div>
```

## Header & footer

HEEx:

```heex
<.message>
  <:header>Olivia</:header>
  <.bubble variant="muted">I already checked the logs.</.bubble>
</.message>
<.message align="end">
  <.bubble>Send the report to the team. Ping @shadcn if you need help.</.bubble>
  <:footer>Read <span class="font-normal">Yesterday</span></:footer>
</.message>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <div data-slot="message" data-align="start">
    <div data-slot="message-content">
      <div data-slot="message-header">Olivia</div>
      <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">I already checked the logs.</div></div>
    </div>
  </div>
  <div data-slot="message" data-align="end">
    <div data-slot="message-content">
      <div data-slot="bubble" data-variant="default" data-align="start"><div data-slot="bubble-content">Send the report to the team. Ping @shadcn if you need help.</div></div>
      <div data-slot="message-footer">Read <span class="font-normal">Yesterday</span></div>
    </div>
  </div>
</div>
```

## Attachment

HEEx:

```heex
<.message>
  <.bubble variant="muted">Done. Here's the PDF with the image added as the cover page.</.bubble>
  <.attachment>
    <:media><.icon name="hero-document-text" /></:media>
    <:title>sales-dashboard.pdf</:title>
    <:description>PDF · 2.4 MB</:description>
    <:actions>
      <.attachment_action label="Download" variant="secondary"><.icon name="hero-arrow-down-tray" /></.attachment_action>
    </:actions>
  </.attachment>
</.message>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <div data-slot="message" data-align="end">
    <div data-slot="message-content">
      <div data-slot="attachment" data-state="done" data-size="default" data-orientation="vertical">
        <div data-slot="attachment-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="Workspace" /></div>
      </div>
      <div data-slot="bubble" data-variant="default" data-align="start"><div data-slot="bubble-content">Here's the image. Can you add it to the PDF? Use it for the cover page.</div></div>
    </div>
  </div>
  <div data-slot="message" data-align="start">
    <div data-slot="message-content">
      <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">Done. Here's the PDF with the image added as the cover page.</div></div>
      <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal">
        <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
        <div data-slot="attachment-content"><span data-slot="attachment-title">sales-dashboard.pdf</span><span data-slot="attachment-description">PDF · 2.4 MB</span></div>
        <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-secondary" aria-label="Download" title="Download"><span class="hero-arrow-down-tray size-3.5" aria-hidden="true"></span></button></div>
      </div>
    </div>
  </div>
</div>
```

## Actions

HEEx:

```heex
<.message>
  <.bubble variant="muted">The install failure is coming from the workspace package.</.bubble>
  <:footer>
    <.button variant="ghost" size="icon" aria-label="Copy" phx-click="copy"><.icon name="hero-clipboard" /></.button>
    <.button variant="ghost" size="icon" aria-label="Like" phx-click="like"><.icon name="hero-hand-thumb-up" /></.button>
    <.button variant="ghost" size="icon" aria-label="Dislike" phx-click="dislike"><.icon name="hero-hand-thumb-down" /></.button>
  </:footer>
</.message>
```

```html
<div class="w-full max-w-sm">
  <div data-slot="message" data-align="start">
    <div data-slot="message-content">
      <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">The install failure is coming from the workspace package.</div></div>
      <div data-slot="message-footer">
        <button class="btn btn-ghost btn-square btn-sm" aria-label="Copy" title="Copy" data-toast="Copied to clipboard"><span class="hero-clipboard size-4" aria-hidden="true"></span></button>
        <button class="btn btn-ghost btn-square btn-sm" aria-label="Like" title="Like"><span class="hero-hand-thumb-up size-4" aria-hidden="true"></span></button>
        <button class="btn btn-ghost btn-square btn-sm" aria-label="Dislike" title="Dislike"><span class="hero-hand-thumb-down size-4" aria-hidden="true"></span></button>
      </div>
    </div>
  </div>
</div>
```
