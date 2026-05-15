defmodule CardGameBackPhoenix.Utils.Accounts do
  alias CardGameBackPhoenix.Accounts.User
  alias CardGameBackPhoenix.Repo
  import Ecto.Query

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def list_relationships_by_status(user, status) do
    query = from(r in CardGameBackPhoenix.Schemas.UserRelationship, where: r.status == ^status)
    user
    |> Repo.preload([
      friends_as_user1: query,
      friends_as_user2: query
    ])
  end
end
