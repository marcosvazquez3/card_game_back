defmodule CardGameBackPhoenix.Router do
  use Plug.Router
  alias CardGameBackPhoenix.Game.Table
  alias CardGameBackPhoenix.Utils

  plug(Plug.Logger) # Permite loggear as requests que recibamos

  plug(:match) # Para facer matching das request

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Jason
    ) # Permite parsear o body se matchea o formato

  plug(:dispatch)

  # https://hexdocs.pm/elixir/String.html#to_existing_atom/1
  # Usar string to existing atom que podo mapealo aos atoms que quero
  # Fáltame facer match das partidas
  # Ecto é unha librería para traballar con BD

  post "/:table_id/show" do
    cards = conn.body_params["cards"]
    player_name = conn.body_params["player_name"]
    Table.show(table_id, cards, player_name)
    send_resp(conn, 200, "done show")
  end

  post "/:table_id/scout" do
    cards = conn.body_params["card"]
    position = conn.body_params["position"]
    player_name = conn.body_params["player_name"]
    Table.scout(table_id, cards, position, player_name)
    send_resp(conn, 200, "done show")
  end

  get "/table" do
    attrs = %{
      user_name: conn.body_params["user_name"],
      email: conn.body_params["email"],
      password_hash: conn.body_params["password_hash"]
    }
    case Utils.Games.create_game(attrs) do
      {:ok, game} ->
        TableSupervisor.new_game(CardGameBackPhoenix.Game.id)
        send_resp(conn, 200, Jason.encode!(%{table_id: CardGameBackPhoenix.Game.id, status: CardGameBackPhoenix.Game.status, players: [""]}))

      {:error, changeset} ->
        errors = Utils.ErrorHelper.errors_to_map(changeset)
        send_resp(conn, 422, Jason.encode!(%{errors: errors}))
    end
  end

  post "/:table_id/invitePlayer/:player_name" do
    Table.add_player(table_id, player_name)
    send_resp(conn, 200, "Player added")
  end

  get "/:table_id/getState" do
    table_state = Table.get_table_state(table_id)
    send_resp(conn, 200, "current state: #{inspect(table_state)}")
  end

  post "/sign_up" do
    attrs = %{
      user_name: conn.body_params["user_name"],
      email: conn.body_params["email"],
      password_hash: conn.body_params["password_hash"]
    }

    case Utils.Accounts.create_user(attrs) do
      {:ok, _user} ->
        send_resp(conn, 201, "Account added")

      {:error, changeset} ->
        errors = Utils.ErrorHelper.errors_to_map(changeset)
        send_resp(conn, 422, Jason.encode!(%{errors: errors}))
    end
  end

  match _, do: send_resp(conn, 404, "Not Found")

end
