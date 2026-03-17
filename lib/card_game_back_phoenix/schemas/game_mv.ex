defmodule CardGameBackPhoenix.Schemas.Game_mv do
  use Ecto.Schema

  schema "game_mv" do
    field :game_id, :string
    field :player_id, :utc_datetime
    field :move, :utc_datetime
    field :card, :map
    field :inserted_at, :utc_datetime
  end

end
