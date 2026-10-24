defmodule ShadcnDaisyui.Components.Conversation do
  @moduledoc """
  Conversation components (chat and AI transcripts): message, bubble, and
  marker. They compose with `ShadcnDaisyui.Components.Display.attachment/1` and
  `ShadcnDaisyui.Components.Display.avatar/1`.

      <.message_group>
        <.message align="end">
          <.bubble>Deploying to prod real quick.</.bubble>
        </.message>
        <.message>
          <:avatar><.avatar fallback="R" class="w-8" /></:avatar>
          <.bubble variant="muted">It's 4:55 PM. On a Friday.</.bubble>
        </.message>
        <.marker status shimmer>Oliver is typing...</.marker>
      </.message_group>

  An AI chat adds three more: `message_scroller/1` (the scrolling transcript
  that follows a streaming reply), `trace/1` (the assistant's steps, tool
  calls, sources and plans) and `prompt_input/1` (the composer: a growing
  field, Send that turns into Stop, attachments and suggestions).

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias ShadcnDaisyui.CoreComponents
  alias ShadcnDaisyui.FormComponents

  # ----------------------------------------------------------------------------
  # Message
  # ----------------------------------------------------------------------------
  @doc """
  One turn in a conversation: optional avatar, header (name, time), the content
  (bubbles, attachments, anything), and a footer (status, actions).
  `align="end"` puts the avatar on the right and right-aligns the content (the
  current user's messages).

      <.message align="end">
        <:avatar><.avatar fallback="ME" class="w-8" /></:avatar>
        <.bubble>It's a one-line change.</.bubble>
        <:footer>Delivered</:footer>
      </.message>
  """
  attr(:align, :string, default: "start", values: ~w(start end))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:avatar)
  slot(:header)
  slot(:footer)
  slot(:inner_block, required: true)

  def message(assigns) do
    ~H"""
    <div data-slot="message" data-align={@align} class={@class} {@rest}>
      <div :for={avatar <- @avatar} data-slot="message-avatar">{render_slot(avatar)}</div>
      <div data-slot="message-content">
        <div :if={@header != []} data-slot="message-header">{render_slot(@header)}</div>
        {render_slot(@inner_block)}
        <div :if={@footer != []} data-slot="message-footer">{render_slot(@footer)}</div>
      </div>
    </div>
    """
  end

  @doc """
  A vertical run of messages. For a live transcript, set `role="log"` and an
  `aria-label` so new messages are announced.

      <.message_group role="log" aria-label="Conversation">…</.message_group>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def message_group(assigns) do
    ~H"""
    <div data-slot="message-group" class={@class} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  # ----------------------------------------------------------------------------
  # Bubble
  # ----------------------------------------------------------------------------
  @bubble_tags %{"div" => "div", "button" => "button", "a" => "a"}

  @doc """
  A message bubble. Variants: `default` (primary, your own messages),
  `secondary`, `muted` (incoming), `tinted` (soft primary), `outline`, `ghost`
  (unframed, full width - assistant text and markdown), `destructive`.

      <.bubble variant="muted">Alright, let me take a look.</.bubble>
      <.bubble align="end">Sounds good.</.bubble>

  Reactions sit on the bubble edge:

      <.bubble variant="muted">
        Tests passed on the first try.
        <:reactions label="Reactions: party popper">🎉</:reactions>
      </.bubble>

  Make the bubble itself clickable (suggested replies) with `as="button"` or
  `as="a"`; `rest` attributes (`phx-click`, `href`, …) go on that element:

      <.bubble variant="tinted" align="end" as="button" phx-click="reply" phx-value-text="I forgot my password">
        I forgot my password
      </.bubble>
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default secondary muted tinted outline ghost destructive)
  )

  attr(:align, :string, default: "start", values: ~w(start end))
  attr(:as, :string, default: "div", values: ~w(div button a), doc: "the content element")
  attr(:class, :any, default: nil, doc: "on the bubble root")
  attr(:content_class, :any, default: nil, doc: "on the content surface")
  attr(:rest, :global, include: ~w(href target rel download type disabled), doc: "on the content")

  slot :reactions do
    attr(:label, :string, doc: "accessible summary, e.g. \"Reactions: thumbs up\"")
    attr(:side, :string, values: ~w(top bottom))
    attr(:align, :string, values: ~w(start end))
  end

  slot(:inner_block, required: true)

  def bubble(assigns) do
    assigns =
      assigns
      |> assign(:tag, Map.fetch!(@bubble_tags, assigns.as))
      |> assign(:rest, button_type(assigns.rest, assigns.as))

    ~H"""
    <div data-slot="bubble" data-variant={@variant} data-align={@align} class={@class}>
      <.dynamic_tag
        tag_name={@tag}
        data-slot="bubble-content"
        class={@content_class}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.dynamic_tag>
      <div
        :for={r <- @reactions}
        data-slot="bubble-reactions"
        data-side={r[:side] || "bottom"}
        data-align={r[:align] || "end"}
        role={r[:label] && "img"}
        aria-label={r[:label]}
      >
        {render_slot(r)}
      </div>
    </div>
    """
  end

  @doc """
  Consecutive bubbles from the same sender, spaced tighter than separate
  messages.

      <.bubble_group>
        <.bubble variant="muted">It's always a one-line change.</.bubble>
        <.bubble variant="muted">Alright, let me take a look.</.bubble>
      </.bubble_group>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def bubble_group(assigns) do
    ~H"""
    <div data-slot="bubble-group" class={@class} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  # ----------------------------------------------------------------------------
  # Marker
  # ----------------------------------------------------------------------------
  @doc """
  An inline line inside a conversation: a status ("Thinking..."), a system note,
  a bordered row, or a labeled separator.

      <.marker>
        <:icon><.icon name="hero-magnifying-glass" /></:icon>
        Explored 4 files
      </.marker>
      <.marker variant="separator">Today</.marker>
      <.marker variant="border">Reviewed 8 related files</.marker>
      <.marker status shimmer>
        <:icon><.spinner size="loading-xs" /></:icon>
        Thinking...
      </.marker>

  `status` sets `role="status"` so screen readers announce it; `shimmer` sweeps
  a highlight across the text (respects reduced motion). Pass `href` /
  `navigate` / `patch` for a link marker, or `as="button"` (with `phx-click`) for
  an action.
  """
  attr(:variant, :string, default: "default", values: ~w(default separator border))
  attr(:status, :boolean, default: false, doc: "announce as role=status")
  attr(:shimmer, :boolean, default: false, doc: "animated in-progress text")
  attr(:as, :string, default: "div", values: ~w(div button))
  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(type disabled target rel download))
  slot(:icon, doc: "a 16px glyph or spinner (decorative, aria-hidden)")
  slot(:inner_block, required: true)

  def marker(assigns) do
    assigns =
      assigns
      |> assign(:link?, !!(assigns.href || assigns.navigate || assigns.patch))
      |> assign(:rest, button_type(assigns.rest, assigns.as))

    ~H"""
    <.link
      :if={@link?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      data-slot="marker"
      data-variant={@variant}
      class={@class}
      {@rest}
    >
      <.marker_parts icon={@icon} shimmer={@shimmer} inner_block={@inner_block} />
    </.link>
    <.dynamic_tag
      :if={!@link?}
      tag_name={@as}
      data-slot="marker"
      data-variant={@variant}
      role={@status && "status"}
      class={@class}
      {@rest}
    >
      <.marker_parts icon={@icon} shimmer={@shimmer} inner_block={@inner_block} />
    </.dynamic_tag>
    """
  end

  # <button>s default to type="button" so they never submit an enclosing form
  defp button_type(rest, "button"), do: Map.put_new(rest, :type, "button")
  defp button_type(rest, _as), do: rest

  defp marker_parts(assigns) do
    ~H"""
    <span :if={@icon != []} data-slot="marker-icon" aria-hidden="true">{render_slot(@icon)}</span>
    <span data-slot="marker-content" class={@shimmer && "shimmer"}>{render_slot(@inner_block)}</span>
    """
  end

  # ----------------------------------------------------------------------------
  # Message scroller
  # ----------------------------------------------------------------------------
  @doc """
  The scrolling transcript of a chat, as shadcn/ui's Message Scroller: a
  labelled, keyboard-scrollable viewport that fills its parent, the rows in a
  `role="log"` live region, and a scroll-to-latest button that is inert while
  there is nothing below.

      <.message_scroller
        id="chat"
        items={@streams.messages}
        anchor={fn {_id, m} -> m.role == :user end}
        busy={@streaming?}
        default_position="last-anchor"
        :let={{_id, m}}
      >
        <:above :if={@more?}>
          <.button variant="ghost" size="sm" phx-click="load-earlier">Load earlier messages</.button>
        </:above>
        <.message align={if m.role == :user, do: "end", else: "start"}>…</.message>
      </.message_scroller>

  `items` is a list (each row keyed by `item.id`, or `item_id`) or a LiveView
  stream (`phx-update="stream"`, keyed by the stream's DOM ids). Each row is
  rendered by the inner block, `:let={item}` (`{dom_id, item}` for a stream,
  as in `<.table>`). `anchor` marks turn anchors - usually the reader's own
  messages. `busy` sets `aria-busy` on the log while a reply streams, so
  screen readers announce it once it's done.

  Behaviour (the `ShadcnMessageScroller` hook):

    * Opens at `default_position`: `"end"` (the latest message), `"start"`,
      or `"last-anchor"` (the last anchored turn at the top; the end when that
      turn fits or there is none). The viewport stays hidden until it's
      positioned, so it never flashes the top first.
    * Follows new and growing content (a streaming reply) while the reader is
      at the live edge (`follow`); a wheel, touch, scroll key or the scrollbar
      releases it, and scrolling back down or the button re-engages it.
    * A new anchored turn moves near the top, `peek` px (64) of the row before
      it still showing, with room made below it for the reply.
    * Rows added above (a stream insert `at: 0`, "Load earlier") keep the row
      you are reading in place.

  `<:above>` and `<:below>` render inside the log, above and below the rows
  (a "Load earlier" button, a typing marker). Put it in a parent with a
  height: in `<.app_shell fill>` it fills the page between the page header and
  the composer. Dispatch `shadcn:scroll-to` on it with
  `detail: %{to: "end" | "start" | row_dom_id}` to jump.
  """
  attr(:id, :string, required: true)

  attr(:items, :any,
    required: true,
    doc: "the rows: a list, or a LiveView stream (`@streams.messages`)"
  )

  attr(:item_id, :any,
    default: nil,
    doc: "`fn item -> dom_id end`; a stream's own ids, or \"<id>-<item.id>\" for a list"
  )

  attr(:anchor, :any, default: nil, doc: "`fn item -> boolean end`: turn anchors")
  attr(:busy, :boolean, default: false, doc: "a reply is streaming (`aria-busy` on the log)")
  attr(:default_position, :string, default: "end", values: ~w(end start last-anchor))
  attr(:follow, :boolean, default: true, doc: "follow new content while at the live edge")
  attr(:peek, :integer, default: 64, doc: "px of the previous row left above a new anchor")
  attr(:label, :string, default: "Messages", doc: "the viewport's accessible name")
  attr(:button, :string, default: "end", values: ~w(end start both none))
  attr(:end_label, :string, default: "Scroll to latest message")
  attr(:start_label, :string, default: "Scroll to first message")
  attr(:class, :any, default: nil)
  attr(:content_class, :any, default: nil, doc: "on the log (gap, padding, max width)")
  attr(:item_class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "one row, `:let={item}`")
  slot(:above, doc: "inside the log, above the rows")
  slot(:below, doc: "inside the log, below the rows")

  def message_scroller(assigns) do
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.items)
    id = assigns.id

    item_id =
      cond do
        assigns.item_id -> assigns.item_id
        stream? -> fn {dom_id, _item} -> dom_id end
        true -> fn item -> "#{id}-#{list_item_key!(item)}" end
      end

    assigns =
      assigns
      |> assign(:stream?, stream?)
      |> assign(:item_dom_id, item_id)
      |> assign(:anchor?, assigns.anchor || fn _ -> false end)
      |> assign(:pending, assigns.default_position != "start")

    ~H"""
    <div
      id={@id}
      data-slot="message-scroller"
      data-default-position={@default_position}
      data-follow={to_string(@follow)}
      data-peek={@peek}
      data-pending-scroll={@pending}
      phx-hook="ShadcnMessageScroller"
      phx-mounted={
        JS.ignore_attributes(["data-pending-scroll", "data-scrollable", "data-autoscrolling"])
      }
      class={@class}
      {@rest}
    >
      <div
        id={"#{@id}-viewport"}
        data-slot="message-scroller-viewport"
        role="region"
        aria-label={@label}
        tabindex="0"
        data-pending-scroll={@pending}
        phx-mounted={
          JS.ignore_attributes(["data-pending-scroll", "data-scrollable", "data-autoscrolling"])
        }
      >
        <div
          data-slot="message-scroller-content"
          role="log"
          aria-relevant="additions"
          aria-busy={to_string(@busy)}
          class={@content_class}
        >
          <div :if={@above != []} data-slot="message-scroller-above">{render_slot(@above)}</div>
          <div id={"#{@id}-items"} data-slot="message-scroller-items" phx-update={@stream? && "stream"}>
            <div
              :for={item <- @items}
              id={@item_dom_id.(item)}
              data-slot="message-scroller-item"
              data-scroll-anchor={to_string(!!@anchor?.(item))}
              class={@item_class}
            >
              {render_slot(@inner_block, item)}
            </div>
          </div>
          <div :if={@below != []} data-slot="message-scroller-below">{render_slot(@below)}</div>
        </div>
        <div
          data-slot="message-scroller-spacer"
          aria-hidden="true"
          phx-mounted={JS.ignore_attributes(["style"])}
        >
        </div>
      </div>
      <.scroller_button :if={@button in ~w(start both)} id={@id} direction="start" label={@start_label} />
      <.scroller_button :if={@button in ~w(end both)} id={@id} direction="end" label={@end_label} />
    </div>
    """
  end

  defp list_item_key!(%{id: key}) when not is_nil(key), do: key

  defp list_item_key!(item) do
    raise ArgumentError,
          "<.message_scroller> keys a list's rows by `item.id`; pass `item_id` for #{inspect(item)}"
  end

  attr(:id, :string, required: true)
  attr(:direction, :string, required: true)
  attr(:label, :string, required: true)

  defp scroller_button(assigns) do
    ~H"""
    <button
      type="button"
      id={"#{@id}-to-#{@direction}"}
      data-slot="message-scroller-button"
      data-direction={@direction}
      data-active="false"
      aria-controls={"#{@id}-viewport"}
      title={@label}
      inert
      tabindex="-1"
      class="btn btn-outline btn-square"
      phx-mounted={JS.ignore_attributes(["data-active", "inert", "tabindex"])}
    >
      <span class="hero-arrow-down size-4" aria-hidden="true"></span>
      <span class="sr-only">{@label}</span>
    </button>
    """
  end

  # ----------------------------------------------------------------------------
  # Trace
  # ----------------------------------------------------------------------------
  @doc """
  What the assistant did or is doing, as shadcn/ui's Trace: one row per step,
  tool call, source or plan item. A row is done unless it has a `status`:
  `running` (its title shimmers; not with reduced motion), `pending` (not
  started, dimmed) or `error`.

      <.trace>
        <:line icon="hero-check">Searched 240 orders</:line>
        <:line icon="hero-check" description="3 files">Read the customer file</:line>
        <:line status="running" icon="hero-sparkles">Checking the invoices</:line>
        <:line status="pending" icon="hero-ellipsis-horizontal">Write the summary</:line>
      </.trace>

  A `<:line>` takes `status`, `icon` (a heroicon name), `description` (short
  text after the title that never truncates: a duration, a count) and
  `href` / `navigate` / `patch` (a source link; `target="_blank"` says "opens
  in a new tab" to screen readers). The title is one line and truncates.

  A row that opens to show detail (a tool call's input and output, the steps
  behind a summary, the sources an answer used) is a `trace_line/1` in the
  inner block, with a `<:detail>`; rows nest:

      <.trace>
        <.trace_line id="turn-7-steps">
          <:icon><.icon name="hero-list-bullet" /></:icon>
          Worked through 3 steps
          <:description>4s</:description>
          <:detail>
            <.trace>
              <:line icon="hero-check">Searched 240 orders</:line>
            </.trace>
          </:detail>
        </.trace_line>
      </.trace>

  Status is shown by colour and motion only, so word the title to say it:
  "Running mix test", "Failed to send the email". Each row is a list item;
  the icons are hidden from screen readers.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :line, doc: "one row; the inner block is its title" do
    attr(:status, :string, values: ~w(running pending error))
    attr(:icon, :string, doc: "a heroicon name: \"hero-magnifying-glass\"")
    attr(:description, :string, doc: "short text after the title (a duration, a count)")
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:target, :string)
  end

  slot(:inner_block, doc: "`trace_line/1` rows (with detail, a custom icon)")

  def trace(assigns) do
    ~H"""
    <div data-slot="trace" role="list" class={@class} {@rest}>
      <.trace_line
        :for={line <- @line}
        status={line[:status]}
        href={line[:href]}
        navigate={line[:navigate]}
        patch={line[:patch]}
        target={line[:target]}
      >
        <:icon :if={line[:icon]}><span class={line[:icon]}></span></:icon>
        {render_slot(line)}
        <:description :if={line[:description]}>{line[:description]}</:description>
      </.trace_line>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  One `trace/1` row with slots: `<:icon>` (any 16px glyph, spinner or
  favicon), the title (inner block), `<:description>` and `<:detail>`. With a
  `<:detail>` the row is a disclosure - a button with `aria-expanded` and a
  chevron that opens the detail under it (indented, with a line on its left) -
  and needs an `id`. `open` is how it starts; after that the reader's choice
  stands across LiveView patches.

      <.trace_line id="call-42" status="error">
        <:icon><.icon name="hero-command-line" /></:icon>
        Failed to run mix test
        <:description>2 failures</:description>
        <:detail>…</:detail>
      </.trace_line>
  """
  attr(:id, :string, default: nil, doc: "required with `<:detail>`")
  attr(:status, :string, default: nil, values: [nil, "running", "pending", "error"])
  attr(:open, :boolean, default: false, doc: "with `<:detail>`: start open")
  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:target, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(rel download))

  slot(:icon, doc: "a 16px glyph before the title (hidden from screen readers)")
  slot(:inner_block, required: true, doc: "the title: one line, truncated")
  slot(:description, doc: "short text after the title; never truncates")
  slot(:detail, doc: "what the row opens to show; makes it a disclosure")

  def trace_line(%{detail: [_ | _], id: nil}) do
    raise ArgumentError, "<.trace_line> with a <:detail> needs an `id` (the button controls it)"
  end

  def trace_line(assigns) do
    assigns = assign(assigns, :link?, !!(assigns.href || assigns.navigate || assigns.patch))

    ~H"""
    <div role="listitem" data-slot="trace-item" class={@class}>
      <%= cond do %>
        <% @detail != [] -> %>
          <div id={@id} data-slot="trace-collapsible">
            <button
              type="button"
              id={"#{@id}-trigger"}
              data-slot="trace-collapsible-trigger"
              aria-expanded={to_string(@open)}
              aria-controls={"#{@id}-detail"}
              phx-mounted={JS.ignore_attributes(["aria-expanded"])}
              {@rest}
            >
              <.trace_parts {assigns} />
              <span data-slot="trace-icon" data-chevron aria-hidden="true">
                <span class="hero-chevron-right"></span>
              </span>
            </button>
            <div id={"#{@id}-detail"} data-slot="trace-collapsible-content">
              <div data-slot="trace-collapsible-clip">
                <div data-slot="trace-collapsible-content-inner">{render_slot(@detail)}</div>
              </div>
            </div>
          </div>
        <% @link? -> %>
          <.link
            href={@href}
            navigate={@navigate}
            patch={@patch}
            target={@target}
            data-slot="trace-link"
            {@rest}
          >
            <.trace_parts {assigns} />
          </.link>
        <% true -> %>
          <.trace_parts {assigns} />
      <% end %>
    </div>
    """
  end

  defp trace_parts(assigns) do
    ~H"""
    <span data-slot="trace-line" data-status={@status}>
      <span :for={icon <- @icon} data-slot="trace-icon" aria-hidden="true">{render_slot(icon)}</span>
      <span data-slot="trace-title" class={@status == "running" && "shimmer"}>
        {render_slot(@inner_block)}<span :if={@target == "_blank"} class="sr-only"> (opens in a new tab)</span>
      </span>
      <span :if={@description != []} data-slot="trace-description">{render_slot(@description)}</span>
    </span>
    """
  end

  # ----------------------------------------------------------------------------
  # Prompt input
  # ----------------------------------------------------------------------------
  @doc """
  The chat composer: a field that grows with its text (up to 12rem, then it
  scrolls), Send that turns into Stop while a reply streams, an attach button
  on a LiveView upload with the picked files as attachment tiles above the
  text, and suggestion chips above it all. Put it in your form:

      <.form for={@form} id="chat-form" phx-change="validate" phx-submit="send">
        <.prompt_input
          id="composer"
          field={@form[:text]}
          placeholder="Ask anything…"
          busy={@streaming?}
          on_stop="stop"
          upload={@uploads.files}
          on_cancel="cancel-upload"
        >
          <:suggestion :if={@empty?} value="Which orders are overdue?">Overdue orders</:suggestion>
        </.prompt_input>
      </.form>

  Enter sends (Shift+Enter adds a line; never while an input method is
  composing), and the field clears as soon as the message is on its way -
  reset your form in the submit handler too. Send does nothing while the field
  is empty (`aria-disabled`, unless files are attached). While `busy` the
  button is Stop: it pushes `on_stop` (an event, default `"stop"`, or a
  `Phoenix.LiveView.JS`; `target` for a LiveComponent) and Enter doesn't send.

  `upload` adds the attach button (a label around the hidden
  `live_file_input`, so Enter or Space opens the picker); files dropped on the
  field or pasted into it go to the same upload. Each picked file is an
  `<.attachment>` tile, like `<.dropzone>`'s; `on_cancel` adds the remove
  button (`%{"ref" => ref}`), `error_text` words the errors.

  A `<:suggestion value="…">` is a `<.bubble as="button">` chip that puts its
  `value` in the field and sends it (`send={false}`: only fills the field), or
  give it your own `phx-click`. `<:tools>` adds controls beside the attach
  button (a model picker). Needs the `ShadcnPromptInput` hook.
  """
  attr(:id, :string, required: true)
  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "the message field: `@form[:text]`")
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:label, :string, default: "Message", doc: "the field's accessible name")
  attr(:placeholder, :string, default: nil)
  attr(:busy, :boolean, default: false, doc: "a reply is streaming: the button is Stop")
  attr(:on_stop, :any, default: "stop", doc: "event (or JS) the Stop button pushes")
  attr(:target, :any, default: nil, doc: "`phx-target` for `on_stop` and `on_cancel`")
  attr(:upload, Phoenix.LiveView.UploadConfig, default: nil, doc: "adds the attach button")
  attr(:on_cancel, :any, default: nil, doc: "event (or JS) a tile's remove button pushes")
  attr(:error_text, :any, default: nil, doc: "`fn error -> text end` for upload errors")
  attr(:disabled, :boolean, default: false)
  attr(:submit_label, :string, default: "Send")
  attr(:stop_label, :string, default: "Stop")
  attr(:attach_label, :string, default: "Attach files")
  attr(:suggestions_label, :string, default: "Suggestions")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:suggestion,
    doc:
      "a chip: `value` (put in the field and sent), `send={false}`, `variant`, or your own `phx-click`"
  )

  slot(:tools, doc: "controls beside the attach button")

  def prompt_input(assigns) do
    assigns = prompt_field(assigns)
    entries = if assigns.upload, do: assigns.upload.entries, else: []

    upload_messages =
      if assigns.upload,
        do: FormComponents.upload_messages(assigns.upload, assigns.error_text),
        else: []

    blank? = assigns.value |> to_string() |> String.trim() == ""

    assigns =
      assigns
      |> assign(:entries, entries)
      |> assign(:upload_messages, upload_messages)
      |> assign(:empty?, blank? and entries == [])
      |> assign(
        :describedby,
        [
          upload_messages != [] && "#{assigns.id}-errors",
          assigns.errors != [] && "#{assigns.id}-field-errors"
        ]
        |> Enum.filter(& &1)
        |> Enum.join(" ")
      )

    ~H"""
    <div
      id={@id}
      data-slot="prompt-input"
      data-busy={@busy}
      data-disabled={@disabled}
      data-dropzone={@upload && "upload"}
      phx-hook="ShadcnPromptInput"
      class={@class}
      {@rest}
    >
      <div
        :if={@suggestion != []}
        data-slot="prompt-input-suggestions"
        role="group"
        aria-label={@suggestions_label}
      >
        <.bubble
          :for={s <- @suggestion}
          variant={s[:variant] || "outline"}
          as="button"
          data-prompt-suggestion={s[:value]}
          data-send={s[:send] == false && "false"}
          disabled={@disabled}
          {Phoenix.Component.assigns_to_attributes(s, [:value, :send, :variant])}
        >
          {render_slot(s)}
        </.bubble>
      </div>
      <div
        data-slot="prompt-input-box"
        data-dropzone-area
        phx-drop-target={@upload && !@disabled && @upload.ref}
        phx-mounted={JS.ignore_attributes(["data-dragging"])}
      >
        <div
          :if={@entries != []}
          data-slot="prompt-input-attachments"
          role="list"
          aria-label="Attached files"
        >
          <FormComponents.upload_tiles
            id={@id}
            upload={@upload}
            on_cancel={@on_cancel}
            target={@target}
            error_text={@error_text}
          />
        </div>
        <textarea
          id={@input_id}
          name={@name}
          data-slot="prompt-input-textarea"
          rows="1"
          placeholder={@placeholder}
          aria-label={@label}
          aria-describedby={@describedby != "" && @describedby}
          aria-invalid={@errors != [] && "true"}
          enterkeyhint="send"
          disabled={@disabled}
          phx-mounted={JS.ignore_attributes(["style"])}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
        <div data-slot="prompt-input-toolbar">
          <label
            :if={@upload}
            data-slot="prompt-input-attach"
            class="btn btn-ghost btn-square"
            title={@attach_label}
            data-disabled={@disabled}
          >
            <.live_file_input upload={@upload} disabled={@disabled} />
            <span class="hero-paper-clip size-4" aria-hidden="true"></span>
            <span class="sr-only">{@attach_label}</span>
          </label>
          {render_slot(@tools)}
          <button
            type={if @busy, do: "button", else: "submit"}
            id={"#{@id}-submit"}
            data-slot="prompt-input-submit"
            data-state={if @busy, do: "busy", else: "idle"}
            class={["btn btn-square", if(@busy, do: "btn-secondary", else: "btn-primary")]}
            aria-label={if @busy, do: @stop_label, else: @submit_label}
            title={if @busy, do: @stop_label, else: @submit_label}
            aria-disabled={@empty? and !@busy and "true"}
            disabled={@disabled}
            phx-click={@busy && @on_stop}
            phx-target={@busy && @target}
            phx-mounted={JS.ignore_attributes(["aria-disabled"])}
          >
            <span :if={!@busy} class="hero-arrow-up size-4" aria-hidden="true"></span>
            <span :if={@busy} class="hero-stop-solid size-4" aria-hidden="true"></span>
          </button>
        </div>
      </div>
      <div
        :if={@upload}
        id={"#{@id}-errors"}
        data-slot="prompt-input-errors"
        aria-live="polite"
      >
        <p :for={msg <- @upload_messages}>
          <span class="hero-exclamation-circle size-4" aria-hidden="true"></span>{msg}
        </p>
      </div>
      <div :if={@errors != []} id={"#{@id}-field-errors"} data-slot="prompt-input-field-errors">
        <CoreComponents.error :for={msg <- @errors}>{msg}</CoreComponents.error>
      </div>
    </div>
    """
  end

  # id/name/value/errors from the field; explicit attrs win
  defp prompt_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors =
      if Phoenix.Component.used_input?(field),
        do: Enum.map(field.errors, &ShadcnDaisyui.Translate.translate_error/1),
        else: []

    assigns
    |> assign(:field, nil)
    |> assign(:errors, errors)
    |> assign(:input_id, field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, if(is_nil(assigns.value), do: field.value, else: assigns.value))
  end

  defp prompt_field(assigns) do
    assigns
    |> assign(:errors, [])
    |> assign(:input_id, "#{assigns.id}-input")
  end
end
