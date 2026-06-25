defmodule CardGameBackPhoenixWeb.Live.UserDashboardLive do
  use CardGameBackPhoenixWeb, :live_view

  alias CardGameBackPhoenixWeb.Presence

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    presence_topic = "presence:friends:#{current_user.id}"
    dm_topic = "user:messages:#{current_user.id}"

    if connected?(socket) do
      my_presence_topic = "user:presence:#{current_user.id}"

      Presence.track(
        self(),
        my_presence_topic,
        current_user.id,
        %{user_id: current_user.id, username: current_user.user_name, status: :online, status_text: "Online"}
      )
      Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, dm_topic)
      friends_from_db = CardGameBackPhoenix.Utils.Accounts.list_friends(current_user.id)

      Enum.each(friends_from_db, fn friend ->
        Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, "user:presence:#{friend.id}")
      end)

      Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, "user:notifications:#{current_user.id}")
    end

    friends = fetch_friends_status(current_user)

    assigns = [
      current_user: current_user,
      page_state: "dashboard",
      current_table_id: nil,
      presence_topic: presence_topic,
      dm_topic: dm_topic,

      friends: friends,
      chat_messages: [],
      lobby_players: [],


      game: %{
        phase: :setup,
        table_registry: nil,
        player_count: nil,
        table_cards_count: nil,
        table_cards_owner: nil,
        table_cards: [],
        player_order: [],
        turn: nil,
        player_list: %{}
      },
      selected_cards: [],
      scoreboard: %{},
      game_over_reason: nil
    ]

    {:ok, assign(socket, assigns)}
  end

  defp fetch_friends_status(current_user) do
    friends_from_db = CardGameBackPhoenix.Utils.Accounts.list_friends(current_user.id)

    Enum.map(friends_from_db, fn friend ->
      friend_presence = Presence.list("user:presence:#{friend.id}")

      case Map.values(friend_presence) do
        [%{metas: [meta | _]}] ->
          %{
            user_id: friend.id,
            name: friend.user_name,
            status: meta[:status],
            status_text: format_status_text(meta[:status])
          }
        _ ->
          %{
            user_id: friend.id,
            name: friend.user_name,
            status: :offline,
            status_text: "Offline"
          }
      end
    end)
  end

  def handle_info({:friend_online_ping, initiator_id}, socket) do
    CardGameBackPhoenix.Utils.Accounts.accept_presence_handshake(
      socket.assigns.current_user,
      initiator_id,
      self()
    )
    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    updated_presences = Presence.list(socket.assigns.presence_topic)
    {:noreply, assign(socket, friends: fetch_friends_status(socket.assigns.current_user))}
  end

  def handle_info(%{event: "incoming_dm", payload: message}, socket) do
    updated_messages = socket.assigns.chat_messages ++ [message]
    {:noreply, assign(socket, chat_messages: updated_messages)}
  end

  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_info({:page_state, new_state}, socket) do
    {:noreply, assign(socket, page_state: new_state)}
  end

  def handle_info({:change_state, new_state}, socket) do
    {:noreply, assign(socket, page_state: new_state)}
  end

  defp format_presences(presences) do
    Enum.map(presences, fn {_user_id, %{metas: [meta | _]}} ->
      %{
        user_id: meta[:user_id],
        name: meta[:user_name],
        status: meta[:status],
        status_text: format_status_text(meta[:status])
      }
    end)
  end

  def handle_event("back_to_dashboard", _params, socket) do
    {:noreply,
     socket
     |> assign(
       page_state: "dashboard",
       current_table_id: nil,
       lobby_players: [],
       selected_cards: [],
       scoreboard: %{},
       game_over_reason: nil
     )}
  end

  def handle_event("add_friend", %{"friend_id" => typed_id}, socket) do
    current_user = socket.assigns.current_user

    case CardGameBackPhoenix.Accounts.get_user_by_id(typed_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "No user found.")}

      friend ->
        case CardGameBackPhoenix.Utils.Accounts.request_friendship(current_user, friend.id, self()) do
          {:ok, _relationship} ->
            {:noreply, put_flash(socket, :info, "Friend added successfully!")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Could not add friend.")}
        end
    end
  end

  def handle_event("send_invite", %{"friend_id" => friend_id}, socket) do
  invited_friend = Enum.find(socket.assigns.friends, fn f ->
    to_string(f.user_id) == to_string(friend_id)
  end)

  case invited_friend do
    nil ->
      {:noreply, put_flash(socket, :error, "No se encontró al amigo.")}

    friend ->
      name = friend[:name] || friend["name"] || "Jugador"
      table_id = socket.assigns.current_table_id

      new_player = %{name: name, ready: false, user_id: friend.user_id}

      updated_lobby = socket.assigns.lobby_players ++ [new_player]

      Phoenix.PubSub.broadcast(
        CardGameBackPhoenix.PubSub,
        "user:notifications:#{friend.user_id}",
        {:force_join_lobby, table_id, updated_lobby}
      )

      Phoenix.PubSub.broadcast(
        CardGameBackPhoenix.PubSub,
        "table_live:#{table_id}",
        {:lobby_updated, updated_lobby}
      )

      {:noreply,
       socket
       |> assign(lobby_players: updated_lobby, page_state: "lobby")
       |> put_flash(:info, "¡Invitación enviada!")}
  end
end


  ############################################################################
  # EVENTOS DE XOGO
  ############################################################################


  def handle_info(:intent_start_game, socket) do
    table_id = socket.assigns.current_table_id
    lobby_players = socket.assigns.lobby_players

    player_ids = Enum.map(socket.assigns.lobby_players, fn p -> p.user_id end)

    case CardGameBackPhoenix.Utils.Tables.start_game(socket.assigns.current_table_id, player_ids) do
      {:ok, _pid} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{table_id}",
          :game_started
        )
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo iniciar: #{inspect(reason)}")}
    end
  end

  def handle_info(:game_started, socket) do
    table_id = socket.assigns.current_table_id
    current_user_id = socket.assigns.current_user.id
    lobby_players = socket.assigns.lobby_players
    state = CardGameBackPhoenix.Game.Table.get_table_state(table_id)
    player = get_in(state.player_list, [current_user_id])
    my_hand = if player, do: player.cards, else: []

    opponents = build_opponents_list(state.player_list, current_user_id, lobby_players)

    {:noreply,
    socket
    |> assign(
      page_state: "pre_game",
      active_show: state.table_cards || [],
      game: state,
      opponents: opponents,
      turn: state.turn,
      selected_cards: []
    )
    |> put_flash(:info, "¡Reparto hecho! Revisa tu mano y marca que estás listo.")}
  end

  defp build_opponents_list(player_list, current_user_id, lobby_players) do
    player_list
    |> Map.drop([current_user_id])
    |> Enum.map(fn {id, player} ->
      lobby_info = Enum.find(lobby_players, fn lp -> lp.user_id == id end)

      display_name = if lobby_info, do: lobby_info.name, else: "Jugador #{id}"

      %{
        id: id,
        name: display_name,
        card_count: length(player.cards)
      }
    end)
  end

  defp build_opponents_list(table_state, current_user_id) do
    table_state.player_list
    |> Map.drop([current_user_id]) # Quitamos al propio usuario
    |> Enum.map(fn {_id, player} ->
      %{name: player.name, card_count: length(player.cards)}
    end)
  end

  def handle_info({:play_action_show, cards}, socket) do
    table_id = socket.assigns.current_table_id
    player_id = socket.assigns.current_user.id
    case CardGameBackPhoenix.Game.Table.show(table_id, cards, player_id) do
      {:ok, state} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{table_id}",
          {:game_updated, state}
        )
        {:noreply, put_flash(socket, :info, "¡Has jugado tu Show!")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Jugada inválida: #{reason}")}

      {:game_over, reason, scoreboard} ->
        {:noreply, broadcast_game_over(socket, reason, scoreboard)}
    end
  end

  def handle_info({:play_action_scout, where, hand_position, flip?}, socket) do
    table_id = socket.assigns.current_table_id
    player_id = socket.assigns.current_user.id

    case CardGameBackPhoenix.Game.Table.scout(table_id, player_id, where, hand_position, flip?) do
      {:ok, new_state} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{table_id}",
          {:game_updated, new_state}
        )
        {:noreply, put_flash(socket, :info, "¡Carta scouteada con éxito!")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "No puedes hacer Scout: #{reason}")}

      {:game_over, reason, scoreboard} ->
        {:noreply, broadcast_game_over(socket, reason, scoreboard)}
    end
  end

  def handle_info({:play_action_scout_for_show, where, hand_position, flip?}, socket) do
    table_id = socket.assigns.current_table_id
    player_id = socket.assigns.current_user.id

    case CardGameBackPhoenix.Game.Table.scout_for_show(table_id, player_id, where, hand_position, flip?) do
      {:ok, new_state} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{table_id}",
          {:game_updated, new_state}
        )
        {:noreply, put_flash(socket, :info, "¡Carta tomada! Ahora selecciona cartas y haz Show.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo hacer el Scout: #{reason}")}
    end
  end

  def handle_info({:game_finished, reason, scoreboard}, socket) do
    current_user_id = socket.assigns.current_user.id
    lobby_players = socket.assigns.lobby_players
    named_scoreboard =
      Enum.map(scoreboard, fn {player_id, score} ->
        lobby_info = Enum.find(lobby_players, fn lp -> lp.user_id == player_id end)
        name = if lobby_info, do: lobby_info.name, else: "Jugador #{player_id}"
        is_me = player_id == current_user_id
        %{player_id: player_id, name: name, score: score, is_me: is_me}
      end)
      |> Enum.sort_by(& &1.score, :desc)

    {:noreply,
     socket
     |> assign(
       page_state: "game_over",
       scoreboard: named_scoreboard,
       game_over_reason: reason
     )}
  end

  def handle_info(:player_quit_game, socket) do
    {:noreply,
    socket
    |> assign(
      page_state: "dashboard",
      current_table_id: nil,
      selected_cards: [],
      active_show: []
    )
    |> put_flash(:info, "Has abandonado la partida.")}
  end


  def handle_info({:game_updated, genserver_state}, socket) do
    current_user_id = socket.assigns.current_user.id
    lobby_players = socket.assigns.lobby_players
    updated_opponents = build_opponents_list(genserver_state.player_list, current_user_id, lobby_players)
    {:noreply,
    socket
    |> assign(game: genserver_state)
    |> assign(opponents: updated_opponents)}
  end

  def handle_info(:player_mark_ready, socket) do
    table_id = socket.assigns.current_table_id
    user_id = socket.assigns.current_user.id

    case CardGameBackPhoenix.Game.Table.player_ready(table_id, user_id) do
      {:ok, :all_ready} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{table_id}",
          :all_players_ready
        )
        {:noreply, socket}

      {:ok, :player_marked_ready} ->
        new_state = CardGameBackPhoenix.Game.Table.get_table_state(table_id)
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{table_id}",
          {:game_updated, new_state}
        )
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo marcar como listo: #{reason}")}
    end
  end

  def handle_info(:all_players_ready, socket) do
    table_id = socket.assigns.current_table_id
    current_user_id = socket.assigns.current_user.id

    state = CardGameBackPhoenix.Game.Table.get_table_state(table_id)
    opponents = build_opponents_list(state.player_list, current_user_id, socket.assigns.lobby_players)

    {:noreply,
    socket
    |> assign(
      page_state: "game",
      game: state,
      opponents: opponents,
      turn: state.turn,
      selected_cards: []
    )
    |> put_flash(:info, "¡Todos listos! Empieza la partida.")}
  end

  def handle_info({:flip_initial_hand}, socket) do
    game_id = socket.assigns.current_table_id
    user_id = socket.assigns.current_user.id
    case CardGameBackPhoenix.Game.Table.flip_initial_hand(game_id, user_id) do
      {:ok, updated_state} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{game_id}",
          {:game_updated, updated_state}
        )
        {:noreply, socket}

      {:error, :partida_corrupta} ->
        Phoenix.PubSub.broadcast(
          CardGameBackPhoenix.PubSub,
          "table_live:#{game_id}",
          :game_aborted
        )
        {:noreply, socket}
    end
  end


  ############################################################################
  ############################################################################


  def handle_info(:intent_create_game, socket) do
    current_user = socket.assigns.current_user

    attrs = %{owner_id: current_user.id, status: :lobby}

    case CardGameBackPhoenix.Utils.Tables.create_game(attrs) do
      {:ok, table} ->
        initial_lobby = [%{name: current_user.user_name, ready: true, user_id: current_user.id}]

        if connected?(socket) do
          Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, "table_live:#{table.id}")
        end

        {:noreply,
        socket
        |> assign(
          page_state: "lobby",
          lobby_players: initial_lobby,
          current_table_id: table.id
        )
        |> put_flash(:info, "¡Mesa ##{table.id} creada en Base de Datos!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "No se pudo registrar la mesa en la base de datos.")}
    end
  end

  def handle_event("join_table", %{"table_id" => table_id_str}, socket) do
    table_id = String.to_integer(table_id_str)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, "table_live:#{table_id}")
    end

    {:noreply,
    socket
    |> assign(
      page_state: "lobby",
      current_table_id: table_id
    )}
  end

  def handle_info({:force_join_lobby, table_id, updated_lobby}, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CardGameBackPhoenix.PubSub, "table_live:#{table_id}")
    end

    {:noreply,
    socket
    |> assign(
      page_state: "lobby",
      current_table_id: table_id,
      lobby_players: updated_lobby
    )
    |> put_flash(:info, "¡Te han arrastrado a la partida ##{table_id}!")}
  end

  def handle_info({:lobby_updated, updated_lobby}, socket) do
    {:noreply, assign(socket, lobby_players: updated_lobby)}
  end

  def handle_info({:friend_handshake, initiator_id}, socket) do
    CardGameBackPhoenix.Utils.Accounts.accept_presence_handshake(socket.assigns.current_user, initiator_id, self())
    {:noreply, socket}
  end

  defp broadcast_game_over(socket, reason, scoreboard) do
    table_id = socket.assigns.current_table_id

    Phoenix.PubSub.broadcast(
      CardGameBackPhoenix.PubSub,
      "table_live:#{table_id}",
      {:game_finished, reason, scoreboard}
    )

    socket
  end

  defp format_status_text(:online), do: "Online"
  defp format_status_text(:ingame), do: "In Match"
  defp format_status_text(:inlobby), do: "In Lobby"
  defp format_status_text(_), do: "Available"

  def render(assigns) do
    ~H"""
    <div style="display: flex; height: 100vh; font-family: sans-serif;">
      <main style="flex: 1; display: flex; flex-direction: column; padding: 40px;">
        <%= if @page_state == "dashboard" do %>
          <.live_component module={CardGameBackPhoenixWeb.Live.UserDashboard.DashboardComponent} id="dashboard" page_state={@page_state} current_user={@current_user} />
        <% end %>

        <%= if @page_state == "lobby" do %>
          <.live_component module={CardGameBackPhoenixWeb.Live.UserDashboard.LobbyComponent} id="lobby"
          page_state={@page_state}
          current_table_id={@current_table_id}
          lobby_players={@lobby_players} />
        <% end %>

        <%= if @page_state == "game_over" do %>
          <% winner = List.first(@scoreboard) %>
          <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; gap: 24px;">

            <div style="text-align: center;">
              <div style="font-size: 56px; margin-bottom: 8px;">🏆</div>
              <h1 style="margin: 0; font-size: 32px;">¡Partida finalizada!</h1>
              <p style="color: #64748b; margin-top: 8px;">
                <%= case @game_over_reason do
                  :empty_hand -> "Un jugador ha vaciado su mano"
                  :unbeatable_table -> "La mesa era imbatible"
                  _ -> "Fin de ronda"
                end %>
              </p>
            </div>

            <%= if winner do %>
              <div style="background: linear-gradient(135deg, #fef9c3, #fde68a); border: 2px solid #f59e0b; border-radius: 12px; padding: 16px 32px; text-align: center;">
                <span style="font-size: 14px; color: #92400e; font-weight: bold; text-transform: uppercase; letter-spacing: 0.05em;">Ganador</span>
                <div style="font-size: 28px; font-weight: bold; color: #78350f; margin-top: 4px;">
                  <%= if winner.is_me, do: "¡Tú! (#{winner.name})", else: winner.name %>
                </div>
                <div style="font-size: 20px; color: #92400e; margin-top: 2px;"><%= winner.score %> puntos</div>
              </div>
            <% end %>

            <div style="width: 100%; max-width: 480px;">
              <h3 style="text-align: center; color: #475569; margin-bottom: 12px;">Clasificación final</h3>
              <div style="display: flex; flex-direction: column; gap: 8px;">
                <%= for {entry, pos} <- Enum.with_index(@scoreboard, 1) do %>
                  <div style={"display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; border-radius: 8px; border: 1px solid #{if entry.is_me, do: "#bfdbfe", else: "#e2e8f0"}; background-color: #{if entry.is_me, do: "#eff6ff", else: "white"};"}>
                    <div style="display: flex; align-items: center; gap: 12px;">
                      <span style={"font-size: 20px; font-weight: bold; color: #{case pos do 1 -> "#f59e0b"; 2 -> "#94a3b8"; 3 -> "#b45309"; _ -> "#cbd5e1" end};"}>
                        <%= case pos do 1 -> "🥇"; 2 -> "🥈"; 3 -> "🥉"; _ -> "#{pos}." end %>
                      </span>
                      <span style="font-weight: bold; color: #1e293b;">
                        <%= entry.name %><%= if entry.is_me, do: " (tú)" %>
                      </span>
                    </div>
                    <span style="font-size: 20px; font-weight: bold; color: #0f172a;"><%= entry.score %> pts</span>
                  </div>
                <% end %>
              </div>
            </div>

            <button phx-click="back_to_dashboard" style="background-color: #4f46e5; color: white; padding: 14px 40px; font-size: 16px; font-weight: bold; border: none; border-radius: 8px; cursor: pointer; margin-top: 8px;">
              Volver al inicio
            </button>
          </div>
        <% end %>

        <%= if @page_state in ["pre_game", "game"] do %>
          <.live_component module={CardGameBackPhoenixWeb.Live.UserDashboard.GameComponent} id="game" page_state={@page_state}
          game={@game}
          opponents={@opponents}
          selected_cards={@selected_cards}
          current_user={@current_user}/>
        <% end %>
      </main>

      <aside style="width: 300px; border-left: 1px solid #eee; padding: 20px; box-sizing: border-box; display: flex; flex-direction: column; height: 100vh;">

        <div style="flex: 1; overflow-y: auto; margin-bottom: 20px; padding-right: 4px;">
          <h2 style="margin-top: 0; color: #ffffff;">Friends</h2>

          <%= if flash = Phoenix.Flash.get(@flash, :info) do %>
            <p style="background: #def7ec; color: #03543f; padding: 8px; border-radius: 4px; font-size: 0.85em; margin-bottom: 12px;">
              <%= flash %>
            </p>
          <% end %>
          <%= if error = Phoenix.Flash.get(@flash, :error) do %>
            <p style="background: #fde8e8; color: #9b1c1c; padding: 8px; border-radius: 4px; font-size: 0.85em; margin-bottom: 12px; border-left: 4px solid #e11d48;">
              <%= error %>
            </p>
          <% end %>

          <ul style="list-style-type: none; padding: 0; margin: 0;">
            <%= for friend <- @friends do %>
              <li style="margin-bottom: 12px; padding-bottom: 12px; border-bottom: 1px solid #ffffff;">
                <div>
                  <strong style="color: #DAC5E3;"><%= friend.name %></strong> <br />
                  <span style={
                    cond do
                      friend.status == :online -> "color: green;"
                      friend.status == :inlobby -> "color: blue;"
                      friend.status == :ingame -> "color: blue;"
                      true -> "color: gray;"
                    end
                  }>
                    <%= friend.status_text %>
                  </span>
                </div>
                <%= if @page_state == "lobby" && friend.status == :online do %>
                  <button
                    phx-click="send_invite"
                    phx-value-friend_id={friend.user_id}
                    style="background-color: #3b82f6; color: white; padding: 6px 12px; border: none; border-radius: 4px; cursor: pointer; font-weight: bold; font-size: 14px;">
                    Invite
                  </button>
                <% end %>
              </li>
            <% end %>
          </ul>
        </div>

        <div style="flex-shrink: 0; padding-top: 10px;">

          <h3 style="margin-top: 0; margin-bottom: 8px; font-size: 1.1em; color: #ffffff;">Add Friend</h3>
          <form phx-submit="add_friend" style="margin-bottom: 16px;">
            <input
              type="text"
              name="friend_id"
              placeholder="Enter Friend ID..."
              style="display: block; width: 100%; box-sizing: border-box; padding: 10px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 0.9em; outline: none; margin-bottom: 8px;"
              required
            />
            <button
              type="submit"
              style="display: block; width: 100%; padding: 10px; background: #4F46E5; color: white; border: none; border-radius: 4px; font-size: 0.9em; cursor: pointer; font-weight: bold;"
            >
              Send Request
            </button>
          </form>

          <div style="background: #ffffff; padding: 12px; border-radius: 6px; text-align: center; border: 1px solid #eee;">
            <span style="font-size: 0.75em; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em; display: block; margin-bottom: 2px; font-weight: 600;">
              Your Share ID
            </span>
            <strong style="display: block; font-size: 1.25em; color: #1f2937; font-family: monospace;">
              <%= @current_user.id %>
            </strong>
          </div>
        </div>

      </aside>
    </div>
    """
  end
end
