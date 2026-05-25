defmodule CardGameBackPhoenix.Utils.Accounts do
  alias CardGameBackPhoenix.Accounts.User
  alias CardGameBackPhoenix.Repo
  alias CardGameBackPhoenix.Schemas.UsersRelationships
  import Ecto.Query

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def list_relationships_by_status(user_id, status) do
    query =
      from(r in UsersRelationships,
        where: r.status == ^status and (r.user1_id == ^user_id or r.user2_id == ^user_id),
        preload: [:user1, :user2]
      )

    Repo.all(query)
      |> Enum.map(fn r ->
        if r.user1_id == user_id, do: r.user2, else: r.user1
      end)
      |> Enum.uniq_by(& &1.id)
  end

  def add_friend(sender_id, receiver_id) do
    add_relationship(sender_id, receiver_id, :friends)
  end

  def block_user(sender_id, receiver_id) do
    add_relationship(sender_id, receiver_id, :blocked)
  end

  defp add_relationship(sender_id, receiver_id, status) do
    %UsersRelationships{}
      |> UsersRelationships.changeset(%{
        user1_id: sender_id,
        user2_id: receiver_id,
        status: status
      })
      |> Repo.insert!(
        on_conflict: {:replace, [:status]},
        conflict_target: [:user1_id, :user2_id]
      )
  end

  def dump_table(schema) do
    IO.puts("\n--- DUMPING MULTIPLE ROWS FOR #{schema} ---")

    schema
    |> Repo.all()
    |> IO.inspect(label: "Current Database State")

    IO.puts("--------------------------------------------\n")
  end

end
