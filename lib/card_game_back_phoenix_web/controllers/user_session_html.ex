defmodule CardGameBackPhoenixWeb.UserSessionHTML do
  use CardGameBackPhoenixWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:card_game_back_phoenix, CardGameBackPhoenix.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
