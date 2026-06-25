defmodule CardGameBackPhoenix.Game.PlayerList do

  alias CardGameBackPhoenix.Game.Player
  # Esto sería mais ben player info
  # defstruct [%Player{cards: [], player_id: 2, player_name: "name2", pointcards: [], points: 0},%Player{cards: [], player_id: 1, player_name: "name1", pointcards: [], points: 0}]
  # defstruct, cambiar la estructura de los jugadores, tiene que ser un diccionario
  # Tenemos que tener como key el id del jugador
  def new() do
    %{}
  end


  def add(player_id, player_nested_map) do
    if Map.has_key?(player_nested_map, player_id) do
      {:error, :name_taken}
    else
      Map.put(player_nested_map, player_id, Player.new(player_id))
    end
  end

  def deal_the_cards(player_nested_map, player_count, deck) do
    card_per_hand = round(length(deck)/player_count)
    hand_decks = Enum.chunk_every(deck, card_per_hand)
    Enum.zip(player_nested_map, hand_decks)
  end


  def get_player(player_id, player_map) do
    Map.get(player_map, player_id)
  end

  def update_player(updated_player, player_map) do
    Map.put(player_map, updated_player.player_id, updated_player)
  end

end
