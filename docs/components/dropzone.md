# Dropzone

A file picker people can also drop files on: a dashed area that opens the picker on a click or tap, with picked files as attachment tiles under it.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

The zone is the upload's phx-drop-target: a <label> around the visually hidden live_file_input, so a click, a tap, Enter or Space opens the picker - no inline JS. Without slots the title and the description come from the upload ("One .csv file, up to 1 MB."). Each entry is an <.attachment>: uploading with its progress, done, or an error with the reason; on_cancel adds a remove button. Errors for the whole upload (too many files) show under the zone. The ShadcnDropzone hook highlights the zone while files are over it on every LiveView version, and takes a plain form's drops (name instead of upload).

## Usage guidance

Use when:

- Every file upload in a form: an import, attachments, a logo or avatar
- Tight forms: size="compact", one input-height row

Don't use for:

- Showing files already attached - render them as <.attachment> tiles, without a picker
- A bare live_file_input or a hand-rolled drop area - this is the one file picker
- Pasting images into a message composer - handle paste on the composer itself

Sizing: Default: at least 8rem tall, 24px padding, rounded-lg, a 32px muted icon box, a text-sm medium title and one text-xs muted line. Compact: h-9 like an input (44px on touch), the description under it in text-sm muted. Tiles are full width, 8px apart.

Responsive: Full width of the form column at every width. Touch screens can't drag, so the title reads "Choose a file" there and the compact row grows to 44px.

iOS: .fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:) behind a bordered button (or PhotosPicker for photos), plus .dropDestination(for: URL.self) for drag and drop on iPad; picked files are attachment rows below it.

## Specs

| Part | Description |
| --- | --- |
| Zone | Dashed rounded-lg label; the drop target and the picker. |
| Icon | hero-arrow-up-tray in a 32px muted box. |
| Title | text-sm medium: what to drop or choose. |
| Description | text-xs muted: types, size limit, how many. |
| Errors | text-sm destructive lines under the zone. |
| Entries | One full-width attachment tile per file. |

| Property | Value |
| --- | --- |
| Zone | min-height 8rem, 1.5rem padding, var(--radius-lg) |
| Border | 1px dashed var(--border-color); var(--primary) while dragging |
| Drag fill | var(--accent), 150ms (none with reduced motion) |
| Icon box | 2rem, var(--muted), var(--radius-md), 1rem glyph |
| Compact | 2.25rem row (2.75rem on touch), var(--radius-md) |
| Focus ring | 0 0 0 3px var(--ring) @ 50% while the input has :focus-visible |

Tokens used: `border-color`, `primary`, `accent`, `muted`, `muted-foreground`, `input`, `ring`, `destructive`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Focus the zone (its input); the ring shows |
| Enter / Space | Open the file picker |
| Tab | Move on to each file's remove button |

Role / ARIA: A native file input, visually hidden inside the zone's <label>: the label's title names it, aria-describedby reads the description and the errors, aria-invalid marks a rejected file. Picked files are a list.

Focus: The 3px ring is drawn on the zone while its input has :focus-visible (:has), so a mouse click doesn't leave it lit.

Screen reader: The input announces its title, then the description and any errors. Upload errors are in a polite live region; each file's tile names it and its state.

Touch target: The whole zone is the target; compact grows to 44px on touch. Touch screens can't drag, so the title says "Choose a file".

Reduced motion: The 150ms border and fill change is dropped.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
@State private var importing = false
@State private var files: [URL] = []

Button("Choose a CSV file", systemImage: "square.and.arrow.up") { importing = true }
    .buttonStyle(.bordered)
    .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText]) { result in
        if case .success(let url) = result { files = [url] }
    }
    .dropDestination(for: URL.self) { urls, _ in
        files = Array(urls.prefix(1))
        return !urls.isEmpty
    }

