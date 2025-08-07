#Aquí se va a guardar el estado de las cartas en la mesa
#https://hexdocs.pm/elixir/agents.html
#Pode usarse o GenServer
#https://hexdocs.pm/elixir/1.12/GenServer.html

defmodule Table do

  use GenServer

  alias Deck

  # Cliente

  def start_link(table_registry) do
    # Este table id ya es el registry
    GenServer.start_link(__MODULE__, table_registry, name: table_registry)
    # Este start_link llama a init
  end


  #Servidor

  @impl true
  def init(table_registry) do
    init_data = %{
      table_registry: table_registry,
      player_count: 0,
      player_list: %{},
      table_cards_count: 0,
      table_cards: [],
    }
    # Necesito crear unha estructura que garde a información completa da partida
    {:ok, init_data}
  end

  def start_game(table_registry) do
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
    deck = Deck.deck_gen(state.player_count)
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


  def add_player(player_id, player_name, table_registry) do
    GenServer.call(table_registry, {:add_player, player_id, player_name})
  end

  # Non necesita o table registry porque solo siver para decidir o proceso a cal enviarlle o call
  # Debería mirar si el player_id existe?
  def handle_call({:add_player, player_id, player_name}, _from, state) do
    player_nested_map = PlayerList.add(player_id, player_name, state.player_list)
    new_state = %{state | player_list: player_nested_map, player_count: Map.keys(player_nested_map) |> length()}
    {:reply, "player added", new_state}
  end


  def check_cards(cards, player_id, player_list) do
    player = PlayerList.get_player(player_id, player_list)

  end

  def is_a_valid_hand?([], _, _) do
    true
  end

  def is_a_valid_hand?([{n,_}|t], last_card_number, :incremental) do
    case n - last_card_number do
      -1 -> is_a_valid_hand?(t, n, :equals)
      _ -> false
    end
  end

  def is_a_valid_hand?([{n,_}|t], last_card_number, :decremental) do
    case n - last_card_number do
      1 -> is_a_valid_hand?(t, n, :equals)
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

  defp check_f_card(f_card_t, f_card_p) do
    if f_card_p > f_card_t do
      true
    else
      false
    end
  end

  # Logica, si la primera carta es mayor las demás lo son, se asume
  # Si no lo es miramos que el resto de cartas que se ponen del jugador son iguales
  defp compare_cards_equal_length([f_card_t | tail_t], [f_card_p | tail_p]) do
    f_number_t = f_card_t |> elem(0)
    f_number_p = f_card_p |> elem(0)

    s_card_t = hd(tail_t)
    s_card_p = hd(tail_p)
    s_number_t = s_card_t |> elem(0)
    s_number_p = s_card_p |> elem(0)

    cond do
      (f_number_p == s_number_p) && (f_number_t == s_number_t) ->
        check_f_card(f_card_t, f_card_p)
      (f_number_p < s_number_p) && (f_number_t < s_number_t) ->
        check_f_card(f_card_t, f_card_p)
      (f_number_p == s_number_p) && (f_number_t < s_number_t) ->
        true
      (f_number_p < s_number_p) && (f_number_t == s_number_t) ->
        false
      true ->
        "There's been a problem"
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

  def is_a_valid_hand?([{n,_}|t]) do
    is_a_valid_hand?(t,n)
  end

  def delete_player_cards([], _, []) do
    []
  end

  def delete_player_card([], _, current_player_cards) do
    current_player_cards
  end

  def delete_player_cards([h|t], player_id, current_player_cards) do
    state_cards = current_player_cards
    new_card_state = List.delete(state_cards, h)
    case new_card_state == state_cards do
      false -> delete_player_cards(t, player_id, new_card_state)
      true -> "cards are not found in the player hand"
    end
  end

  def is_string([]) do false end

  def is_string(x) when is_binary(x), do: String.valid?(x)

  def show_action(cards, player_id, state, current_player_cards) do
    updated_player_cards = delete_player_cards(cards, player_id, current_player_cards)
    if is_string(updated_player_cards) do
      {:reply, :error, "cards invalid to show"}
    else
      new_state_player_update = put_in(state.player_list[player_id].cards, updated_player_cards)
      new_state = %{new_state_player_update | table_cards: cards, table_cards_count: length(cards)}
      {:reply, "Game created", new_state}
    end
  end

  def handle_call({:show, cards, player_id}, _from, state) do
    case is_a_valid_hand?(cards) and  is_player_hand_good_enough?(state.table_cards, cards) do
      true -> show_action(cards, player_id, state, state.player_list[player_id].cards)
      false -> {:reply, :error, "cards invalid to show"}
    end
  end


  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {"current state", state}, state}
  end

  def via_tuple(table_id), do: {:via, Registry, {Registry.Table, table_id}}

end
