defmodule CardGameBackPhoenixWeb.TableChannel do
  use CardGameBackPhoenixWeb, :channel
  alias CardGameBackPhoenix.Game.Table
  alias CardGameBackPhoenix.Game.TableManager
  alias CardGameBackPhoenix.Utils.Tables


  # Ahora el join solo indica que te has unido a la lobby
  # Orden, os xogadores van unirse ao game cunha chamada https
  # esto vai crear o game_id porque vai generar a entrada na db
  # Despois de recibir esta reposta o front vai unirse ao channels directamente
  def join("table:" <> table_id_str, _payload, socket) do
    table_id = String.to_integer(table_id_str)
    case TableManager.get_table_db(table_id) do
      nil ->
        {:error, %{reason: "table_not_found"}}
      table ->
    if authorized?(socket.assigns.user_id, table) do
      update_status_for_friends(socket, :lobby)
      send(self(), :after_join)
      {:ok, assign(socket, :table_id, table_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
    end
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = CardGameBackPhoenixWeb.Presence.track(socket, socket.assigns.user_id, %{
      user_id: socket.assigns.user_id,
      online_at: System.system_time(:second)
    })
    push(socket, "presence_state", CardGameBackPhoenixWeb.Presence.list(socket))
    {:noreply, socket}
  end

  # Aínda non sei onde o vou usar
  def handle_info(:lobby_timeout, socket) do
    push(socket, "error", %{reason: "Game expired due to inactivity"})
    {:stop, :normal, socket}
  end

  def handle_in("start_game", _payload, socket) do
    topic = socket.topic
    presences = CardGameBackPhoenixWeb.Presence.list(topic)
    player_ids =
      presences
      |> Map.keys()
      |> Enum.map(&String.to_integer/1)
    table_id = socket.assigns.table_id
    case Tables.start_game(table_id, player_ids) do
      {:ok, _pid} ->
        new_socket = assign(socket, :phase, :running)
        broadcast!(new_socket, "game_started", %{status: "running"})
        update_status_for_friends(new_socket, :in_game)
        {:noreply, new_socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("get_user_state", _payload, socket) do
    # Necesito validación para que solo o usuario poida pedir o seu estado
    table_id = socket.assigns.table_id
    player_id = socket.assigns.user_id
    clean_state = Table.get_user_state(table_id, player_id)
    {:reply, {:ok, clean_state}, socket}
  end

  def handle_in("select_orientation", %{"flipped" => should_flip}, socket) do
    table_id = socket.assigns.table_id
    user_id = socket.assigns.user_id
    if should_flip do
      Table.flip_initial_hand(table_id, user_id)
    end
    Table.player_ready(table_id, user_id)
    case Table.all_players_ready?(table_id) do
      {true, turn} -> broadcast!(socket, "orientation_fase_ended", %{turn: turn})
      {false, _turn} -> push(socket, "orientation_locked", %{success: true})
    end
    {:noreply, socket}
  end

  def handle_in("scout", %{"where" => "beginning", "hand_position" => hand_position, "flip" => true}, socket) do
    process_scout_action(:beginning, hand_position, true, socket)
  end

  def handle_in("scout", %{"where" => "end", "hand_position" => hand_position, "flip" => false}, socket) do
    process_scout_action(:end, hand_position, false, socket)
  end

  def handle_in("scout", %{"where" => invalid_edge, "hand_position" => hand_position, "flip" => invalid_flip}, socket) do
    push(socket, "action_failed", %{error: "Invalid edge side: #{invalid_edge}. Must be 'beginning' or 'end'"})
    {:noreply, socket}
  end

  def process_scout_action(where, hand_position, flip?, socket) do
    player_id = socket.assigns.user_id
    table_id = socket.assigns.table_id

    case Table.scout(table_id, player_id, where, hand_position, flip?) do
      :ok ->
        current_state = Table.get_table_state(table_id)
        broadcast!(
          socket, "player_scouted",
          %{
            player: player_id,
            cards_in_hand: length(current_state.player_list[player_id].cards),
            table_state: current_state.table_cards
          }
        )
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{message: reason}}, socket}
    end
  end

  def handle_in("show", %{"cards" => cards}, socket) do
    player_id = socket.assigns.user_id
    table_id = socket.assigns.table_id

    case Table.show(table_id, cards, player_id) do
      {:ok, state} ->
        broadcast!(socket, "player_showed", %{player: player_id})
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{message: reason}}, socket}
      {:game_over, reason, scoreboard} ->
        broadcast!(socket, "end_game", %{
          reason: to_string(reason),
          final_scores: scoreboard
        })
        {:reply, {:ok, %{status: "game_over"}}, socket}
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

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (table:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_user_id, _table_id) do
    true
  end


  # TODO está mal
  defp update_status_for_friends(socket, status) do
    user_id = socket.assigns.user_id
    friends_topic = "presence:friends:#{user_id}"
    case CardGameBackPhoenixWeb.Presence.get_by_key(friends_topic, user_id) do
      %{metas: [latest_meta | _]} ->
        friends_channel_pid = latest_meta.phx_ref_pid
        {:ok, _} = CardGameBackPhoenixWeb.Presence.update(
          friends_channel_pid,
          friends_topic,
          user_id,
          %{
            online_at: latest_meta.online_at,
            status: status
          }
        )
      [] ->
        :ok
    end
  end
end
