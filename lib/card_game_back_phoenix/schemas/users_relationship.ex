defmodule CardGameBackPhoenix.Schemas.UserRelationship do
  use Ecto.Schema

  schema "users_relationship" do
    belongs_to :user1, CardGameBackPhoenix.Schema.User, foreign_key: :user1_id
    belongs_to :user2, CardGameBackPhoenix.Schema.User, foreign_key: :user2_id
    field :status, Ecto.Enum, values: [:friends, :blocked]
    field :inserted_at, :utc_datetime
  end

end
