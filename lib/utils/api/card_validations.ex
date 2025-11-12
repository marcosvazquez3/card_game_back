defmodule Utils.Api.CardValidations do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:top, :integer)
    field(:bottom, :integer)
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [:top, :bottom])
    |> validate_required([:top, :bottom])
  end
end
