# shadcn_daisyui

Make [daisyUI v5](https://daisyui.com) look and behave like [shadcn/ui](https://ui.shadcn.com)
in Phoenix - neutral palette, light + dark - shipped as a Hex-style package.

It bundles:

- **Theme CSS** - one self-contained Tailwind v4 / daisyUI v5 file. Import it and every
  daisyUI class (`btn`, `card`, `input`, `tabs`, …) renders shadcn-styled.
- **Interactive JS** - `initShadcnDaisyui()` (dead views) + LiveView `Hooks` for the
  stateful components (command, combobox, calendar, date-picker, OTP, carousel, resizable,
  tab nav, chip row, page header, data table, section nav, dropzone, …), plus the app shell's behaviour.
- **Function components** - `ShadcnDaisyui.Components` (`<.app_shell>` - a signed-in
  app's whole shell - `<.badge>`, `<.card>`, `<.dialog>`, `<.combobox>`, `<.tabs>`, …),
  `ShadcnDaisyui.FormComponents` (`<.field>`, `<.checkbox>`, `<.switch>`,
  `<.radio_group>`, `<.dropzone>`, …), and `ShadcnDaisyui.CoreComponents` - a **drop-in replacement
  for Phoenix 1.8's generated core components** (`<.input field={@form[:email]}>`,
  `<.button>`, `<.table>`, `<.flash>`, plus `<.page_header>`), so `phx.gen.live` /
  `phx.gen.html` output works unmodified.
- **AI usage rules** - `usage-rules.md` ships in the package; sync it into your app's
  `AGENTS.md` / `CLAUDE.md` with the [usage_rules](https://hex.pm/packages/usage_rules)
  package so coding agents follow the design system on every UI decision.

Requires **Tailwind v4 + daisyUI v5** (Phoenix 1.8 ships both).

## Install

```elixir
# mix.exs
def deps do
  [
    {:shadcn_daisyui, github: "infinity-home-services/shadcn_daisyui"}
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
- root layout - `data-theme="shadcn"` on `<html>`, or, for Phoenix 1.8's stock
  theme script, wraps its `setTheme` in the `theme-transition` guard so the
  light/dark swap stays instant
- `core_components.ex` - replaced with a thin module delegating to
  `ShadcnDaisyui.CoreComponents` (original backed up; every component overridable;
  your Gettext error translation preserved)
- `lib/<app>_web.ex` - templates get `use ShadcnDaisyui.Components`

Because assets are imported from `deps/`, upgrading is just
`mix deps.update shadcn_daisyui`. Prefer owning the files? `mix shadcn_daisyui.install --copy`
copies them into `assets/` (refresh later with `mix shadcn_daisyui.upgrade`).

**Upgrading from 0.3:** the transition guard is now scoped to theme swaps, so
anything that sets `data-theme` directly will fade. Re-run
`mix shadcn_daisyui.install` (idempotent) to patch Phoenix's stock theme script,
or switch your toggle to `setTheme` from `shadcn-daisyui.js`. A hand-written
script needs the same wrap:

```js
const setTheme = (theme) => {
  document.documentElement.classList.add("theme-transition");
  // ... set or remove data-theme as before ...
  requestAnimationFrame(() =>
    requestAnimationFrame(() => document.documentElement.classList.remove("theme-transition"))
  );
};
```

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

<.alert_dialog id="delete-report">
  <:trigger><.button variant="outline">Delete…</.button></:trigger>
  <:title>Delete Q3 report?</:title>
  <:description>This action cannot be undone.</:description>
  <:action variant="destructive" phx-click="delete">Delete report</:action>
</.alert_dialog>

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

Toasts (shadcn's Sonner): put `<.toaster />` in your root layout once, then

```elixir
# from a LiveView
{:noreply, push_toast(socket, "Event has been created", type: :success,
  action: %{label: "Undo", event: "undo", value: %{id: event.id}})}
```

```js
// or from JS
import { toast } from "shadcn_daisyui"
toast.promise(save(), { loading: "Saving…", success: "Saved", error: "Could not save" })
```

Toasts and Phoenix flashes (`put_flash`) show above an open sheet, dialog,
drawer or command palette and stay clickable there. Flashes render as Sonner
toasts too: info clears itself after 5 seconds, errors stay until closed.

Chat and AI transcripts compose `<.message>`, `<.bubble>`, `<.marker>`, and
`<.attachment>`:

```heex
<.message_group role="log" aria-label="Conversation">
  <.message align="end"><.bubble>Deploying to prod real quick.</.bubble></.message>
  <.message>
    <:avatar><.avatar fallback="R" class="w-8" /></:avatar>
    <.bubble variant="muted">It's 4:55 PM. On a Friday.</.bubble>
  </.message>
  <.marker status shimmer>Oliver is typing...</.marker>
</.message_group>
```

List pages and record pages have their parts too: `<.table_toolbar>` (views,
search, a filters sheet, filter chips) over a `<.data_table>` (a body that
scrolls under a sticky header, sortable columns, rows that open the record,
ticked rows with a bulk bar, more rows as the end comes into view), with what
it shows kept in the URL by `ShadcnDaisyui.DataTable.State`; and on the record,
`<.record_tabs>`, `<.section_nav>`, `<.table_card>`, `<.time_field>` and
`<.empty>`. A dialog the server decides on opens from the server:

```elixir
def handle_event("cancel", _params, socket) do
  if socket.assigns.dirty?,
    do: {:noreply, push_show_modal(socket, "discard")},
    else: {:noreply, push_navigate(socket, to: ~p"/orders")}
end
```

A file upload is `<.dropzone>`: a dashed area people drop files on or click to
choose, wired to a LiveView upload, with the picked files as attachment tiles
(progress, errors, a remove button) under it:

```heex
<.dropzone id="import-file" upload={@uploads.people_csv} on_cancel="import:cancel" />
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

Every component in shadcn-svelte's catalog (61 as of October 2026, including Item,
the Message / Bubble / Marker / Attachment chat set, Sonner, and Range Calendar) is
reproducible with this theme - function-component wrappers exist for the common
primitives, forms, overlays, navigation, conversation, and the interactive
components; everything else is raw daisyUI classes that the theme
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
import { Hooks as ShadcnHooks, initConfirmDialog } from "shadcn_daisyui"
const liveSocket = new LiveSocket("/live", Socket, { params: {...}, hooks: { ...ShadcnHooks } })
// opt in: data-confirm asks in the package's alert dialog, not the browser's confirm()
initConfirmDialog()
```

```heex
<!-- root.html.heex -->
<html lang="en" data-theme="shadcn">
```

## License

MIT.
