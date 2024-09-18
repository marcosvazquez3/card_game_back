defmodule Actions do

  #para cada acción vamos a recibir el estado de la mesa
  #y las cartas que se usan
  # Deberías poder elegir cual de las dos opciones hacer primero
  # Fáltanme todas as comprobacións de ambas cousas

  def show_cards(cards_hand, cards_table) do
    #En principio a mesa vai ser un diccionario ou algo polo estilo
    if length(cards_hand) > length(cards_table) do
      cards_table = cards_hand
    end
    cards_table #Teño que mirar de mostrar error
  end

  def take_cards(cards_to_take, cards_table) do
    cards_table.delete(cards_to_take)
    cards_table
  end

  def take_and_show(cards_hand, cards_to_take, cards_table) do
    cards_table = take_cards(cards_to_take, cards_table)
    cards_table = show_cards(cards_hand, cards_table)
    cards_table
  end

end
