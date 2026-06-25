defmodule CardGameBackPhoenix.Game.Table do
  use GenServer
  alias CardGameBackPhoenix.Game
  alias CardGameBackPhoenix.Game.ScoutLogic

  # =========================================================================
  # API Cliente
  # =========================================================================

  def start_link(table_id) do
    GenServer.start_link(__MODULE__, table_id, name: via_tuple(table_id))
  end

  def start_game(table_id), do: GenServer.call(via_tuple(table_id), :start_game)
  def add_player(table_id, player_id), do: GenServer.call(via_tuple(table_id), {:add_player, player_id})
  def show(table_id, cards, player_id), do: GenServer.call(via_tuple(table_id), {:show, cards, player_id})
  def scout(table_id, player_id, where, hand_position, flip?), do: GenServer.call(via_tuple(table_id), {:scout, player_id, where, hand_position, flip?})
  def scout_for_show(table_id, player_id, where, hand_position, flip?), do: GenServer.call(via_tuple(table_id), {:scout_for_show, player_id, where, hand_position, flip?})
  def get_table_state(table_id), do: GenServer.call(via_tuple(table_id), :get_state)
  def get_user_state(table_id, user_id), do: GenServer.call(via_tuple(table_id), {:get_user_state, user_id})
  def all_players_ready?(table_id), do: GenServer.call(via_tuple(table_id), :all_players_ready)
  def flip_initial_hand(table_id, user_id), do: GenServer.call(via_tuple(table_id), {:flip_initial_hand, user_id})
  def mark_player_ready(table_id, user_id), do: GenServer.call(via_tuple(table_id), {:mark_player_ready, user_id})
  def player_ready(table_id, user_id), do: mark_player_ready(table_id, user_id)

  # =========================================================================
  # Callbacks Servidor (GenServer)
  # =========================================================================

  @impl true
  def init(table_id) do
    init_data = %{
      phase: :setup,
      table_registry: via_tuple(table_id),
      player_count: 0,
      player_list: %{},
      table_cards_count: 0,
      table_cards_owner: nil,
      table_cards: [],
      player_order: [],
      ready_players: %{},
      turn: "unknown"
    }
    {:ok, init_data}
  end

  @impl true
  def handle_call(:start_game, _from, state) do
    deck = Game.Deck.deck_gen(state.player_count)
    player_nested_map = ScoutLogic.deal_the_cards(deck, state.player_list)
    new_state = %{state | player_list: player_nested_map}
    {:reply, "Game created", new_state}
  end

  @impl true
  def handle_call({:add_player, player_id}, _from, state) do
    player_nested_map = Game.PlayerList.add(player_id, state.player_list)

    {player_order, turn} = case state.player_order do
      [] -> {[player_id], player_id}
      order -> {[player_id | order], nil}
    end

    aux_state = if turn, do: %{state | turn: turn}, else: state
    updated_ready_players = Map.put(state.ready_players, player_id, false)

    new_state = %{aux_state |
      player_list: player_nested_map,
      player_count: map_size(player_nested_map),
      player_order: player_order,
      ready_players: updated_ready_players
    }
    {:reply, "player added", new_state}
  end

  @impl true
  def handle_call({:show, cards, player_id}, _from, state) do
    is_turn = state.turn == player_id
    current_player_cards = state.player_list[player_id].cards
    valid_hand = ScoutLogic.is_a_valid_hand?(cards)
    adjacent = ScoutLogic.are_adjacent_in_hand?(cards, current_player_cards)
    good_enough = ScoutLogic.is_player_hand_good_enough?(state.table_cards, cards)

    if is_turn and valid_hand and adjacent and good_enough do
      case ScoutLogic.delete_player_cards(cards, player_id, current_player_cards) do
        {:error, reason} ->
          {:reply, {:error, reason}, state}
        updated_player_cards ->
          point_cards = state.table_cards
          existing_point_cards = state.player_list[player_id].point_cards
          updated_point_cards = existing_point_cards ++ point_cards

          state_with_points = put_in(state, [:player_list, player_id, Access.key!(:point_cards)], updated_point_cards)
          new_state_player_update = put_in(state_with_points, [:player_list, player_id, Access.key!(:cards)], updated_player_cards)

          next_player_turn = ScoutLogic.get_next_player_turn(state.player_order, state.turn)
          new_state = %{new_state_player_update | table_cards: cards, table_cards_count: length(cards), turn: next_player_turn, table_cards_owner: player_id}

          new_state = if state.player_list[player_id].scout_and_show == :in_progress do
            put_in(new_state, [:player_list, player_id, Access.key!(:scout_and_show)], true)
          else
            new_state
          end

          handle_potential_end(new_state, player_id)
      end
    else
      {:reply, {:error, "turn or hand not valid"}, state}
    end
  end

  @impl true
  def handle_call({:scout, player_id, where, hand_position, flip?}, _from, state) do
    if state.turn == player_id do
      receives_points = state.table_cards_owner
      give_points = get_in(state, [:player_list, receives_points, Access.key!(:points)])
      new_user_point_state = put_in(state, [:player_list, receives_points, Access.key!(:points)], give_points + 1)

      {card, new_table} = ScoutLogic.get_card(where, new_user_point_state.table_cards, flip?)
      updated_player_cards = List.insert_at(new_user_point_state.player_list[player_id].cards, hand_position, card)
      new_state_player_update = put_in(new_user_point_state, [:player_list, player_id, Access.key!(:cards)], updated_player_cards)

      next_player_turn = ScoutLogic.get_next_player_turn(state.player_order, state.turn)
      new_state = %{new_state_player_update | table_cards: new_table, table_cards_count: length(new_table), turn: next_player_turn}

      handle_potential_end(new_state, player_id)
    else
      {:reply, {:error, "Not your turn"}, state}
    end
  end

  @impl true
  def handle_call({:scout_for_show, player_id, where, hand_position, flip?}, _from, state) do
    cond do
      state.turn != player_id ->
        {:reply, {:error, "Not your turn"}, state}

      state.player_list[player_id].scout_and_show != false ->
        {:reply, {:error, "Scout & Show token not available"}, state}

      state.table_cards_owner == nil ->
        {:reply, {:error, "No cards on table to scout"}, state}

      true ->
        receives_points = state.table_cards_owner
        current_points = get_in(state, [:player_list, receives_points, Access.key!(:points)])
        state_with_point = put_in(state, [:player_list, receives_points, Access.key!(:points)], current_points + 1)

        {card, new_table} = ScoutLogic.get_card(where, state_with_point.table_cards, flip?)
        updated_cards = List.insert_at(state_with_point.player_list[player_id].cards, hand_position, card)

        new_state =
          state_with_point
          |> put_in([:player_list, player_id, Access.key!(:cards)], updated_cards)
          |> put_in([:player_list, player_id, Access.key!(:scout_and_show)], :in_progress)
          |> Map.merge(%{table_cards: new_table, table_cards_count: length(new_table)})

        {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:get_user_state, user_id}, _from, state) do
    clean_ids = state.player_order -- [user_id]
    clea_player_list = Enum.reduce(clean_ids, state.player_list, fn id, acc ->
      user = acc[id]
      Map.put(acc, id, %{player_id: user.player_id, cards: length(user.cards)})
    end)
    {:reply, {"current state", %{state | player_list: clea_player_list}}, state}
  end

  @impl true
  def handle_call(:all_players_ready, _from, state) do
    are_all_ready = Enum.all?(state.player_order, fn player_id ->
      Map.get(state.ready_players, player_id, false) == true
    end)
    if are_all_ready do
      new_state = %{state | phase: :playing}
      {:reply, {true, state.turn}, new_state}
    else
      {:reply, {false, state.turn}, state}
    end
  end

  @impl true
  def handle_call({:flip_initial_hand, user_id}, _from, state) do
    updated_player_list = Map.update!(state.player_list, user_id, fn player ->
      %{player | cards: Game.Deck.flip_hand(player.cards)}
    end)
    updated_state = %{state | player_list: updated_player_list}
    {:reply, {:ok, updated_state}, updated_state}
  end

  @impl true
  def handle_call({:mark_player_ready, user_id}, _from, state) do
    updated_ready_map = Map.put(state.ready_players, user_id, true)
    updated_state = %{state | ready_players: updated_ready_map}
    reply = if Enum.all?(updated_ready_map, fn {_, v} -> v end), do: {:ok, :all_ready}, else: {:ok, :player_marked_ready}
    {:reply, reply, updated_state}
  end

  # =========================================================================
  # Funcións de axuda internas
  # =========================================================================

  defp handle_potential_end(state, player_id) do
    case ScoutLogic.check_end_game(state, player_id) do
      {:end_round, reason} ->
        {updated_player_list, scoreboard} = ScoutLogic.compute_final_scoreboards(reason, state)
        end_state = %{state | player_list: updated_player_list, phase: :game_over}
        {:reply, {:game_over, reason, scoreboard}, end_state}
      {:continue, _} ->
        {:reply, {:ok, state}, state}
    end
  end

  def via_tuple(table_id), do: {:via, Registry, {Registry.Table, table_id}}
end
