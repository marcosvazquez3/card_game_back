defmodule Test_Table do


  use GenServer
  use ExUnit.Case, async: true
  import Mimic
  # import ExUnit.CaptureLog
  doctest Game.Table
  setup :set_mimic_global
  setup :verify_on_exit!

  test "Testing Table initialization" do
    {_, pid} = Game.Table.start_link(:testing)
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
    {_, pid} = Game.Table.start_link(:testing)
    GenServer.call(pid, {:add_player, "pepe"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 1,
        player_list: %{
          "pepe" => %Game.Player{cards: [], player_name: "pepe", pointcards: [], points: 0}
        },
        table_cards: [],
        table_cards_count: 0,
        table_registry: :testing
      }
    } == state
  end


  test "Testing adding two player" do
    {_, pid} = Game.Table.start_link(:testing)
    GenServer.call(pid, {:add_player, "name1"})
    GenServer.call(pid, {:add_player, "name2"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            "name1" => %Game.Player{
              cards: [],
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            "name2" => %Game.Player{
              cards: [],
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

  test "Testing adding two player and starting games" do
    # https://github.com/jjh42/mock?tab=readme-ov-file#with_mock---Mocking-a-single-module
    # Mockear el add deck o el add player
    Game.Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Game.Table.start_link(:testing)
    GenServer.call(pid, {:add_player, "name1"})
    GenServer.call(pid, {:add_player, "name2"})
    GenServer.call(pid, :start_game)
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            "name1" => %Game.Player{
              cards: [{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2}],
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            "name2" => %Game.Player{
              cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
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
    Game.Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Game.Table.start_link(:testing)
    GenServer.call(pid, {:add_player, "name1"})
    GenServer.call(pid, {:add_player, "name2"})
    GenServer.call(pid, :start_game)
    GenServer.call(pid, {:show, [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}], "name1"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            "name1" => %Game.Player{
              cards: [],
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            "name2" => %Game.Player{
              cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
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
    Game.Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Game.Table.start_link(:testing)
    GenServer.call(pid, {:add_player, "name1"})
    GenServer.call(pid, {:add_player, "name2"})
    GenServer.call(pid, :start_game)
    GenServer.call(pid, {:show, [{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2}], "name1"})
    GenServer.call(pid, {:show, [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}], "name2"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            "name1" => %Game.Player{
              cards: [],
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            "name2" => %Game.Player{
              cards: [],
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

  test "Testing first scout" do
    Game.Deck
    |> expect(:deck_gen, fn _players ->
      [
        [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
        {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        [{2, 1}, {2, 1}, {2, 1}, {2, 1}, {2, 1},
        {2, 1}, {2, 1}, {2, 1}, {2, 1}]
      ]
    end)
    {_, pid} = Game.Table.start_link(:testing)
    GenServer.call(pid, {:add_player, "name1"})
    GenServer.call(pid, {:add_player, "name2"})
    GenServer.call(pid, :start_game)
    GenServer.call(pid, {:show, [{1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}], "name1"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            "name1" => %Game.Player{
              cards: [],
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            "name2" => %Game.Player{
              cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
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

    GenServer.call(pid, {:scout, {1, 2}, 0, "name1"})
    state = GenServer.call(pid, :get_state)
    assert {
      "current state",
      %{
        player_count: 2,
        player_list: %{
            "name1" => %Game.Player{
              cards: [{1, 2}],
              player_name: "name1",
              pointcards: [],
              points: 0
            },
            "name2" => %Game.Player{
              cards: [{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1},{2,1}],
              player_name: "name2",
              pointcards: [],
              points: 0
            }
          },
        table_cards: [ {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}],
        table_cards_count: 8,
        table_registry: :testing
      }
    } == state
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

end
