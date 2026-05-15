defmodule CardGameBackPhoenix.Schemas.UsersRelationships do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_relationships" do
    belongs_to :user1, CardGameBackPhoenix.Accounts.User, foreign_key: :user1_id
    belongs_to :user2, CardGameBackPhoenix.Accounts.User, foreign_key: :user2_id
    field :status, Ecto.Enum, values: [:friends, :blocked]
    timestamps(type: :utc_datetime)
  end

  def changeset(relationship, attrs) do
    attrs = sort_ids(attrs)
    relationship
    |> cast(attrs, [:user1_id, :user2_id, :status])
    |> validate_required([:user1_id, :user2_id, :status])
    |> validate_not_self_friending()
    |> unique_constraint([:user1_id, :user2_id], name: :users_relationship_index)
  end

  # Permite ordenar os ids, o id con menor tamaño irá sempre de primeiro
  defp sort_ids(%{user1_id: u1, user2_id: u2} = attrs) do
    [id1, id2] = Enum.sort([u1, u2])
    %{attrs | user1_id: id1, user2_id: id2}
  end

  defp validate_not_self_friending(changeset) do
    u1 = get_field(changeset, :user1_id)
    u2 = get_field(changeset, :user2_id)

    if u1 && u1 == u2 do
      add_error(changeset, :user2_id, "cannot create a relationship with yourself")
    else
      changeset
    end
  end

end
