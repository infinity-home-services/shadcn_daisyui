defmodule ShadcnDaisyui.Components.Display do
  @moduledoc """
  Display components: accordion, avatar, progress, skeleton, spinner, and the
  toast host.

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
  The toast host container that `showToast()` (from the bundled JS) appends to.
  Put one in your root layout. For server-driven notices use
  `ShadcnDaisyui.CoreComponents.flash/1` instead.
  """
  attr(:id, :string, default: "toast-host")
  attr(:class, :any, default: nil)

  def toast_host(assigns) do
    ~H"""
    <div
      id={@id}
      class={["toast toast-end toast-bottom z-[60]", @class]}
      role="status"
      aria-live="polite"
    >
    </div>
    """
  end
end
