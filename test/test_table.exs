defmodule Test_Table do


  use GenServer
  use ExUnit.Case, async: true
  import Mimic
  # import ExUnit.CaptureLog
  doctest Table
  setup :set_mimic_global
  setup :verify_on_exit!

  test "Testing Table initialization" do
    {_, pid} = Table.start_link(:testing)
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 0,
        player_list: %{},
        table_cards: [],
        table_cards_count: 0,
        table_registry: :testing
      }
    } == state
  end

  test "Testing adding a player" do
    {_, pid} = Table.start_link(:testing)
    IO.inspect(pid)
    GenServer.call(pid, {:add_player, 1, "pepe"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 1,
        player_list: %{
          1 => %Player{cards: [], player_id: 1, player_name: "pepe", pointcards: [], points: 0}
        },
        table_cards: [],
        table_cards_count: 0,
        table_registry: :testing
      }
    } == state
  end


  test "Testing adding two player" do
    {_, pid} = Table.start_link(:testing)
    GenServer.call(pid, {:add_player, 1, "name1"})
    GenServer.call(pid, {:add_player, 2, "name2"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            1 => %Player{
              cards: [],
              player_id: 1,
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            2 => %Player{
              cards: [],
              player_id: 2,
              player_name: "name2",
              pointcards: [],
              points: 0
            }
          },
        table_cards: [],
        table_cards_count: 0,
        table_registry: :testing
      }
    } == state
  end

  # TODO falta por mockear
  test "Testing adding two player and starting games" do
    # https://github.com/jjh42/mock?tab=readme-ov-file#with_mock---Mocking-a-single-module
    # Mockear el add deck o el add player
    Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Table.start_link(:testing)
    GenServer.call(pid, {:add_player, 1, "name1"})
    GenServer.call(pid, {:add_player, 2, "name2"})
    GenServer.call(pid, :start_game)
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            1 => %Player{
              cards: [{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2}],
              player_id: 1,
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            2 => %Player{
              cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
              player_id: 2,
              player_name: "name2",
              pointcards: [],
              points: 0
            }
          },
        table_cards: [],
        table_cards_count: 0,
        table_registry: :testing
      }
    } == state
  end

  test "Testing first show" do
    Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Table.start_link(:testing)
    GenServer.call(pid, {:add_player, 1, "name1"})
    GenServer.call(pid, {:add_player, 2, "name2"})
    GenServer.call(pid, :start_game)
    GenServer.call(pid, {:show, [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}], 1})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            1 => %Player{
              cards: [],
              player_id: 1,
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            2 => %Player{
              cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
              player_id: 2,
              player_name: "name2",
              pointcards: [],
              points: 0
            }
          },
        table_cards: [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        table_cards_count: 9,
        table_registry: :testing
      }
    } == state
  end


  test "Testing 2 continues shows" do
    Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Table.start_link(:testing)
    GenServer.call(pid, {:add_player, 1, "name1"})
    GenServer.call(pid, {:add_player, 2, "name2"})
    GenServer.call(pid, :start_game)
    GenServer.call(pid, {:show, [{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2}], 1})
    GenServer.call(pid, {:show, [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}], 2})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            1 => %Player{
              cards: [],
              player_id: 1,
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            2 => %Player{
              cards: [],
              player_id: 2,
              player_name: "name2",
              pointcards: [],
              points: 0
            }
          },
        table_cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
        table_cards_count: 9,
        table_registry: :testing
      }
    } == state
  end



  def init(init_arg) do
    {:ok, init_arg}
  end

end
