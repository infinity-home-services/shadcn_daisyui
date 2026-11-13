defmodule ShadcnDaisyui.Components.SignIn do
  @moduledoc ~S"""
  The sign-in page: `sign_in_page/1`, one page for every app that signs
  people in with Microsoft. Each app passes its own name, mark and routes.

      <.sign_in_page
        app_name="Acme"
        org="Acme Inc."
        href={~p"/auth/entra"}
        configured={MyApp.Entra.configured?()}
        notice={Phoenix.Flash.get(@flash, :sign_in)}
      />

  The page is the whole screen, so render it on its own, outside the app's
  `Layouts.app/1` (keep `<.flash_group flash={@flash} />` beside it).

  **Sizes** (the layout foundations' size classes): phones (below 40rem) get
  the form edge to edge, tablets (40rem to 64rem) a card on a muted page (or
  on the `image`), and desktops (from 64rem) two halves: a panel naming the
  application (the org, the app's name large, a rule, the tagline, over the
  `image`) and the form.

  **The app's look**: `image` (the picture behind the panel and the tablet
  card), the theme's colours (a brand theme's `--sign-in-accent` colours the
  application's name over the picture, `--sign-in-title-fill` replaces that
  fill outright, and `--app-icon` / `--app-icon-foreground`, else its
  primary, colour the app's icon), `<:panel>` (the panel's centre) and
  `<:logo>` (the mark over the form). Sign in with Microsoft is neutral in
  every brand: the theme's text colour with its page colour on it, black in
  light and white in dark. A brand theme with a scope of its own
  (`data-brand="acme"` in `{@rest}`) brands just this page.

  **Notices**: what happened, above the button. The controller that refuses
  a sign-in, or signs someone out, puts the notice's key in the flash under
  `:sign_in` and redirects to the sign-in page, so the page words it the same
  way in every app:

      conn |> put_flash(:sign_in, "no_access") |> redirect(to: ~p"/sign-in")

  | Key | Says |
  |---|---|
  | `signed_out` | You're signed out. Microsoft asks which account to use next time. |
  | `unavailable` | Microsoft can't be reached right now. |
  | `canceled` | Microsoft didn't complete the sign-in. |
  | `failed` | The sign-in didn't complete. |
  | `no_access` | You don't have access to Acme yet. Your manager gives access. |
  | `ended` | Your access to Acme has ended. |
  | `not_configured` | Microsoft sign-in isn't set up on this server. |

  Anything else is an `<:alert title="…">` of your own (`variant="destructive"`
  for a refusal). `configured={false}` shows the `not_configured` notice and
  disables the button.

  **Development sign-in**: the `<:development>` slot, under a divider. Render
  it only in development and test builds, as the route behind it is. Each
  entry with a `label` is a section that folds away, and so is the whole
  development sign-in; `shadcn-daisyui.js` remembers what's hidden in this
  browser (localStorage `shadcn:sign-in-hidden`), so a developer can keep the
  page as production shows it.

  Ids: `sign-in` (the page, or your `id`), `sign-in-notice` (with
  `data-notice` set to the key), `sign-in-microsoft`, `sign-in-development`
  (and `sign-in-development-<key>` per section).

  Imported by `use ShadcnDaisyui.Components`.
  """
  use Phoenix.Component

  import ShadcnDaisyui.Components, only: [alert: 1]

  @notices ~w(signed_out unavailable canceled failed no_access ended not_configured)

  @doc "The notice keys `sign_in_page/1` words itself."
  def notices, do: @notices

  @doc """
  A notice's wording for an app: `%{title, description, variant, icon}`
  (`description` may be nil, `variant` is `"default"` or `"destructive"`), or
  nil for a key it doesn't know.

      iex> ShadcnDaisyui.Components.SignIn.notice("ended", "Acme").title
      "Your access to Acme has ended."
  """
  def notice(key, app_name) do
    case key(key) do
      nil -> nil
      known -> message(known, app_name)
    end
  end

  @doc ~S"""
  The sign-in page for an app that signs people in with Microsoft.

      <.sign_in_page
        app_name="Acme"
        org="Acme Inc."
        tagline="Orders, quotes and customers in one place."
        href={~p"/auth/entra"}
        configured={MyApp.Entra.configured?()}
        notice={Phoenix.Flash.get(@flash, :sign_in)}
      >
        <:logo><img src={~p"/images/mark.svg"} alt="" /></:logo>
        <:development :if={@development?}>
          <.form for={@form} action={~p"/sign-in/development"} class="space-y-4">
            <.input field={@form[:email]} type="email" label="Email" required />
            <.button variant="outline" class="w-full">Sign in</.button>
          </.form>
        </:development>
      </.sign_in_page>

  `notice` is one of `notices/0` (a string or an atom), or nil. A key it
  doesn't know shows nothing, so a stale flash never breaks the page.
  """
  attr(:id, :string, default: "sign-in")
  attr(:app_name, :string, required: true, doc: "the app's name, in the title and the notices")
  attr(:org, :string, default: nil, doc: "who runs the app, under the form and on the panel")

  attr(:tagline, :string,
    default: nil,
    doc: "one line about the app, under its name on the desktop panel"
  )

  attr(:icon, :string, default: "hero-cube", doc: "the app's mark when there's no `<:logo>`")

  attr(:image, :string,
    default: nil,
    doc:
      "a picture behind the desktop panel and the tablet card (its URL), darkened so text on it reads"
  )

  attr(:image_alt, :string, default: "", doc: "the picture's alt text (empty: decorative)")

  attr(:href, :string,
    default: nil,
    doc: "where Sign in with Microsoft goes (`~p\"/auth/entra\"`)"
  )

  attr(:configured, :boolean,
    default: true,
    doc: "false when Microsoft sign-in isn't set up on this server"
  )

  attr(:notice, :any, default: nil, doc: "a key from `notices/0`, or nil")

  attr(:description, :string,
    default: "With your Microsoft work account.",
    doc: "the line under the title"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:logo, doc: "the app's mark (an `<img>` or an svg), in place of the icon tile")

  slot(:panel,
    doc:
      "the desktop panel's centre, in place of the org, app name, rule and tagline (`sign-in-app-name`, `sign-in-rule`, `sign-in-tagline` style your own)"
  )

  slot :alert, doc: "a notice of your own, in place of `notice`" do
    attr(:title, :string, required: true)
    attr(:variant, :string, values: ~w(default destructive))
  end

  slot :development,
    doc:
      "the development sign-in, only in development and test builds; each entry with a `label` is a section people can hide" do
    attr(:label, :string,
      doc: "the section's heading; hidden sections stay hidden in this browser"
    )

    attr(:id, :string, doc: "the section's key for remembering it (default: from the label)")
  end

  slot(:footer, doc: "links under the form, such as a privacy page")

  def sign_in_page(assigns) do
    notice = if assigns.configured, do: key(assigns.notice), else: "not_configured"

    assigns =
      assigns
      |> assign(:notice_key, notice)
      |> assign(:message, notice && message(notice, assigns.app_name))

    ~H"""
    <main id={@id} class={["sign-in", @class]} {@rest}>
      <aside class="sign-in-aside" data-image={@image && "true"}>
        <img :if={@image} class="sign-in-aside-image" src={@image} alt={@image_alt} />
        <div class="sign-in-aside-content">
          <%= if @panel != [] do %>
            {render_slot(@panel)}
          <% else %>
            <p :if={@org} class="sign-in-org">{@org}</p>
            <p class="sign-in-app-name">{@app_name}</p>
            <span :if={@tagline} class="sign-in-rule" aria-hidden="true"></span>
            <p :if={@tagline} class="sign-in-tagline">{@tagline}</p>
          <% end %>
        </div>
      </aside>

      <div class="sign-in-main">
        <div class="sign-in-panel">
          <header class="sign-in-header">
            <.mark logo={@logo} icon={@icon} />
            <h1 class="sign-in-title">Sign in to {@app_name}</h1>
            <p class="sign-in-description">{@description}</p>
          </header>

          <.alert
            :for={alert <- Enum.take(@alert, 1)}
            id="sign-in-notice"
            data-notice="custom"
            variant={alert[:variant] || "default"}
            class="sign-in-notice"
          >
            <:icon><span class={icon_for(alert[:variant] || "default")}></span></:icon>
            <:title>{alert.title}</:title>
            <%!-- a self-closing <:alert … /> has no inner block: a title alone --%>
            {alert[:inner_block] && render_slot(alert)}
          </.alert>

          <.alert
            :if={@alert == [] && @message}
            id="sign-in-notice"
            data-notice={@notice_key}
            variant={@message.variant}
            class="sign-in-notice"
          >
            <:icon><span class={@message.icon}></span></:icon>
            <:title>{@message.title}</:title>
            {@message.description}
          </.alert>

          <a
            :if={@configured}
            id="sign-in-microsoft"
            href={@href}
            class="btn sign-in-microsoft"
          >
            <.microsoft_logo /> Sign in with Microsoft
          </a>
          <button
            :if={!@configured}
            id="sign-in-microsoft"
            type="button"
            class="btn sign-in-microsoft"
            disabled
          >
            <.microsoft_logo /> Sign in with Microsoft
          </button>

          <details
            :if={@development != []}
            id="sign-in-development"
            class="sign-in-development"
            data-sign-in-section="development"
            open
          >
            <summary class="sign-in-divider">
              <span>Development sign-in</span>
              <span class="hero-chevron-down sign-in-chevron" aria-hidden="true"></span>
            </summary>
            <div class="sign-in-development-body">
              <p class="sign-in-development-note">Shown in development and test builds only.</p>
              <%= for section <- @development do %>
                <details
                  :if={section[:label]}
                  id={"sign-in-development-" <> section_key(section)}
                  class="sign-in-section"
                  data-sign-in-section={section_key(section)}
                  open
                >
                  <summary class="sign-in-section-summary">
                    <span>{section.label}</span>
                    <span class="hero-chevron-down sign-in-chevron" aria-hidden="true"></span>
                  </summary>
                  <div class="sign-in-section-body">{render_slot(section)}</div>
                </details>
                <div :if={!section[:label]}>{render_slot(section)}</div>
              <% end %>
            </div>
          </details>
        </div>

        <footer :if={@org || @footer != []} class="sign-in-footer">
          <span :if={@org} class="sign-in-footer-org">{@org}</span>
          {render_slot(@footer)}
        </footer>
      </div>
    </main>
    """
  end

  attr(:logo, :list, required: true)
  attr(:icon, :string, required: true)

  defp mark(assigns) do
    ~H"""
    <span class={["sign-in-mark", @logo == [] && "sign-in-tile"]}>
      <%= if @logo != [] do %>
        {render_slot(@logo)}
      <% else %>
        <span class={@icon} aria-hidden="true"></span>
      <% end %>
    </span>
    """
  end

  # Microsoft's four squares, in Microsoft's colours (a logo, not a theme colour)
  defp microsoft_logo(assigns) do
    ~H"""
    <svg class="sign-in-microsoft-logo" viewBox="0 0 21 21" aria-hidden="true" focusable="false">
      <rect x="1" y="1" width="9" height="9" fill="#f25022" />
      <rect x="11" y="1" width="9" height="9" fill="#7fba00" />
      <rect x="1" y="11" width="9" height="9" fill="#00a4ef" />
      <rect x="11" y="11" width="9" height="9" fill="#ffb900" />
    </svg>
    """
  end

  defp section_key(%{id: id}) when is_binary(id), do: id

  defp section_key(%{label: label}) do
    label |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")
  end

  defp key(nil), do: nil
  defp key(key) when is_atom(key), do: key(Atom.to_string(key))
  defp key(key) when key in @notices, do: key
  defp key(_unknown), do: nil

  defp icon_for("destructive"), do: "hero-exclamation-circle"
  defp icon_for(_default), do: "hero-information-circle"

  defp message("signed_out", _app) do
    %{
      variant: "default",
      icon: "hero-check-circle",
      title: "You're signed out.",
      description: "Microsoft asks which account to use next time."
    }
  end

  defp message("unavailable", _app),
    do: error("Microsoft can't be reached right now.")

  defp message("canceled", _app), do: error("Microsoft didn't complete the sign-in.")
  defp message("failed", _app), do: error("The sign-in didn't complete.")

  defp message("no_access", app),
    do: error("You don't have access to #{app} yet.", "Your manager gives access.")

  defp message("ended", app), do: error("Your access to #{app} has ended.")

  defp message("not_configured", _app) do
    %{
      variant: "default",
      icon: "hero-information-circle",
      title: "Microsoft sign-in isn't set up on this server.",
      description: nil
    }
  end

  defp error(title, description \\ nil),
    do: %{
      variant: "destructive",
      icon: icon_for("destructive"),
      title: title,
      description: description
    }
end
