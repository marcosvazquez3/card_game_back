defmodule CardGameBackPhoenix.Utils.Accounts do
  alias CardGameBackPhoenix.Schemas.User
  alias CardGameBackPhoenix.Database.Repo

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
