defmodule FriendsController do
  use CardGameBackPhoenixWeb, :controller
  alias CardGameBackPhoenix.Utils.Accounts
  def add_friend(conn, %{"friend_id" => friend_id_str}) do
    current_user = conn.assigns.current_user
    friend_id = String.to_integer(friend_id_str)
    if current_user.id == friend_id do
      conn
      |> put_flash(:error, "You cannot add yourself as a friend.")
    else
      case Accounts.add_friend(current_user.id, friend_id) do
        {:ok, _relationship} ->
          conn
          |> put_flash(:info, "Friend request sent successfully!")
          |> redirect(to: ~p"/users/settings")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Unable to send friend request. You might already be friends.")
          |> redirect(to: ~p"/users/settings")
      end
    end
  end

end
