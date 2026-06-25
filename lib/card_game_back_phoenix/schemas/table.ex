defmodule CardGameBackPhoenix.Schemas.Table do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tables" do
    timestamps()
    belongs_to :owner, CardGameBackPhoenix.Accounts.User
    field :ending_date, :utc_datetime
    field :status, Ecto.Enum, values: [:lobby, :running, :finished], default: :lobby

  end

  def changeset(table, attrs) do
    table
    |> cast(attrs, [:status, :owner_id])
    |> validate_required([:owner_id])
  end

  def status_changeset(table, attrs) do
    table
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> did_game_finish?()
  end

  defp did_game_finish?(changeset) do
    if get_change(changeset, :status) == :finished do
      put_change(changeset, :ending_date, DateTime.utc_now() |> DateTime.truncate(:second))
    else
      changeset
    end
  end

end
