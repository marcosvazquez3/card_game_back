defmodule CardGameBackPhoenixWeb.TableChannel do
  use CardGameBackPhoenixWeb, :channel
  alias CardGameBackPhoenix.Game.Table
  alias CardGameBackPhoenix.Game.TableManager
  alias CardGameBackPhoenix.TableSupervisor


  # Ahora el join solo indica que te has unido a la lobby
  # Orden, os xogadores van unirse ao game cunha chamada https
  # esto vai crear o game_id porque vai generar a entrada na db
  # Despois de recibir esta reposta o front vai unirse ao channels directamente
  def join("table:" <> table_id, _payload, socket) do
    table_id = socket.assigns.table_id
    if authorized?(socket.assigns.user_id, table_id) do
      case TableManager.get_table_db(table_id) do
        nil -> {:error, :not_found}
        _game -> {:ok, assign(socket, :table_id, table_id)}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:lobby_timeout, socket) do
    push(socket, "error", %{reason: "Game expired due to inactivity"})
    {:stop, :normal, socket}
  end


  # O table_id vai vir dado, cando a primeira persoa lle de a crear game
  # que a generará unha soa persoan, xa se vai generar un uuid
  # que despois usaremos na table_id
  # O username vai vir directamente no socket vaise asignar directamente no momento do logging
  def handle_in("start_game", _payload, socket) do
    table_id = socket.assigns.table_id
    case TableManager.whereis(table_id) do
      nil ->
        TableSupervisor.new_game(table_id)
        TableManager.join_table(table_id, socket.assigns.username)
      _pid ->
        TableManager.join_table(table_id, socket.assigns.username)
    end
    broadcast!(socket, "game_started", %{})
    {:reply, :ok, socket}
    new_socket = assign(socket, :phase, :running)
    # O do mapa mólame xD
    broadcast!(socket, "game_started", %{map: "desert_map"})
    {:noreply, new_socket}
  end

  def handle_in("scout", %{"cards" => cards, "position" => pos}, socket) do
    player_name = socket.assigns.username
    table_id = socket.assigns.table_id

    case Table.scout(table_id, cards, pos, player_name) do
      :ok ->
        broadcast!(socket, "player_scouted", %{player: player_name, position: pos})
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
