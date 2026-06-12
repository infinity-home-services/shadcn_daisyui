# shadcn_daisyui

Make [daisyUI v5](https://daisyui.com) look and behave like [shadcn/ui](https://ui.shadcn.com)
in Phoenix - neutral palette, light + dark - shipped as a Hex-style package.

It bundles:

- **Theme CSS** - one self-contained Tailwind v4 / daisyUI v5 file. Import it and every
  daisyUI class (`btn`, `card`, `input`, `tabs`, …) renders shadcn-styled.
- **Interactive JS** - `initShadcnDaisyui()` (dead views) + LiveView `Hooks` for the
  stateful components (command, combobox, calendar, date-picker, OTP, carousel, resizable, …).
- **Function components** - `ShadcnDaisyui.Components` (`<.badge>`, `<.card>`,
  `<.dialog>`, `<.combobox>`, `<.tabs>`, `<.sidebar_layout>`, …),
  `ShadcnDaisyui.FormComponents` (`<.field>`, `<.checkbox>`, `<.switch>`,
  `<.radio_group>`, …), and `ShadcnDaisyui.CoreComponents` - a **drop-in replacement
  for Phoenix 1.8's generated core components** (`<.input field={@form[:email]}>`,
  `<.button>`, `<.table>`, `<.flash>`), so `phx.gen.live` / `phx.gen.html` output
  works unmodified.
- **AI usage rules** - `usage-rules.md` ships in the package; sync it into your app's
  `AGENTS.md` / `CLAUDE.md` with the [usage_rules](https://hex.pm/packages/usage_rules)
  package so coding agents follow the design system on every UI decision.

Requires **Tailwind v4 + daisyUI v5** (Phoenix 1.8 ships both).

## Install

```elixir
# mix.exs
def deps do
  [
    {:shadcn_daisyui, github: "N00nDay/shadcn_daisyui"}
  ]
end
```

```bash
mix deps.get
mix shadcn_daisyui.install
```

The installer wires everything automatically:

- `assets/css/app.css` - daisyUI `themes: false`, imports the theme from `deps/`,
  adds `@source` for the package's components, sets the `dark:` variant
- `assets/js/app.js` - imports the `Hooks` and spreads them into your `LiveSocket`
- root layout - `data-theme="shadcn"` on `<html>`
- `core_components.ex` - replaced with a thin module delegating to
  `ShadcnDaisyui.CoreComponents` (original backed up; every component overridable;
  your Gettext error translation preserved)
- `lib/<app>_web.ex` - templates get `use ShadcnDaisyui.Components`

Because assets are imported from `deps/`, upgrading is just
`mix deps.update shadcn_daisyui`. Prefer owning the files? `mix shadcn_daisyui.install --copy`
copies them into `assets/` (refresh later with `mix shadcn_daisyui.upgrade`).

### AI agents

```bash
# with {:usage_rules, "~> 0.1", only: [:dev]} in your deps:
mix usage_rules.sync AGENTS.md --all
```

This puts the design-system rules (use these components, never hand-roll Tailwind
markup, semantic tokens only, …) into the context of every AI coding agent working
on your app.

## Use it

Plain daisyUI classes are already themed:

```heex
<button class="btn btn-primary">Deploy</button>
<div class="card"><div class="card-body">…</div></div>
```

Forms, via your (replaced) CoreComponents:

```heex
<.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:role]} type="select" label="Role" options={["admin", "member"]} />
  <.input field={@form[:active]} type="checkbox" label="Active" />
  <.button phx-disable-with="Saving…">Save</.button>
</.form>
```

And the component library:

```heex
<.badge variant="secondary">Paid</.badge>
<.alert variant="destructive"><:title>Error</:title>Session expired.</.alert>

<.dialog id="confirm">
  <:trigger><.button variant="outline">Delete…</.button></:trigger>
  <:title>Are you absolutely sure?</:title>
  <:description>This action cannot be undone.</:description>
  <:actions>
    <form method="dialog"><.button variant="outline">Cancel</.button></form>
    <.button variant="destructive" phx-click="delete">Delete</.button>
  </:actions>
</.dialog>

<.tabs id="settings">
  <:tab label="Account" checked>…</:tab>
  <:tab label="Password">…</:tab>
</.tabs>

<.date_picker id="due-date" />
<.combobox id="framework" placeholder="Select framework…">
  <:option value="Phoenix">Phoenix</:option>
  <:option value="Next.js">Next.js</:option>
</.combobox>
```

Interactive components need an `id` (LiveView hook requirement) and the `Hooks`
registered (the installer does this).

## Theming / branding

The neutral theme is the default. Brand themes override the same OKLCH tokens in a
`[data-theme="yourbrand"]` block - generate one with:

```bash
mix shadcn_daisyui.gen.theme acme --primary "oklch(0.55 0.2 250)" --radius 0.5rem
```

See `usage-rules/theming.md` and the interactive theme creator on the docs site.

## What's included

All 58 shadcn/ui components are reproducible with this theme - function-component
wrappers exist for the common primitives, forms, overlays, navigation, and the
interactive components; everything else is raw daisyUI classes that the theme
styles (recipes in `usage-rules.md`). See the docs site for a live gallery of
every component, and `/llms.txt` there for the AI-readable index.

## Manual setup (without the task)

```css
/* assets/css/app.css */
@import "tailwindcss";
@plugin "../vendor/daisyui" { themes: false; }
@import "../../deps/shadcn_daisyui/priv/static/shadcn-daisyui.css";
@source "../../deps/shadcn_daisyui/lib";
@custom-variant dark (&:where([data-theme=shadcn-dark], [data-theme=shadcn-dark] *, .dark, .dark *));
```

```js
// assets/js/app.js
import { Hooks as ShadcnHooks } from "shadcn_daisyui"
const liveSocket = new LiveSocket("/live", Socket, { params: {...}, hooks: { ...ShadcnHooks } })
```

```heex
<!-- root.html.heex -->
<html lang="en" data-theme="shadcn">
```

## License

MIT.
