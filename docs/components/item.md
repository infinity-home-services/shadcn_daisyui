# Item

A versatile row for displaying content with media, title, description, and actions.

## Usage guidance

Use when:

- Settings rows, notification rows, and file/member lists: one object per row with an action
- A list where each row needs more than a label (media, two lines of text, buttons)

Don't use for:

- Form fields - use <.field> / <.input>, which own labels and errors
- Dense tabular data you compare across rows - use <.table>
- Menu commands - use a dropdown menu or command palette

Sizing: Default 14px/16px padding; sm 10px/12px for denser lists; xs 8px/10px inside menus and popovers. Titles clamp to one line, descriptions to two.

Responsive: Rows wrap: header/footer always span the full width, and actions drop under the text when space runs out. On compact screens keep one primary action per row.

iOS: A List row: HStack of image, VStack(title, subtitle), Spacer, trailing control. Use .listRowInsets to match the size scale.

## Specs

| Part | Description |
| --- | --- |
| Item | data-slot=item row (a <div>, or an <a> when linked). |
| Media (optional) | Leading icon, avatar, or 40px image; top-aligns when there's a description. |
| Content | Title (1 line) and description (2 lines, muted). |
| Actions (optional) | Trailing buttons, badges, or a chevron. |
| Header / footer (optional) | Full-width rows above / below. |

| Property | Value |
| --- | --- |
| Padding (default / sm / xs) | 14px 16px / 10px 12px / 8px 10px |
| Gap (default / sm / xs) | 14px / 10px / 8px |
| Radius | var(--radius-md), 1px border (transparent unless outline) |
| Title | 14px / 500, line-clamp 1 |
| Description | 14px muted-foreground, line-clamp 2 (12px at xs) |
| Image media | 40px (sm 32px, xs 24px), var(--radius-sm) |
| Muted variant | muted at 50% |
| Link hover | muted background, 100ms |

Tokens used: `border-color`, `muted`, `muted-foreground`, `ring`, `primary`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus a linked item, or the buttons in its actions |
| Enter | Follow a linked item |

Role / ARIA: A plain container; <.item_group> is role=list, so give each item role=listitem. Linked items render a real <a>.

Focus: Linked items show the 3px ring (border-color ring + ring shadow). Don't nest interactive controls inside a linked item - keep actions outside or use a non-link item.

Screen reader: Title then description read in order. Icon media is decorative (aria-hidden); give icon-only action buttons an aria-label.

Touch target: Default rows are 48px+ tall; icon-only actions need a 44pt hit area on touch (btn-sm square is 32px - pad the row or use btn on touch).

Reduced motion: Only a 100ms color change on hover; nothing moves.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack(spacing: 14) {
    Image(systemName: "shield.lefthalf.filled")
    VStack(alignment: .leading, spacing: 4) {
        Text("Security Alert").font(.subheadline.weight(.medium))
        Text("New login detected from unknown device.")
            .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
    }
    Spacer()
    Button("Review") {}.buttonStyle(.bordered).controlSize(.small)
}
.padding(.vertical, 14).padding(.horizontal, 16)
.overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.sdBorder))
```

Inside a List, the row is the item (drop the overlay). The outline variant maps to a stroked RoundedRectangle; muted to a .fill(Color.sdMuted.opacity(0.5)) background.

## Props

| Name | Type | Default |
| --- | --- | --- |
| variant | default \| outline \| muted | default |
| size | default \| sm \| xs | default |
| href / navigate / patch | string | nil (renders a link) |
| :media variant | default \| icon \| image | default |
| slots | :media :title :description :actions :header :footer | - |

## Variants

HEEx:

```heex
<.item>
  <:title>Default Variant</:title>
  <:description>Standard styling with subtle background and borders.</:description>
  <:actions><.button variant="outline" size="sm">Open</.button></:actions>
</.item>
<.item variant="outline">…</.item>
<.item variant="muted">…</.item>
```

```html
<div class="flex w-full max-w-md flex-col gap-6">
  <div data-slot="item" data-variant="default" data-size="default">
    <div data-slot="item-content">
      <div data-slot="item-title">Default Variant</div>
      <p data-slot="item-description">Standard styling with subtle background and borders.</p>
    </div>
    <div data-slot="item-actions"><button class="btn btn-outline btn-sm">Open</button></div>
  </div>
  <div data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-content">
      <div data-slot="item-title">Outline Variant</div>
      <p data-slot="item-description">Outlined style with clear borders and transparent background.</p>
    </div>
    <div data-slot="item-actions"><button class="btn btn-outline btn-sm">Open</button></div>
  </div>
  <div data-slot="item" data-variant="muted" data-size="default">
    <div data-slot="item-content">
      <div data-slot="item-title">Muted Variant</div>
      <p data-slot="item-description">Subdued appearance with muted colors for secondary content.</p>
    </div>
    <div data-slot="item-actions"><button class="btn btn-outline btn-sm">Open</button></div>
  </div>
