defmodule ShadcnDaisyuiDemoWeb.StrictCSP do
  @moduledoc """
  Serves a page under a strict script policy:

      script-src 'self' 'nonce-<random>'; object-src 'none'; base-uri 'self'

  External scripts from this origin and `<script nonce=…>` blocks run;
  inline event handlers (`onclick=…`), `javascript:` URLs and un-nonced inline
  scripts are blocked. The nonce is assigned as `:csp_nonce` so the root layout
  can stamp its inline theme script and emit a matching
  `<meta http-equiv="Content-Security-Policy">` (the static export has no
  response headers, so the meta tag keeps the policy enforced there too).
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64(padding: false)

    conn
    |> assign(:csp_nonce, nonce)
    # replaces Phoenix's default `base-uri 'self'; frame-ancestors 'self';`
    # (put_secure_browser_headers), keeping both directives
    |> put_resp_header("content-security-policy", policy(nonce) <> "; frame-ancestors 'self'")
  end

  @doc """
  The policy for a nonce, as used in the meta tag (`frame-ancestors` is only
  honoured as a header, so the plug appends it there).
  """
  def policy(nonce), do: "script-src 'self' 'nonce-#{nonce}'; object-src 'none'; base-uri 'self'"
end
