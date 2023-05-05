defmodule BlackjackCli.HttpClientSupervisor do
  use DynamicSupervisor

  alias BlackjackCli.HttpClient

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, [strategy: :one_for_one, shutdown: 1000],
      name: __MODULE__
    )
  end

  def child_spec(protocol) do
    %{
      id: "#{protocol}_client" |> String.to_atom(),
      start: {HttpClient, :start_link, [protocol]},
      type: :worker,
      restart: :transient
    }
  end

  @impl true
  def init(args) do
    DynamicSupervisor.init(args)
  end
end
