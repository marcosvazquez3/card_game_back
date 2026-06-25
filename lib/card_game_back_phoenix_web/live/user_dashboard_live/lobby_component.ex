defmodule CardGameBackPhoenixWeb.Live.UserDashboard.LobbyComponent do
  use CardGameBackPhoenixWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div :if={@page_state == "lobby"}>
        <div style="border-bottom: 2px solid #eee; padding-bottom: 15px; margin-bottom: 30px;">
          <h1 style="margin: 0;">Game Lobby #<%= assigns.current_table_id %></h1>
        </div>

        <div style="flex: 1;">
          <h3>Players in Room (<%= Enum.count(@lobby_players) %>/4)</h3>
          <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 15px;">
            <%= for player <- @lobby_players do %>
              <div style="display: flex; align-items: center; justify-content: space-between; padding: 15px; border: 1px solid #ddd; border-radius: 8px; background-color: #575757;">
                <div style="display: flex; align-items: center;">
                  <strong style="font-size: 16px;"><%= player.name %></strong>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div style="display: flex; justify-content: center; align-items: center; gap: 20px; padding-top: 20px; border-top: 1px solid #eee;">
          <button phx-click="leave_lobby" phx-target={@myself} style="background-color: #ef4444; color: white; width: 215px; padding: 15px 0; font-size: 20px; font-weight: bold; border: none; border-radius: 8px; cursor: pointer; text-align: center;">
            Leave Lobby
          </button>
          <button phx-click="start_game" phx-target={@myself} style="background-color: #10b981; color: white; width: 215px; padding: 15px 0; font-size: 20px; font-weight: bold; border: none; border-radius: 8px; cursor: pointer; text-align: center;">
            Start Game
          </button>
        </div>
      </div>

    </div>
    """
  end

  def handle_event("leave_lobby", _, socket) do
    send(self(), {:change_state, "dashboard"})
    {:noreply, socket}
  end
  def handle_event("start_game", _, socket) do
    send(self(), :intent_start_game)
    {:noreply, socket}
  end
end
