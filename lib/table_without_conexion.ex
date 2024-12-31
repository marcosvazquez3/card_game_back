defmodule Table_WT_Conection do

  # A tabla do estado da mesa vai ser deta maneira, {"table", [card1,card2], "player_name"}
  # A tabla dos xogadores vai ser desta maneira, {"player_name", [cards], points, [point_cards]}
  # A tabla que garda o número de xogadores é esta dos{"players", num_players, [name1, name2]}
  # Compilar c("lib/table_without_conexion.ex")
  # c("lib/deck.ex")
  # TODO Facer un end_checker para que mire se a partida ten que finalizar
  # TODO, crear turnos que solo permitan ao xogador que lle tocar xogar ese turno

  # TODO non permitir crear partidas para un solo xogador

  # ---------------------------------------------- #
  #  CREACIÓN DE PARTIDA                           #
  # ---------------------------------------------- #

  def create_game(num_players) do
    :ets.new(:game_state, [:public, :named_table])
    :ets.insert_new(:game_state, {"table", [], ""})
    :ets.insert_new(:game_state, {"players", num_players, []})
    deck = Deck.deck_gen(num_players)
    :ets.insert(:game_state, {"deck", deck})
    {:ok, "Game created"}
  end

  # ---------------------------------------------- #


  # ---------------------------------------------- #
  #  AÑADIR JUGADORES                              #
  # ---------------------------------------------- #

  def save_players(player_name) do
    [{_, num_players, player_list}] = :ets.lookup(:game_state, "players")
    :ets.insert_new(:game_state, {player_name})
    :ets.insert(:game_state, {"players", num_players, [player_name | player_list]})
    {:ok, "Player created"}
  end

  # El num_players del case, si no se le pone el "^" piensa que es una variable nueva
  def check_player_count(player_name) do
    [{_, num_players, player_list}] = :ets.lookup(:game_state, "players")
    case length(player_list) do
      ^num_players -> {:error, "No more players allowed"}
      _ -> save_players(player_name)
    end
  end

  def add_player(player_name) do
    exists_player = :ets.lookup(:game_state, player_name)
    case exists_player do
      [] -> check_player_count(player_name)
      _ -> {:error, "Player name already exist"}
    end
  end

  # TODO hai que modificar esto
  def update_player_cards({player_name, hand}) do
      :ets.insert(:game_state, {player_name, hand, 0, []})
  end


  # ---------------------------------------------- #
  # Repartir cartas
  # ---------------------------------------------- #

  def distribute_cards() do
    [{_, num_players, player_list}] = :ets.lookup(:game_state, "players")
    [{_, deck}] = :ets.lookup(:game_state, "deck")
    card_per_hand = round(length(deck)/num_players)
    hand_decks = Enum.chunk_every(deck, card_per_hand)
    players_with_decks = Enum.zip(player_list, hand_decks)
    for {player_name, hand} <- players_with_decks, do: :ets.insert(:game_state, {player_name, hand, 0, []})
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
  # A idea aquí é ter funcións para cada un dos casos, primerio identifico en cal estamos e despois miramos o resultado

  defp check_f_card(f_card_t, f_card_p) do
    if f_card_p > f_card_t do
      true
    else
      false
    end
  end

  # Logica, si la primera carta es mayor las demás lo son, se asume
  # Si no lo es miramos que el resto de cartas que se ponen del jugador son iguales
  defp compare_cards_equal_length([f_card_t | tail_t], [f_card_p | tail_p]) do
    f_number_t = f_card_t |> elem(0)
    f_number_p = f_card_p |> elem(0)

    [s_card_t, _] = tail_t
    [s_card_p, _] = tail_p
    s_number_t = s_card_t |> elem(0)
    s_number_p = s_card_p |> elem(0)

    cond do
      (f_number_p == s_number_p) && (f_number_t == s_number_t) ->
        check_f_card(f_card_t, f_card_p)
      (f_number_p < s_number_p) && (f_number_t < s_number_t) ->
        check_f_card(f_card_t, f_card_p)
      (f_number_p == s_number_p) && (f_number_t < s_number_t) ->
        true
      (f_number_p < s_number_p) && (f_number_t == s_number_t) ->
        false
      true ->
        "There's been a problem"
    end
  end

  defp can_put_cards?(table_cards, player_cards) do
    cond do
      length(table_cards) < length(player_cards) ->
        true
      length(table_cards) == length(player_cards) ->
        compare_cards_equal_length(table_cards, player_cards)
      true ->
        false
    end
  end

  defp put_cards_on_table(player_info, position, number_of_cards) do
    [{player_name, hand, _, card_poinst}] = player_info

    cards_to_show = hand |> Enum.slice(position, number_of_cards)
    # Miro las cartas en la mesa
    [{_, table_cards, _}] = :ets.lookup(:game_state, "table")
    if not can_put_cards?(table_cards, cards_to_show) do
      {:error, "No se pudieron poner las cartas"}
    else
      :ets.insert(:game_state, {"table", cards_to_show, player_name})
      {:ok, "Cartas puestas"}
    end
  end

  # Se va a modificar el show para solo pasar la posición de la carta a mostrar
  def show(player_name, position, number_of_cards) do
    exists_player = :ets.lookup(:game_state, player_name)
    case exists_player do
      [] -> {:error, "Player does not exists"}
      _ -> put_cards_on_table(exists_player, position, number_of_cards)
    end
    should_the_game_end?(player_name)
  end

  # ---------------------------------------------- #

  def take_cards(player_name, {x,y}, position, orientation, table_cards) do
    if card in table_cards do
      {_, player_cards, points, point_cards} = :ets.lookup(:game_state, player_name)
      cond do
        orientation -> card = {y,x}
      end
      insert_card_given_pos(player_cards, card, position)
      :ets.insert(:game_state, {player_name, player_cards, points, point_cards})
    end
  end

  def give_points(player_name) do
    [{_, cards, points, point_cards}] = :ets.lookup(:game_state, player_name)
    :ets.insert(:game_state, {player_name, cards, points+1, point_cards})

  end

  #Solo se poden coller as cartas dos vordes
  def process_take(player_name, card_taken, position, orientation, table_state) do
    [{_, table_cards, table_player}] = table_state
    take_cards(player_name, card, position, orientation, table_cards)
    give_points(player_name)
  end

  # cards son as cartas que se quitan da table y la posición en la que se meten en la mano
  # Solo se poden coller as cartas das beiras, non as do medio
  # Como solo se pode coller a primeira ou a última podo facer o de collela e ou do principio ou do final
  # Necesito a pensar en esta partida como estados
  def take(player_name, card_taken, orientation) do
    state = :ets.lookup(:game_state, "table")
    case state do
      [{"table"}] -> {:error, "Cannot scout no cards on the table"}
      [_] -> process_take(player_name, card_taken, position, orientation, state) # Tengo que dar los puntos a la pers
    end
  end

  # ---------------------------------------------- #

  def check_player_info(player_name) do
    exists_player = :ets.lookup(:game_state, player_name)
    case exists_player do
      [] -> {:error, "Player does not exists"}
      _ -> exists_player
    end
  end

  def check_table_cards() do
    :ets.lookup(:game_state, "table")
  end

  def player_hand_deck_check(player_name) do
    exists_player = :ets.lookup(:game_state, player_name)
  end

  def should_the_game_end?(player_name) do
    [{_, cards, points, point_cards}] = :ets.lookup(:game_state, player_name)
    case cards do
      [] -> the_game_ends()
      _ -> {:ok, "Nada que hacer el juego continua"}
    end
  end

  def the_game_ends() do
    #calc_poinst

    :ets.delete(:game_state)
    {:final, "The game has ended"}
  end

  def calc_points() do
    [{_, num_players, player_names}] = :ets.lookup(:game_state, "players")
  end

  def calc_point([h|t], result_array) do
    [{_, cards, points, point_cards}] = :ets.lookup(:game_state, h)
    real_points = length(point_cards) + points - length(cards)
    [{h, real_points} | result_array]
  end
end
