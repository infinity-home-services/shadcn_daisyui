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

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

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
end
