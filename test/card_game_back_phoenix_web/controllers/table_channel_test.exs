defmodule CardGameBackPhoenixWeb.TableChannelTest do
  use CardGameBackPhoenixWeb.ChannelCase
  alias CardGameBackPhoenixWeb.UserSocket
  doctest CardGameBackPhoenix.Utils.Games

  setup do
    user = %YourApp.Accounts.User{id: "123", name: "Player1"}
    {:ok, socket} = connect(UserSocket, %{"token" => "valid_token"})
    %{socket: socket, user: user}
  end

  test "Join table" do
    CardGameBackPhoenix.Repo
    |> expect(:insert, fn _changeset -> {
      :ok,
      %CardGameBackPhoenix.Schemas.Game{
        id: "550e8400-e29b-41d4-a716-446655440000",
        status: :lobby,
        owner_id: 1,
        creation_date: ~U[2026-04-25 20:00:00Z],
        ending_date: nil
      }
    }end)
    {:ok, reply, socket} = subscribe_and_join(socket, "game_lobby:123", %{"some" => "data"})

    # Now you can check if the join was successful
    assert socket.topic == "game_lobby:123"
  end

  # describe "GET /users/register" do
  #   test "renders registration page", %{conn: conn} do
  #     conn = get(conn, ~p"/users/register")
  #     response = html_response(conn, 200)
  #     assert response =~ "Register"
  #     assert response =~ ~p"/users/log-in"
  #     assert response =~ ~p"/users/register"
  #   end

  #   test "redirects if already logged in", %{conn: conn} do
  #     conn = conn |> log_in_user(user_fixture()) |> get(~p"/users/register")

  #     assert redirected_to(conn) == ~p"/"
  #   end
  # end

  # describe "POST /users/register" do
  #   @tag :capture_log
  #   test "creates account but does not log in", %{conn: conn} do
  #     email = unique_user_email()

  #     conn =
  #       post(conn, ~p"/users/register", %{
  #         "user" => valid_user_attributes(email: email)
  #       })

  #     refute get_session(conn, :user_token)
  #     assert redirected_to(conn) == ~p"/users/log-in"

  #     assert conn.assigns.flash["info"] =~
  #              ~r/An email was sent to .*, please access it to confirm your account/
  #   end

  #   test "render errors for invalid data", %{conn: conn} do
  #     conn =
  #       post(conn, ~p"/users/register", %{
  #         "user" => %{"email" => "with spaces"}
  #       })

  #     response = html_response(conn, 200)
  #     assert response =~ "Register"
  #     assert response =~ "must have the @ sign and no spaces"
  #   end
  # end
end
