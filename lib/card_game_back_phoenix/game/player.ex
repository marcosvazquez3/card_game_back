defmodule CardGameBackPhoenix.Game.Player do

  # Esto sería mais ben player info
  defstruct [:player_id, cards: [], points: 0, point_cards: []]

  def new(player_id) do
    %CardGameBackPhoenix.Game.Player{player_id: player_id}
  end

  def add_hand_cards(player, hand_cards) do
    %{player | cards: hand_cards}
  end

end
