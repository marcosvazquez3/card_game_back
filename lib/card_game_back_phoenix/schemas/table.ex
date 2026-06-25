defmodule CardGameBackPhoenix.Schemas.Table do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tables" do
    timestamps()
    belongs_to :owner, CardGameBackPhoenix.Accounts.User
    field :started_at, :naive_datetime
    field :ended_at, :naive_datetime
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
    case get_change(changeset, :status) do
      :running -> put_change(changeset, :started_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      :finished -> put_change(changeset, :ended_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      _ -> changeset
    end
  end

end
