defmodule BlackjackCli.Views.LoginTest do
  @doctest BlackjackCli.Views.Login.State
  use BlackjackCli.RepoCase, async: true

  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.App.State
  alias BlackjackCli.Views.Login.LoginForm
  alias BlackjackCli.Views.Login.State, as: LoginState
  alias BlackjackCli.Blackjack

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)
  @up key(:arrow_up)
  @down key(:arrow_down)
  @delete key(:delete)

  @login_path BlackjackCli.blackjack_api() <> "/login"
  @valid_user_params valid_user()
  @invalid_user_params invalid_user()

  setup do
    LoginState.start_login()

    %{registry: Registry.App}
  end

  setup do
    %{
      initial_state:
        State.update(%{state() | input: "", screen: :login, menu: false}, {:event, %{}})
    }
  end

  setup :verify_on_exit!

  describe "update/2" do
    test "update login username and password with enter", %{
      initial_state: initial_state,
      registry: registry
    } do
      HttpClientMock
      |> expect(:http_post, fn @login_path, @valid_user_params ->
        %HTTPoison.Response{body: login_success_resp(), status_code: 200}
      end)

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username" |> String.last(),
                 user: nil,
                 screen: :login,
                 token: "",
                 data: [],
                 menu: false
               }

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :login, token: "", data: [], menu: false}

      assert %{tab_count: 1, username: "username", password: "password", errors: ""} ==
               LoginForm.get_fields()

      logged_in_user = State.update(initial_state, {:event, %{key: @enter}})

      assert %{
               input: 0,
               user: %{username: "username"},
               screen: :menu,
               token: logged_in_user.token,
               data: [],
               menu: true
             } == logged_in_user
    end

    test "update login username and password with menu", %{
      initial_state: initial_state,
      registry: registry
    } do
      HttpClientMock
      |> expect(:http_post, fn @login_path, @valid_user_params ->
        %HTTPoison.Response{body: login_success_resp(), status_code: 200}
      end)

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username" |> String.last(),
                 user: nil,
                 screen: :login,
                 token: "",
                 data: [],
                 menu: false
               }

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "d", user: nil, screen: :login, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: 0, user: nil, screen: :login, token: "", data: [], menu: true}

      assert State.update(%{initial_state | input: 0, menu: true}, {:event, %{key: @down}}) ==
               %{input: 1, user: nil, screen: :login, token: "", data: [], menu: true}

      assert %{tab_count: 2, username: "username", password: "password", errors: ""} ==
               LoginForm.get_fields()

      logged_in_user = State.update(initial_state, {:event, %{key: @enter}})

      assert %{
               input: 0,
               user: %{username: "username"},
               screen: :menu,
               token: logged_in_user.token,
               data: [],
               menu: true
             } == logged_in_user
    end

    test "update login errors from no password or username", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert %{tab_count: 1, username: "", password: "", errors: "username cannot be blank."} =
               LoginForm.get_fields()
    end

    test "update login errors from bad password", %{
      initial_state: initial_state,
      registry: registry
    } do
      HttpClientMock
      |> expect(:http_post, fn @login_path, @invalid_user_params ->
        %HTTPoison.Response{body: login_credentials_fail_resp(), status_code: 422}
      end)

      assert input(initial_state, State, %{input: "badname"}) ==
               %{input: "e", user: nil, screen: :login, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @tab}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{input: "d", user: nil, screen: :login, token: "", data: [], menu: false}

      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}

      assert %{
               tab_count: 1,
               username: "badname",
               password: "notpassword",
               errors: "invalid credentials"
             } = LoginForm.get_fields()
    end

    test "character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "a", screen: :login}) ==
               %{input: "a", user: nil, screen: :login, token: "", data: [], menu: false}
    end

    test "space bar input", %{initial_state: initial_state} do
      assert State.update(initial_state, {:event, %{key: @space_bar}}) ==
               %{input: " ", user: nil, screen: :login, token: "", data: [], menu: false}
    end

    test "character deletion", %{initial_state: initial_state} do
      assert State.update(%{initial_state | input: "a"}, {:event, %{key: @delete}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}
    end

    test "go back to start menu", %{initial_state: initial_state} do
      assert %{input: "", user: nil, screen: :login, token: "", data: [], menu: false} =
               State.update(initial_state, {:event, %{key: @tab}})

      assert %{input: 0, user: nil, screen: :login, token: "", data: [], menu: true} =
               State.update(initial_state, {:event, %{key: @tab}})

      assert %{input: 0, user: nil, screen: :login, token: "", data: [], menu: true} =
               State.update(initial_state, {:event, %{key: @enter}})
    end
  end
end
