defmodule CardGameBackPhoenix.Schemas.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "player" do
    belongs_to :game, CardGameBackPhoenix.Schemas.Table
    belongs_to :user, CardGameBackPhoenix.Accounts.User
    field :position, :integer

    timestamps()
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:game_id, :user_id])
    |> validate_required([:game_id, :user_id])
    |> unique_constraint([:user_id, :game_id], name: :players_user_id_game_id_index)
  end
end
