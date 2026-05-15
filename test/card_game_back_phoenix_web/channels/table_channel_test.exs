defmodule CardGameBackPhoenixWeb.TableChannelTest do
  use CardGameBackPhoenixWeb.ChannelCase
  alias CardGameBackPhoenixWeb.UserSocket
  use Mimic


  setup do
    # Create the owner of the game
    {:ok, user} = create_user("Player_1")
    {:ok, table} = create_game(user.id)
    {:ok, socket} = connect_socket(user.id)
    {:ok, reply, socket} = subscribe_and_join(socket, "table:#{table.id}", %{"some" => "data"})
    %{socket: socket, user_id: user.id, table_id: table.id}
  end

  defp create_user(user_name) do
    CardGameBackPhoenix.Accounts.register_user(%{
      email: "test#{System.unique_integer()}@example.com",
      password: "password1234",
      user_name: "Player1"
    })
  end

  defp create_game(user_id) do
    table_attrs = %{
      mv_dc: "doc_123_abc",
      status: :lobby,
      owner_id: user_id
    }
    CardGameBackPhoenix.Utils.Tables.create_game(table_attrs)
  end

  defp connect_socket(user_id) do
    token = Phoenix.Token.sign(CardGameBackPhoenixWeb.Endpoint, "user socket", user_id)
    connect(UserSocket, %{"token" => token})
  end

  test "Join table", %{socket: socket, user_id: user_id, table_id: table_id} do
    assert socket.topic == "table:#{table_id}"
  end

  defp setup_test_user(name, topic) do
    {:ok, user} = create_user(name)
    {:ok, socket} = connect_socket(user.id)
    subscribe_and_join(socket, topic, %{"some" => "data"})
    user.id
  end

  test "Check presence", %{socket: socket, user_id: user_1_id, table_id: table_id} do
    # Add three users to the channel
    topic = "table:#{table_id}"

    # User 2
    user_2_id = setup_test_user("Player_2", topic)

    # User 3
    user_3_id = setup_test_user("Player_3", topic)

    # User 3
    user_4_id = setup_test_user("Player_4", topic)

    u1 = "#{user_1_id}"
    u2 = "#{user_2_id}"
    u3 = "#{user_3_id}"
    u4 = "#{user_4_id}"

    # Assert that all four keys exist in the map simultaneously
    assert %{
      ^u1 => %{metas: [%{user_id: ^user_1_id} | _]},
      ^u2 => %{metas: [%{user_id: ^user_2_id} | _]},
      ^u3 => %{metas: [%{user_id: ^user_3_id} | _]},
      ^u4 => %{metas: [%{user_id: ^user_4_id} | _]}
    } = CardGameBackPhoenixWeb.Presence.list(topic)
  end


  defp create_and_start_game(table_id, socket) do
    # Add three users to the channel
    topic = "table:#{table_id}"
    user_2_id = setup_test_user("Player_2", topic)
    user_3_id = setup_test_user("Player_3", topic)
    user_4_id = setup_test_user("Player_4", topic)

    ref = push(socket, "start_game", %{})
  end


  test "Validate game start", %{socket: socket, user_id: user_1_id, table_id: table_id} do
    create_and_start_game(table_id, socket)
    assert_broadcast "game_started", %{status: "running"}
    game_pid = CardGameBackPhoenix.Game.TableManager.whereis(table_id)
    assert Process.alive?(game_pid)

  end


  test "Validate player information", %{socket: socket, user_id: user_1_id, table_id: table_id} do
    create_and_start_game(table_id, socket)


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
