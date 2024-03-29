defmodule BlackjackCli.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    Application.ensure_all_started(:ratatouille)

    children = [
      {Registry, keys: :unique, name: Registry.App},
      {Task.Supervisor, name: BlackjackCli.TaskSupervisor},
      BlackjackCli.HttpClientSupervisor.child_spec(:http),
      BlackjackCli.HttpClientSupervisor.child_spec(:ws),
      gui()
    ]

    # IO.inpsect(self(), label: "SELF")
    opts = [strategy: :one_for_one, name: BlackjackCli.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp gui do
    if Mix.env() == :test do
      {Ratatouille.Runtime.Supervisor, runtime: [app: BlackjackCli.App]}
    else
      {Ratatouille.Runtime.Supervisor,
       runtime: [
         app: BlackjackCli.App,
         interval: 100,
         quit_events: [{:key, 0x1B}],
         shutdown: :system
       ]}
    end
  end
end
