defmodule ShadcnDaisyuiDemoWeb.Catalog.Enrichment.Composition do
  @moduledoc """
  Design metadata for the composition components (Item, Attachment, Message,
  Bubble, Marker, Range Calendar). Values mirror the `data-slot` rules in
  `priv/static/shadcn-daisyui.css`, which follow shadcn-svelte's default style.
  """

  def specs do
    %{
      "item" => %{
        specs: %{
          anatomy: [
            %{part: "Item", description: "data-slot=item row (a <div>, or an <a> when linked)."},
            %{
              part: "Media (optional)",
              description:
                "Leading icon, avatar, or 40px image; top-aligns when there's a description."
            },
            %{part: "Content", description: "Title (1 line) and description (2 lines, muted)."},
            %{part: "Actions (optional)", description: "Trailing buttons, badges, or a chevron."},
            %{part: "Header / footer (optional)", description: "Full-width rows above / below."}
          ],
          measurements: [
            %{property: "Padding (default / sm / xs)", value: "14px 16px / 10px 12px / 8px 10px"},
            %{property: "Gap (default / sm / xs)", value: "14px / 10px / 8px"},
            %{
              property: "Radius",
              value: "var(--radius-md), 1px border (transparent unless outline)"
            },
            %{property: "Title", value: "14px / 500, line-clamp 1"},
            %{property: "Description", value: "14px muted-foreground, line-clamp 2 (12px at xs)"},
            %{property: "Image media", value: "40px (sm 32px, xs 24px), var(--radius-sm)"},
            %{property: "Muted variant", value: "muted at 50%"},
            %{property: "Link hover", value: "muted background, 100ms"}
          ],
          tokens: ["border-color", "muted", "muted-foreground", "ring", "primary"]
        },
        accessibility: %{
          roles:
            "A plain container; <.item_group> is role=list, so give each item role=listitem. Linked items render a real <a>.",
          keyboard: [
            %{keys: "Tab", action: "Focus a linked item, or the buttons in its actions"},
            %{keys: "Enter", action: "Follow a linked item"}
          ],
          focus:
            "Linked items show the 3px ring (border-color ring + ring shadow). Don't nest interactive controls inside a linked item - keep actions outside or use a non-link item.",
          screen_reader:
            "Title then description read in order. Icon media is decorative (aria-hidden); give icon-only action buttons an aria-label.",
          touch_target:
            "Default rows are 48px+ tall; icon-only actions need a 44pt hit area on touch (btn-sm square is 32px - pad the row or use btn on touch).",
          reduced_motion: "Only a 100ms color change on hover; nothing moves."
        },
        swiftui: %{
          code: ~S"""
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
          """,
          notes:
            "Inside a List, the row is the item (drop the overlay). The outline variant maps to a stroked RoundedRectangle; muted to a .fill(Color.sdMuted.opacity(0.5)) background."
        },
        ios_status: :partial
      },
      "attachment" => %{
        specs: %{
          anatomy: [
            %{
              part: "Attachment",
              description: "Card-surface tile with data-state, data-size, data-orientation."
            },
            %{
              part: "Media",
              description: "Square icon well (muted) or image; dims while uploading/processing."
            },
            %{
              part: "Content",
              description: "Title (truncated, shimmers while busy) and description (12px muted)."
            },
            %{
              part: "Actions (optional)",
              description: "24px ghost icon buttons; top-right overlay when vertical."
            },
            %{
              part: "Trigger (optional)",
              description: "Invisible full-tile button under the actions."
            }
          ],
          measurements: [
            %{property: "Radius", value: "var(--radius-xl) (xs: var(--radius-lg))"},
            %{property: "Media", value: "40px (sm 32px, xs 28px), var(--radius-lg)"},
            %{property: "Padding with text", value: "8px 10px (sm 6px 8px, xs 4px 6px)"},
            %{property: "Min width", value: "160px horizontal; 96px vertical (120px with text)"},
            %{property: "idle", value: "dashed border"},
            %{property: "error", value: "destructive 30% border, destructive 10% media tint"},
            %{property: "uploading / processing", value: "title shimmer, image at 60% opacity"},
            %{property: "Group", value: "12px gap, horizontal scroll with snap"}
          ],
          tokens: [
            "card",
            "card-foreground",
            "border-color",
            "muted",
            "muted-foreground",
            "destructive",
            "ring"
          ]
        },
        accessibility: %{
          roles:
            "A plain container. The trigger is a real <button> with a required label (e.g. \"Preview report.pdf\"); actions are buttons with required labels.",
          keyboard: [
            %{keys: "Tab", action: "Move to the trigger, then each action"},
            %{keys: "Enter / Space", action: "Activate the focused trigger or action"}
          ],
          focus:
            "Focus anywhere inside shows a 1px ring around the whole tile; actions sit above the trigger so both stay clickable.",
          screen_reader:
            "Put the state in the description text (\"Uploading · 64%\", \"Upload failed. Try again.\") - the dashed border, tint, and shimmer are visual only. Name actions with the file (\"Remove report.pdf\").",
          touch_target:
            "Action buttons are 24px; on touch, the trigger covers the tile, and destructive actions should confirm or offer undo.",
          reduced_motion:
            "The title shimmer stops under prefers-reduced-motion; the text stays readable."
        },
        swiftui: %{
          code: ~S"""
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
          """,
          notes:
            "Use ProgressView(value:) in the media well while uploading, and QuickLook (.quickLookPreview) for the trigger."
        },
        ios_status: :partial
      },
      "message" => %{
        specs: %{
          anatomy: [
            %{
              part: "Message",
              description: "Row with data-align (end reverses it for the current user)."
            },
            %{
              part: "Avatar (optional)",
              description: "32px round, bottom-aligned with the last bubble."
            },
            %{part: "Content", description: "Column of header, bubbles/attachments, footer."},
            %{
              part: "Header / footer (optional)",
              description: "12px / 500 muted text, inset 12px."
            }
          ],
          measurements: [
            %{property: "Avatar gap", value: "8px"},
            %{property: "Content gap", value: "10px between parts"},
            %{property: "Avatar", value: "min 32px, muted fallback background"},
            %{
              property: "Header / footer",
              value: "12px / 500 muted-foreground, 12px inline padding (0 beside ghost bubbles)"
            },
            %{property: "Group gap", value: "8px (use gap-6 between turns)"}
          ],
          tokens: ["muted", "muted-foreground", "foreground"]
        },
        accessibility: %{
          roles:
            "Plain containers. Wrap a live transcript in <.message_group role=\"log\" aria-label=\"…\"> so new messages are announced politely.",
          focus:
            "Messages aren't focusable; only controls inside them (footer actions, links) are.",
          screen_reader:
            "Sender isn't conveyed by alignment alone - include the name in the header, or visually hidden text (\"You said\", \"Olivia said\") for avatar-less rows.",
          touch_target: "Footer action buttons need a 44pt hit area on touch.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          HStack(alignment: .bottom, spacing: 8) {
              if message.isMine { Spacer(minLength: 48) }
              if !message.isMine { AvatarView(message.author).frame(width: 32, height: 32) }
              VStack(alignment: message.isMine ? .trailing : .leading, spacing: 10) {
                  Text(message.author.name).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                  BubbleView(message)
              }
              if !message.isMine { Spacer(minLength: 48) }
          }
          """,
          notes:
            "Lay out a transcript as a ScrollView + LazyVStack with .defaultScrollAnchor(.bottom); post an accessibility announcement for incoming messages."
        },
        ios_status: :partial
      },
      "bubble" => %{
        specs: %{
          anatomy: [
            %{
              part: "Bubble",
              description: "data-variant / data-align wrapper; max 80% of the row (ghost: 100%)."
            },
            %{
              part: "Content",
              description:
                "The painted surface: a <div>, or a <button>/<a> for clickable bubbles."
            },
            %{
              part: "Reactions (optional)",
              description: "Pill on the top or bottom edge, ringed in the card color."
            }
          ],
          measurements: [
            %{property: "Padding", value: "8px 12px (ghost: 0)"},
            %{property: "Radius", value: "var(--radius-xl)"},
            %{property: "Text", value: "14px, 1.625 line height"},
            %{
              property: "default / secondary / muted",
              value: "primary / secondary / muted surfaces"
            },
            %{property: "tinted", value: "primary hue at L 0.93 (dark 0.30), 40% chroma"},
            %{property: "destructive", value: "destructive 10% (text destructive)"},
            %{
              property: "Reactions",
              value: "full radius, muted, 3px card ring, 75% off the edge, 12px inset"
            },
            %{property: "Group gap", value: "8px"}
          ],
          tokens: [
            "primary",
            "primary-foreground",
            "secondary",
            "secondary-foreground",
            "muted",
            "background",
            "border-color",
            "destructive",
            "card",
            "ring"
          ]
        },
        accessibility: %{
          roles:
            "Plain text containers. Clickable bubbles are real <button>s (type=button) or links. Reactions with a label become role=img with that label.",
          keyboard: [
            %{
              keys: "Tab",
              action: "Focus clickable bubbles (suggested replies) and links inside"
            },
            %{keys: "Enter / Space", action: "Send the focused suggested reply"}
          ],
          focus: "Clickable bubbles show the 3px ring on the content surface.",
          screen_reader:
            "Label reaction pills with a summary (\"Reactions: thumbs up, and 2 more\") - raw emoji read poorly. Variant color carries no meaning on its own.",
          touch_target:
            "Suggested-reply bubbles are at least 40px tall; keep 8px between them so taps don't collide.",
          reduced_motion: "Only a color change on hover; nothing moves."
        },
        swiftui: %{
          code: ~S"""
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
          """,
          notes:
            "Suggested replies map to Buttons with a bubble background; ghost bubbles are plain Text / markdown with no background."
        },
        ios_status: :partial
      },
      "marker" => %{
        specs: %{
          anatomy: [
            %{
              part: "Marker",
              description: "Full-width row (div, a, or button) with data-variant."
            },
            %{part: "Icon (optional)", description: "16px decorative glyph or spinner."},
            %{part: "Content", description: "Muted text; optional shimmer while in progress."}
          ],
          measurements: [
            %{property: "Text", value: "14px muted-foreground"},
            %{property: "Icon", value: "16px, 8px gap"},
            %{
              property: "separator",
              value: "1px border-color rules either side of centered text"
            },
            %{property: "border", value: "1px bottom border, 8px bottom padding"},
            %{property: "Link / button hover", value: "foreground text"},
            %{
              property: "Shimmer",
              value: "2s linear sweep, highlight 20% alpha (lighter in dark)"
            }
          ],
          tokens: ["muted-foreground", "foreground", "border-color"]
        },
        accessibility: %{
          roles:
            "status sets role=status, so live progress (\"Thinking…\") is announced politely. Link markers are <a>; action markers are <button type=button>.",
          keyboard: [
            %{keys: "Tab", action: "Focus link and button markers"},
            %{keys: "Enter / Space", action: "Activate the focused marker"}
          ],
          focus: "Only link and button markers are focusable.",
          screen_reader:
            "The icon is aria-hidden; the text must say what happened. Don't mark every historical note as status - only the one that's live.",
          touch_target:
            "Action markers are text-height; on touch, give them vertical padding (py-2) to reach 44pt.",
          reduced_motion:
            "The shimmer stops under prefers-reduced-motion; spinners keep turning slowly."
        },
        swiftui: %{
          code: ~S"""
          Label("Explored 4 files", systemImage: "magnifyingglass")
              .font(.subheadline)
              .foregroundStyle(.secondary)

          HStack(spacing: 4) {
              VStack { Divider() }
              Text("Today").font(.subheadline).foregroundStyle(.secondary)
              VStack { Divider() }
          }
          """,
          notes:
            "For the status marker use HStack { ProgressView(); Text(\"Thinking…\") }, and announce it with .accessibilityAddTraits(.updatesFrequently)."
        },
        ios_status: :partial
      },
      "range-calendar" => %{
        specs: %{
          anatomy: [
            %{
              part: "Root",
              description: "data-range-calendar wrapper with optional hidden start/end inputs."
            },
            %{
              part: "Navigation",
              description: "Previous / next month ghost buttons in the top corners."
            },
            %{
              part: "Month grid",
              description: "Caption, weekday header, and day buttons (role=gridcell)."
            },
            %{
              part: "Range band",
              description: "Endpoints in primary; days between on an accent band."
            }
          ],
          measurements: [
            %{property: "Day cell", value: "32px square, var(--radius-md)"},
            %{property: "Endpoints", value: "primary / primary-foreground"},
            %{
              property: "Band",
              value: "accent, square inside, rounded at the range ends and week edges"
            },
            %{property: "Today", value: "1px border-color ring"},
            %{property: "Months", value: "1 by default; 2 side by side at ≥ 640px, stacked below"}
          ],
          tokens: [
            "primary",
            "primary-foreground",
            "accent",
            "accent-foreground",
            "muted-foreground",
            "border-color"
          ]
        },
        accessibility: %{
          roles:
            "Each month is role=grid labeled with its month and year; days are buttons (role=gridcell) with full-date labels and aria-selected on the endpoints.",
          keyboard: [
            %{
              keys: "Tab",
              action: "Move focus into the grid (one tab stop) and to the month buttons"
            },
            %{
              keys: "Arrow keys",
              action: "Move one day / one week; previews the band while picking the end"
            },
            %{keys: "Home / End", action: "Start / end of the week"},
            %{keys: "PageUp / PageDown", action: "Previous / next month (Shift: year)"},
            %{keys: "Enter / Space", action: "Set the start, then the end"}
          ],
          focus:
            "Roving tabindex: the focused, selected, or today's date is the single tab stop; the view follows focus across months.",
          screen_reader:
            "Day buttons announce the full date and whether they're selected. Echo the chosen range in nearby text (or the form's labels) so it's confirmed after selection.",
          touch_target:
            "Day cells are 32px; on touch-first layouts scale the grid up (e.g. [--cell:2.75rem]) or use the native date inputs.",
          reduced_motion: "No animation; month changes swap instantly."
        },
        swiftui: %{
          code: ~S"""
          @State private var start = Date()
          @State private var end = Date().addingTimeInterval(7 * 86_400)

          Form {
              DatePicker("Check-in", selection: $start, displayedComponents: .date)
              DatePicker("Check-out", selection: $end, in: start..., displayedComponents: .date)
          }
          """,
          notes:
            "SwiftUI has no range-band calendar. Two bound DatePickers (or MultiDatePicker for discrete days) cover the data; a custom LazyVGrid is needed for the visual band."
        },
        ios_status: :guidance_only
      }
    }
  end
end
