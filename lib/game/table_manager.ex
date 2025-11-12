defmodule Game.TableManager do
  @registry Registry.Table

  def get_table_pid(table_id) do
    case Registry.lookup(@registry, table_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def send_action(table_id, action) do
    case get_table_pid(table_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, action)
    end
  end

  def via_tuple(table_id) do
    {:via, Registry, {@registry, table_id}}
  end
end
