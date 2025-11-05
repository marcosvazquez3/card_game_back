defmodule Game.Player do

  # Esto sería mais ben player info
  defstruct [:player_name, cards: [], points: 0, pointcards: []]

  def new(player_name) do
    %Game.Player{player_name: player_name}
  end

  def add_hand_cards(player, hand_cards) do
    %{player | cards: hand_cards}
  end

end
