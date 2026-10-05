defmodule ShadcnDaisyuiDemoWeb.Catalog.Composition do
  @moduledoc """
  Base catalog entries for the shadcn composition components added in 0.5:
  Item, Attachment, Message, Bubble, Marker, and Range Calendar. Their design
  metadata lives in `Catalog.Enrichment.Composition`; both are merged into the
  catalog by `ShadcnDaisyuiDemoWeb.Catalog`.

  Each example's `code` is the exact markup the function component renders
  (`data-slot` attributes, styled by the theme CSS), so it works as a plain-HTML
  recipe too. Image examples use an inline SVG placeholder so they need no
  network.
  """

  def all do
    [item(), attachment(), message(), bubble(), marker(), range_calendar()]
  end

  defp item do
    %{
      slug: "item",
      title: "Item",
      description:
        "A versatile row for displaying content with media, title, description, and actions.",
      guidance: %{
        use_when: [
          "Settings rows, notification rows, and file/member lists: one object per row with an action",
          "A list where each row needs more than a label (media, two lines of text, buttons)"
        ],
        avoid_when: [
          "Form fields - use <.field> / <.input>, which own labels and errors",
          "Dense tabular data you compare across rows - use <.table>",
          "Menu commands - use a dropdown menu or command palette"
        ],
        sizing:
          "Default 14px/16px padding; sm 10px/12px for denser lists; xs 8px/10px inside menus and popovers. Titles clamp to one line, descriptions to two.",
        responsive:
          "Rows wrap: header/footer always span the full width, and actions drop under the text when space runs out. On compact screens keep one primary action per row.",
        ios:
          "A List row: HStack of image, VStack(title, subtitle), Spacer, trailing control. Use .listRowInsets to match the size scale."
      },
      props: [
        %{name: "variant", type: "default | outline | muted", default: "default"},
        %{name: "size", type: "default | sm | xs", default: "default"},
        %{name: "href / navigate / patch", type: "string", default: "nil (renders a link)"},
        %{name: ":media variant", type: "default | icon | image", default: "default"},
        %{
          name: "slots",
          type: ":media :title :description :actions :header :footer",
          default: "-"
        }
      ],
      examples: [
        %{
          title: "Variants",
          heex: ~S"""
          <.item>
            <:title>Default Variant</:title>
            <:description>Standard styling with subtle background and borders.</:description>
            <:actions><.button variant="outline" size="sm">Open</.button></:actions>
          </.item>
          <.item variant="outline">…</.item>
          <.item variant="muted">…</.item>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Size",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Icon",
          heex: ~S"""
          <.item variant="outline">
            <:media variant="icon"><.icon name="hero-shield-exclamation" /></:media>
            <:title>Security Alert</:title>
            <:description>New login detected from unknown device.</:description>
            <:actions><.button size="sm" variant="outline">Review</.button></:actions>
          </.item>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Avatar",
          heex: ~S"""
          <.item variant="outline">
            <:media><.avatar fallback="ER" class="w-10" /></:media>
            <:title>Evil Rabbit</:title>
            <:description>Last seen 5 months ago</:description>
            <:actions>
              <.button variant="outline" size="icon" aria-label="Invite"><.icon name="hero-plus" /></.button>
            </:actions>
          </.item>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Image",
          heex: ~S"""
          <.item variant="outline" href={~p"/albums/#{album}"}>
            <:media variant="image"><img src={album.cover_url} alt={album.title} /></:media>
            <:title>{album.title} <span class="text-muted-foreground">- {album.artist}</span></:title>
            <:description>{album.album}</:description>
            <:actions><span class="text-sm text-muted-foreground">{album.duration}</span></:actions>
          </.item>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Group",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Header & footer",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        }
      ]
    }
  end

  defp attachment do
    %{
      slug: "attachment",
      title: "Attachment",
      description:
        "Displays a file or image attachment with media, metadata, upload state, and actions.",
      guidance: %{
        use_when: [
          "Files picked for upload, in progress, or already attached (composer, form, message)",
          "Showing a file's name, type, and size with remove / download / retry actions"
        ],
        avoid_when: [
          "The file input itself - use a file input or drop zone, then render picked files as attachments",
          "Image galleries - use a grid of images or a carousel"
        ],
        sizing:
          "Default: 40px media, 14px text. sm: 32px media, 12px text. xs: 28px media for tight composers. Horizontal tiles are at least 160px; vertical tiles 96px (120px with text).",
        responsive:
          "Put several in an <.attachment_group>: one horizontally scrolling, snap-aligned row that never wraps the layout. Use w-full tiles in a vertical list on compact screens.",
        ios:
          "An HStack card: thumbnail or SF Symbol, VStack(name, metadata), trailing buttons; ProgressView for uploading. ShareLink / QuickLook for open and download."
      },
      props: [
        %{name: "state", type: "idle | uploading | processing | error | done", default: "done"},
        %{name: "size", type: "default | sm | xs", default: "default"},
        %{name: "orientation", type: "horizontal | vertical", default: "horizontal"},
        %{name: ":media variant", type: "icon | image", default: "icon"},
        %{name: ":trigger", type: "label (required) + phx-click", default: "-"},
        %{name: "attachment_action label", type: "string (required)", default: "-"}
      ],
      examples: [
        %{
          title: "Default",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "States",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Sizes",
          heex: ~S"""
          <.attachment size="sm">…</.attachment>
          <.attachment size="xs">…</.attachment>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Image",
          heex: ~S"""
          <.attachment orientation="vertical">
            <:media variant="image"><img src={@photo.url} alt={@photo.name} /></:media>
            <:title>{@photo.name}</:title>
            <:description>{@photo.size}</:description>
          </.attachment>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Group",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Trigger",
          heex: ~S"""
          <.attachment class="w-full">
            <:media><.icon name="hero-document-magnifying-glass" /></:media>
            <:title>research-summary.pdf</:title>
            <:description>Open preview dialog</:description>
            <:actions>
              <.attachment_action label="Remove research-summary.pdf" phx-click="remove"><.icon name="hero-x-mark" /></.attachment_action>
            </:actions>
            <:trigger label="Preview research-summary.pdf" phx-click={show_modal("preview")} />
          </.attachment>
          """,
          code: ~S"""
          <div class="w-full max-w-sm">
            <div data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal" class="w-full">
              <div data-slot="attachment-media" data-variant="icon"><span class="hero-document-magnifying-glass" aria-hidden="true"></span></div>
              <div data-slot="attachment-content"><span data-slot="attachment-title">research-summary.pdf</span><span data-slot="attachment-description">Open preview dialog</span></div>
              <div data-slot="attachment-actions">
                <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Copy link" title="Copy link" onclick="window.toast('Link copied')"><span class="hero-link size-3.5" aria-hidden="true"></span></button>
                <button type="button" data-slot="attachment-action" class="btn btn-square btn-xs btn-ghost" aria-label="Remove research-summary.pdf" title="Remove research-summary.pdf" onclick="window.toast('Removed research-summary.pdf')"><span class="hero-x-mark size-3.5" aria-hidden="true"></span></button>
              </div>
              <button type="button" data-slot="attachment-trigger" aria-label="Preview research-summary.pdf" onclick="window.toast('Opening preview…')"></button>
            </div>
          </div>
          """
        }
      ]
    }
  end

  defp message do
    %{
      slug: "message",
      title: "Message",
      description:
        "Displays a message in a conversation, with optional avatar, header, footer, and alignment.",
      guidance: %{
        use_when: [
          "Chat, support, and AI-assistant transcripts",
          "Comment threads where each entry has an author, content, and status"
        ],
        avoid_when: [
          "Notifications or activity feeds without a conversation - use <.item>",
          "A single system notice inside a transcript - use <.marker>"
        ],
        sizing:
          "8px between avatar and content, 10px between parts of one message, 32px avatars. Header/footer are 12px muted text inset 12px to line up with bubble text.",
        responsive:
          "Content takes the remaining width; bubbles cap at 80% of it. On compact screens drop avatars for the current user's own (align end) messages.",
        ios:
          "A ScrollView of HStacks (avatar + VStack of bubbles), aligned leading/trailing by sender; use .defaultScrollAnchor(.bottom)."
      },
      props: [
        %{name: "align", type: "start | end", default: "start"},
        %{name: "slots", type: ":avatar :header :footer + inner content", default: "-"},
        %{
          name: "message_group",
          type: "role=\"log\" aria-label for live transcripts",
          default: "-"
        }
      ],
      examples: [
        %{
          title: "Default",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Header & footer",
          heex: ~S"""
          <.message>
            <:header>Olivia</:header>
            <.bubble variant="muted">I already checked the logs.</.bubble>
          </.message>
          <.message align="end">
            <.bubble>Send the report to the team. Ping @shadcn if you need help.</.bubble>
            <:footer>Read <span class="font-normal">Yesterday</span></:footer>
          </.message>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Attachment",
          heex: ~S"""
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
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Actions",
          heex: ~S"""
          <.message>
            <.bubble variant="muted">The install failure is coming from the workspace package.</.bubble>
            <:footer>
              <.button variant="ghost" size="icon" aria-label="Copy" phx-click="copy"><.icon name="hero-clipboard" /></.button>
              <.button variant="ghost" size="icon" aria-label="Like" phx-click="like"><.icon name="hero-hand-thumb-up" /></.button>
              <.button variant="ghost" size="icon" aria-label="Dislike" phx-click="dislike"><.icon name="hero-hand-thumb-down" /></.button>
            </:footer>
          </.message>
          """,
          code: ~S"""
          <div class="w-full max-w-sm">
            <div data-slot="message" data-align="start">
              <div data-slot="message-content">
                <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">The install failure is coming from the workspace package.</div></div>
                <div data-slot="message-footer">
                  <button class="btn btn-ghost btn-square btn-sm" aria-label="Copy" title="Copy" onclick="window.toast('Copied to clipboard')"><span class="hero-clipboard size-4" aria-hidden="true"></span></button>
                  <button class="btn btn-ghost btn-square btn-sm" aria-label="Like" title="Like"><span class="hero-hand-thumb-up size-4" aria-hidden="true"></span></button>
                  <button class="btn btn-ghost btn-square btn-sm" aria-label="Dislike" title="Dislike"><span class="hero-hand-thumb-down size-4" aria-hidden="true"></span></button>
                </div>
              </div>
            </div>
          </div>
          """
        }
      ]
    }
  end

  defp bubble do
    %{
      slug: "bubble",
      title: "Bubble",
      description:
        "Displays conversational content in a message bubble, with variants, alignment, grouping, and reactions.",
      guidance: %{
        use_when: [
          "The content of a chat message, inside <.message> (or on its own)",
          "Suggested replies: a group of clickable tinted bubbles (as=\"button\")",
          "Assistant answers with markdown: the ghost variant (no frame, full width)"
        ],
        avoid_when: [
          "Callouts and notices on a page - use <.alert> or a card",
          "Status lines inside a transcript - use <.marker>"
        ],
        sizing:
          "12px/8px padding, 14px text at 1.625 line height, var(--radius-xl) corners, max 80% of the row (ghost: 100%). 8px between bubbles in a group.",
        responsive:
          "Bubbles wrap long words and never exceed their row; keep the 80% cap on compact screens so sender alignment stays readable.",
        ios:
          "Text with padding and a RoundedRectangle background (accent for own messages, secondarySystemFill for others); reactions as an overlay(alignment: .bottomTrailing) capsule."
      },
      props: [
        %{
          name: "variant",
          type: "default | secondary | muted | tinted | outline | ghost | destructive",
          default: "default"
        },
        %{name: "align", type: "start | end", default: "start"},
        %{name: "as", type: "div | button | a", default: "div"},
        %{
          name: ":reactions",
          type: "label, side (top | bottom), align (start | end)",
          default: "-"
        }
      ],
      examples: [
        %{
          title: "Variants",
          heex: ~S"""
          <.bubble>This is the default primary bubble.</.bubble>
          <.bubble variant="secondary" align="end">This is the secondary variant.</.bubble>
          <.bubble variant="muted">This one is muted.</.bubble>
          <.bubble variant="tinted" align="end">This one is tinted.</.bubble>
          <.bubble variant="outline">We can also use an outlined variant.</.bubble>
          <.bubble variant="destructive" align="end">Or a destructive variant.</.bubble>
          <.bubble variant="ghost">Ghost bubbles work for assistant text and markdown.</.bubble>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Reactions",
          heex: ~S"""
          <.bubble variant="muted" align="end">
            I don't need tests, I know my code works.
            <:reactions label="Reactions: thumbs up, surprised" align="start">👍 😮</:reactions>
          </.bubble>
          <.bubble align="end">
            Tests passed on the first try. All 142 of them.
            <:reactions label="Reactions: party popper, clapping hands" side="top" align="start">🎉 👏</:reactions>
          </.bubble>
          """,
          code: ~S"""
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
          """
        },
        %{
          title: "Suggested replies",
          heex: ~S"""
          <.bubble variant="muted">How can I help you today?</.bubble>
          <.bubble_group>
            <.bubble :for={reply <- @suggestions} variant="tinted" align="end" as="button" phx-click="reply" phx-value-text={reply}>
              {reply}
            </.bubble>
          </.bubble_group>
          """,
          code: ~S"""
          <div class="flex w-full max-w-sm flex-col gap-8">
            <div data-slot="bubble" data-variant="muted" data-align="start"><div data-slot="bubble-content">How can I help you today?</div></div>
            <div data-slot="bubble-group">
              <div data-slot="bubble" data-variant="tinted" data-align="end"><button type="button" data-slot="bubble-content" onclick="window.toast('You clicked forgot password')">I forgot my password</button></div>
              <div data-slot="bubble" data-variant="tinted" data-align="end"><button type="button" data-slot="bubble-content" onclick="window.toast('You clicked help with subscription')">I need help with my subscription</button></div>
              <div data-slot="bubble" data-variant="tinted" data-align="end"><button type="button" data-slot="bubble-content" onclick="window.toast('Connecting you to a human…')">Something else. Talk to a human.</button></div>
            </div>
          </div>
          """
        },
        %{
          title: "Group",
          heex: ~S"""
          <.bubble_group>
            <.bubble variant="muted">Hey, are you around?</.bubble>
            <.bubble variant="muted">The deploy is stuck on step 3.</.bubble>
          </.bubble_group>
          """,
          code: ~S"""
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
          """
        }
      ]
    }
  end

  defp marker do
    %{
      slug: "marker",
      title: "Marker",
      description:
        "Displays an inline status, system note, bordered row, or labeled separator in a conversation.",
      guidance: %{
        use_when: [
          "Agent or system activity in a transcript (\"Explored 4 files\", \"Switched branch\")",
          "Live status while work runs (\"Thinking…\", \"Running tests\") with status + shimmer",
          "Date or event separators between groups of messages (variant=\"separator\")"
        ],
        avoid_when: [
          "Messages from a person or the assistant - use <.message> + <.bubble>",
          "Page-level notices - use <.alert>; transient confirmations - use toast()"
        ],
        sizing:
          "14px muted text, 16px icon, 8px icon gap. Border variant adds 8px bottom padding and a 1px rule; separator draws 1px rules either side.",
        responsive:
          "Markers span the full width of the transcript and wrap long text; separator labels stay centered.",
        ios:
          "A Label(text, systemImage:) in .secondary foreground; separators as HStack { Divider; Text; Divider }. Use ProgressView() for the status spinner."
      },
      props: [
        %{name: "variant", type: "default | separator | border", default: "default"},
        %{name: "status", type: "boolean (role=status)", default: "false"},
        %{name: "shimmer", type: "boolean", default: "false"},
        %{name: "as", type: "div | button", default: "div"},
        %{name: "href / navigate / patch", type: "string", default: "nil (renders a link)"},
        %{name: ":icon", type: "slot (decorative)", default: "-"}
      ],
      examples: [
        %{
          title: "Default",
          heex: ~S"""
          <.marker>
            <:icon><.icon name="hero-arrows-right-left" /></:icon>
            Switched to a new branch
          </.marker>
          <.marker status shimmer>
            <:icon><.spinner size="loading-xs" /></:icon>
            Thinking...
          </.marker>
          <.marker variant="separator">Conversation compacted</.marker>
          """,
          code: ~S"""
          <div class="flex w-full max-w-sm flex-col gap-8">
            <div data-slot="marker" data-variant="default">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrows-right-left"></span></span>
              <span data-slot="marker-content">Switched to a new branch</span>
            </div>
            <div data-slot="marker" data-variant="default" role="status">
              <span data-slot="marker-icon" aria-hidden="true"><span class="loading loading-spinner loading-xs"></span></span>
              <span data-slot="marker-content" class="shimmer">Thinking...</span>
            </div>
            <div data-slot="marker" data-variant="separator">
              <span data-slot="marker-content">Conversation compacted</span>
            </div>
            <div data-slot="marker" data-variant="default">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-magnifying-glass"></span></span>
              <span data-slot="marker-content">Explored 4 files</span>
            </div>
          </div>
          """
        },
        %{
          title: "Variants",
          heex: ~S"""
          <.marker>A default marker for inline notes.</.marker>
          <.marker variant="separator">A separator marker</.marker>
          <.marker variant="border">A border marker for row boundaries.</.marker>
          """,
          code: ~S"""
          <div class="flex w-full max-w-sm flex-col gap-8">
            <div data-slot="marker" data-variant="default"><span data-slot="marker-content">A default marker for inline notes.</span></div>
            <div data-slot="marker" data-variant="separator"><span data-slot="marker-content">A separator marker</span></div>
            <div data-slot="marker" data-variant="border"><span data-slot="marker-content">A border marker for row boundaries.</span></div>
          </div>
          """
        },
        %{
          title: "Status & shimmer",
          heex: ~S"""
          <.marker status>
            <:icon><.spinner size="loading-xs" /></:icon>
            Compacting conversation
          </.marker>
          <.marker variant="separator" status shimmer>Reading 4 files</.marker>
          """,
          code: ~S"""
          <div class="flex w-full max-w-sm flex-col gap-8">
            <div data-slot="marker" data-variant="default" role="status">
              <span data-slot="marker-icon" aria-hidden="true"><span class="loading loading-spinner loading-xs"></span></span>
              <span data-slot="marker-content">Compacting conversation</span>
            </div>
            <div data-slot="marker" data-variant="separator" role="status">
              <span data-slot="marker-icon" aria-hidden="true"><span class="loading loading-spinner loading-xs"></span></span>
              <span data-slot="marker-content">Running tests</span>
            </div>
            <div data-slot="marker" data-variant="default" role="status">
              <span data-slot="marker-content" class="shimmer">Thinking...</span>
            </div>
            <div data-slot="marker" data-variant="separator" role="status">
              <span data-slot="marker-content" class="shimmer">Reading 4 files</span>
            </div>
          </div>
          """
        },
        %{
          title: "Border",
          heex: ~S"""
          <.marker :for={step <- @steps} variant="border">
            <:icon><.icon name={step.icon} /></:icon>
            {step.label}
          </.marker>
          """,
          code: ~S"""
          <div class="flex w-full max-w-sm flex-col gap-3">
            <div data-slot="marker" data-variant="border">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrows-right-left"></span></span>
              <span data-slot="marker-content">Switched to release-candidate</span>
            </div>
            <div data-slot="marker" data-variant="border">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-magnifying-glass"></span></span>
              <span data-slot="marker-content">Reviewed 8 related files</span>
            </div>
            <div data-slot="marker" data-variant="border">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-document-text"></span></span>
              <span data-slot="marker-content">Opened implementation notes</span>
            </div>
          </div>
          """
        },
        %{
          title: "Links & buttons",
          heex: ~S"""
          <.marker href={@pr_url}>
            <:icon><.icon name="hero-arrows-right-left" /></:icon>
            View the pull request
          </.marker>
          <.marker as="button" phx-click="revert">
            <:icon><.icon name="hero-arrow-uturn-left" /></:icon>
            Revert this change
          </.marker>
          """,
          code: ~S"""
          <div class="flex w-full max-w-sm flex-col gap-8">
            <a href="#links-and-buttons" data-slot="marker" data-variant="default">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrows-right-left"></span></span>
              <span data-slot="marker-content">View the pull request</span>
            </a>
            <button type="button" data-slot="marker" data-variant="default" onclick="window.toast('You clicked the revert button')">
              <span data-slot="marker-icon" aria-hidden="true"><span class="hero-arrow-uturn-left"></span></span>
              <span data-slot="marker-content">Revert this change</span>
            </button>
          </div>
          """
        }
      ]
    }
  end

  defp range_calendar do
    %{
      slug: "range-calendar",
      title: "Range Calendar",
      description: "A calendar component that allows users to select a range of dates.",
      hook: true,
      guidance: %{
        use_when: [
          "Picking a start and end date in place, where the calendar is the main control (booking, reporting periods)",
          "Forms that store two date fields (check-in / check-out) - bind start_name / end_name"
        ],
        avoid_when: [
          "Space is tight or the range is secondary - use <.date_range> (a popover)",
          "A single date - use <.calendar> or <.date_picker>"
        ],
        sizing:
          "32px day cells, 12px padding; one month by default, months={2} side by side on medium screens and up.",
        responsive:
          "Two months stack vertically under 640px. Keep the calendar inside a card or bordered box so it reads as one control.",
        ios:
          "MultiDatePicker covers discrete days; for a true range, two DatePickers (.graphical) bound to start/end, or a custom grid."
      },
      props: [
        %{name: "id", type: "string (required)", default: "-"},
        %{name: "months", type: "integer", default: "1"},
        %{name: "start / end", type: "Date | ISO string", default: "nil"},
        %{name: "start_name / end_name", type: "string (form field names)", default: "nil"}
      ],
      notes:
        "Emits ISO dates (YYYY-MM-DD) into hidden inputs when start_name / end_name are set, dispatching input + change so phx-change fires. A range-change DOM event with { start, end } bubbles from the root.",
      examples: [
        %{
          title: "Default",
          heex: ~S"""
          <.range_calendar id="range-calendar" class="w-fit rounded-md border border-base-300 p-3" />
          """,
          code: ~S"""
          <div data-range-calendar data-months="1" class="w-fit rounded-md border border-base-300 p-3">
            <div data-range-calendar-grid></div>
          </div>
          """
        },
        %{
          title: "Two months",
          heex: ~S"""
          <.range_calendar id="report-period" months={2} class="w-fit rounded-md border border-base-300 p-3" />
          """,
          code: ~S"""
          <div data-range-calendar data-months="2" class="w-fit rounded-md border border-base-300 p-3">
            <div data-range-calendar-grid></div>
          </div>
          """
        },
        %{
          title: "Form",
          heex: ~S"""
          <.form for={@form} id="booking-form" phx-change="validate" phx-submit="save">
            <.range_calendar
              id="booking-dates"
              start_name={@form[:check_in].name}
              end_name={@form[:check_out].name}
              start={@form[:check_in].value}
              end={@form[:check_out].value}
              class="w-fit rounded-md border border-base-300 p-3"
            />
            <.button>Book</.button>
          </.form>
          """,
          code: ~S"""
          <form class="flex flex-col items-start gap-3" onsubmit="event.preventDefault(); const d = new FormData(this); window.toast('Booked', { description: d.get('booking[check_in]') + ' → ' + d.get('booking[check_out]') })">
            <div data-range-calendar data-months="1" class="w-fit rounded-md border border-base-300 p-3">
              <input type="hidden" name="booking[check_in]" data-range-start />
              <input type="hidden" name="booking[check_out]" data-range-end />
              <div data-range-calendar-grid></div>
            </div>
            <button class="btn btn-primary">Book</button>
          </form>
          """
        }
      ]
    }
  end
end
