defmodule CardGameBackPhoenix.Schemas.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "player" do
    belongs_to :game, CardGameBackPhoenix.Schemas.Games
    belongs_to :user, CardGameBackPhoenix.Schema.User

    field :position, :integer

    timestamps()
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:game_id, :user_id, :position])
    |> validate_required([:game_id, :user_id])
  end
end
