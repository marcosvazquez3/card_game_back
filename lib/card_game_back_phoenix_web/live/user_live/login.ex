defmodule CardGameBackPhoenixWeb.Live.UserLive.Login do
  use CardGameBackPhoenixWeb, :live_view

  alias CardGameBackPhoenix.Accounts
  import CardGameBackPhoenixWeb.CoreComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 28rem; margin: 4rem auto; padding: 1.5rem; border: 1px solid #e2e8f0; border-radius: 0.375rem; font-family: sans-serif;">
      <div style="margin-bottom: 1.5rem;">
        <h1 style="font-size: 1.5rem; font-weight: bold; color: #0f172a; margin: 0;">Sign In</h1>
        <p style="font-size: 0.875rem; color: #64748b; margin-top: 0.25rem;">Enter your credentials to access the game.</p>
      </div>

      <.form :let={f} for={@form} action={~p"/users/log-in"} as={:user}>
        <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

        <div style="margin-bottom: 1rem;">
          <label for="email" style="display: block; font-size: 0.875rem; font-weight: 500; color: #334155; margin-bottom: 0.25rem;">Email</label>
          <input type="email" id="email" name={f[:email].name} value={f[:email].value} required style="width: 100%; padding: 0.5rem; border: 1px solid #cbd5e1; border-radius: 0.25rem;" />
        </div>

        <div style="margin-bottom: 1rem;">
          <label for="password" style="display: block; font-size: 0.875rem; font-weight: 500; color: #334155; margin-bottom: 0.25rem;">Password</label>
          <input type="password" id="password" name={f[:password].name} value={f[:password].value} required style="width: 100%; padding: 0.5rem; border: 1px solid #cbd5e1; border-radius: 0.25rem;" />
        </div>

        <div style="margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between;">
          <label style="display: flex; align-items: center; font-size: 0.875rem; color: #334155;">
            <input type="checkbox" name={f[:remember_me].name} checked={f[:remember_me].value} style="margin-right: 0.5rem;" />
            Keep me logged in
          </label>
          <a href={~p"/users/reset_password"} style="font-size: 0.875rem; color: #475569; text-decoration: underline;">Forgot password?</a>
        </div>

        <button type="submit" style="width: 100%; padding: 0.5rem; background-color: #0f172a; color: white; font-weight: 500; border: none; border-radius: 0.25rem; cursor: pointer;">
          Log In
        </button>
      </.form>

      <div style="margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #f1f5f9; text-align: center; font-size: 0.875rem; color: #475569;">
        Need an account? <a href={~p"/users/register"} style="font-weight: 600; color: #0f172a; text-decoration: underline;">Register</a>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/live/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/")}
  end

  defp local_mail_adapter? do
    Application.get_env(:card_game_back_phoenix, CardGameBackPhoenix.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
