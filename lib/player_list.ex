defmodule PlayerList do

  # Esto sería mais ben player info
  # defstruct [%Player{cards: [], player_id: 2, player_name: "name2", pointcards: [], points: 0},%Player{cards: [], player_id: 1, player_name: "name1", pointcards: [], points: 0}]
  # defstruct, cambiar la estructura de los jugadores, tiene que ser un diccionario
  # Tenemos que tener como key el id del jugador
  def new() do
    %{}
  end


  def add(player_id, player_name, player_nested_map) do
    Map.put(player_nested_map, player_id, Player.new(player_id, player_name))
  end

  def deal_the_cards(player_nested_map, player_count, deck) do
    card_per_hand = round(length(deck)/player_count)
    hand_decks = Enum.chunk_every(deck, card_per_hand)
    players_with_decks = Enum.zip(player_nested_map, hand_decks)
  end


  def get_player(player_id, player_nested_map) do
    Enum.map(player_nested_map, fn player -> player.player_id == player_id end)
  end

  def update_player(updated_player,player_nested_map) do
    Enum.map(player_nested_map,
      fn player ->
        cond do
          player.player_id == updated_player.player_id -> updated_player
          true -> player
        end
      end
    )
  end

end
