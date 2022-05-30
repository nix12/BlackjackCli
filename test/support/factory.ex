defmodule BlackjackCli.Factory do
  use ExMachina

  def user_factory(attrs \\ %{}) do
    user = %{
      user: %{
        username: sequence("username"),
        password_hash: "password"
      }
    }

    user
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def server_factory(attrs \\ %{}) do
    server = %{
      server_name: sequence(:server_name, &"test_server-#{&1}"),
      table_count: 0,
      player_count: 0
    }

    server
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
