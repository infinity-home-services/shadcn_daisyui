defmodule ShadcnDaisyuiDemoWeb.Router do
  use ShadcnDaisyuiDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShadcnDaisyuiDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShadcnDaisyuiDemoWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/docs", DocsController, :index
    get "/docs/installation", DocsController, :installation
    get "/docs/themes", DocsController, :themes
    get "/docs/components/:component", DocsController, :component
  end

  # AI-consumable plain-text/JSON endpoints. No browser pipeline: these are
  # fetched by crawlers and agents with arbitrary Accept headers, and need no
  # session, CSRF, or layout.
  scope "/", ShadcnDaisyuiDemoWeb do
    get "/llms.txt", DocsController, :llms
    get "/llms-full.txt", DocsController, :llms_full
    get "/docs/search.json", DocsController, :search
  end

  # Other scopes may use custom stacks.
  # scope "/api", ShadcnDaisyuiDemoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:shadcn_daisyui_demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShadcnDaisyuiDemoWeb.Telemetry
    end
  end
end
