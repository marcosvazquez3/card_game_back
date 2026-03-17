#Interesante sobre supervisores dinámicos
#https://elixirforum.com/t/difference-between-supervisors-and-dynamicsupervisors-what-am-i-missing/48821/3
defmodule CardGameBackPhoenix.TableSupervisor do

  use DynamicSupervisor

  @spec init(:ok) ::
          {:ok,
           %{
             extra_arguments: list(),
             intensity: non_neg_integer(),
             max_children: :infinity | non_neg_integer(),
             period: pos_integer(),
             strategy: :one_for_one
           }}
  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_options) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new_game(table_id) do
    DynamicSupervisor.start_child(__MODULE__, {CardGameBackPhoenix.Game.Table, via_tuple(table_id)})
  end

  def destroy_table(table_id) do
    :ets.delete(:game_state, table_id)
    if pid = CardGameBackPhoenix.Game.TableManager.get_table_pid(table_id) do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    else
      :ok  # or log error/warning
    end
  end

  defp via_tuple(name) do
    {:via, Registry, {Registry.Table, name}}
  end

end
