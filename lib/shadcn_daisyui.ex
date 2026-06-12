defmodule ShadcnDaisyui do
  @moduledoc """
  shadcn-daisyui - a daisyUI v5 theme + Phoenix components that make daisyUI
  look and behave like [shadcn/ui](https://ui.shadcn.com).

  This package ships three things:

    * **Theme CSS** - `priv/static/shadcn-daisyui.css`. A self-contained Tailwind
      v4 / daisyUI v5 theme (neutral palette, light + dark) plus component
      overrides. Import it once and every daisyUI class looks like shadcn.

    * **Interactive JS** - `priv/static/shadcn-daisyui.js`. Vanilla handlers for
      the components that need state (command palette, combobox, calendar,
      date-picker, data-table, context-menu, OTP, carousel, resizable). Exposes
      `initShadcnDaisyui()` for dead views and `Hooks` for LiveView.

    * **Function components** - `ShadcnDaisyui.Components`. `<.button>`,
      `<.badge>`, `<.card>`, `<.date_picker>`, … so you write components instead
      of copied markup.

  Run `mix shadcn_daisyui.install` after adding the dep to wire everything up.

  See the README for the full setup.
  """

  @doc "Absolute path to the bundled theme CSS, for tooling that needs it."
  def css_path, do: Application.app_dir(:shadcn_daisyui, "priv/static/shadcn-daisyui.css")

  @doc "Absolute path to the bundled interactive JS, for tooling that needs it."
  def js_path, do: Application.app_dir(:shadcn_daisyui, "priv/static/shadcn-daisyui.js")
end
