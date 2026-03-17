defmodule CardGameBackPhoenix.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:user_name, :email, :creation_date]}
  schema "user" do
    field :user_name, :string
    field :password_hash, :string
    field :email, :string
    field :creation_date, :utc_datetime
    has_many :relations_as_user1, CardGameBackPhoenix.Schemas.UserToUserStatus, foreign_key: :user1_id
    has_many :relations_as_user2, CardGameBackPhoenix.Schemas.UserToUserStatus, foreign_key: :user2_id
  end


  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_name, :password_hash, :email])
    |> validate_required([:user_name, :password_hash, :email])
    |> validate_length(:user_name, min: 3)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