ForEach(files, id: \.self) { url in
    AttachmentRow(name: url.lastPathComponent, size: url.fileSize, progress: upload.progress[url])
}
```

iPhone has no drag between apps: the picker button is the control and .dropDestination only adds iPad drag and drop. Show each picked file as a row (icon, name, size, a ProgressView while it uploads, a remove button), as <.attachment> does.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| upload | Phoenix.LiveView.UploadConfig | nil |
| name / accept / multiple | plain form (instead of upload) | nil |
| size | default \| compact | default |
| disabled | boolean | false |
| on_cancel | event \| JS (pushes %{"ref" => ref}) | nil |
| target | phx-target for on_cancel | nil |
| error_text | fn error -> text \| nil end | nil |
| :title touch | slot + touch-screen wording | from the upload |
| :description | slot | types, size limit, count |
| :entry | slot (:let={entry}) | attachment tile |

## Default

HEEx:

```heex
<.dropzone id="import-file" upload={@uploads.people_csv} on_cancel="import:cancel">
  <:title touch="Choose a CSV file">Drop a CSV file here, or choose one</:title>
  <:description>One .csv file, up to 1 MB.</:description>
</.dropzone>
```

```html
<div id="import-file-demo" class="dropzone w-full max-w-md" data-dropzone="plain" data-size="default">
  <label class="dropzone-area" data-dropzone-area>
    <input type="file" id="import-file-demo-input" name="people_csv" accept=".csv" class="dropzone-input" aria-describedby="import-file-demo-description">
    <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
    <span id="import-file-demo-title" class="dropzone-title">
      <span class="dropzone-mouse">Drop a CSV file here, or choose one</span>
      <span class="dropzone-touch">Choose a CSV file</span>
    </span>
    <span id="import-file-demo-description" class="dropzone-description" aria-hidden="true">
      One .csv file, up to 1 MB.
    </span>
    <span id="import-file-demo-chosen" class="dropzone-chosen" data-dropzone-chosen phx-update="ignore" hidden>
    </span>
  </label>
  <div id="import-file-demo-errors" class="dropzone-errors" aria-live="polite">
  </div>
</div>
```

## Compact

HEEx:

```heex
<label for={@uploads.logo.ref} class="text-sm font-medium">Logo</label>
<.dropzone id="logo" upload={@uploads.logo} size="compact" on_cancel="cancel-upload" />
```

```html
<div class="grid w-full max-w-sm gap-2">
  <label for="logo-demo-input" class="text-sm font-medium">Logo</label>
  <div id="logo-demo" class="dropzone" data-dropzone="plain" data-size="compact">
    <label class="dropzone-area" data-dropzone-area>
      <input type="file" id="logo-demo-input" name="logo" accept=".png,.svg" class="dropzone-input" aria-describedby="logo-demo-description">
      <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
      <span id="logo-demo-title" class="dropzone-title">
        <span class="dropzone-mouse">Choose a file or drop it here</span>
        <span class="dropzone-touch">Choose a file</span>
      </span>
      <span id="logo-demo-chosen" class="dropzone-chosen" data-dropzone-chosen phx-update="ignore" hidden>
      </span>
    </label>
    <p id="logo-demo-description" class="dropzone-description">
      One .png or .svg file, up to 500 KB.
    </p>
    <div id="logo-demo-errors" class="dropzone-errors" aria-live="polite">
    </div>
  </div>
