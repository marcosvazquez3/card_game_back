defmodule CardGameBackPhoenix.Utils.Tables do
  alias CardGameBackPhoenix.Schemas
  alias CardGameBackPhoenix.Repo
  alias CardGameBackPhoenix.TableSupervisor
  alias Ecto.Multi
  alias CardGameBackPhoenix.Game
  @registry Registry.Table

  def create_game(attrs) do
    %Schemas.Table{}
    |> Schemas.Table.changeset(attrs)
    |> Repo.insert()
  end

  def update_game(%Schemas.Table{} = game, attrs) do
    game
    |> Schemas.Table.changeset(attrs)
    |> Repo.update()
  end

  def update_table_status(table_id, new_status) do
    # NON ME GUSTA NADA
    table = Repo.get!(Schemas.Table, table_id)
    table
    |> Schemas.Table.status_changeset(%{status: new_status})
    |> Repo.update()
  end

  def start_game(table_id, player_ids) do
    case create_game_db(table_id, player_ids) do
      {:ok, _result} ->
        {:ok, game_pid} = TableSupervisor.new_game(table_id)
        Enum.each(player_ids, fn player_id ->
          Game.Table.add_player(table_id, player_id)
        end)
        Game.Table.start_game(table_id)
        {:ok, game_pid}
      {:error, _step, _reason, _changes} ->
        {:error, %{message: "Failed to initialize game"}}
    end
  end

  def create_game_db(table_id, player_ids) do
    multi = Multi.new()
    |> Multi.update(:update_status, Schemas.Table.status_changeset(table, %{status: :running}))
    |> Multi.run(:add_players, fn repo, %{update_status: updated_table} ->
      add_players(repo, updated_table.id, player_ids)
    end)

    case Repo.transaction(multi) do
      {:ok, _result} ->
        {:ok, "Partida iniciada"}

      {:error, step, reason, _changes} ->
        {:error, {step, reason}}
    end
  end

  defp add_players(repo, table_id, player_ids) do
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    entries = Enum.map(player_ids, fn player_id ->
      %{
        game_id: table_id,
        user_id: player_id,
        inserted_at: timestamp,
        updated_at: timestamp
      }
    end)
    case repo.insert_all("players", entries) do
      {count, _} when count > 0 -> {:ok, count}
      _ -> {:error, "No players were added"}
    end
  end

  def join_running_game() do
  end
end
