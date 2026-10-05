defmodule ShadcnDaisyui.Components.Display do
  @moduledoc """
  Display components: accordion, avatar, item, attachment, progress, skeleton,
  spinner, and the toaster.

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  @doc """
  An accordion. One section open at a time by default (radio-based); pass
  `multiple` for independent sections.

      <.accordion id="faq">
        <:section title="Is it accessible?" open>Yes. It adheres to the WAI-ARIA pattern.</:section>
        <:section title="Is it styled?">Yes, shadcn-matched out of the box.</:section>
      </.accordion>
  """
  attr(:id, :string, required: true)
  attr(:multiple, :boolean, default: false, doc: "allow several sections open at once")
  attr(:class, :any, default: nil)

  slot :section, required: true do
    attr(:title, :string, required: true)
    attr(:open, :boolean)
  end

  def accordion(assigns) do
    ~H"""
    <div class={["card w-full", @class]}>
      <div class="card-body py-1">
        <div :for={section <- @section} class="collapse collapse-arrow">
          <input
            type={(@multiple && "checkbox") || "radio"}
            name={!@multiple && @id}
            checked={section[:open]}
          />
          <div class="collapse-title">{section.title}</div>
          <div class="collapse-content">{render_slot(section)}</div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  An avatar with image or initials fallback.

      <.avatar src={@user.photo_url} alt={@user.name} fallback="JD" />
      <.avatar fallback="UI" shape="rounded-lg" />
  """
  attr(:src, :string, default: nil)
  attr(:alt, :string, default: nil)
  attr(:fallback, :string, default: nil, doc: "initials shown when there is no image")
  attr(:shape, :string, default: "rounded-full")
  attr(:class, :any, default: "w-10", doc: "size classes")

  def avatar(assigns) do
    ~H"""
    <div class={["avatar", !@src && "avatar-placeholder"]}>
      <div class={[@shape, @class]}>
        <img :if={@src} src={@src} alt={@alt} />
        <span :if={!@src} class="text-sm font-medium">{@fallback}</span>
      </div>
    </div>
    """
  end

  @doc """
  A stacked group of avatars.

      <.avatar_group>
        <.avatar fallback="AB" class="w-10" />
        <.avatar fallback="CD" class="w-10" />
        <.avatar fallback="+3" class="w-10" />
      </.avatar_group>
  """
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def avatar_group(assigns) do
    ~H"""
    <div class={["avatar-group -space-x-3", @class]}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  A progress bar.

      <.progress value={60} />
  """
  attr(:value, :integer, default: nil, doc: "omit for an indeterminate bar")
  attr(:max, :integer, default: 100)
  attr(:class, :any, default: "w-full")

  def progress(assigns) do
    ~H"""
    <progress class={["progress", @class]} value={@value} max={@max}></progress>
    """
  end

  @doc """
  A skeleton placeholder. Size it with classes.

      <.skeleton class="h-4 w-48" />
      <.skeleton class="h-10 w-10 rounded-full" />
  """
  attr(:class, :any, default: "h-4 w-full")

  def skeleton(assigns) do
    ~H"""
    <div class={["skeleton", @class]}></div>
    """
  end

  @doc """
  A loading spinner.

      <.spinner />
      <.spinner size="loading-sm" />
  """
  attr(:size, :string, default: nil, values: [nil, "loading-xs", "loading-sm", "loading-lg"])
  attr(:class, :any, default: nil)

  def spinner(assigns) do
    ~H"""
    <span class={["loading loading-spinner", @size, @class]}></span>
    """
  end

  @doc """
  The toaster: where `toast()` (from the bundled JS) and `push_toast/3` render
  sonner-style notifications. Put one in your root layout. It needs the
  `ShadcnToaster` hook for server-pushed toasts (`push_toast/3`); client-only
  `toast()` calls work without it.

      <.toaster />
      <.toaster position="top-center" rich_colors close_button />

  For form/validation feedback tied to a page, prefer `<.flash>` or inline
  errors; toasts are for brief confirmations that disappear.
  """
  attr(:id, :string, default: "toaster")

  attr(:position, :string,
    default: "bottom-right",
    values: ~w(top-left top-center top-right bottom-left bottom-center bottom-right)
  )

  attr(:expand, :boolean, default: false, doc: "show every toast expanded instead of stacked")
  attr(:rich_colors, :boolean, default: false, doc: "tint success/info/warning/error toasts")
  attr(:close_button, :boolean, default: false, doc: "show a close button on every toast")
  attr(:duration, :integer, default: 4000, doc: "default auto-dismiss time in ms")
  attr(:visible_toasts, :integer, default: 3)
  attr(:class, :any, default: nil)

  def toaster(assigns) do
    ~H"""
    <section
      id={@id}
      phx-hook="ShadcnToaster"
      phx-update="ignore"
      data-sonner-section
      data-position={@position}
      data-expand={to_string(@expand)}
      data-rich-colors={to_string(@rich_colors)}
      data-close-button={to_string(@close_button)}
      data-duration={@duration}
      data-visible-toasts={@visible_toasts}
      aria-label="Notifications alt+T"
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      tabindex="-1"
      class={@class}
    >
    </section>
    """
  end

  @doc """
  Deprecated: use `toaster/1`. Kept so existing root layouts keep working;
  renders a toaster with the old `toast-host` id.
  """
  attr(:id, :string, default: "toast-host")
  attr(:class, :any, default: nil)

  def toast_host(assigns), do: toaster(assigns)

  @doc """
  Sends a toast to the page's `<.toaster>` from a LiveView.

      {:noreply, push_toast(socket, "Event has been created",
        description: "Sunday, December 03 at 9:00 AM",
        action: %{label: "Undo", event: "undo", value: %{id: event.id}})}

      push_toast(socket, "Saved", type: :success)

  Options: `:type` (`:default | :success | :info | :warning | :error | :loading`),
  `:description`, `:duration` (ms), `:position`, `:id` (reuse to update a toast),
  `:important` (assertive announcement), `:close_button`, `:action` / `:cancel`
  (`%{label: ..., event: ..., value: %{...}}` - clicking pushes `event` back to the
  LiveView). `push_toast(socket, nil, dismiss: id)` dismisses one (or all, with
  `dismiss: true`).
  """
  def push_toast(socket, message, opts \\ []) do
    payload =
      case Keyword.get(opts, :dismiss) do
        nil ->
          opts
          |> Keyword.take([:id, :description, :duration, :position, :important, :close_button])
          |> Map.new()
          |> Map.put(:message, message)
          |> Map.put(:type, opts |> Keyword.get(:type, :default) |> to_string())
          |> put_button(:action, opts[:action])
          |> put_button(:cancel, opts[:cancel])

        true ->
          %{dismiss: true}

        id ->
          %{dismiss: true, id: id}
      end

    Phoenix.LiveView.push_event(socket, "shadcn:toast", payload)
  end

  defp put_button(payload, _key, nil), do: payload

  defp put_button(payload, key, button) when is_map(button) do
    Map.put(payload, key, Map.take(button, [:label, :event, :value]))
  end

  # ----------------------------------------------------------------------------
  # Item
  # ----------------------------------------------------------------------------
  @doc """
  A flexible row: media, title, description, and actions. Use it for settings
  rows, file/member lists, and notification rows. Pass `href`, `navigate`, or
  `patch` to make the whole row a link.

      <.item variant="outline">
        <:media variant="icon"><.icon name="hero-shield-check" /></:media>
        <:title>Two-factor authentication</:title>
        <:description>Verify via email or phone number.</:description>
        <:actions><.button size="sm">Enable</.button></:actions>
      </.item>

  Variants: `default` (borderless), `outline`, `muted`. Sizes: `default`, `sm`,
  `xs`. Media variants: `default`, `icon` (16px glyph), `image` (40px thumb).
  `<:header>` / `<:footer>` span the full row above / below. Extra content in the
  inner block renders under the description.
  """
  attr(:variant, :string, default: "default", values: ~w(default outline muted))
  attr(:size, :string, default: "default", values: ~w(default sm xs))
  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(role method download target rel))

  slot :media do
    attr(:variant, :string, values: ~w(default icon image))
    attr(:class, :any)
  end

  slot(:title)
  slot(:description)
  slot(:actions)
  slot(:header)
  slot(:footer)
  slot(:inner_block)

  def item(assigns) do
    assigns =
      assign(assigns, :link?, !!(assigns.href || assigns.navigate || assigns.patch))

    ~H"""
    <.link
      :if={@link?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      data-slot="item"
      data-variant={@variant}
      data-size={@size}
      class={@class}
      {@rest}
    >
      <.item_parts
        header={@header}
        media={@media}
        title={@title}
        description={@description}
        inner_block={@inner_block}
        actions={@actions}
        footer={@footer}
      />
    </.link>
    <div :if={!@link?} data-slot="item" data-variant={@variant} data-size={@size} class={@class} {@rest}>
      <.item_parts
        header={@header}
        media={@media}
        title={@title}
        description={@description}
        inner_block={@inner_block}
        actions={@actions}
        footer={@footer}
      />
    </div>
    """
  end

  defp item_parts(assigns) do
    ~H"""
    <div :if={@header != []} data-slot="item-header">{render_slot(@header)}</div>
    <div
      :for={media <- @media}
      data-slot="item-media"
      data-variant={media[:variant] || "default"}
      class={media[:class]}
    >
      {render_slot(media)}
    </div>
    <div
      :if={@title != [] or @description != [] or @inner_block != []}
      data-slot="item-content"
    >
      <div :if={@title != []} data-slot="item-title">{render_slot(@title)}</div>
      <p :if={@description != []} data-slot="item-description">{render_slot(@description)}</p>
      {render_slot(@inner_block)}
    </div>
    <div :if={@actions != []} data-slot="item-actions">{render_slot(@actions)}</div>
    <div :if={@footer != []} data-slot="item-footer">{render_slot(@footer)}</div>
    """
  end

  @doc """
  A vertical list of items (`role="list"`). Give each `<.item>` `role="listitem"`,
  and separate them with `<.item_separator />` if you want rules between rows.

      <.item_group>
        <.item :for={u <- @users} role="listitem" size="sm">
          <:media><.avatar fallback={u.initials} class="w-8" /></:media>
          <:title>{u.name}</:title>
          <:description>{u.email}</:description>
        </.item>
      </.item_group>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def item_group(assigns) do
    ~H"""
    <div role="list" data-slot="item-group" class={@class} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "A 1px horizontal rule between items in an `item_group/1`."
  attr(:class, :any, default: nil)

  def item_separator(assigns) do
    ~H"""
    <div role="separator" aria-orientation="horizontal" data-slot="item-separator" class={@class}></div>
    """
  end

  # ----------------------------------------------------------------------------
  # Attachment
  # ----------------------------------------------------------------------------
  @doc """
  A file or image attachment: media, name, metadata, upload state, and actions.

      <.attachment state="uploading">
        <:media><.spinner size="loading-sm" /></:media>
        <:title>design-system.zip</:title>
        <:description>Uploading · 64%</:description>
        <:actions>
          <.attachment_action label="Cancel upload" phx-click="cancel" phx-value-ref={@ref}>
            <.icon name="hero-x-mark" />
          </.attachment_action>
        </:actions>
      </.attachment>

  `state`: `idle` (dashed border, ready to upload), `uploading` / `processing`
  (title shimmers, image dimmed), `error` (destructive tint), `done`. Sizes:
  `default`, `sm`, `xs`. `orientation="vertical"` makes an image-first tile.
  Media `variant="image"` holds an `<img>`; the default `icon` variant holds a
  glyph or spinner. Add `<:trigger label="Preview …" phx-click={...}>` to make the
  whole tile clickable while the actions stay independently clickable above it.
  """
  attr(:state, :string, default: "done", values: ~w(idle uploading processing error done))
  attr(:size, :string, default: "default", values: ~w(default sm xs))
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :media do
    attr(:variant, :string, values: ~w(icon image))
    attr(:class, :any)
  end

  slot(:title)
  slot(:description)
  slot(:actions)

  slot :trigger, doc: "a full-tile button (label it); put phx-click / JS on it" do
    attr(:label, :string, required: true)
    attr(:"phx-click", :any)
    attr(:"phx-value-id", :any)
    attr(:"phx-target", :any)
  end

  slot(:inner_block)

  def attachment(assigns) do
    ~H"""
    <div
      data-slot="attachment"
      data-state={@state}
      data-size={@size}
      data-orientation={@orientation}
      class={@class}
      {@rest}
    >
      <div
        :for={media <- @media}
        data-slot="attachment-media"
        data-variant={media[:variant] || "icon"}
        class={media[:class]}
      >
        {render_slot(media)}
      </div>
      <div :if={@title != [] or @description != []} data-slot="attachment-content">
        <span :if={@title != []} data-slot="attachment-title">{render_slot(@title)}</span>
        <span :if={@description != []} data-slot="attachment-description">
          {render_slot(@description)}
        </span>
      </div>
      {render_slot(@inner_block)}
      <div :if={@actions != []} data-slot="attachment-actions">{render_slot(@actions)}</div>
      <button
        :for={trigger <- @trigger}
        type="button"
        data-slot="attachment-trigger"
        aria-label={trigger.label}
        {Phoenix.Component.assigns_to_attributes(trigger, [:label])}
      >
      </button>
    </div>
    """
  end

  @doc """
  An icon button for an attachment's `<:actions>` (ghost, 24px). `label` is
  required - it becomes the accessible name and tooltip.

      <.attachment_action label="Remove report.pdf" phx-click="remove">
        <.icon name="hero-x-mark" />
      </.attachment_action>
  """
  attr(:label, :string, required: true)
  attr(:variant, :string, default: "ghost", values: ~w(ghost secondary outline))
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(type disabled form name value href download))
  slot(:inner_block, required: true)

  def attachment_action(assigns) do
    assigns =
      assign(
        assigns,
        :vclass,
        %{
          "ghost" => "btn-ghost",
          "secondary" => "btn-secondary",
          "outline" => "btn-outline"
        }[assigns.variant]
      )

    ~H"""
    <button
      type="button"
      data-slot="attachment-action"
      class={["btn btn-square btn-xs", @vclass, @class]}
      aria-label={@label}
      title={@label}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  A horizontally scrolling, snap-aligned row of attachments.

      <.attachment_group>
        <.attachment :for={f <- @files} class="w-64">…</.attachment>
      </.attachment_group>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def attachment_group(assigns) do
    ~H"""
    <div data-slot="attachment-group" class={@class} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
