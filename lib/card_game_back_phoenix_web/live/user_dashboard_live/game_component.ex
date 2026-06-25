defmodule CardGameBackPhoenixWeb.Live.UserDashboard.GameComponent do
  use CardGameBackPhoenixWeb, :live_component
  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:scout_target, fn -> nil end)
      |> assign_new(:scout_mode, fn -> :scout end)
      |> assign_new(:scout_flip, fn -> false end)
      |> assign_new(:scout_hand_position, fn -> 0 end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id={@id}>

        <div :if={@page_state == "pre_game"} style="display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100%; gap: 22px;">
          <% me = @game.player_list[@current_user.id] %>
          <% ready_count = Enum.count(@game.player_list, fn {_id, p} -> p.ready end) %>
          <% total = map_size(@game.player_list) %>

          <div style="text-align: center;">
            <h2 style="margin: 0;">Preparación de la partida</h2>
            <p style="color: #64748b; max-width: 480px;">
              Revisa tu mano inicial. Puedes girarla antes de empezar. Cuando estés conforme, marca <strong>Estoy Listo</strong>.
            </p>
          </div>

          <div style="background-color: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 8px; padding: 8px 16px; font-weight: bold; color: #334155;">
            Jugadores listos: <%= ready_count %> / <%= total %>
          </div>

          <div style="display: flex; justify-content: center; align-items: flex-end; gap: 10px; min-height: 110px;">
            <%= for card <- me.cards do %>
              <div style="width: 55px; height: 85px; background-color: #3b82f6; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 18px; font-weight: bold; border-radius: 6px; box-shadow: 0 2px 4px rgba(0,0,0,0.15);">
                <div><%= elem(card, 0) %></div>
                <div style="border-top: 1px solid rgba(255,255,255,0.3); width: 70%; margin: 2px 0;"></div>
                <div><%= elem(card, 1) %></div>
              </div>
            <% end %>
          </div>

          <%= if me.ready do %>
            <div style="background-color: #dcfce7; color: #166534; border: 2px solid #22c55e; padding: 12px 24px; border-radius: 8px; font-weight: bold;">
              ✓ Estás listo. Esperando a los demás jugadores...
            </div>
          <% else %>
            <div style="display: flex; gap: 15px;">
              <button phx-click="flip_hand" phx-target={@myself} style="background-color: #10b981; color: white; padding: 12px 24px; font-size: 16px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                Girar Mano 🔄
              </button>
              <button phx-click="mark_ready" phx-target={@myself} style="background-color: #2563eb; color: white; padding: 12px 30px; font-size: 16px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                Estoy Listo ✓
              </button>
            </div>
          <% end %>
        </div>

        <div :if={@page_state == "game"} style="display: flex; flex-direction: column; justify-content: space-between; height: 100%;">

          <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #333; padding-bottom: 10px;">
            <div>
              <h2 style="margin: 0;">Scout Arena</h2>
              <span style="color: #666; font-size: 14px;">Match Active</span>
            </div>
          </div>

          <div style="margin-top: 15px; display: flex; justify-content: center; width: 100%;">
            <%= if to_string(@game.turn) == to_string(@current_user.id) do %>
              <div style="background-color: #dcfce7; color: #166534; border: 2px solid #22c55e; padding: 10px 20px; border-radius: 8px; font-weight: bold; font-size: 16px; display: flex; align-items: center; gap: 8px; box-shadow: 0 4px 6px rgba(34,197,94,0.15);">
                🟢 ¡Es tu turno! Juega un Show o haz Scout
              </div>
            <% else %>
              <% rival_en_turno = Enum.find(@opponents, fn o -> to_string(o.id) == to_string(@game.turn) end) %>
              <div style="background-color: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; padding: 10px 20px; border-radius: 8px; font-size: 16px; display: flex; align-items: center; gap: 6px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                ⏳ Es el turno de: <strong style="color: #0f172a; font-size: 17px;"><%= (rival_en_turno && rival_en_turno.name) || "Rival" %></strong>
              </div>
            <% end %>
          </div>

          <div style="display: flex; gap: 40px; background-color: #f8fafc; padding: 12px; margin-top: 15px; border-radius: 8px; border: 1px solid #e2e8f0; justify-content: center;">
            <%= for opponent <- @opponents do %>
              <% es_su_turno = to_string(@game.turn) == to_string(opponent.id) %>
              <div style={if es_su_turno, do: "display: flex; align-items: center; gap: 12px; background-color: #fef08a; padding: 6px 12px; border-radius: 6px; border: 1px solid #eab308;", else: "display: flex; align-items: center; gap: 12px; padding: 6px 12px;"}>
                <span style="font-weight: bold; color: #475569;">
                  <%= opponent.name %> <%= if es_su_turno, do: "⚡" %>
                </span>
                <div style="display: flex; align-items: center; gap: 6px;">
                  <div style="width: 30px; height: 45px; background-color: #94a3b8; border: 2px solid #64748b; border-radius: 4px; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 12px;">🂠</div>
                  <span style="font-size: 16px; font-weight: bold; color: #1e293b;"><%= opponent.card_count %> cards</span>
                </div>
              </div>
            <% end %>
          </div>

          <div style="flex: 1; display: flex; flex-direction: column; justify-content: center; align-items: center; background-color: #f3f4f6; margin: 20px 0; border-radius: 12px; border: 2px dashed #cbd5e1;">
            <span style="color: #64748b; font-size: 14px; text-transform: uppercase; font-weight: bold; margin-bottom: 15px;">Active Show on Table</span>
            <div style="display: flex; gap: 10px;">
              <%= if @game.table_cards == [] do %>
                <em style="color: #94a3b8;">Table is empty! Play a Show.</em>
              <% else %>
                <%= for card <- @game.table_cards do %>
                  <div style="width: 60px; height: 90px; background-color: #e11d48; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; border-radius: 6px; box-shadow: 0 4px 6px rgba(0,0,0,0.15);">
                    <div><%= elem(card, 0) %></div>
                    <div style="border-top: 1px solid rgba(255,255,255,0.4); width: 70%; margin: 2px 0;"></div>
                    <div><%= elem(card, 1) %></div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <div style="display: flex; flex-direction: column; align-items: center; border-top: 1px solid #eee; padding-top: 20px;">
            <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 15px;">
              <h3 style="margin: 0; color: #475569;">Your Hand:</h3>
              <%= if to_string(@game.turn) == to_string(@current_user.id) do %>
                <span style="background-color: #dbeafe; color: #1e40af; font-size: 14px; font-weight: bold; padding: 4px 10px; border-radius: 4px; border: 1px solid #bfdbfe;">YOUR turn ★ Click cards to select</span>
              <% end %>
            </div>

            <div style="display: flex; justify-content: center; align-items: flex-end; gap: 10px; min-height: 110px; margin-bottom: 25px; width: 100%;">
              <%= for {card, idx} <- Enum.with_index(@game.player_list[@current_user.id].cards) do %>
                <% is_selected = Enum.member?(@selected_cards, idx) %>
                <div phx-click="toggle_select_card" phx-value-index={idx} phx-target={@myself}
                    style={if is_selected, do: "width: 55px; height: 85px; background-color: #2563eb; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 18px; font-weight: bold; border-radius: 6px; cursor: pointer; transform: translateY(-20px); box-shadow: 0 10px 15px rgba(37,99,235,0.4); border: 3px solid #fef08a;", else: "width: 55px; height: 85px; background-color: #3b82f6; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 18px; font-weight: bold; border-radius: 6px; cursor: pointer; box-shadow: 0 2px 4px rgba(0,0,0,0.15);"}>
                  <div><%= elem(card, 0) %></div>
                  <div style="border-top: 1px solid rgba(255,255,255,0.3); width: 70%; margin: 2px 0;"></div>
                  <div><%= elem(card, 1) %></div>
                </div>
              <% end %>
            </div>

            <% is_my_turn = to_string(@game.turn) == to_string(@current_user.id) %>
            <% token_state = @game.player_list[@current_user.id].scout_and_show %>
            <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
              <button phx-click="exit_game" phx-target={@myself} style="background-color: #64748b; color: white; padding: 12px 24px; font-size: 14px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">Quit Match</button>

              <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap; justify-content: flex-end;">
                <%= if is_my_turn do %>
                  <%= if token_state == :in_progress do %>
                    <span style="background-color: #fef9c3; color: #854d0e; padding: 10px 16px; font-size: 14px; font-weight: bold; border-radius: 6px; border: 1px solid #fde68a;">
                      ⚡ Scout hecho — selecciona cartas y haz Show
                    </span>
                  <% else %>
                    <button phx-click="open_scout_modal" phx-value-where="beginning" phx-target={@myself} style="background-color: #d97706; color: white; padding: 12px 20px; font-size: 14px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                      Scout Izq. (Cost 1 🪙)
                    </button>

                    <button phx-click="open_scout_modal" phx-value-where="end" phx-target={@myself} style="background-color: #b45309; color: white; padding: 12px 20px; font-size: 14px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                      Scout Der. (Cost 1 🪙)
                    </button>

                    <%= if token_state == false do %>
                      <button phx-click="open_scout_for_show_modal" phx-value-where="beginning" phx-target={@myself} style="background-color: #ec4899; color: white; padding: 12px 16px; font-size: 14px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                        Scout & Show Izq. ⚡
                      </button>

                      <button phx-click="open_scout_for_show_modal" phx-value-where="end" phx-target={@myself} style="background-color: #be185d; color: white; padding: 12px 16px; font-size: 14px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                        Scout & Show Der. ⚡
                      </button>
                    <% else %>
                      <span style="background-color: #f1f5f9; color: #94a3b8; padding: 12px 16px; font-size: 14px; font-weight: bold; border-radius: 6px; border: 1px dashed #cbd5e1;">
                        Scout & Show usado ✓
                      </span>
                    <% end %>
                  <% end %>

                  <button phx-click="show_cards" phx-target={@myself} style="background-color: #2563eb; color: white; padding: 12px 30px; font-size: 16px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
                    <%= if Enum.count(@selected_cards) == 0, do: "Show cards", else: "Show Selected (#{Enum.count(@selected_cards)})" %>
                  </button>
                <% else %>
                  <span style="color: #94a3b8; font-size: 14px; font-style: italic;">Esperando tu turno…</span>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <%= if @scout_target do %>
          <div style="position: fixed; inset: 0; background-color: rgba(0, 0, 0, 0.6); display: flex; align-items: center; justify-content: center; z-index: 50;">
            <div style="background-color: white; padding: 30px; border-radius: 12px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.3); max-width: 420px; width: 100%; color: #1e293b;">

              <h3 style="margin-top: 0; font-size: 20px; text-align: center;">
                <%= case @scout_mode do
                  :scout_for_show -> "Scout & Show — Fase 1: Tomar carta ⚡"
                  _ -> "Configurar Acción de Scout"
                end %>
              </h3>
              <p style="color: #64748b; font-size: 14px; text-align: center; margin-bottom: 25px;">
                Vas a tomar la carta del lado <strong><%= if @scout_target == :beginning, do: "Izquierdo", else: "Derecho" %></strong> de la mesa.
                <%= if @scout_mode == :scout_for_show do %>
                  <br/>Después podrás seleccionar cartas de tu mano y hacer Show.
                <% end %>
              </p>

              <form phx-submit="confirm_scout" phx-target={@myself} style="display: flex; flex-direction: column; gap: 20px;">

                <div>
                  <label style="display: block; font-weight: bold; margin-bottom: 8px; font-size: 14px; color: #475569;">1. Orientación de la carta:</label>
                  <div style="display: flex; gap: 10px;">
                    <button type="button" phx-click="toggle_modal_flip" phx-value-flip="false" phx-target={@myself}
                            style={"flex: 1; padding: 12px; border-radius: 8px; font-weight: bold; cursor: pointer; border: 2px solid #{if !@scout_flip, do: "#2563eb", else: "#cbd5e1"}; background-color: #{if !@scout_flip, do: "#eff6ff", else: "white"}; color: #{if !@scout_flip, do: "#2563eb", else: "#64748b"};"}>
                      Normal
                    </button>
                    <button type="button" phx-click="toggle_modal_flip" phx-value-flip="true" phx-target={@myself}
                            style={"flex: 1; padding: 12px; border-radius: 8px; font-weight: bold; cursor: pointer; border: 2px solid #{if @scout_flip, do: "#10b981", else: "#cbd5e1"}; background-color: #{if @scout_flip, do: "#ecfdf5", else: "white"}; color: #{if @scout_flip, do: "#10b981", else: "#64748b"};"}>
                      Girar 🔄
                    </button>
                  </div>
                </div>

                <div>
                  <label style="display: block; font-weight: bold; margin-bottom: 8px; font-size: 14px; color: #475569;">2. ¿Dónde quieres insertarla en tu mano?</label>
                  <% hand_cards = @game.player_list[@current_user.id].cards %>
                  <% total_cards = Enum.count(hand_cards) %>

                  <select name="hand_position" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #cbd5e1; background-color: white; font-size: 15px; color: #1e293b; outline: none;">
                    <%= for idx <- 0..total_cards do %>
                      <option value={idx} selected={idx == @scout_hand_position}>
                        <%= cond do
                          idx == 0 -> "Al principio (Índice 0)"
                          idx == total_cards -> "Al final de todo (Índice #{idx})"
                          true -> "Posición intermedia #{idx} (Antes de la carta #{idx + 1})"
                        end %>
                      </option>
                    <% end %>
                  </select>
                </div>

                <div style="display: flex; flex-direction: column; gap: 10px; margin-top: 10px;">
                  <button type="submit" style={"color: white; padding: 14px; font-size: 16px; font-weight: bold; border: none; border-radius: 8px; cursor: pointer; text-align: center; background-color: #{if @scout_mode == :scout_for_show, do: "#be185d", else: "#2563eb"};"}>
                    <%= if @scout_mode == :scout_for_show, do: "Tomar carta (Fase 1) ⚡", else: "Confirmar y Hacer Scout" %>
                  </button>
                  <button type="button" phx-click="close_scout_modal" phx-target={@myself} style="background-color: transparent; color: #94a3b8; padding: 8px; font-size: 14px; border: none; cursor: pointer;">
                    Cancelar acción
                  </button>
                </div>

              </form>

            </div>
          </div>
        <% end %>
      </div>
    """
  end

  # --- MANEJADORES DE EVENTOS ---

  @impl true
  def handle_event("open_scout_modal", %{"where" => where_param}, socket) do
    where_atom = if where_param == "beginning", do: :beginning, else: :end
    {:noreply, assign(socket, scout_target: where_atom, scout_mode: :scout)}
  end

  @impl true
  def handle_event("open_scout_for_show_modal", %{"where" => where_param}, socket) do
    where_atom = if where_param == "beginning", do: :beginning, else: :end
    {:noreply, assign(socket, scout_target: where_atom, scout_mode: :scout_for_show)}
  end

  def handle_event("toggle_modal_flip", %{"flip" => flip_param}, socket) do
    {:noreply, assign(socket, scout_flip: flip_param == "true")}
  end

  @impl true
  def handle_event("confirm_scout", %{"hand_position" => pos_str}, socket) do
    where_atom = socket.assigns.scout_target
    flip_boolean = socket.assigns.scout_flip
    hand_position = String.to_integer(pos_str)
    scout_mode = socket.assigns.scout_mode

    case scout_mode do
      :scout_for_show ->
        send(self(), {:play_action_scout_for_show, where_atom, hand_position, flip_boolean})
        {:noreply, reset_scout_modal(socket)}

      _ ->
        send(self(), {:play_action_scout, where_atom, hand_position, flip_boolean})
        {:noreply, reset_scout_modal(socket)}
    end
  end

  defp reset_scout_modal(socket) do
    assign(socket,
      scout_target: nil,
      scout_mode: :scout,
      scout_flip: false,
      scout_hand_position: 0
    )
  end

  @impl true
  def handle_event("close_scout_modal", _params, socket) do
    {:noreply, reset_scout_modal(socket)}
  end

  def handle_event("show_cards", _params, socket) do
    selected_indices = socket.assigns.selected_cards

    if Enum.empty?(selected_indices) do
      send(self(), {:put_flash, :error, "¡Selecciona alguna carta primero!"})
      {:noreply, socket}
    else
      game = socket.assigns.game
      user_id = socket.assigns.current_user.id
      user_id_int = if is_binary(user_id), do: String.to_integer(user_id), else: user_id
      player_cards = game.player_list[user_id_int].cards
      cards_to_show = Enum.map(selected_indices, &Enum.at(player_cards, &1))

      send(self(), {:play_action_show, cards_to_show})
      {:noreply, assign(socket, selected_cards: [])}
    end
  end

  def handle_event("flip_hand", _params, socket) do
    send(self(), {:flip_initial_hand})
    {:noreply, socket}
  end

  def handle_event("mark_ready", _params, socket) do
    send(self(), :player_mark_ready)
    {:noreply, socket}
  end

  @impl true
  def handle_event("exit_game", _params, socket) do
    send(self(), :player_quit_game)
    {:noreply, socket}
  end

  def handle_event("toggle_select_card", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    selected = socket.assigns.selected_cards

    new_selected =
      if Enum.member?(selected, idx) do
        Enum.reject(selected, &(&1 == idx))
      else
        Enum.sort([idx | selected])
      end

    {:noreply, assign(socket, selected_cards: new_selected)}
  end
end
