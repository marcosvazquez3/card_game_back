#Aquí se va a guardar el estado de las cartas en la mesa
#https://hexdocs.pm/elixir/agents.html
#Pode usarse o GenServer
#https://hexdocs.pm/elixir/1.12/GenServer.html

defmodule Table do

  use GenServer

  alias Deck

  # Callbacks

  def start_link(tableid) do
    GenServer.star_link(__MODULE__, table_id, name: via_tuple(table_id))
  end

  @impl true
  def init(table_id) do
    {:ok, table_id}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end

  defp via_tuple(table_id) do
    # And the tuple always follow the same format:
    # {:via, module_name, term}
    {:via, Registry, {Registr.Table, table_id}}
  end

end
