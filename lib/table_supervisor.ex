#Interesante sobre supervisores dinámicos
#https://elixirforum.com/t/difference-between-supervisors-and-dynamicsupervisors-what-am-i-missing/48821/3
defmodule Table_Supervisor do

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

  def new_table() do
    table_id = generate_table_id()
    {:ok, _} = DynamicSupervisor.start_child(__MODULE__, {Table, table_id})
    table_id
  end

  def destroy_table(table_id) do
    :ets.delete(:game_state, table_id)
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_game_id(table_id))
  end

  def exists_id?(table_id) do
    not (Registry.lookup(Registry.Game, table_id) == [])
  end

  defp generate_table_id() do
    id =
      :rand.uniform(9999)
      |> Integer.to_string()
      |> String.pad_leading(4, "#")

    if exists_id?(id) do
      generate_table_id()
    else
      id
    end
  end



end
