defmodule LiveviewGridWeb.Router do
  use LiveviewGridWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveviewGridWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated_api do
    plug :accepts, ["json"]
    plug LiveviewGridWeb.Plugs.RequireApiKey
  end

  scope "/", LiveviewGridWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/grid", GridLive

    # Dashboard pages - sidebar layout
    live_session :dashboard,
      layout: {LiveviewGridWeb.Layouts, :dashboard},
      on_mount: [{LiveviewGridWeb.Hooks, :assign_current_path}] do
      live "/demo", DemoLive
      live "/renderer-demo", RendererDemoLive
      live "/dbms-demo", DbmsDemoLive
      live "/api-demo", ApiDemoLive
      live "/api-keys", ApiKeyLive
      live "/api-docs", ApiDocLive
    end
  end

  # Mock REST API - authenticated endpoints
  scope "/api", LiveviewGridWeb do
    pipe_through :authenticated_api

    get "/users", MockApiController, :index
    get "/users/:id", MockApiController, :show
    post "/users", MockApiController, :create
    put "/users/:id", MockApiController, :update
    patch "/users/:id", MockApiController, :patch
    delete "/users/:id", MockApiController, :delete
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:liveview_grid, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiveviewGridWeb.Telemetry
    end
  end
end
