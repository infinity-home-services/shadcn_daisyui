# shadcn_daisyui

Make [daisyUI v5](https://daisyui.com) look and behave like [shadcn/ui](https://ui.shadcn.com)
in Phoenix — neutral palette, light + dark — shipped as a Hex-style package.

It bundles:

- **Theme CSS** — one self-contained Tailwind v4 / daisyUI v5 file. Import it and every
  daisyUI class (`btn`, `card`, `input`, `tabs`, …) renders shadcn-styled.
- **Interactive JS** — `initShadcnDaisyui()` (dead views) + LiveView `Hooks` for the
  stateful components (command, combobox, calendar, date-picker, data-table, context-menu,
  OTP, carousel, resizable).
- **Function components** — `ShadcnDaisyui.Components`: `<.button>`, `<.badge>`, `<.card>`,
  `<.date_picker>`, `<.combobox>`, …

Requires **Tailwind v4 + daisyUI v5** (Phoenix 1.8 ships both).

## Install

```elixir
# mix.exs — no Hex publish needed; install straight from git
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

The task copies `shadcn-daisyui.css` → `assets/css/`, `shadcn-daisyui.js` → `assets/vendor/`,
and patches `assets/css/app.css` (daisyUI `themes: false`, imports the theme, sets the dark
variant). Then finish the two steps it prints:

```js
// assets/js/app.js
import { Hooks } from "../vendor/shadcn-daisyui"
const liveSocket = new LiveSocket("/live", Socket, { params: {...}, hooks: { ...Hooks } })
// dead views instead: import { initShadcnDaisyui } from "../vendor/shadcn-daisyui"; initShadcnDaisyui()
```

```heex
<!-- root.html.heex -->
<html lang="en" data-theme="shadcn">
```

That's it — `data-theme="shadcn-dark"` flips to dark.

## Use it

Plain daisyUI classes are already themed:

```heex
<button class="btn btn-primary">Deploy</button>
<div class="card"><div class="card-body">…</div></div>
```

Or the function components:

```heex
use ShadcnDaisyui.Components

<.button variant="outline" size="sm">Save</.button>
<.badge variant="secondary">Paid</.badge>
<.alert variant="destructive"><:title>Error</:title>Session expired.</.alert>

<.date_picker id="due-date" />
<.combobox id="framework" placeholder="Select framework…">
  <:option value="Phoenix">Phoenix</:option>
  <:option value="Next.js">Next.js</:option>
</.combobox>
```

Interactive components need an `id` (LiveView hook requirement) and the `Hooks` registered.

## What's included

All 58 shadcn/ui components are reproducible with this theme — ~46 as pure daisyUI classes,
the rest via the bundled JS. Function-component wrappers exist for the common primitives and the
interactive components; everything else is raw daisyUI classes that the theme styles. See the
demo app for a live gallery of every component.

## Manual setup (without the task)

```css
/* assets/css/app.css */
@import "tailwindcss";
@plugin "../vendor/daisyui" { themes: false; }
@import "../../deps/shadcn_daisyui/priv/static/shadcn-daisyui.css";
@source "../../deps/shadcn_daisyui/lib";
@custom-variant dark (&:where([data-theme=shadcn-dark], [data-theme=shadcn-dark] *, .dark, .dark *));
```

## License

MIT.
