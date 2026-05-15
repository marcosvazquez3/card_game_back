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


  # O table_id vai vir dado, cando a primeira persoa lle de a crear game
  # que a generará unha soa persoan, xa se vai generar un uuid
  # que despois usaremos na table_id
  # O username vai vir directamente no socket vaise asignar directamente no momento do logging
  # FALTAN VALIDACIÓNS PA CONDICIÓNS DE CARREIRA
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
        state = Table.get_table_state(table_id)
        IO.inspect(state)
        new_socket = assign(socket, :phase, :running)
        broadcast!(new_socket, "game_started", %{status: "running"})
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("scout", %{"cards" => cards, "position" => pos}, socket) do
    player_name = socket.assigns.username
    table_id = socket.assigns.table_id

    case Table.scout(table_id, cards, pos, player_name) do
      :ok ->
        current_state = Table.get_table_state(table_id)
        broadcast!(
          socket, "player_scouted",
          %{
            player: player_name,
            cards_in_hand: current_state.player_list[player_name].cards,
            table_state: current_state.table_cards
          }
        )
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{message: reason}}, socket}
    end
  end

  def handle_in("show", %{"card" => cards, "position" => pos}, socket) do
    player_name = socket.assigns.username
    table_id = socket.assigns.table_id

    case Table.show(table_id, cards, player_name) do
      :ok ->
        broadcast!(socket, "player_showed", %{player: player_name, position: pos})
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{message: reason}}, socket}
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
end
