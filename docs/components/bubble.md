# Bubble

Displays conversational content in a message bubble, with variants, alignment, grouping, and reactions.

## Usage guidance

Use when:

- The content of a chat message, inside <.message> (or on its own)
- Suggested replies: a group of clickable tinted bubbles (as="button")
- Assistant answers with markdown: the ghost variant (no frame, full width)

Don't use for:

- Callouts and notices on a page - use <.alert> or a card
- Status lines inside a transcript - use <.marker>

Sizing: 12px/8px padding, 14px text at 1.625 line height, var(--radius-xl) corners, max 80% of the row (ghost: 100%). 8px between bubbles in a group.

Responsive: Bubbles wrap long words and never exceed their row; keep the 80% cap on compact screens so sender alignment stays readable.

iOS: Text with padding and a RoundedRectangle background (accent for own messages, secondarySystemFill for others); reactions as an overlay(alignment: .bottomTrailing) capsule.

## Specs

| Part | Description |
| --- | --- |
| Bubble | data-variant / data-align wrapper; max 80% of the row (ghost: 100%). |
| Content | The painted surface: a <div>, or a <button>/<a> for clickable bubbles. |
| Reactions (optional) | Pill on the top or bottom edge, ringed in the card color. |

| Property | Value |
| --- | --- |
| Padding | 8px 12px (ghost: 0) |
| Radius | var(--radius-xl) |
| Text | 14px, 1.625 line height |
| default / secondary / muted | primary / secondary / muted surfaces |
| tinted | primary hue at L 0.93 (dark 0.30), 40% chroma |
| destructive | destructive 10% (text destructive) |
| Reactions | full radius, muted, 3px card ring, 75% off the edge, 12px inset |
| Group gap | 8px |

Tokens used: `primary`, `primary-foreground`, `secondary`, `secondary-foreground`, `muted`, `background`, `border-color`, `destructive`, `card`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus clickable bubbles (suggested replies) and links inside |
| Enter / Space | Send the focused suggested reply |

Role / ARIA: Plain text containers. Clickable bubbles are real <button>s (type=button) or links. Reactions with a label become role=img with that label.

Focus: Clickable bubbles show the 3px ring on the content surface.

Screen reader: Label reaction pills with a summary ("Reactions: thumbs up, and 2 more") - raw emoji read poorly. Variant color carries no meaning on its own.

Touch target: Suggested-reply bubbles are at least 40px tall; keep 8px between them so taps don't collide.

Reduced motion: Only a color change on hover; nothing moves.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Text(message.text)
    .font(.subheadline)
    .padding(.vertical, 8).padding(.horizontal, 12)
    .background(message.isMine ? Color.sdPrimary : Color.sdMuted,
                in: RoundedRectangle(cornerRadius: 14))
    .foregroundStyle(message.isMine ? Color.sdPrimaryForeground : Color.sdForeground)
    .overlay(alignment: .bottomTrailing) {
        if let r = message.reactions {
            Text(r).font(.footnote).padding(.horizontal, 6)
                .background(Color.sdMuted, in: Capsule())
                .offset(x: -12, y: 12)
        }
    }
```

Suggested replies map to Buttons with a bubble background; ghost bubbles are plain Text / markdown with no background.

## Props

| Name | Type | Default |
| --- | --- | --- |
| variant | default \| secondary \| muted \| tinted \| outline \| ghost \| destructive | default |
| align | start \| end | start |
| as | div \| button \| a | div |
| :reactions | label, side (top \| bottom), align (start \| end) | - |

## Variants

HEEx:

```heex
<.bubble>This is the default primary bubble.</.bubble>
<.bubble variant="secondary" align="end">This is the secondary variant.</.bubble>
<.bubble variant="muted">This one is muted.</.bubble>
<.bubble variant="tinted" align="end">This one is tinted.</.bubble>
<.bubble variant="outline">We can also use an outlined variant.</.bubble>
<.bubble variant="destructive" align="end">Or a destructive variant.</.bubble>
<.bubble variant="ghost">Ghost bubbles work for assistant text and markdown.</.bubble>
```

```html
<div class="flex w-full max-w-sm flex-col gap-10">
  <div data-slot="bubble" data-variant="default" data-align="start"><div data-slot="bubble-content">This is the default primary bubble.</div></div>
  <div data-slot="bubble" data-variant="secondary" data-align="end"><div data-slot="bubble-content">This is the secondary variant.</div></div>
  <div data-slot="bubble" data-variant="muted" data-align="start">
    <div data-slot="bubble-content">This one is muted. It uses a lower emphasis color for the chat bubble.</div>
    <div data-slot="bubble-reactions" data-side="bottom" data-align="end" role="img" aria-label="Reaction: thumbs up">👍</div>
  </div>
  <div data-slot="bubble" data-variant="tinted" data-align="end"><div data-slot="bubble-content">This one is tinted. The tint is a softer color derived from the primary color.</div></div>
  <div data-slot="bubble" data-variant="outline" data-align="start"><div data-slot="bubble-content">We can also use an outlined variant.</div></div>
  <div data-slot="bubble" data-variant="destructive" data-align="end">
    <div data-slot="bubble-content">Or a destructive variant with a reaction.</div>
    <div data-slot="bubble-reactions" data-side="bottom" data-align="end" role="img" aria-label="Reaction: fire">🔥</div>
  </div>
  <div data-slot="bubble" data-variant="ghost" data-align="start">
    <div data-slot="bubble-content">
      <p>Ghost bubbles work for assistant text, <strong>markdown</strong>, and other content that should not be framed.</p>
      <p class="mt-4">They take the full width of the container. You can also render <code class="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">code</code> in them.</p>
    </div>
  </div>
