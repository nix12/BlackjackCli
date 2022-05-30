defmodule BlackjackCli.Views.CreateServerTest do
  @doctest BlackjackCli.Views.CreateServer.State
  use BlackjackCli.RepoCase, async: true

  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.App.State

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  setup do
    %{
      initial_state:
        State.update(%{state() | input: "", screen: :create_server, menu: false}, {:event, %{}})
    }
  end

  describe "update/2" do
    test "character deletion", %{initial_state: initial_state} do
      assert State.update(%{initial_state | input: "a"}, {:event, %{key: @delete}}) ==
               %{input: "", user: nil, screen: :create_server, token: "", data: [], menu: false}
    end

    test "space bar input", %{initial_state: initial_state} do
      assert State.update(initial_state, {:event, %{key: @space_bar}}) ==
               %{input: " ", user: nil, screen: :create_server, token: "", data: [], menu: false}
    end

    test "should take character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "asdf"})
    end

    test "should create new server and return to :servers screen", %{initial_state: initial_state} do
      assert State.update(
               initial_state,
               {:event, %{key: @enter}}
             ) ==
               %{input: 0, user: nil, screen: :servers, token: "", data: [], menu: false}
    end
  end
end
