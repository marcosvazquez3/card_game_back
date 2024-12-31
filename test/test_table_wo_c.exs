defmodule TableTest do
  # Para lanzar os test facer mix test test/test_table_wo_c.exs
  # TODO poner un mínimo de 2 juagadores
  use ExUnit.Case
  doctest Table_WT_Conection

  test "create table state" do
    assert Table_WT_Conection.create_game(4) == {:ok, "Game created"}
    assert :ets.lookup(:game_state, "table") == [{"table", [], ""}]
    assert :ets.lookup(:game_state, "players") == [{"players", 4, []}]
    [{_, deck}] = :ets.lookup(:game_state, "deck")
    assert length(deck) == 36
  end

  test "add one player" do
    Table_WT_Conection.create_game(2)
    assert Table_WT_Conection.add_player("Marcos") == {:ok, "Player created"}
    assert :ets.lookup(:game_state, "Marcos") == [{"Marcos"}]
  end

  test "fail add more players that are allowed" do
    Table_WT_Conection.create_game(2)
    assert Table_WT_Conection.add_player("Marcos") == {:ok, "Player created"}
    assert Table_WT_Conection.add_player("Pepe") == {:ok, "Player created"}
    assert Table_WT_Conection.add_player("Jose") == {:error, "No more players allowed"}
  end

  test "fail to add a player that already exists" do
    Table_WT_Conection.create_game(2)
    assert Table_WT_Conection.add_player("Marcos") == {:ok, "Player created"}
    assert Table_WT_Conection.add_player("Marcos") == {:error, "Player name already exist"}
  end

  test "distribute cards test" do
    Table_WT_Conection.create_game(2)
    assert Table_WT_Conection.add_player("Marcos") == {:ok, "Player created"}
    assert Table_WT_Conection.add_player("Pepe") == {:ok, "Player created"}
    Table_WT_Conection.distribute_cards()
    [{_,pepe_hand,_,_}] = :ets.lookup(:game_state, "Pepe")
    assert length(pepe_hand) == 9
    [{_,marcos_hand,_,_}] = :ets.lookup(:game_state, "Marcos")
    assert length(marcos_hand) == 9
  end

  test "show with empty table" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    hand = [{5,2},{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:ok, "Cartas puestas"}
    assert :ets.lookup(:game_state, "table") == [{"table", hand |> Enum.slice(1,3), "Marcos"}]
  end

  test "show when table table deck is smaller" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    :ets.insert(:game_state, {"table", [{2,2},{3,9}], "Pepe"})
    hand = [{5,2},{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:ok, "Cartas puestas"}
    assert :ets.lookup(:game_state, "table") == [{"table", hand |> Enum.slice(1,3), "Marcos"}]
  end

  test "show when table deck is same size but numbers are bigger" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    :ets.insert(:game_state, {"table", [{1,3},{2,2},{3,9}], "Pepe"})
    hand = [{5,2},{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:ok, "Cartas puestas"}
    assert :ets.lookup(:game_state, "table") == [{"table", hand |> Enum.slice(1,3), "Marcos"}]
  end

  test "show when table deck is same size but numbers are bigger same numbers" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    :ets.insert(:game_state, {"table", [{1,3},{1,2},{1,9}], "Pepe"})
    hand = [{5,2},{2,3},{2,2},{2,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:ok, "Cartas puestas"}
    assert :ets.lookup(:game_state, "table") == [{"table", hand |> Enum.slice(1,3), "Marcos"}]
  end

  test "show when table deck is same size but player hand is same numbers" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    :ets.insert(:game_state, {"table", [{3,3},{4,2},{5,9}], "Pepe"})
    hand = [{5,2},{2,3},{2,2},{2,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:ok, "Cartas puestas"}
    assert :ets.lookup(:game_state, "table") == [{"table", hand |> Enum.slice(1,3), "Marcos"}]
  end

  test "show fails because cards are smaller in size" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    table = [{1,3},{2,2},{3,9}]
    :ets.insert(:game_state, {"table", table, "Pepe"})
    hand = [{5,2},{2,3},{2,2},{2,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 2) == {:error, "No se pudieron poner las cartas"}
    assert :ets.lookup(:game_state, "table") == [{"table", table, "Pepe"}]
  end

  test "show fails because cards are smaller in number" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    table = [{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"table", table, "Pepe"})
    hand = [{5,2},{1,3},{2,2},{3,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:error, "No se pudieron poner las cartas"}
    assert :ets.lookup(:game_state, "table") == [{"table", table, "Pepe"}]
  end

  test "show fails because cards are same in number" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    table = [{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"table", table, "Pepe"})
    hand = [{5,2},{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.show("Marcos", 1, 3) == {:error, "No se pudieron poner las cartas"}
    assert :ets.lookup(:game_state, "table") == [{"table", table, "Pepe"}]
  end

  # TODO facer tests para o take cards, ver que os puntos se suman ben
  # TODO falta hacer test para ver que la partida se acaba y hay que meter funcíon de turnos
  test "take basic" do
    Table_WT_Conection.create_game(2)
    Table_WT_Conection.add_player("Marcos")
    Table_WT_Conection.add_player("Pepe")
    table = [{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"table", table, "Pepe"})
    hand = [{5,2},{2,3},{3,2},{4,9}]
    :ets.insert(:game_state, {"Marcos", hand, 0, []})
    assert Table_WT_Conection.get("Marcos", 1, 3) == {:error, "No se pudieron poner las cartas"}
    assert :ets.lookup(:game_state, "table") == [{"table", table, "Pepe"}]
  end

end
