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

## Deploy (Phoenix host: Fly.io, Render, …)

A `Dockerfile` is included (`mix phx.gen.release --docker`). Because the demo's build context is
`demo/` — where the package source one directory up isn't available — the image build fetches the
package from GitHub by setting `SHADCN_DAISYUI_FROM_GIT=1` (handled in the `Dockerfile` and
`shadcn_daisyui_dep/0` in `mix.exs`).

Required runtime env vars (see `config/runtime.exs`):

- `SECRET_KEY_BASE` — generate with `mix phx.gen.secret`
- `PHX_HOST` — your public hostname
- `PORT` — defaults to `4000`

**Fly.io:** from `demo/`, run `fly launch` (it detects the `Dockerfile`), set the secrets
(`fly secrets set SECRET_KEY_BASE=… PHX_HOST=…`), then `fly deploy`.

**Render:** new Web Service → this repo → root directory `demo`, Docker runtime; add the env vars
above.
