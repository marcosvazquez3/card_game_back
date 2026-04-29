defmodule CardGameBackPhoenixWeb.MineUserSocket do
  use Phoenix.Socket

  # Route "room:*" topics to the RoomChannel module
  # The "*" is a wildcard - room:lobby, room:123, room:anything all match
  channel "table:*", RealtimeChatWeb.RoomChannel
  # This is the channel for the user to user communication
  channel "user:*", RealtimeChatWeb.UserChannel

  # Socket params come from the client connection
  # Use this to authenticate and identify the user
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, user_id} ->
        # Assign user_id to socket - available in all channels
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  # Each socket connection needs a unique identifier
  # Used for targeting specific users with messages
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"

  defp verify_token(token) do
    # Verify JWT or Phoenix.Token
    Phoenix.Token.verify(
      RealtimeChatWeb.Endpoint,
      "user auth",
      token,
      max_age: 86400
    )
  end
end
