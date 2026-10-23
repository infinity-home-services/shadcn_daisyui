# Empty

An empty state: an icon in a muted circle, a short title, one line saying what belongs here, and an optional action.

On its own it is a bordered card (variant="card"). Inside a table or card use variant="plain": a centred block with no border of its own. <.data_table>'s :empty slot renders it that way, below the header and not as a row. Say what belongs here and how to add it; a filter that matched nothing offers to clear the filters. Links inside the description are underlined.

## Usage guidance

Use when:

- A page or list with nothing in it yet ("No invoices yet")
- A search or filter that matched nothing - say so and offer to clear it
- An empty table or card - variant="plain" inside it

Don't use for:

- Errors - use an alert that says what went wrong and how to fix it
- Loading - use skeletons or a spinner, never an empty state that flips to content
- A field with no value - show "Not set" in muted text

Sizing: A 40px muted circle with a 20px icon, an 8px gap, a text-sm medium title, one text-sm muted line (max 24rem), and size="sm" actions 8px below. Card: 48px / 24px padding, rounded-xl, 1px border. Plain: 40px vertical padding, no border.

Responsive: Centred and balanced at every width; the text wraps within 24rem. Keep it to one action on phones.

iOS: ContentUnavailableView with a label, a description and actions - the same three parts.

## Specs

| Part | Description |
| --- | --- |
| Media | A 40px muted circle holding the icon or :media. |
| Title | Short, text-sm medium: "No invoices yet". |
| Description | One muted line: what belongs here, how it gets here. |
| Actions | Optional size="sm" buttons, centred. |

| Property | Value |
| --- | --- |
| Media | 2.5rem / 40px circle, var(--muted), 1.25rem icon |
| Gap | 0.5rem between parts; actions 0.5rem further |
| Card padding | 3rem block, 1.5rem inline; 1px border, var(--radius-xl) |
| Plain padding | 2.5rem block, no border |
| Description | text-sm, var(--muted-foreground), max 24rem |

Tokens used: `card`, `card-foreground`, `border-color`, `muted`, `muted-foreground`, `foreground`

## Accessibility

Role / ARIA: Plain text in a div; the circle is aria-hidden, so the title and description carry the meaning.

Focus: Not focusable itself; its action buttons keep their own focus rings.

Screen reader: Read as text. When it replaces results after a search or filter, the change should be announced (a live region on the result count, or move focus to it).

Touch target: Actions reach 44px on touch through the button sizes.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
ContentUnavailableView {
    Label("No invoices yet", systemImage: "doc.text")
} description: {
    Text("Invoices you send show up here.")
} actions: {
    Button("New invoice") { newInvoice() }
}
```

ContentUnavailableView is the native empty state (and .search for a search that matched nothing); use it as a List's overlay when the list is empty.

## Props

| Name | Type | Default |
| --- | --- | --- |
| icon | string (heroicon class) | nil |
| title | string | nil |
| variant | card \| plain | card |
| class | any | nil |
| inner_block | slot (one muted line) | - |
| :media | slot (replaces the icon in the circle) | - |
| :actions | slot (size="sm" buttons) | - |

## Card

HEEx:

```heex
<.empty icon="hero-document-text" title="No invoices yet">
  Invoices you send show up here.
  <:actions><.button size="sm" navigate={~p"/invoices/new"}>New invoice</.button></:actions>
</.empty>
```

```html
<div class="empty-state w-full max-w-md" data-variant="card">
  <div class="empty-state-media" aria-hidden="true">
    <span class="hero-document-text size-5"></span>
  </div>
  <p class="empty-state-title">No invoices yet</p>
  <div class="empty-state-description">
    Invoices you send show up here.
  </div>
  <div class="empty-state-actions"><button class="btn btn-primary btn-sm">
      New invoice
    </button></div>
</div>
```

## In a table or card

HEEx:

```heex
<.card>
  <.card_body>
    <.card_title>Team</.card_title>
    <.card_description>People who can work on this project.</.card_description>
  </.card_body>
  <.empty variant="plain" icon="hero-user-group" title="No members yet">
    Invite people to work on this project with you.
    <:actions><.button size="sm" variant="outline">Invite people</.button></:actions>
  </.empty>
</.card>
```

```html
<div class="card w-full max-w-md">
  <div class="card-body">
    <h3 class="card-title">Team</h3>
    <p class="text-sm text-muted-foreground">People who can work on this project.</p>
  </div>
  <div class="empty-state" data-variant="plain">
    <div class="empty-state-media" aria-hidden="true">
      <span class="hero-user-group size-5"></span>
    </div>
    <p class="empty-state-title">No members yet</p>
    <div class="empty-state-description">
      Invite people to work on this project with you.
    </div>
    <div class="empty-state-actions"><button class="btn btn-outline btn-sm">
        Invite people
      </button></div>
  </div>
</div>
```

## Custom media

HEEx:

```heex
<.empty title="No messages from Pat Lee">
  <:media><span class="text-sm font-medium">PL</span></:media>
  When Pat writes to you, it shows up here.
  <:actions><.button size="sm" variant="outline">Send a message</.button></:actions>
</.empty>
```

```html
<div class="empty-state w-full max-w-md" data-variant="card">
  <div class="empty-state-media" aria-hidden="true">
    <span class="text-sm font-medium">PL</span>
  </div>
  <p class="empty-state-title">No messages from Pat Lee</p>
  <div class="empty-state-description">
    When Pat writes to you, it shows up here.
  </div>
  <div class="empty-state-actions"><button class="btn btn-outline btn-sm">
      Send a message
    </button></div>
</div>
```
