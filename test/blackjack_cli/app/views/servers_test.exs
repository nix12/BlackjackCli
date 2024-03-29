defmodule BlackjackCli.Views.ServersTest do
  use BlackjackCli.RepoCase
  @doctest BlackjackCli.Views.Servers.State

  import BlackjackCli.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Servers.State
  alias BlackjackCli.Core.Server
  alias BlackjackCli.Accounts.User

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BlackjackCli.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(BlackjackCli.Repo, {:shared, self()})
  end

  setup_all do
    build(:server) |> insert()
  end

  setup_all do
    data = [
      %{"player_count" => 0, "server_name" => "server0", "table_count" => 0},
      %{"player_count" => 0, "server_name" => "server1", "table_count" => 0},
      %{"player_count" => 0, "server_name" => "server2", "table_count" => 0},
      %{"player_count" => 0, "server_name" => "server3", "table_count" => 0},
      %{"player_count" => 0, "server_name" => "server4", "table_count" => 0}
    ]

    [data: data]
  end

  setup do
    [initial_state: %{BlackjackCli.App.State.init() | screen: :servers}]
  end

  describe "update/2" do
    test "should move the servers menu down one when down arrow is pressed", %{
      initial_state: initial_state,
      data: data
    } do
      assert key(initial_state, @down, State, %{input: 1}) ==
               %{input: 1, user: nil, screen: :servers, token: "", data: data, menu: true}
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state,
      data: data
    } do
      assert input(initial_state, State, %{input: ?s}) ==
               %{input: 1, user: nil, screen: :servers, token: "", data: data, menu: true}
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state,
      data: data
    } do
      assert key(initial_state, @up, State, %{input: 0, screen: :servers}) ==
               %{input: 0, user: nil, screen: :servers, token: "", data: data, menu: true}
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state,
      data: data
    } do
      assert input(%{initial_state | input: 1}, State, %{input: ?s}) ==
               %{input: 1, user: nil, screen: :servers, token: "", data: data, menu: true}
    end

    test "should move from servers to server menu", %{
      initial_state: initial_state,
      data: data
    } do
      assert key(initial_state, @tab, State, %{input: 0, menu: true}) ==
               %{input: 0, user: nil, screen: :servers, token: "", data: data, menu: true}
    end

    test "should change screen based on menu options", %{initial_state: initial_state, data: data} do
      assert key(initial_state, @tab, State, %{menu: true, input: 0}) ==
               %{input: 0, user: nil, screen: :servers, token: "", data: data, menu: true}

      assert key(initial_state, @down, State, %{menu: true, input: 1}) ==
               %{input: 1, user: nil, screen: :servers, token: "", data: data, menu: true}

      assert key(initial_state, @down, State, %{menu: true, input: 2}) ==
               %{input: 2, user: nil, screen: :servers, token: "", data: data, menu: true}

      assert key(initial_state, @enter, State, %{input: 2, menu: true, screen: :menu}) ==
               %{input: 2, user: nil, screen: :menu, token: nil, data: data, menu: true}
    end

    test "should change screen to chosen server", %{initial_state: initial_state} do
      build(:user) |> insert()

      BlackjackCli.Views.Login.State.start_login()

      assert input(initial_state, BlackjackCli.Views.Login.State, %{
               input: "username0",
               screen: :login
             })

      assert key(initial_state, @tab, BlackjackCli.Views.Login.State, %{input: "", screen: :login})

      assert input(initial_state, BlackjackCli.Views.Login.State, %{
               input: "password",
               screen: :login
             })

      assert %{active: false, username: "username0", password: "password", errors: ""} =
               Agent.get(BlackjackCli.via_tuple(Registry.App, :login), & &1)

      assert key(initial_state, @enter, BlackjackCli.Views.Login.State, %{
               input: 0,
               screen: :menu,
               user: %{username: "username0"}
             })

      assert key(initial_state, @enter, State, %{
               screen: :server,
               input: 0,
               user: %{username: "username0"}
             })
    end
  end

  describe "switch_menus/1" do
    test "when :menu is not included in model", %{initial_state: initial_state} do
      assert key(initial_state, @tab, State, %{menu: true, input: 0})
    end
  end
end
