defmodule CardGameBackPhoenix.Repo.Migrations.Table do
  use Ecto.Migration

  def change do
    create table(:tables) do
      add :mv_dc, :string
      add :ending_date, :utc_datetime
      add :status, :string, default: "lobby", null: false
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:tables, [:owner_id])
  end
end