</div>
```

## Size

HEEx:

```heex
<.item variant="outline">
  <:title>Basic Item</:title>
  <:description>A simple item with title and description.</:description>
  <:actions><.button variant="outline" size="sm">Action</.button></:actions>
</.item>
<.item variant="outline" size="sm" href="#">
  <:media><.icon name="hero-check-badge" class="size-5" /></:media>
  <:title>Your profile has been verified.</:title>
  <:actions><.icon name="hero-chevron-right" class="size-4" /></:actions>
</.item>
```

```html
<div class="flex w-full max-w-md flex-col gap-6">
  <div data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-content">
      <div data-slot="item-title">Basic Item</div>
      <p data-slot="item-description">A simple item with title and description.</p>
    </div>
    <div data-slot="item-actions"><button class="btn btn-outline btn-sm">Action</button></div>
  </div>
  <a href="#" data-slot="item" data-variant="outline" data-size="sm">
    <div data-slot="item-media" data-variant="default"><span class="hero-check-badge size-5" aria-hidden="true"></span></div>
    <div data-slot="item-content"><div data-slot="item-title">Your profile has been verified.</div></div>
    <div data-slot="item-actions"><span class="hero-chevron-right size-4" aria-hidden="true"></span></div>
  </a>
</div>
```

## Icon

HEEx:

```heex
<.item variant="outline">
  <:media variant="icon"><.icon name="hero-shield-exclamation" /></:media>
  <:title>Security Alert</:title>
  <:description>New login detected from unknown device.</:description>
  <:actions><.button size="sm" variant="outline">Review</.button></:actions>
</.item>
```

```html
<div class="flex w-full max-w-lg flex-col gap-6">
  <div data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-media" data-variant="icon"><span class="hero-shield-exclamation" aria-hidden="true"></span></div>
    <div data-slot="item-content">
      <div data-slot="item-title">Security Alert</div>
      <p data-slot="item-description">New login detected from unknown device.</p>
    </div>
    <div data-slot="item-actions"><button class="btn btn-outline btn-sm">Review</button></div>
  </div>
</div>
```

## Avatar

HEEx:

```heex
<.item variant="outline">
  <:media><.avatar fallback="ER" class="w-10" /></:media>
  <:title>Evil Rabbit</:title>
  <:description>Last seen 5 months ago</:description>
  <:actions>
    <.button variant="outline" size="icon" aria-label="Invite"><.icon name="hero-plus" /></.button>
  </:actions>
</.item>
```

```html
<div class="flex w-full max-w-lg flex-col gap-6">
  <div data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-media" data-variant="default">
      <div class="avatar avatar-placeholder"><div class="w-10 rounded-full"><span class="text-sm font-medium">ER</span></div></div>
    </div>
    <div data-slot="item-content">
      <div data-slot="item-title">Evil Rabbit</div>
      <p data-slot="item-description">Last seen 5 months ago</p>
    </div>
    <div data-slot="item-actions">
      <button class="btn btn-outline btn-square btn-sm" aria-label="Invite"><span class="hero-plus size-4" aria-hidden="true"></span></button>
    </div>
  </div>
</div>
```

## Image

HEEx:

```heex
<.item variant="outline" href={~p"/albums/#{album}"}>
  <:media variant="image"><img src={album.cover_url} alt={album.title} /></:media>
  <:title>{album.title} <span class="text-muted-foreground">- {album.artist}</span></:title>
  <:description>{album.album}</:description>
  <:actions><span class="text-sm text-muted-foreground">{album.duration}</span></:actions>
