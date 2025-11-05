defmodule RouterManager do

  use Ecto.Schema
  import Ecto.Changeset

  schema "show" do
    field :cards, {:array, :map} # They need to be validated one by one
    field :player_id, :integer
  end

  defp validate_cards(changeset) do
    field = :cards
    cards = get_field(changeset, field, [])

    cond do
      not is_list(cards) ->
        add_error(changeset, field, "must be a list")

      Enum.any?(cards, fn
        {a, b} when is_integer(a) and is_integer(b) -> false
        %{"a" => a, "b" => b} when is_integer(a) and is_integer(b) -> false
        _ -> true
      end) ->
        add_error(changeset, field, "each card must be a pair of integers")

      true ->
        changeset
    end
  end


  # TODO pensar se esto é necesario aquí
  # defp validate_player_id_exists(changeset) do
  #   field = :player_id
  #   player_id = get_field(changeset, field, [])
  # end

  def show_changeset(show_body_params, attrs) do
    show_body_params
    |> cast(attrs, [:cards, :player_id])
    |> validate_required([:cards, :player_id])
    |> validate_cards()
  end
end
