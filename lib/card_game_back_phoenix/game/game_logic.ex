defmodule CardGameBackPhoenix.Game.ScoutLogic do
  @moduledoc """
  Lóxica funcional pura e inmutable para o xogo Scout.
  Deseñada para ser libre de estado (stateless).
  """
  alias CardGameBackPhoenix.Game

  # =========================================================================
  # Validacións de Mans e Regras
  # =========================================================================

  def is_a_valid_hand?([]), do: true
  def is_a_valid_hand?([{n, _} | t]), do: is_a_valid_hand?(t, n)

  defp is_a_valid_hand?([], _, _), do: true
  defp is_a_valid_hand?([{n, _} | t], last, :incremental) when n - last == -1, do: is_a_valid_hand?(t, n, :incremental)
  defp is_a_valid_hand?([{n, _} | t], last, :decremental) when n - last == 1, do: is_a_valid_hand?(t, n, :decremental)
  defp is_a_valid_hand?([{n, _} | t], last, :equals) when n - last == 0, do: is_a_valid_hand?(t, n, :equals)
  defp is_a_valid_hand?(_, _, _), do: false

  defp is_a_valid_hand?([{n, _} | t], last) do
    cond do
      n - last == 1 -> is_a_valid_hand?(t, n, :decremental)
      n - last == 0 -> is_a_valid_hand?(t, n, :equals)
      n - last == -1 -> is_a_valid_hand?(t, n, :incremental)
      true -> false
    end
  end

  def is_player_hand_good_enough?(table_cards, player_cards) do
    cond do
      length(table_cards) < length(player_cards) -> true
      length(table_cards) == length(player_cards) -> compare_cards_equal_length(table_cards, player_cards)
      true -> false
    end
  end

  defp compare_cards_equal_length(table_cards, played_cards) do
    table_is_set = cards_are_set?(table_cards)
    played_is_set = cards_are_set?(played_cards)

    cond do
      played_is_set and not table_is_set -> true
      table_is_set and not played_is_set -> false
      true ->
        highest_table_card = Enum.max_by(table_cards, fn {num, _suit} -> num end)
        highest_played_card = Enum.max_by(played_cards, fn {num, _suit} -> num end)
        elem(highest_played_card, 0) > elem(highest_table_card, 0)
    end
  end

  defp cards_are_set?(cards) do
    case Enum.map(cards, fn {num, _suit} -> num end) do
      [] -> false
      [first | rest] -> Enum.all?(rest, fn num -> num == first end)
    end
  end

  # =========================================================================
  # Mutacións do Estado (Operacións Inmutables)
  # =========================================================================

  def deal_the_cards(deck, player_list) do
    players = Map.to_list(player_list)
    Enum.zip(players, deck)
    |> Enum.map(fn {{player_id, player_map}, cards} ->
      {player_id, Map.put(player_map, :cards, cards)}
    end)
    |> Enum.into(%{})
  end

  def delete_player_cards([], _player_id, current_player_cards), do: current_player_cards
  def delete_player_cards([h | t], player_id, current_player_cards) do
    new_card_state = List.delete(current_player_cards, h)
    if new_card_state == current_player_cards do
      {:error, "Card #{inspect(h)} not found in player #{player_id}'s hand"}
    else
      delete_player_cards(t, player_id, new_card_state)
    end
  end

  def get_next_player_turn(player_order, current_turn) do
    index = Enum.find_index(player_order, &(&1 == current_turn))
    if index == length(player_order) - 1 do
      Enum.at(player_order, 0)
    else
      Enum.at(player_order, index + 1)
    end
  end

  def get_card(:end, cards, flip?) do
    {card, new_table_state} = List.pop_at(cards, -1)
    {Game.Deck.flip_single_card(card, flip?), new_table_state}
  end
  def get_card(:beginning, [h | t], flip?) do
    {Game.Deck.flip_single_card(h, flip?), t}
  end

  # =========================================================================
  # Ciclo de Vida e Fins de Partida
  # =========================================================================

  def check_end_game(state, active_player) do
    player_cards = get_in(state, [:player_list, active_player, Access.key!(:cards)])
    if length(player_cards) == 0 do
      {:end_round, :empty_hand}
    else
      if state.turn == state.table_cards_owner do
        {:end_round, :unbeatable_table}
      else
        {:continue, state}
      end
    end
  end

  def compute_final_scoreboards(reason, state) do
    updated_player_list =
      Map.new(state.player_list, fn {player_id, player} ->
        scouted_points = player.points
        show_points = length(player.point_cards)
        cards_in_hand = length(player.cards)

        penalty = cond do
          reason == :empty_hand and player_id == state.turn -> 0
          reason == :unbeatable_table and player_id == state.table_cards_owner -> 0
          true -> cards_in_hand
        end

        round_score = show_points + scouted_points - penalty
        {player_id, %{player | points: round_score}}
      end)

    scoreboard = Map.new(updated_player_list, fn {player_id, player} -> {player_id, player.points} end)
    {updated_player_list, scoreboard}
  end
end
