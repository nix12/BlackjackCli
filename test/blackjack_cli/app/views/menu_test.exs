defmodule BlackjackCli.Views.MenuTest do
  @doctest BlackjackCli.Views.Menu.State
  use BlackjackCli.RepoCase, async: false

  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.App.State

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  setup do
    %{initial_state: State.update(%{state() | screen: :menu}, {:event, %{}})}
  end

  describe "update/2" do
    test "should move menu select down one when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert State.update(initial_state, {:event, %{key: @down}}) ==
               %{input: 1, user: nil, screen: :menu, token: "", data: [], menu: true}
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert input(initial_state, State, %{input: ?s, screen: :menu, user: nil}) ==
               %{input: 1, user: nil, screen: :menu, token: "", data: [], menu: true}
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert State.update(initial_state, {:event, %{key: @up}}) ==
               %{input: 0, user: nil, screen: :menu, token: "", data: [], menu: true}
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert input(%{initial_state | input: 1}, State, %{input: ?w, screen: :menu, user: nil}) ==
               %{input: 0, user: nil, screen: :menu, token: "", data: [], menu: true}
    end

    test "change screen when enter is pressed", %{
      initial_state: initial_state
    } do
      user = build(:user) |> set_password("password") |> insert()
      user_params = %{user: %{username: user.username, password_hash: "password"}}
      %HTTPoison.Response{body: body} = BlackjackCli.login_path(user_params)
      body = body |> Jason.decode!()

      assert State.update(
               %{
                 initial_state
                 | token: body["token"],
                   user: %{username: user.username}
               },
               {:event, %{key: @enter}}
             ) == %{
               input: 0,
               user: %{username: body["user"]["username"]},
               screen: :servers,
               token: body["token"],
               data: [],
               menu: true
             }
    end
  end
end
