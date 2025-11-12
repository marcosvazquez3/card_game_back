defmodule Utils.Api.ShowValidations do
  use Ecto.Schema
  import Ecto.Changeset
  alias Utils.Api.CardValidations

  @primary_key false
  embedded_schema do
    embeds_many(:cards, CardValidations)
    field(:name, :string)
  end

  def changeset(petition, attrs) do
    petition
    |> cast(attrs, [:name])
    |> validate_required([:cards, :name])
    |> validate_length(:cards, min: 1)
  end
end
