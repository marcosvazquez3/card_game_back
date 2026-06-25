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

  def get_table_db(table_id) do
    Repo.get(Schemas.Table, table_id)
  end
end
