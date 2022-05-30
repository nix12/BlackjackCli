defmodule BlackjackCli.Views.StartTest do
  @doctest BlackjackCli.Views.Start.State
  use BlackjackCli.RepoCase, async: true

  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.App.State

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  setup do
    %{initial_state: State.update(state(), {:event, %{}})}
  end

  describe "update/2" do
    test "should move menu select down one when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert State.update(initial_state, {:event, %{key: @down}}) ==
               %{input: 1, user: nil, screen: :start, token: "", data: [], menu: true}
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert input(initial_state, State, %{input: ?s, screen: :start, user: nil}) ==
               %{input: 1, user: nil, screen: :start, token: "", data: [], menu: true}
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert State.update(initial_state, {:event, %{key: @up}}) ==
               %{input: 0, user: nil, screen: :start, token: "", data: [], menu: true}
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert input(%{initial_state | input: 1}, State, %{input: ?w, screen: :start, user: nil}) ==
               %{input: 0, user: nil, screen: :start, token: "", data: [], menu: true}
    end

    test "should change screen to :login when selected and enter is pressed", %{
      initial_state: initial_state
    } do
      assert State.update(initial_state, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :login, token: "", data: [], menu: false}
    end

    test "should change screen to :registration when selected and enter is pressed", %{
      initial_state: initial_state
    } do
      assert State.update(%{initial_state | input: 1}, {:event, %{key: @enter}}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}
    end
  end
end