</div>
```

## Multiple, uploading

HEEx:

```heex
<%!-- allow_upload(:files, accept: ~w(image/* .pdf), max_entries: 5, auto_upload: true) --%>
<.dropzone id="attachments" upload={@uploads.files} on_cancel="cancel-upload" />

def handle_event("cancel-upload", %{"ref" => ref}, socket),
  do: {:noreply, cancel_upload(socket, :files, ref)}
```

```html
<div id="attachments-demo" class="dropzone w-full max-w-md" data-dropzone="upload" data-size="default">
  <label class="dropzone-area" data-dropzone-area>
    <input id="phx-demo-files" type="file" name="files" accept="image/*,.pdf" data-phx-auto-upload class="dropzone-input" multiple aria-describedby="attachments-demo-description">
    <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
    <span id="attachments-demo-title" class="dropzone-title">
      <span class="dropzone-mouse">Drop files here, or choose them</span>
      <span class="dropzone-touch">Choose files</span>
    </span>
    <span id="attachments-demo-description" class="dropzone-description" aria-hidden="true">
      Up to 5 image or .pdf files, 8 MB each.
    </span>
  </label>
  <div id="attachments-demo-errors" class="dropzone-errors" aria-live="polite">
  </div>
  <div class="dropzone-entries" role="list" aria-label="Chosen files">
    <div role="listitem">
      <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" id="attachments-demo-0">
        <div data-slot="attachment-media" data-variant="icon">
          <span class="hero-check" aria-hidden="true"></span>
        </div>
        <div data-slot="attachment-content">
          <span data-slot="attachment-title">inspection-report.pdf</span>
          <span data-slot="attachment-description">
            Uploaded · 2.4 MB
          </span>
        </div>
        <div data-slot="attachment-actions">
          <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove inspection-report.pdf" title="Remove inspection-report.pdf" phx-click="cancel-upload" phx-value-ref="0">
            <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
    <div role="listitem">
      <div data-slot="attachment" data-state="uploading" data-size="default" data-orientation="horizontal" id="attachments-demo-1">
        <div data-slot="attachment-media" data-variant="icon">
          <span class="loading loading-spinner loading-sm" aria-hidden="true"></span>
        </div>
        <div data-slot="attachment-content">
          <span data-slot="attachment-title">roof-measurements.pdf</span>
          <span data-slot="attachment-description">
            Uploading · 64%
          </span>
        </div>
        <div data-slot="attachment-actions">
          <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Cancel roof-measurements.pdf" title="Cancel roof-measurements.pdf" phx-click="cancel-upload" phx-value-ref="1">
            <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
    <div role="listitem">
      <div data-slot="attachment" data-state="uploading" data-size="default" data-orientation="horizontal" id="attachments-demo-2">
        <div data-slot="attachment-media" data-variant="icon">
          <span class="loading loading-spinner loading-sm" aria-hidden="true"></span>
        </div>
        <div data-slot="attachment-content">
          <span data-slot="attachment-title">permit-scan.pdf</span>
          <span data-slot="attachment-description">
            Uploading · 12%
          </span>
        </div>
        <div data-slot="attachment-actions">
          <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Cancel permit-scan.pdf" title="Cancel permit-scan.pdf" phx-click="cancel-upload" phx-value-ref="2">
            <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Errors

HEEx:

```heex
<.dropzone
  id="import-file"
  upload={@uploads.people_csv}
  on_cancel="import:cancel"
  error_text={fn
    :not_accepted -> "That isn't a CSV file. Export the sheet as .csv first."
    _ -> nil
  end}
/>
```

```html
<div id="import-errors-demo" class="dropzone w-full max-w-md" data-dropzone="upload" data-size="default" data-invalid>
  <label class="dropzone-area" data-dropzone-area>
    <input id="phx-demo-people_csv" type="file" name="people_csv" accept=".csv" class="dropzone-input" aria-describedby="import-errors-demo-description import-errors-demo-errors import-errors-demo-0-error import-errors-demo-1-error" aria-invalid="true">
    <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
    <span id="import-errors-demo-title" class="dropzone-title">
      <span class="dropzone-mouse">Drop a file here, or choose one</span>
      <span class="dropzone-touch">Choose a file</span>
    </span>
    <span id="import-errors-demo-description" class="dropzone-description" aria-hidden="true">
      One .csv file, up to 1 MB.
    </span>
  </label>
  <div id="import-errors-demo-errors" class="dropzone-errors" aria-live="polite">
    <p>
      <span class="hero-exclamation-circle" aria-hidden="true"></span>Too many files. Choose one.
    </p>
  </div>
  <div class="dropzone-entries" role="list" aria-label="Chosen files">
    <div role="listitem">
      <div data-slot="attachment" data-state="error" data-size="default" data-orientation="horizontal" id="import-errors-demo-0">
        <div data-slot="attachment-media" data-variant="icon">
          <span class="hero-exclamation-triangle" aria-hidden="true"></span>
        </div>
        <div data-slot="attachment-content">
          <span data-slot="attachment-title">people.xlsx</span>
          <span data-slot="attachment-description">
            <span id="import-errors-demo-0-error">That isn&#39;t a CSV file. Export the sheet as .csv first.</span>
          </span>
        </div>
        <div data-slot="attachment-actions">
          <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove people.xlsx" title="Remove people.xlsx" phx-click="import:cancel" phx-value-ref="0">
            <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
    <div role="listitem">
      <div data-slot="attachment" data-state="error" data-size="default" data-orientation="horizontal" id="import-errors-demo-1">
        <div data-slot="attachment-media" data-variant="icon">
          <span class="hero-exclamation-triangle" aria-hidden="true"></span>
        </div>
        <div data-slot="attachment-content">
          <span data-slot="attachment-title">people-2019-2026.csv</span>
          <span data-slot="attachment-description">
            <span id="import-errors-demo-1-error">File is larger than 1 MB.</span>
          </span>
        </div>
        <div data-slot="attachment-actions">
          <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove people-2019-2026.csv" title="Remove people-2019-2026.csv" phx-click="import:cancel" phx-value-ref="1">
            <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Disabled

HEEx:

```heex
<.dropzone id="import-file" upload={@uploads.people_csv} disabled />
```

```html
<div id="import-disabled-demo" class="dropzone w-full max-w-md" data-dropzone="plain" data-size="default" data-disabled>
  <label class="dropzone-area" data-dropzone-area>
    <input type="file" id="import-disabled-demo-input" name="people_csv" accept=".csv" disabled class="dropzone-input" aria-describedby="import-disabled-demo-description">
    <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
    <span id="import-disabled-demo-title" class="dropzone-title">
      <span class="dropzone-mouse">Drop a file here, or choose one</span>
      <span class="dropzone-touch">Choose a file</span>
    </span>
    <span id="import-disabled-demo-description" class="dropzone-description" aria-hidden="true">
      One .csv file, up to 1 MB.
    </span>
    <span id="import-disabled-demo-chosen" class="dropzone-chosen" data-dropzone-chosen phx-update="ignore" hidden>
    </span>
  </label>
  <div id="import-disabled-demo-errors" class="dropzone-errors" aria-live="polite">
  </div>
</div>
```

## Plain form

HEEx:

```heex
<form action={~p"/documents"} method="post" enctype="multipart/form-data">
  <.dropzone id="documents" name="documents" accept=".pdf,.txt" multiple />
</form>
```

```html
<form action="#" class="w-full max-w-md">
  <div id="documents-demo" class="dropzone" data-dropzone="plain" data-size="default">
    <label class="dropzone-area" data-dropzone-area>
      <input type="file" id="documents-demo-input" name="documents[]" accept=".pdf,.txt" multiple class="dropzone-input" aria-describedby="documents-demo-description">
      <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
      <span id="documents-demo-title" class="dropzone-title">
        <span class="dropzone-mouse">Drop files here, or choose them</span>
        <span class="dropzone-touch">Choose files</span>
      </span>
      <span id="documents-demo-description" class="dropzone-description" aria-hidden="true">
        One or more .pdf or .txt files.
      </span>
      <span id="documents-demo-chosen" class="dropzone-chosen" data-dropzone-chosen phx-update="ignore" hidden>
      </span>
    </label>
    <div id="documents-demo-errors" class="dropzone-errors" aria-live="polite">
    </div>
  </div>
</form>
```
