defmodule CardGameBackPhoenix.Game.TableManager do
  alias CardGameBackPhoenix.Game.Table
  alias CardGameBackPhoenix.Schemas
  alias CardGameBackPhoenix.Utils.Games
  alias CardGameBackPhoenix.TableSupervisor
  alias CardGameBackPhoenix.Repo
  @registry Registry.Table
  def whereis(table_id) do
    case Registry.lookup(@registry, table_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  # def join_table(table_id, username) do
  #   case TableSupervisor.new_game(table_id) do
  #     {:ok, _pid} ->
  #       Games.add_player(table_id, username)
  #       Table.add_player(table_id, username)

  #     {:error, {:already_started, _pid}} ->
  #       Games.add_player(table_id, username)
  #       Table.add_player(table_id, username)

  #     _ -> {:error, "Server Failure"}
  #   end
  # end

  def get_table_db(table_id) do
    Repo.get(Schemas.Table, table_id)
  end
end
