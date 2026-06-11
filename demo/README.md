# shadcn_daisyui — demo & docs site

A Phoenix 1.8 app that documents the [`shadcn_daisyui`](https://github.com/N00nDay/shadcn_daisyui)
package: a landing page, a per-component docs browser (live previews + Preview/Code tabs), an
installation guide, and an interactive theme creator.

It lives in the package repo under `demo/` and is **excluded from the published Hex package**
(the package only ships `lib priv .formatter.exs mix.exs README.md LICENSE`).

## Run locally

```bash
cd demo
mix setup
mix phx.server
```

Then visit [`localhost:4000`](http://localhost:4000).

The package is linked by path (`{:shadcn_daisyui, path: ".."}`) so local changes to the package
are picked up live.

## Deploy — static site (recommended)

The site has no dynamic data, so it pre-renders to static HTML and can be served by any static
host (Render Static Site, Cloudflare Pages, Netlify, GitHub Pages — free, fast, nothing to run).

```bash
cd demo
MIX_ENV=prod mix site.export      # -> _site/  (every route as HTML + digested assets)
```

`mix site.export` builds + digests assets, renders each route to `…/index.html`, and copies the
assets into `_site/`. Internal links are clean URLs (`/docs/components/button`), which static hosts
resolve to the matching `index.html`. All interactivity (theme toggle, calendar, command palette,
data table) is client-side JS and works with no server.

**Render (Static Site):** Build Command `mix deps.get && MIX_ENV=prod mix site.export`,
Publish Directory `demo/_site` (set the Root Directory to `demo`). Requires an Elixir build
environment — if the static-site builder lacks Elixir, run the export in CI (GitHub Actions) and
publish `_site` instead.

**Cloudflare Pages / Netlify / GitHub Pages:** point them at the generated `_site/` (build it in CI
or commit it).

## Deploy — live Phoenix server (alternative)

A `Dockerfile` is also included (`mix phx.gen.release --docker`) for running the app as a real
service. Because the build context is `demo/` — where the package one directory up isn't available
— the image build fetches the package from GitHub via `SHADCN_DAISYUI_FROM_GIT=1` (handled in the
`Dockerfile` and `shadcn_daisyui_dep/0` in `mix.exs`). Set `SECRET_KEY_BASE` (`mix phx.gen.secret`),
`PHX_HOST`, and optionally `PORT`, then deploy with `fly launch` (Fly.io) or a Docker Web Service
(Render, root directory `demo`).
