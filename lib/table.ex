#Aquí se va a guardar el estado de las cartas en la mesa
#https://hexdocs.pm/elixir/agents.html
defmodule Table do

  defmodule Card do
    defstruct [top: "", bottom: ""]
  end

  _players = "Number of players"

  cards_on_table = []

  def add_cards(card_array) do
    cards_on_table = card_array
  end

  def remove_cards([]) do
    :end
  end

  def remove_cards([position | lits]) do
  end

end
