defmodule CardGameBackPhoenix.Repo.Migrations.Player do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :game_id, references(:tables, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :position, :integer
      timestamps(type: :utc_datetime)
    end
    create index(:players, [:game_id])
    create index(:players, [:user_id])
    create unique_index(:players, [:game_id, :user_id])
  end
end