</.item>
```

```html
<div role="list" data-slot="item-group" class="max-w-md">
  <a href="#" role="listitem" data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="Midnight City Lights cover" /></div>
    <div data-slot="item-content">
      <div data-slot="item-title">Midnight City Lights <span class="text-muted-foreground">- Neon Dreams</span></div>
      <p data-slot="item-description">Electric Nights</p>
    </div>
    <div data-slot="item-content" class="text-sm text-muted-foreground">3:45</div>
  </a>
  <a href="#" role="listitem" data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="Coffee Shop Conversations cover" /></div>
    <div data-slot="item-content">
      <div data-slot="item-title">Coffee Shop Conversations <span class="text-muted-foreground">- The Morning Brew</span></div>
      <p data-slot="item-description">Urban Stories</p>
    </div>
    <div data-slot="item-content" class="text-sm text-muted-foreground">4:05</div>
  </a>
</div>
```

## Group

HEEx:

```heex
<.item_group class="max-w-sm">
  <%= for {person, i} <- Enum.with_index(@people) do %>
    <.item_separator :if={i > 0} />
    <.item role="listitem">
      <:media><.avatar fallback={person.initials} class="w-10" /></:media>
      <:title>{person.username}</:title>
      <:description>{person.email}</:description>
      <:actions>
        <.button variant="ghost" size="icon" aria-label={"Add #{person.username}"}><.icon name="hero-plus" /></.button>
      </:actions>
    </.item>
  <% end %>
</.item_group>
```

```html
<div role="list" data-slot="item-group" class="max-w-sm rounded-xl border border-base-300 bg-card p-2">
  <div role="listitem" data-slot="item" data-variant="default" data-size="default">
    <div data-slot="item-media" data-variant="default"><div class="avatar avatar-placeholder"><div class="w-10 rounded-full"><span class="text-sm font-medium">SC</span></div></div></div>
    <div data-slot="item-content"><div data-slot="item-title">shadcn</div><p data-slot="item-description">shadcn@vercel.com</p></div>
    <div data-slot="item-actions"><button class="btn btn-ghost btn-square btn-sm" aria-label="Add shadcn"><span class="hero-plus size-4" aria-hidden="true"></span></button></div>
  </div>
  <div role="separator" aria-orientation="horizontal" data-slot="item-separator"></div>
  <div role="listitem" data-slot="item" data-variant="default" data-size="default">
    <div data-slot="item-media" data-variant="default"><div class="avatar avatar-placeholder"><div class="w-10 rounded-full"><span class="text-sm font-medium">ML</span></div></div></div>
    <div data-slot="item-content"><div data-slot="item-title">maxleiter</div><p data-slot="item-description">maxleiter@vercel.com</p></div>
    <div data-slot="item-actions"><button class="btn btn-ghost btn-square btn-sm" aria-label="Add maxleiter"><span class="hero-plus size-4" aria-hidden="true"></span></button></div>
  </div>
  <div role="separator" aria-orientation="horizontal" data-slot="item-separator"></div>
  <div role="listitem" data-slot="item" data-variant="default" data-size="default">
    <div data-slot="item-media" data-variant="default"><div class="avatar avatar-placeholder"><div class="w-10 rounded-full"><span class="text-sm font-medium">ER</span></div></div></div>
    <div data-slot="item-content"><div data-slot="item-title">evilrabbit</div><p data-slot="item-description">evilrabbit@vercel.com</p></div>
    <div data-slot="item-actions"><button class="btn btn-ghost btn-square btn-sm" aria-label="Add evilrabbit"><span class="hero-plus size-4" aria-hidden="true"></span></button></div>
  </div>
</div>
```

## Header & footer

HEEx:

```heex
<.item variant="outline">
  <:header>
    <span class="text-xs font-medium text-muted-foreground">Deployment</span>
    <.badge variant="secondary">Production</.badge>
  </:header>
  <:title>shadcn-daisyui-docs</:title>
  <:description>Built from main · 2m 14s</:description>
  <:footer>
    <span class="text-xs text-muted-foreground">Deployed 5 minutes ago</span>
    <.button variant="outline" size="sm">Logs</.button>
  </:footer>
</.item>
```

```html
<div class="w-full max-w-md">
  <div data-slot="item" data-variant="outline" data-size="default">
    <div data-slot="item-header">
      <span class="text-xs font-medium text-muted-foreground">Deployment</span>
      <span class="badge badge-secondary">Production</span>
    </div>
    <div data-slot="item-content">
      <div data-slot="item-title">shadcn-daisyui-docs</div>
      <p data-slot="item-description">Built from main · 2m 14s</p>
    </div>
    <div data-slot="item-footer">
      <span class="text-xs text-muted-foreground">Deployed 5 minutes ago</span>
      <button class="btn btn-outline btn-sm">Logs</button>
    </div>
  </div>
</div>
```
