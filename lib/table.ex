#Aquí se va a guardar el estado de las cartas en la mesa
#https://hexdocs.pm/elixir/agents.html
#Pode usarse o GenServer
#https://hexdocs.pm/elixir/1.12/GenServer.html

defmodule Table do

  use GenServer

  alias Deck

  # Cliente

  def start_link(table_id) do
    GenServer.start_link(__MODULE__, table_id, name: via_tuple(table_id))
  end

  def start_game(table) do
    #GenServer.cast(via_tupe(table), :start_game)
  end

  defp via_tuple(table_id) do
    # And the tuple always follow the same format:
    # {:via, module_name, term}
    {:via, Registry, {Registry.Table, table_id}}
  end


  #Servidor

  @impl true
  def init(table_id) do
    {:ok, table_id}
  end

  #Estou pensando que non necesito inicializar o game como tal. Non necesito nada antes de que se unan os xogadores
  #escepto a propia mesa
  #Una vez añadidos os xogadores xa podo crear o mazo de cartas

end
