defmodule CardGameBackPhoenix.Schemas.Game do
  use Ecto.Schema

  schema "game" do
    field :mv_dc, :string
    field :creation_date, :utc_datetime
    field :ending_date, :utc_datetime
    field :status, Ecto.Enum, values: [:lobby, :ready, :running, :finished], default: :lobby
  end

  def changeset(game, attrs) do
    game
    |> Ecto.Changeset.cast(attrs, [:mv_dc, :creation_date, :ending_date])
  end

end
