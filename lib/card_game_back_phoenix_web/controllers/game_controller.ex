defmodule CardGameBackPhoenixWeb.GameController do
  use CardGameBackPhoenixWeb, :controller
  alias CardGameBackPhoenix.Utils
  alias CardGameBackPhoenix.TableSupervisor


  def create_game(conn) do
    user = conn.assigns.current_user
    attrs = %{
      status: :lobby,
      owner_id: user
    }
    case Utils.Tables.create_game(attrs) do
      {:ok, game} ->
        TableSupervisor.new_game(game.id)
        send_resp(conn, 200, Jason.encode!(%{table_id: game.id, status: CardGameBackPhoenix.Game.status, players: [""]}))

      {:error, changeset} ->
        errors = Utils.ErrorHelper.errors_to_map(changeset)
        send_resp(conn, 422, Jason.encode!(%{errors: errors}))
    end
  end
end
