defmodule CardGameBackPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CardGameBackPhoenixWeb.Telemetry,
      CardGameBackPhoenix.Database.Repo,
      {DNSCluster, query: Application.get_env(:card_game_back_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CardGameBackPhoenix.PubSub},
      # Start a worker by calling: CardGameBackPhoenix.Worker.start_link(arg)
      # {CardGameBackPhoenix.Worker, arg},
      # Start to serve requests, typically the last entry
      CardGameBackPhoenixWeb.Endpoint,
      {Registry, keys: :unique, name: Registry.Table},
      # ESTO É PA PUBSUB
      # {Registry,
      #  keys: :duplicate, name: Registry.PubSub, partitions: System.schedulers_online()},
      CardGameBackPhoenix.TableSupervisor,
      CardGameBackPhoenixWeb.Presence,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CardGameBackPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CardGameBackPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
