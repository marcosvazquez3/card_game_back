defmodule Player do

  # Esto sería mais ben player info
  defstruct [:player_id, :player_name, cards: [], points: 0, pointcards: []]

  def new(player_id, player_namer) do
    %Player{player_id: player_id, player_name: player_namer}
  end

  def add_hand_cards(player, hand_cards) do
    %{player | cards: hand_cards}
  end

end
