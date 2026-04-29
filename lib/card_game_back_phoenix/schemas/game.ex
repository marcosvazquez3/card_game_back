defmodule CardGameBackPhoenix.Schemas.Game do
  use Ecto.Schema

  schema "game" do
    field :mv_dc, :string #mv_dc means movement document
    timestamps()
    field :ending_date, :utc_datetime
    field :status, Ecto.Enum, values: [:lobby, :running, :finished], default: :lobby
    belongs_to :owner_id, CardGameBackPhoenix.Schema.User
  end

  def changeset(game, attrs) do
    game
    |> Ecto.Changeset.cast(attrs, [:owner_id])
  end

end
