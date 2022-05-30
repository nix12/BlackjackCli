defmodule BlackjackCli.Helpers do
  def state do
    %{input: 0, menu: true, user: nil, screen: :start, token: "", data: []}
  end

  def valid_user do
    %{user: %{username: "username", password_hash: "password"}}
  end

  def invalid_user do
    %{user: %{username: "badname", password_hash: "notpassword"}}
  end

  def no_user do
    %{user: %{username: "", password_hash: ""}}
  end

  def input(initial_state, module, override \\ %{})

  def input(initial_state, module, override) when override.input |> is_bitstring do
    state = %{initial_state | input: ""}

    for ch <- override.input |> to_charlist do
      module.update(state, {:event, %{ch: ch}})
    end
    |> Enum.reduce(
      state,
      fn map, acc ->
        Map.merge(acc, map, fn _k, _v1, v2 -> v2 end)
      end
    )
  end

  def input(initial_state, module, override) when override.input |> is_integer do
    charlist = override.input
    state = Map.merge(initial_state, %{override | input: 0})

    module.update(state, {:event, %{ch: charlist}})
  end
end
