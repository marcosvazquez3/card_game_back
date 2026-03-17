defmodule CardGameBackPhoenix.Utils.Games do
  alias CardGameBackPhoenix.Schemas.Game
  alias CardGameBackPhoenix.Database.Repo

  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end
end
