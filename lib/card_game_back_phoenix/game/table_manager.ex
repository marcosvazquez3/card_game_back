defmodule CardGameBackPhoenix.Game.TableManager do
  @registry Registry.Table

  def whereis(table_id) do
    case Registry.lookup(@registry, table_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def via_tuple(table_id) do
    {:via, Registry, {@registry, table_id}}
  end

  def join_table(table_id, username) do
    case TableSupervisor.new_game(table_id) do
      {:ok, _pid} ->
        Table.add_player(table_id, username)

      {:error, {:already_started, _pid}} ->
        Table.add_player(table_id, username)

      _ -> {:error, "Server Failure"}
    end
  end

  def get_table_db(table_id) do
    Repo.get(Game, table_id)
  end

end
