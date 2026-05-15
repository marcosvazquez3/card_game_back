defmodule CardGameBackPhoenix.Repo.Migrations.UsersRelationships do
  use Ecto.Migration

  def change do
    create table(:users_relationships) do
      add :user1_id, references(:users, on_delete: :delete_all), null: false
      add :user2_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:users_relationships, [:user1_id])
    create index(:users_relationships, [:user2_id])
    create unique_index(:users_relationships, [:user1_id, :user2_id])

    create constraint(
      :users_relationships,
      :ids_are_ordered,
      check: "user1_id < user2_id"
    )
  end
end
