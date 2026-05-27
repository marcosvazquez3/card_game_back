defmodule CardGameBackPhoenixWeb.Router do
  use CardGameBackPhoenixWeb, :router

  import CardGameBackPhoenixWeb.Live.UserAuth
  alias CardGameBackPhoenixWeb.GameController
  alias CardGameBackPhoenix.Router, as: LegacyRouter

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CardGameBackPhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", CardGameBackPhoenixWeb do
  #   pipe_through :browser

  #   get "/", PageController, :home
  # end

  scope "/legacy" do
    forward "/", LegacyRouter
  end

  scope "/game" do
    get "/create", GameController, :create_game
  end

  # Other scopes may use custom stacks.
  # scope "/api", CardGameBackPhoenixWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:card_game_back_phoenix, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CardGameBackPhoenixWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/live", CardGameBackPhoenixWeb.Live do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CardGameBackPhoenixWeb.Live.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
    post "/users/friends/:friend_id", FriendsController, :add_friend
    post "/users/block/:block_id", FriendsController, :block_user
  end

  scope "/", CardGameBackPhoenixWeb.Live do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{CardGameBackPhoenixWeb.Live.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
