# Attachment

Displays a file or image attachment with media, metadata, upload state, and actions.

## Usage guidance

Use when:

- Files picked for upload, in progress, or already attached (composer, form, message)
- Showing a file's name, type, and size with remove / download / retry actions

Don't use for:

- The file input itself - use a file input or drop zone, then render picked files as attachments
- Image galleries - use a grid of images or a carousel

Sizing: Default: 40px media, 14px text. sm: 32px media, 12px text. xs: 28px media for tight composers. Horizontal tiles are at least 160px; vertical tiles 96px (120px with text).

Responsive: Put several in an <.attachment_group>: one horizontally scrolling, snap-aligned row that never wraps the layout. Use w-full tiles in a vertical list on compact screens.

iOS: An HStack card: thumbnail or SF Symbol, VStack(name, metadata), trailing buttons; ProgressView for uploading. ShareLink / QuickLook for open and download.

## Specs

| Part | Description |
| --- | --- |
| Attachment | Card-surface tile with data-state, data-size, data-orientation. |
| Media | Square icon well (muted) or image; dims while uploading/processing. |
| Content | Title (truncated, shimmers while busy) and description (12px muted). |
| Actions (optional) | 24px ghost icon buttons; top-right overlay when vertical. |
| Trigger (optional) | Invisible full-tile button under the actions. |

| Property | Value |
| --- | --- |
| Radius | var(--radius-xl) (xs: var(--radius-lg)) |
| Media | 40px (sm 32px, xs 28px), var(--radius-lg) |
| Padding with text | 8px 10px (sm 6px 8px, xs 4px 6px) |
| Min width | 160px horizontal; 96px vertical (120px with text) |
| idle | dashed border |
| error | destructive 30% border, destructive 10% media tint |
| uploading / processing | title shimmer, image at 60% opacity |
| Group | 12px gap, horizontal scroll with snap |

Tokens used: `card`, `card-foreground`, `border-color`, `muted`, `muted-foreground`, `destructive`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move to the trigger, then each action |
| Enter / Space | Activate the focused trigger or action |

Role / ARIA: A plain container. The trigger is a real <button> with a required label (e.g. "Preview report.pdf"); actions are buttons with required labels.

Focus: Focus anywhere inside shows a 1px ring around the whole tile; actions sit above the trigger so both stay clickable.

Screen reader: Put the state in the description text ("Uploading · 64%", "Upload failed. Try again.") - the dashed border, tint, and shimmer are visual only. Name actions with the file ("Remove report.pdf").

Touch target: Action buttons are 24px; on touch, the trigger covers the tile, and destructive actions should confirm or offer undo.

Reduced motion: The title shimmer stops under prefers-reduced-motion; the text stays readable.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack(spacing: 8) {
    Image(systemName: "doc.text")
        .frame(width: 40, height: 40)
        .background(Color.sdMuted, in: RoundedRectangle(cornerRadius: 10))
    VStack(alignment: .leading, spacing: 2) {
        Text("sales-dashboard.pdf").fontWeight(.medium).lineLimit(1)
        Text("PDF · 2.4 MB").font(.caption).foregroundStyle(.secondary)
    }
    Button { } label: { Image(systemName: "arrow.down.to.line") }
        .buttonStyle(.borderless)
        .accessibilityLabel("Download")
}
.padding(8)
.background(Color.sdCard, in: RoundedRectangle(cornerRadius: 14))
.overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sdBorder))
```

Use ProgressView(value:) in the media well while uploading, and QuickLook (.quickLookPreview) for the trigger.

## Props

| Name | Type | Default |
| --- | --- | --- |
| state | idle \| uploading \| processing \| error \| done | done |
| size | default \| sm \| xs | default |
| orientation | horizontal \| vertical | horizontal |
| :media variant | icon \| image | icon |
| :trigger | label (required) + phx-click | - |
| attachment_action label | string (required) | - |

## Default

HEEx:

```heex
<.attachment>
  <:media><.icon name="hero-document-text" /></:media>
  <:title>sales-dashboard.pdf</:title>
  <:description>PDF · 2.4 MB</:description>
  <:actions>
    <.attachment_action label="Download" variant="secondary">
      <.icon name="hero-arrow-down-tray" />
    </.attachment_action>
  </:actions>
