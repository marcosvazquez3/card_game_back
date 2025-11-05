defmodule Router do
  use Plug.Router

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

  get "/show/" do
    send_resp(conn, 200, "hola GET")
  end

  post "/:id/show" do
    cards = conn.body_params["cards"]
    player_name = conn.body_params["player_name"]
    Game.Table.show(id, cards, player_name)
    send_resp(conn, 200, "done show")
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

  post "/:id/addPlayer/:player_name" do
    Game.Table.add_player(id, player_name)
    send_resp(conn, 200, "Player added")
  end

  get "/:id/getState" do
    table_state = Game.Table.get_table_state(id)
    dbg(table_state)
    send_resp(conn, 200, "current state: #{inspect(table_state)}")
  end

  match _, do: send_resp(conn, 404, "Not Found")

end
