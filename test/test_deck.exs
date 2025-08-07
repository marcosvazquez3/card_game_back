defmodule DeckTest do
  # Para lanzar os test facer mix test test/test_deck.exs
  # TODO poner un mínimo de 2 juagadores
  use ExUnit.Case
  doctest Deck

  test "create deck for 2 players" do
    players = 2
    deck = Deck.deck_gen(players)
    assert length(deck) == players
  end

  test "create deck 112 players" do
    players = 112
    assert length(Deck.deck_gen(players)) == players
  end

  test "create deck 10000 players" do
    players = 10000
    assert length(Deck.deck_gen(players)) == players
  end
end