</.attachment>
```

```html
<div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-full max-w-sm">
  <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
  <div data-slot="attachment-content">
    <span data-slot="attachment-title">sales-dashboard.pdf</span>
    <span data-slot="attachment-description">PDF · 2.4 MB</span>
  </div>
  <div data-slot="attachment-actions">
    <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-secondary" aria-label="Download" title="Download"><span class="hero-arrow-down-tray size-3.5" aria-hidden="true"></span></button>
  </div>
</div>
```

## States

HEEx:

```heex
<.attachment :for={entry <- @uploads.files.entries} state={upload_state(entry)} class="w-full">
  <:media>
    <.spinner :if={entry.progress < 100} size="loading-sm" />
    <.icon :if={entry.progress == 100} name="hero-check" />
  </:media>
  <:title>{entry.client_name}</:title>
  <:description>Uploading · {entry.progress}%</:description>
  <:actions>
    <.attachment_action label={"Cancel #{entry.client_name}"} phx-click="cancel-upload" phx-value-ref={entry.ref}>
      <.icon name="hero-x-mark" />
    </.attachment_action>
  </:actions>
</.attachment>
```

```html
<div class="flex w-full max-w-sm flex-col gap-2">
  <div data-slot="attachment" data-state="idle" data-size="default" data-orientation="horizontal" class="w-full">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-clock" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">selected-file.pdf</span><span data-slot="attachment-description">Ready to upload</span></div>
    <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove selected-file.pdf" title="Remove selected-file.pdf"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
  </div>
  <div data-slot="attachment" data-state="uploading" data-size="default" data-orientation="horizontal" class="w-full">
    <div data-slot="attachment-media" data-variant="icon"><span class="loading loading-spinner loading-sm"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">design-system.zip</span><span data-slot="attachment-description">Uploading · 64%</span></div>
    <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Cancel upload" title="Cancel upload"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
  </div>
  <div data-slot="attachment" data-state="processing" data-size="default" data-orientation="horizontal" class="w-full">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">market-research.pdf</span><span data-slot="attachment-description">Processing document</span></div>
    <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove market-research.pdf" title="Remove market-research.pdf"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
  </div>
  <div data-slot="attachment" data-state="error" data-size="default" data-orientation="horizontal" class="w-full">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-exclamation-triangle" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">financial-model.xlsx</span><span data-slot="attachment-description">Upload failed. Try again.</span></div>
    <div data-slot="attachment-actions">
      <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Retry upload" title="Retry upload"><span class="hero-arrow-path size-3.5" aria-hidden="true"></span></button>
      <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove financial-model.xlsx" title="Remove financial-model.xlsx"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button>
    </div>
  </div>
  <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-full">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-check" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">uploaded-report.pdf</span><span data-slot="attachment-description">Uploaded · 1.8 MB</span></div>
    <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove uploaded-report.pdf" title="Remove uploaded-report.pdf"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
  </div>
</div>
```

## Sizes

HEEx:

```heex
<.attachment size="sm">…</.attachment>
<.attachment size="xs">…</.attachment>
```

```html
<div class="flex flex-col items-start gap-3">
  <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">quarterly-report.pdf</span><span data-slot="attachment-description">PDF · 2.4 MB</span></div>
  </div>
  <div data-slot="attachment" data-state="done" data-size="sm" data-orientation="horizontal">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">quarterly-report.pdf</span><span data-slot="attachment-description">PDF · 2.4 MB</span></div>
  </div>
  <div data-slot="attachment" data-state="done" data-size="xs" data-orientation="horizontal">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">quarterly-report.pdf</span></div>
  </div>
</div>
```

## Image

HEEx:

```heex
<.attachment orientation="vertical">
  <:media variant="image"><img src={@photo.url} alt={@photo.name} /></:media>
  <:title>{@photo.name}</:title>
  <:description>{@photo.size}</:description>
