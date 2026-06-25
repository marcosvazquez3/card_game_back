defmodule CardGameBackPhoenix.Game.Player do

  defstruct [:player_id, cards: [], points: 0, point_cards: [], scout_and_show: :false, ready: :false]

  def new(player_id) do
    %CardGameBackPhoenix.Game.Player{player_id: player_id}
  end

  def add_hand_cards(player, hand_cards) do
    %{player | cards: hand_cards}
  end

  def add_scout_chip(player) do
    %{player | points: player.points + 1}
  end

  def capture_cards(player, captured_cards) when is_list(captured_cards) do
    %{player | point_cards: player.point_cards ++ captured_cards}
  end

  def calculate_score(player) do
    scout_chips = player.points
    captured_points = Enum.count(player.point_cards)
    penalty_points = Enum.count(player.cards)

    scout_chips + captured_points - penalty_points
  end

end
