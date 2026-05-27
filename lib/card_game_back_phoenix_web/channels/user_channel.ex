defmodule CardGameBackPhoenixWeb.UserChannel do
  use CardGameBackPhoenixWeb, :channel
  alias CardGameBackPhoenixWeb.Presence

  def join("user:" <> user_id_str, _payload, socket) do
    user_id = String.to_integer(user_id_str)
    if user_id == socket.assigns.user_id do
      friends = CardGameBackPhoenix.Utils.Accounts.list_relationships_by_status(user_id, "friends")
      Enum.each(friends, fn friend ->
        Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, "presence:friends:#{friend.id}")
      end)
      send(self(), :after_join)
      current_online_friends =
        Enum.map(friends, fn friend ->
          get_online_status(friend)
        end)
      {:ok, %{online_friends: current_online_friends}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    user_id = socket.assigns.user_id
    {:ok, _} = Presence.track(self(), "presence:friends:#{user_id}", user_id, %{
      online_at: System.system_time(:second),
      status: :online
    })
    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_state", payload: diff}, socket) do
    push(socket, "friends_presence_state", diff)
    {:noreply, socket}
  end

  defp get_online_status(friend) do

    topic = "presence:friends:#{friend.id}"
    status = case Presence.list(topic) do
      map when map == %{} -> :offline
      meta_map ->
        {_user_id, %{metas: [latest | _]}} = Enum.at(meta_map, 0)
        latest.status
    end
    %{user_id: friend.id, user_name: friend.user_name, status: status}
  end

end
