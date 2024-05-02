defmodule Table_WT_Conection do

  #A tabla do estado da mesa vai ser deta maneira, {"table", [card1,card2], "player_name"}
  #A tabla dos xogadores vai ser desta maneira, {"name_player", [cards], points, [taken_cards]}
  # Compilar c("lib/table_without_conexion.ex")
  # c("lib/deck.ex")

  def start_game(num_players) do
    :ets.new(:table_state, [:public, :named_table])
    :ets.insert_new(:table_state, {"table"})
    :ets.insert_new(:table_state, {"players", num_players})
    deck = Deck.deck_gen(num_players)
    :ets.insert(:table_state, {"deck", deck})
  end

  def add_player(name_player) do
    exists_player = :ets.lookup(:table_state, name_player)
    case exists_player do
      [] -> {:error, "Player name already exist"}
      _ -> :ets.insert_new(:table_state, {name_player})
    end
    {:ok, "Player created"}
  end

  def update_player_cards(name_player, cards) do
    :ets.insert(:table_state, {name_player, cards})
  end

  # ---------------------------------------------- #

  defp put_cards_on_table(name_player, player_cards, table_state) do
    table_cards = table_state |> elem(1)
    :ets.insert(:table_state, {"table", player_cards, table_cards})
  end

  #Fal por comprobar que o número de cartas é maior que as cartas na mesa
  def show(name_player, cards) do
    exists_player = :ets.lookup(:table_state, name_player)
    table_state = :ets.lookup(:table_state, "table")
    case exists_player do
      [] -> {:error, "Player does not exists"}
      _ -> put_cards_on_table(name_player, cards, table_state)
    end
  end

  # ---------------------------------------------- #
  # Esto funciona
  def find([], _, _, result), do: result

  def find([head | tail], inserts, 0, result),
    do: find(tail, inserts, -1, [head, inserts | result])

  def find([head | tail], inserts, index, result),
    do: find(tail, inserts, index - 1, [head | result])

  def insert_card_given_pos(card, deck, pos) do
    Enum.reverse(find(deck, card, pos, []))
  end
  # ---------------------------------------------- #

  def process_scout(name_player, card, position, table_state) do
    table_cards = table_state |> elem(1)
    if card in table_cards do
      player_state = :ets.lookup(:table_state, name_player)
      player_cards = player_state |> elem(1)
      insert_card_given_pos(player_cards, card, position)
      #:ets.insert()
    end
  end

  # cards son as cartas que se quitan da table y la posición en la que se meten en la mano
  def scout(name_player, cards, position) do
    state = :ets.lookup(:table_state, "table")
    case state do
      [{"table"}] -> {:error, "Cannot scout no cards on the table"}
      [_] -> process_scout(name_player, cards, position, state)
    end
  end

  # ---------------------------------------------- #

  def check_hand_cards(player_name) do
    :ets.lookup(:table_state, "table")
  end

end
