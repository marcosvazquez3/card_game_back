defmodule Deck do

  #Teño que revisar que necesito para o número de xogadores
  #xa que o número de cartas non aumenta linealmente

  @base_number_cards 5

  defp base_list(players) do
    number_cards = @base_number_cards + players
    Enum.to_list(1..number_cards)
  end

  def deck_gen(players) do
    base_list = base_list(players)
    proba = for x <- base_list, y <- base_list, x < y, do: {x, y}
    IO.inspect(length(proba))
    Enum.shuffle(proba)
  end

end
