defmodule CardGameBackPhoenixWeb.Live.UserDashboard.DashboardComponent do
  use CardGameBackPhoenixWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={@id}>

      <div :if={@page_state == "dashboard"} style="display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100%;">
        <h1>Welcome Back, <%= @current_user.user_name %></h1>
        <p>Ready for your next match?</p>
        <button phx-click="go_to_lobby" phx-target={@myself} style="background-color: #4f46e5; color: white; padding: 12px 40px; font-size: 18px; font-weight: bold; border: none; border-radius: 6px; cursor: pointer;">
          Play Game
        </button>
      </div>

    </div>
    """
  end

  def handle_event("go_to_lobby", _, socket) do
    send(self(), :intent_create_game)
    {:noreply, socket}
  end
end
