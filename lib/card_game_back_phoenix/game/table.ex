#Aquí se va a guardar el estado de las cartas en la mesa
#https://hexdocs.pm/elixir/agents.html
#Pode usarse o GenServer
#https://hexdocs.pm/elixir/1.12/GenServer.html

# TODO Facer refactor desto, a lógica ten que salir fora deste archivo
# Cambiar os returns, non podo facer return da info toda de partida porque a lío
# Básicamente devolvolles toda a info da mesa a todo o mundo
defmodule CardGameBackPhoenix.Game.Table do

  use GenServer
  alias CardGameBackPhoenix.Game

  # Cliente

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(table_id) do
    GenServer.start_link(__MODULE__, table_id, name: via_tuple(table_id))
  end

  #Servidor

  @impl true
  def init(table_id) do
    table_registry = via_tuple(table_id)
    init_data = %{
      phase: :setup,
      table_registry: table_registry,
      player_count: 0,
      player_list: %{},
      table_cards_count: 0,
      table_cards_owner: nil,
      table_cards: [],
      player_order: [],
      ready_players: %{},
      turn: "unknown",
    }
    # Necesito crear unha estructura que garde a información completa da partida
    {:ok, init_data}
  end

  def start_game(table_id) do
    table_registry = via_tuple(table_id)
    GenServer.call(table_registry, :start_game)
  end

  def deal_the_cards(deck, state) do
    players = Map.to_list(state.player_list)
    Enum.zip(players, deck)
      |> Enum.map(fn {{player_id, player_map}, cards} ->
        {player_id, Map.put(player_map, :cards, cards)}
      end)
      |> Enum.into(%{})  # Convert back to a map
  end

  def handle_call(:start_game, _from, state) do
    deck = Game.Deck.deck_gen(state.player_count)
    player_nested_map = deal_the_cards(deck, state)
    new_state = %{state | player_list: player_nested_map}
    {:reply, "Game created", new_state}
  end

  # def update_player_cards([player | remaining_players]) do

  # end

  @spec update_player_cards([]) :: {:ok, <<_::192>>}
  def update_player_cards([]) do
    {:ok, "all player cards updated"}
  end


  def add_player(table_id, player_id) do
    GenServer.call(via_tuple(table_id), {:add_player, player_id})
  end

  # Non necesita o table registry porque solo siver para decidir o proceso a cal enviarlle o call
  def handle_call({:add_player, player_id}, _from, state) do
    player_nested_map = Game.PlayerList.add(player_id, state.player_list)
    {player_order, turn} = add_player_to_player_order(state.player_order, player_id)
    aux_state =
      case turn do
        nil -> state
        _ -> %{state | turn: turn}
      end
    updated_ready_players = Map.put(state.ready_players, player_id, false)
    new_state = %{aux_state | player_list: player_nested_map, player_count: Map.keys(player_nested_map) |> length(), player_order: player_order, ready_players: updated_ready_players}
    {:reply, "player added", new_state}
  end

  defp add_player_to_player_order([], player_id) do
    {[player_id], player_id}
  end

  defp add_player_to_player_order(player_order, player_id) do
    {[player_id | player_order], nil}
  end


  @spec check_cards(any(), any(), any()) :: list()
  def check_cards(cards, player_id, player_list) do
    player = Game.PlayerList.get_player(player_id, player_list)

  end

  def is_a_valid_hand?([], _, _) do
    true
  end

  def is_a_valid_hand?([{n,_}|t], last_card_number, :incremental) do
    case n - last_card_number do
      -1 -> is_a_valid_hand?(t, n, :incremental)
      _ -> false
    end
  end

  def is_a_valid_hand?([{n,_}|t], last_card_number, :decremental) do
    case n - last_card_number do
      1 -> is_a_valid_hand?(t, n, :decremental)
      _ -> false
    end
  end

  def is_a_valid_hand?([{n,_}|t], last_card_number, :equals) do
    case n - last_card_number do
      0 -> is_a_valid_hand?(t, n, :equals)
      _ -> false
    end
  end

  def is_a_valid_hand?([{n,_}|t], last_card_number) do
    case n - last_card_number do
      1 -> is_a_valid_hand?(t, n, :decremental)
      0 -> is_a_valid_hand?(t, n, :equals)
      -1 -> is_a_valid_hand?(t, n, :incremental)
      _ -> false
    end
  end

  def is_a_valid_hand?([{n,_}|t]) do
    is_a_valid_hand?(t,n)
  end


  defp check_f_card(f_card_t, f_card_p) do
    if f_card_p > f_card_t do
      true
    else
      false
    end
  end


  defp compare_cards_equal_length(table_cards, played_cards) do
    table_is_set = cards_are_set?(table_cards)
    played_is_set = cards_are_set?(played_cards)

    cond do
      played_is_set and not table_is_set ->
        true
      table_is_set and not played_is_set ->
        false
      true ->
        highest_table_card = Enum.max_by(table_cards, fn {num, _suit} -> num end)
        highest_played_card = Enum.max_by(played_cards, fn {num, _suit} -> num end)
        check_f_card(highest_table_card, highest_played_card)
    end
  end

  defp cards_are_set?(cards) do
    numbers = Enum.map(cards, fn {num, _suit} -> num end)
    case numbers do
      [] -> false
      [first | rest] -> Enum.all?(rest, fn num -> num == first end)
    end
  end


  defp is_player_hand_good_enough?(table_cards, player_cards) do
    cond do
      length(table_cards) < length(player_cards) ->
        true
      length(table_cards) == length(player_cards) ->
        compare_cards_equal_length(table_cards, player_cards)
      true ->
        false
    end
  end

  def delete_player_cards([], _, []) do
    []
  end

  def delete_player_cards([], _, current_player_cards) do
    current_player_cards
  end

  def delete_player_cards([h|t], player_id, current_player_cards) do
    state_cards = current_player_cards
    new_card_state = List.delete(state_cards, h)
    case new_card_state == state_cards do
      false -> delete_player_cards(t, player_id, new_card_state)
      true -> "Card #{inspect(h)} not found in player #{player_id}'s hand"
    end
  end


  defp is_player_turn(player_id, state) do
    case state.turn do
      player_id -> true
      _ -> false
    end
  end

  def is_string([]) do false end

  def is_string(x) when is_binary(x), do: String.valid?(x)

  def show_action(cards, player_id, current_player_cards, state) do
    updated_player_cards = delete_player_cards(cards, player_id, current_player_cards)
    if is_binary(updated_player_cards) do
      {:reply, {:error, "cards invalid to show"}, state}
    else
      point_cards = state.table_cards
      existing_point_cards = state.player_list[player_id].point_cards
      updated_point_cards = existing_point_cards ++ point_cards
      state_with_points = put_in(
        state,
        [:player_list, player_id, Access.key!(:point_cards)],
        updated_point_cards
      )
      new_state_player_update = put_in(
        state_with_points,
        [:player_list, player_id, Access.key!(:cards)],
        updated_player_cards
      )
      next_player_turn = get_next_player_turn(state)
      new_state = %{new_state_player_update | table_cards: cards, table_cards_count: length(cards), turn: next_player_turn, table_cards_owner: player_id}
      case check_end_game(new_state, player_id) do
        {:end_round, reason, final_state} ->
          end_game(reason, final_state)
        {:continue, _valid_state} ->
          {:reply, :ok, new_state}
      end
    end
  end

  def handle_call({:show, cards, player_id}, _from, state) do
    case is_player_turn(player_id, state) and is_a_valid_hand?(cards) and  is_player_hand_good_enough?(state.table_cards, cards) do
      true -> show_action(cards, player_id, state.player_list[player_id].cards, state)
      false -> {:reply, :error, "turn not valid"}
    end
  end

  def show(table_id, cards, player_id) do
    GenServer.call(via_tuple(table_id), {:show, cards, player_id})
  end



  defp get_card(:end, cards, flip?) do
    {card, new_table_state} = List.pop_at(cards, -1)
    card_flip? = Game.Deck.flip_single_card(card, flip?)
    {card_flip?, new_table_state}
  end

  defp get_card(:beginning, [h|t], flip?) do
    card_flip? = Game.Deck.flip_single_card(h, flip?)
    {card_flip?, t}
  end

  def handle_call({:scout, player_id, where, hand_position, flip?}, _from, state) do
    if is_player_turn(player_id, state) do
      receives_points = state.table_cards_owner
      give_points = get_in(state, [:player_list, receives_points, Access.key!(:points)])
      new_user_point_state = put_in(state, [:player_list, receives_points, Access.key!(:points)], give_points+1)
      {card, new_table} = get_card(where, new_user_point_state.table_cards, flip?)
      updated_player_cards = List.insert_at(new_user_point_state.player_list[player_id].cards, hand_position, card)
      new_state_player_update = put_in(new_user_point_state, [:player_list, player_id, Access.key!(:cards)], updated_player_cards)
      next_player_turn = get_next_player_turn(state)
      new_state = %{new_state_player_update | table_cards: new_table, table_cards_count: length(new_table), turn: next_player_turn}
      case check_end_game(new_state, player_id) do
        {:end_round, reason, final_state} ->
          end_game(reason, final_state)
        {:continue, _valid_state} ->
          {:reply, :ok, new_state}
      end
    else
      {:reply, {:error, "Not your turn"}, state}
    end
  end


  def scout(table_id, player_id, where, hand_position, flip?) do
    GenServer.call(via_tuple(table_id), {:scout, player_id, where, hand_position, flip?})
  end


  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end


  def get_table_state(table_id) do
    GenServer.call(via_tuple(table_id), :get_state)
  end

  defp removing_player_information([h|t], player_list) do
    user = player_list[h]
    new_user = %{
      player_id: user.player_id,
      cards: length(user.cards)
    }
    updated_player_list = Map.put(player_list, h, new_user)
    removing_player_information(t, updated_player_list)
  end

  defp removing_player_information([], player_list) do
    player_list
  end

  defp clean_state(state, user_id) do
    player_list = state.player_list
    clean_ids  = state.player_order -- [user_id]
    clea_player_list = removing_player_information(clean_ids, player_list)
    %{state | player_list: clea_player_list}
  end

  @impl true
  def handle_call({:get_user_state, user_id}, _from, state) do
    clean_state = clean_state(state, user_id)
    {:reply, {"current state", clean_state}, state}
  end

  def get_user_state(table_id, user_id) do
    GenServer.call(via_tuple(table_id), {:get_user_state, user_id})
  end

  # PREGUNTARLLE A LAURA SOBRE ESTO
  def send_action(table_id, action) do
    GenServer.call(via_tuple(table_id), action)
  end

  defp get_next_player_turn(state) do
    index = Enum.find_index(state.player_order, &(&1 == state.turn))
    if index == length(state.player_order)-1 do
      Enum.at(state.player_order, 0)
    else
      Enum.at(state.player_order, index+1)
    end
  end

   def handle_call(:all_players_ready, _from, state) do
    are_all_ready = Enum.all?(state.player_order, fn player_id ->
      Map.get(state.ready_players, player_id, false) == true
    end)
    if are_all_ready == true do
      new_state = %{state | phase: :playing}
      {:reply, {true, state.turn}, new_state}
    else
      {:reply, {false, state.turn}, state}
    end
  end

  def all_players_ready?(table_id) do
    GenServer.call(via_tuple(table_id), :all_players_ready)
  end

  def handle_call({:flip_initial_hand, user_id}, _from, state) do
    updated_player_list =
      Map.update!(state.player_list, user_id, fn player ->
        flipped_hand = Game.Deck.flip_hand(player.cards)
        %{player | cards: flipped_hand}
      end)
    new_state = %{state | player_list: updated_player_list}
    {:reply, {"hand_fliped"}, new_state}
  end

  def flip_initial_hand(table_id, user_id) do
    GenServer.call(via_tuple(table_id), {:flip_initial_hand, user_id})
  end

  def handle_call({:mark_player_ready, user_id}, _from, state) do
    updated_ready_map = Map.put(state.ready_players, user_id, true)
    new_state = %{state | ready_players: updated_ready_map}
    {:reply, {"player_ready"}, new_state}
  end

  def mark_player_ready(table_id, user_id) do
    GenServer.call(via_tuple(table_id), {:mark_player_ready, user_id})
  end


  defp check_end_game(state, active_player) do
    player_cards = get_in(state, [:player_list, active_player, Access.key!(:cards)])
    if length(player_cards) == 0 do
      {:end_round, :empty_hand, state}
    else
      check_unbeatable_table(state)
    end
  end

  defp check_unbeatable_table(state) do
    if state.turn == state.table_cards_owner do
      {:end_round, :unbeatable_table, state}
    else
      {:continue, state} # Business as usual
    end
  end


  defp end_game(reason, state) do
    updated_player_list =
      Map.new(state.player_list, fn {player_id, player} ->
        scouted_points = player.points
        show_points = length(player.point_cards)
        cards_in_hand = length(player.cards)
        penalty =
          cond do
            reason == :empty_hand and player_id == state.turn ->
              0
            reason == :unbeatable_table and player_id == state.table_cards_owner ->
              0
            true ->
              cards_in_hand
          end
        round_score = show_points + scouted_points - penalty
        {player_id, %{player | points: round_score}}
      end)
    end_state = %{
      state |
      player_list: updated_player_list,
      phase: :game_over
    }
    scoreboard =
      Map.new(updated_player_list, fn {player_id, player} ->
        {player_id, player.points}
      end)
    {:reply, {:game_over, reason, scoreboard}, end_state}
  end

  def via_tuple(table_id), do: {:via, Registry, {Registry.Table, table_id}}

end