</.attachment>
```

```html
<div class="flex items-start gap-3">
  <div data-slot="attachment" data-state="done" data-size="default" data-orientation="vertical">
    <div data-slot="attachment-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="Workspace" /></div>
  </div>
  <div data-slot="attachment" data-state="done" data-size="default" data-orientation="vertical">
    <div data-slot="attachment-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="Office" /></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">office.jpg</span><span data-slot="attachment-description">JPG · 1.2 MB</span></div>
  </div>
  <div data-slot="attachment" data-state="uploading" data-size="default" data-orientation="vertical">
    <div data-slot="attachment-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="Studio" /></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">studio.png</span><span data-slot="attachment-description">Uploading · 40%</span></div>
  </div>
</div>
```

## Group

HEEx:

```heex
<.attachment_group>
  <.attachment :for={file <- @files} class="w-64">
    <:media><.icon name="hero-document-text" /></:media>
    <:title>{file.name}</:title>
    <:description>{file.meta}</:description>
    <:actions>
      <.attachment_action label={"Remove #{file.name}"} phx-click="remove" phx-value-id={file.id}>
        <.icon name="hero-x-mark" />
      </.attachment_action>
    </:actions>
  </.attachment>
</.attachment_group>
```

```html
<div class="w-full max-w-sm">
  <div data-slot="attachment-group">
    <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-64">
      <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-text" aria-hidden="true"></span></div>
      <div data-slot="attachment-content"><span data-slot="attachment-title">roadmap-q3.pdf</span><span data-slot="attachment-description">PDF · 1.1 MB</span></div>
      <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove roadmap-q3.pdf" title="Remove roadmap-q3.pdf"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
    </div>
    <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-64">
      <div data-slot="attachment-media" data-variant="image"><img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><rect width='80' height='80' fill='%23d4d4d4'/><circle cx='57' cy='23' r='8' fill='%23f5f5f5'/><path d='M0 62 24 36l17 19 12-11 27 21v15H0z' fill='%23a3a3a3'/></svg>" alt="team-offsite.jpg" /></div>
      <div data-slot="attachment-content"><span data-slot="attachment-title">team-offsite.jpg</span><span data-slot="attachment-description">JPG · 3.4 MB</span></div>
      <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove team-offsite.jpg" title="Remove team-offsite.jpg"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
    </div>
    <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-64">
      <div data-slot="attachment-media" data-variant="icon"><span class="hero-table-cells" aria-hidden="true"></span></div>
      <div data-slot="attachment-content"><span data-slot="attachment-title">budget-2026.xlsx</span><span data-slot="attachment-description">XLSX · 88 KB</span></div>
      <div data-slot="attachment-actions"><button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove budget-2026.xlsx" title="Remove budget-2026.xlsx"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button></div>
    </div>
  </div>
</div>
```

## Trigger

HEEx:

```heex
<.attachment class="w-full">
  <:media><.icon name="hero-document-magnifying-glass" /></:media>
  <:title>research-summary.pdf</:title>
  <:description>Open preview dialog</:description>
  <:actions>
    <.attachment_action label="Remove research-summary.pdf" phx-click="remove"><.icon name="hero-x-mark" /></.attachment_action>
  </:actions>
  <:trigger label="Preview research-summary.pdf" phx-click={show_modal("preview")} />
</.attachment>
```

```html
<div class="w-full max-w-sm">
  <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-full">
    <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-magnifying-glass" aria-hidden="true"></span></div>
    <div data-slot="attachment-content"><span data-slot="attachment-title">research-summary.pdf</span><span data-slot="attachment-description">Open preview dialog</span></div>
    <div data-slot="attachment-actions">
      <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Copy link" title="Copy link" data-toast="Link copied"><span class="hero-link size-3.5" aria-hidden="true"></span></button>
      <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove research-summary.pdf" title="Remove research-summary.pdf" data-toast="Removed research-summary.pdf"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button>
    </div>
    <button type="button" data-slot="attachment-trigger" aria-label="Preview research-summary.pdf" data-toast="Opening preview…"></button>
  </div>
</div>
```
