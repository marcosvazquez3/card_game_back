defmodule TableTest do
  # Para lanzar os test facer mix test test/test_table_wo_c.exs
  # TODO poner un mínimo de 2 juagadores
  use ExUnit.Case
  doctest Table_WT_Conection

  test "create table state" do
    assert Table_WT_Conection.create_game(4) == {:ok, "Game created"}
    assert :ets.lookup(:table_state, "table") == [{"table"}]
    assert :ets.lookup(:table_state, "players") == [{"players", 4, []}]
    [{_, deck}] = :ets.lookup(:table_state, "deck")
    assert length(deck) == 36
  end

  test "add one player" do
    Table_WT_Conection.create_game(2)
    assert Table_WT_Conection.add_player("Marcos") == {:ok, "Player created"}
    assert :ets.lookup(:table_state, "Marcos") == [{"Marcos"}]
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

  test "play the deck basic show" do
    Table_WT_Conection.create_game(2)
    assert Table_WT_Conection.add_player("Marcos") == {:ok, "Player created"}
    assert Table_WT_Conection.add_player("Pepe") == {:ok, "Player created"}
    Table_WT_Conection.distribute_cards()
  end

end
