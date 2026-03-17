defmodule CardGameBackPhoenix.Database.Repo do
  use Ecto.Repo,
    otp_app: :card_game_back_phoenix,
    adapter: Ecto.Adapters.Postgres
end
