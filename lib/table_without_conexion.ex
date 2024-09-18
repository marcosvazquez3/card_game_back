defmodule Table_WT_Conection do

  # A tabla do estado da mesa vai ser deta maneira, {"table", [card1,card2], "player_name"}
  # A tabla dos xogadores vai ser desta maneira, {"name_player", [cards], points, [point_cards]}
  # A tabla que garda o número de xogadores é esta dos{"players", num_players, [name1, name2]}
  # Compilar c("lib/table_without_conexion.ex")
  # c("lib/deck.ex")
  # TODO hai que facer test

  # TODO non permitir crear partidas para un solo xogador

  # ---------------------------------------------- #
  #  CREACIÓN DE PARTIDA                           #
  # ---------------------------------------------- #

  def create_game(num_players) do
    :ets.new(:table_state, [:public, :named_table])
    :ets.insert_new(:table_state, {"table"})
    :ets.insert_new(:table_state, {"players", num_players, []})
    deck = Deck.deck_gen(num_players)
    :ets.insert(:table_state, {"deck", deck})
    {:ok, "Game created"}
  end

  # ---------------------------------------------- #


  # ---------------------------------------------- #
  #  AÑADIR JUGADORES                              #
  # ---------------------------------------------- #

  def save_players(name_player) do
    [{_, num_players, player_list}] = :ets.lookup(:table_state, "players")
    :ets.insert_new(:table_state, {name_player})
    :ets.insert(:table_state, {"players", num_players, [name_player | player_list]})
    {:ok, "Player created"}
  end

  # El num_players del case, si no se le pone el "^" piensa que es una variable nueva
  def check_player_count(name_player) do
    [{_, num_players, player_list}] = :ets.lookup(:table_state, "players")
    case length(player_list) do
      ^num_players -> {:error, "No more players allowed"}
      _ -> save_players(name_player)
    end
  end

  def add_player(name_player) do
    exists_player = :ets.lookup(:table_state, name_player)
    case exists_player do
      [] -> check_player_count(name_player)
      _ -> {:error, "Player name already exist"}
    end
  end

  # TODO hai que modificar esto
  def update_player_cards(name_player, cards) do
    :ets.insert(:table_state, {name_player, cards})
  end


  # ---------------------------------------------- #
  # Repartir cartas
  # ---------------------------------------------- #

  def distribute_cards() do
    [{_, num_players, player_list}] = :ets.lookup(:table_state, "players")
    [{_, deck}] = :ets.lookup(:table_state, "deck")
    card_per_hand = round(length(deck)/num_players)
    hand_decks = Enum.chunk_every(deck, card_per_hand)
  end

  # ---------------------------------------------- #

  # ---------------------------------------------- #
  # Show cards and get cards
  # ---------------------------------------------- #

  def find([], _, _, result), do: result

  def find([head | tail], inserts, 0, result),
    do: find(tail, inserts, -1, [head, inserts | result])

  def find([head | tail], inserts, index, result),
    do: find(tail, inserts, index - 1, [head | result])

  def insert_card_given_pos(card, deck, pos) do
    Enum.reverse(find(deck, card, pos, []))
  end
  # ---------------------------------------------- #

  defp cards_are_equal?([], _) do
    true
  end

  defp cards_are_equal?([card | tl], to_compare) do
    number = card |> elem(1)
    if number == to_compare do
      cards_are_equal?(tl, to_compare)
    else
      false
    end
  end

  # Logica, si la primera carta es mayor las demás lo son, se asume
  # Si no lo es miramos que el resto de cartas que se ponen del jugador son iguales
  defp compare_cards([f_card_t | tail_t], [f_card_p | tail_p]) do
    card_t = f_card_t |> elem(1)
    card_p = tail_p |> elem(1)
    # Si la primera carta es mayor que la primera de la mesa se acepta (asumimos que las cartas vienen ordenadas)
    if card_t < card_p do
      true
    else
      # Si no puede ser que las cartas de la mesa sean escalera y las del jugador iguales, hay que compararlas
      if cards_are_equal?(tail_p, card_p) and not cards_are_equal?(tail_t, card_t) do
        true
      else
        false
      end
    end
  end

  defp can_put_cards?(table_cards, player_cards) do
    cond do
      length(table_cards) <= length(player_cards) ->
        compare_cards(table_cards, player_cards)
      true ->
        false
    end
  end

  # Necesito checkear que pueda bajar las cartas
  defp put_cards_on_table(name_player, player_cards) do
    # Miro el estado de la mesa
    table_state = :ets.lookup(:table_state, "table")
    # Miro las cartas en la mesa
    table_cards = table_state |> elem(1)
    if can_put_cards?(table_cards, player_cards) do
      # pudo poner las cartas
      {:ok, "Cartas puestas"}
    else
      # no pudo
      {:error, "No se pudiron poner las cartas"}
    end
    :ets.insert(:table_state, {"table", player_cards, name_player})
  end

  #Falta por comprobar que o número de cartas é maior que as cartas na mesa
  def show(name_player, cards) do
    exists_player = :ets.lookup(:table_state, name_player)
    case exists_player do
      [] -> {:error, "Player does not exists"}
      _ -> put_cards_on_table(name_player, cards)
    end
  end

  def take_cards(name_player, card, position, table_cards) do
    if card in table_cards do
      {_, player_cards, points, point_cards} = :ets.lookup(:table_state, name_player)
      insert_card_given_pos(player_cards, card, position)
      :ets.insert(:table_state, {name_player, player_cards, points, point_cards})
    end
  end

  def give_point(name_player) do
    :ets.lookup(:table_state, name_player)
  end

  #Acordarse que solo se pueden cojer cartas de los vordes
  def process_get(name_player, card, position, table_state) do
    table_cards = table_state |> elem(1)
    take_cards(name_player, card, position, table_cards)
    #give_points
  end

  # cards son as cartas que se quitan da table y la posición en la que se meten en la mano
  # Solo se poden coller as cartas das beiras, non as do medio
  def get(name_player, card, position) do
    state = :ets.lookup(:table_state, "table")
    case state do
      [{"table"}] -> {:error, "Cannot scout no cards on the table"}
      [_] -> process_get(name_player, card, position, state) # Tengo que dar los puntos a la pers
    end
  end

  # ---------------------------------------------- #

  def check_player_info(player_name) do
    exists_player = :ets.lookup(:table_state, player_name)
    case exists_player do
      [] -> {:error, "Player does not exists"}
      _ -> exists_player
    end
  end

  def check_table_cards(player_name) do
    :ets.lookup(:table_state, "table")
  end
end
