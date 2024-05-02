defmodule Actions do

  #para cada acción vamos a recibir el estado de la mesa
  #y las cartas que se usan

  def show_cards(cards_hand, cards_table) do
    #En principio a mesa vai ser un diccionario ou algo polo estilo
    if length(cards) > length(table_state) do
      cards_table = cards
    cards_table #Teño que mirar de mostrar error
  end

  def take_cards(card_take, cards_table) do
    cards_table.delete(card_take)
    cards_table
  end

end
