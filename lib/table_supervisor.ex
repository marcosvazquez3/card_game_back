#Interesante sobre supervisores dinámicos
#https://elixirforum.com/t/difference-between-supervisors-and-dynamicsupervisors-what-am-i-missing/48821/3
defmodule TableSupervisor do

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
    # Pensar en qué como usar ben o registry
    # Registry.start_link(keys: :unique, name: __MODULE__)
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new_game() do
    table_id = UUID.uuid1()
    {:ok, _} = DynamicSupervisor.start_child(__MODULE__, {Table, via_tuple(table_id)})
    table_id
  end

  def destroy_table(table_id) do
    :ets.delete(:game_state, table_id)
    if pid = pid_from_table_id(table_id) do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    else
      :ok  # or log error/warning
    end
  end

  defp via_tuple(name) do
    {:via, Registry, {Registry.Table, name}}
  end

  defp pid_from_table_id(table_id) do
    case Registry.lookup(Registry.Table, table_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

end
