defmodule CardGameBackPhoenix.Game.Deck do

  # Teño que revisar que necesito para o número de xogadores
  # xa que o número de cartas non aumenta linealmente
  # A idea é que todos os xogadores teñan sempre 9 cartas independentemente dos xogadores
  # TODO facerlle suffle as cartas da baraxa
  alias Decimal

  # A fórmula para o número de combinacións está aquí: https://www.omnicalculator.com/es/estadistica/combinaciones-y-permutaciones
  # Necesito encontrar un fórmula para saber as cartas
  # Porque faise demasiado

  defp base_list(players) do
    number_cards = 9*players
    size_float = (-(-1)+:math.sqrt(((-1)*(-1))-4*1*(-(number_cards*2))))/2
    size = ceil(size_float)
    Enum.to_list(1..size)
  end

  def deck_gen(players) do
    base_list = base_list(players)
    deck = for x <- base_list, y <- base_list, x < y, do: {x, y}
    deck
       |> Enum.reverse()
       |> is_divisor_9?(players)
       |> Enum.reverse()
       |> Enum.shuffle()
       |> flip_cards()
       |> Enum.chunk_every(9)
  end

  def is_divisor_9?([h|t], players) do
    number_cards = players*9
    cond do
      length([h|t]) == number_cards -> [h|t]
      true -> is_divisor_9?(t, players)
    end
  end

  def flip_cards(deck) do
    Enum.map(deck, fn {x, y} ->
      if :rand.uniform(2) == 2 do
        {y, x} # Flip it
      else
        {x, y} # Keep it
      end
    end)
  end

  def flip_hand(hand) do
    hand
    |> Enum.reverse()
    |> Enum.map(fn {top, bottom} -> {bottom, top} end)
  end

  def flip_single_card(card, flip?) do
    {x,y} = card
    case flip? do
      true -> {y,x}
      false -> card
    end
  end

end
