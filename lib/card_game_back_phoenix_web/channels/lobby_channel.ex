defmodule CardGameBackPhoenixWeb.LobbyChannel do
  use CardGameBackPhoenixWeb, :channel

  # Called when a client joins the channel
  # The first argument is the topic they're joining
  # The second is any params sent with the join request
  # The third is the socket struct containing connection state
  @impl true
  def join("room:lobby:" <> room_id, _payload, socket) do
    # Allow anyone to join the lobby
    {:ok, socket}
  end

  def join("room:" <> room_id, payload, socket) do
    # For private rooms, verify the user has access
    if authorized?(socket.assigns.user_id, room_id) do
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Handle incoming messages from clients
  # "new_msg" is the event name, payload is the data sent
  @impl true
  def handle_in("new_msg", %{"body" => body}, socket) do
    # Broadcast to all subscribers of this topic, including sender
    broadcast!(socket, "new_msg", %{
      body: body,
      user_id: socket.assigns.user_id,
      timestamp: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  # Handle typing indicators - broadcast to others but not the sender
  def handle_in("typing", _payload, socket) do
    broadcast_from!(socket, "typing", %{
      user_id: socket.assigns.user_id
    })

    {:noreply, socket}
  end

  # Reply directly to the client with acknowledgment
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  defp authorized?(user_id, room_id) do
    # Add your authorization logic here
    # Check database, cache, or external service
    true
  end
end
