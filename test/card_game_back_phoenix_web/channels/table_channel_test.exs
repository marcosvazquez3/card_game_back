defmodule CardGameBackPhoenixWeb.TableChannelTest do
  use CardGameBackPhoenixWeb.ChannelCase
  alias CardGameBackPhoenixWeb.UserSocket
  alias CardGameBackPhoenix.Game.Deck
  use Mimic
  setup :set_mimic_global
  setup do
    # Create the owner of the game
    {:ok, user} = create_user("Player_1")
    {:ok, table} = create_game(user.id)
    {:ok, socket} = connect_socket(user)
    {:ok, reply, socket} = subscribe_and_join(socket, "table:#{table.id}", %{"some" => "data"})
    %{socket: socket, user_id: user.id, table_id: table.id}
  end

  defp create_user(user_name) do
    CardGameBackPhoenix.Accounts.register_user(%{
      email: "test#{System.unique_integer()}@example.com",
      password: "password1234",
      user_name: user_name
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

  defp connect_socket(user) do
    token = Phoenix.Token.sign(CardGameBackPhoenixWeb.Endpoint, "user socket", %{user_id: user.id, user_name: user.user_name})
    connect(UserSocket, %{"token" => token})
  end

  test "Join table", %{socket: socket, user_id: user_id, table_id: table_id} do
    assert socket.topic == "table:#{table_id}"
  end

  defp setup_test_user(name, topic) do
    {:ok, user} = create_user(name)
    {:ok, socket} = connect_socket(user)
    {:ok, _reply, joined_socket} = subscribe_and_join(socket, topic, %{"some" => "data"})
    {joined_socket, user.id}
  end

  test "Check presence", %{socket: socket, user_id: user_1_id, table_id: table_id} do
    # Add three users to the channel
    topic = "table:#{table_id}"
    # User 2
    {_socket, user_2_id} = setup_test_user("Player_2", topic)
    # User 3
    {_socket, user_3_id} = setup_test_user("Player_3", topic)

    # User 3
    {_socket, user_4_id} = setup_test_user("Player_4", topic)

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
    {socket_user_2, user_2_id} = setup_test_user("Player_2", topic)
    {socket_user_3, user_3_id} = setup_test_user("Player_3", topic)
    {socket_user_4, user_4_id} = setup_test_user("Player_4", topic)
    push(socket, "start_game", %{})
    {{socket_user_2, user_2_id}, {socket_user_3, user_3_id}, {socket_user_4, user_4_id}}
  end


  test "Validate game start", %{socket: socket, user_id: user_1_id, table_id: table_id} do
    create_and_start_game(table_id, socket)
    assert_broadcast "game_started", %{status: "running"}
    game_pid = CardGameBackPhoenix.Game.TableManager.whereis(table_id)
    assert Process.alive?(game_pid)

  end


# O test funciona de principio a fin ben, parece que todo ten sentido. Guay
  test "Test complete game", %{socket: socket_user_1, user_id: user_1_id, table_id: table_id} do
    cards_for_4_players = [
      # [{3, 5}, {9, 7}, {8, 4}, {5, 9}, {1, 9}, {7, 3}, {6, 9}, {8, 1}, {2, 5}],
      [ {9, 7}, {8, 4}, {9, 9}, {9, 9}, {9, 3}, {9, 9}, {9, 1}, {9, 5}],
      [{8, 3}, {2, 4}, {6, 2}, {7, 1}, {6, 8}, {2, 8}, {2, 7}, {4, 9}, {1, 6}],
      [{4, 7}, {8, 5}, {3, 9}, {3, 1}, {3, 4}, {7, 8}, {6, 5}, {5, 1}, {1, 4}],
      [{6, 4}, {2, 1}, {7, 6}, {7, 5}, {2, 9}, {3, 2}, {5, 4}, {6, 3}, {8, 9}]
    ]
    Deck
    |> expect(:deck_gen, fn _count ->
      cards_for_4_players
    end)
    {{socket_user_2, user_2_id}, {socket_user_3, user_3_id}, {socket_user_4, user_4_id}} = create_and_start_game(table_id, socket_user_1)
    assert_broadcast "game_started", %{status: "running"}
    ref = push(socket_user_1, "get_user_state", %{})
    assert_reply ref, :ok, state
    push(socket_user_1, "select_orientation", %{"flipped" => false})
    assert_push "orientation_locked", %{success: true}
    push(socket_user_2, "select_orientation", %{"flipped" => false})
    assert_push "orientation_locked", %{success: true}
    push(socket_user_3, "select_orientation", %{"flipped" => false})
    assert_push "orientation_locked", %{success: true}
    push(socket_user_4, "select_orientation", %{"flipped" => false})
    assert_broadcast "orientation_fase_ended", %{turn: turn}

    # Lets play the game
    push(socket_user_1, "show", %{"cards" => [{9, 7}, {8, 4}]})
    assert_broadcast "player_showed", %{player: ^user_1_id}
    push(socket_user_4, "show", %{"cards" => [{7, 6}, {7, 5}]})
    assert_broadcast "player_showed", %{player: ^user_4_id}
    push(socket_user_3, "show", %{"cards" => [{3, 9}, {3, 1}, {3, 4}]})
    assert_broadcast "player_showed", %{player: ^user_3_id}

    push(socket_user_2, "scout", %{"where" => "beginning", "hand_position" => 1, "flip" => true})
    assert_broadcast "player_showed", %{player: ^user_3_id}


    winner_id = socket_user_1
    loser_id = socket_user_2
    push(socket_user_1, "show", %{"cards" => [{9, 9}, {9, 9}, {9, 3}, {9, 9}, {9, 1}, {9, 5}]})
    assert_broadcast "end_game", %{
      reason: "empty_hand",
      final_scores: final_scores
    }

    assert Map.get(final_scores, user_1_id) == 2
    assert Map.get(final_scores, user_2_id) == -10



    # ref = push(socket_user_1, "get_user_state", %{})
    # assert_reply ref, :ok, new_state
    # IO.inspect(new_state)
  end


  test "Test add friends" do
    {:ok, user_manuel} = create_user("Manuel")
    {:ok, socket_manuel} = connect_socket(user_manuel)

    {:ok, user_maria} = create_user("María")
    {:ok, socket_maria} = connect_socket(user_maria)

    CardGameBackPhoenix.Utils.Accounts.add_friend(user_manuel.id, user_maria.id)

    #CardGameBackPhoenix.Utils.Accounts.dump_table(CardGameBackPhoenix.Schemas.UsersRelationships)

    {:ok, reply_manuel, new_manuel_socket} = subscribe_and_join(socket_manuel, "user:#{user_manuel.id}", %{"some" => "data"})
    assert Enum.any?(reply_manuel.online_friends, fn friend ->
      friend.user_name == "María" and friend.status == :offline
    end)

    {:ok, reply_maria, new_maria_socket} = subscribe_and_join(socket_maria, "user:#{user_maria.id}", %{"some" => "data"})
    assert Enum.any?(reply_maria.online_friends, fn friend ->
      friend.user_name == "Manuel" and friend.status == :online
    end)

    # Manuel starts a game
    #push(socket, "start_game", %{})

  end


end
