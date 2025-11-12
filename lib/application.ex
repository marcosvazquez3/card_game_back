defmodule CardGameBack.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  # PubSub es realtime publisher subcriber

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Table},
      # ESTO É PA PUBSUB
      # {Registry,
      #  keys: :duplicate, name: Registry.PubSub, partitions: System.schedulers_online()},
      TableSupervisor,
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: CardGameBack.TableSupervisor]
    Supervisor.start_link(children, opts)
  end
end
