defmodule Router do
  use Plug.Router

  # Permite loggear as requests que recibamos
  plug(Plug.Logger)

  # Para facer matching das request
  plug(:match)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  # Permite parsear o body se matchea o formato

  plug(:dispatch)

  # https://hexdocs.pm/elixir/String.html#to_existing_atom/1
  # Usar string to existing atom que podo mapealo aos atoms que quero
  # Fáltame facer match das partidas
  # Ecto é unha librería para traballar con BD

  get "/show/" do
    send_resp(conn, 200, "hola GET")
  end

  post "/:id/show" do
    table_id = id
    attrs = %{
      name: conn.body_params["name"],
      cards: conn.body_params["cards"]
    }
    changeset = Utils.Api.ShowValidations.changeset(%Utils.Api.ShowValidations{}, attrs)

    if changeset.valid? do
      %{name: name, cards: cards} = Ecto.Changeset.apply_changes(changeset)
      Game.Table.show(table_id, cards, name)
      send_resp(conn, 200, "done show")
    else
      errors =
        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
      send_resp(conn, 422, Jason.encode!(%{errors: errors}))
    end
  end

  post "/:id/scout" do
    cards = conn.body_params["card"]
    position = conn.body_params["position"]
    player_name = conn.body_params["player_name"]
    Game.Table.scout(id, cards, position, player_name)
    send_resp(conn, 200, "done show")
  end

  get "/table" do
    game_id = TableSupervisor.new_game()
    send_resp(conn, 200, game_id)
  end

  post "/:id/addPlayer" do
    player_name = conn.body_params["name"]
    dbg(player_name)
    Game.Table.add_player(id, player_name)
    send_resp(conn, 200, "Player added")
  end

  get "/:id/getState" do
    table_state = Game.Table.get_table_state(id)
    dbg(table_state)
    send_resp(conn, 200, "current state: #{inspect(table_state)}")
  end


  get "/:id/startGame" do
    Game.Table.start_game(id)
    send_resp(conn, 200, "Game started")
  end

  match(_, do: send_resp(conn, 404, "Not Found"))
end