</div>
```

## Reactions

HEEx:

```heex
<.bubble variant="muted" align="end">
  I don't need tests, I know my code works.
  <:reactions label="Reactions: thumbs up, surprised" align="start">👍 😮</:reactions>
</.bubble>
<.bubble align="end">
  Tests passed on the first try. All 142 of them.
  <:reactions label="Reactions: party popper, clapping hands" side="top" align="start">🎉 👏</:reactions>
</.bubble>
```

```html
<div class="flex w-full max-w-sm flex-col gap-12 py-4">
  <div data-slot="bubble" data-variant="muted" data-align="end">
    <div data-slot="bubble-content">I don't need tests, I know my code works.</div>
    <div data-slot="bubble-reactions" data-side="bottom" data-align="start" role="img" aria-label="Reactions: thumbs up, surprised"><span>👍</span><span>😮</span></div>
  </div>
  <div data-slot="bubble" data-variant="muted" data-align="start">
    <div data-slot="bubble-content">Bold. Fine I'll add some tests. I'll let you know when they're done.</div>
    <div data-slot="bubble-reactions" data-side="bottom" data-align="end" role="img" aria-label="Reactions: eyes, rocket, and 2 more"><span>👀</span><span>🚀</span><span>+2</span></div>
  </div>
  <div data-slot="bubble" data-variant="default" data-align="end">
    <div data-slot="bubble-content">Tests passed on the first try. All 142 of them. Looking good!</div>
    <div data-slot="bubble-reactions" data-side="top" data-align="start" role="img" aria-label="Reactions: party popper, clapping hands"><span>🎉</span><span>👏</span></div>
  </div>
</div>
```

## Suggested replies

HEEx:

```heex
<.bubble variant="muted">How can I help you today?</.bubble>
<.bubble_group>
  <.bubble :for={reply <- @suggestions} variant="tinted" align="end" as="button" phx-click="reply" phx-value-text={reply}>
    {reply}
  </.bubble>
</.bubble_group>
```

```html
<div class="flex w-full max-w-sm flex-col gap-8">
  <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">How can I help you today?</div></div>
  <div data-slot="bubble-group">
    <div data-slot="bubble" data-variant="tinted" data-align="end"><button type="button" data-slot="bubble-content" data-toast="You clicked forgot password">I forgot my password</button></div>
    <div data-slot="bubble" data-variant="tinted" data-align="end"><button type="button" data-slot="bubble-content" data-toast="You clicked help with subscription">I need help with my subscription</button></div>
    <div data-slot="bubble" data-variant="tinted" data-align="end"><button type="button" data-slot="bubble-content" data-toast="Connecting you to a human…">Something else. Talk to a human.</button></div>
  </div>
</div>
```

## Group

HEEx:

```heex
<.bubble_group>
  <.bubble variant="muted">Hey, are you around?</.bubble>
  <.bubble variant="muted">The deploy is stuck on step 3.</.bubble>
</.bubble_group>
```

```html
<div class="flex w-full max-w-sm flex-col gap-6">
  <div data-slot="bubble-group">
    <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">Hey, are you around?</div></div>
    <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">The deploy is stuck on step 3.</div></div>
  </div>
  <div data-slot="bubble-group">
    <div data-slot="bubble" data-variant="default" data-align="end"><div data-slot="bubble-content">On it.</div></div>
    <div data-slot="bubble" data-variant="default" data-align="end"><div data-slot="bubble-content">Looks like a cache miss, rerunning now.</div></div>
  </div>
</div>
```
