defmodule BlackjackCli.GuiServer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def update_model(model) do
    GenServer.call(GuiServer, {:update_model, model})
  end

  def current_model do
    GenServer.call(GuiServer, {:current_model})
  end

  @impl true
  def init(_) do
    initial_state = %{
      input: 0,
      menu: true,
      user: nil,
      screen: :start,
      key: nil,
      data: []
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:update_model, model}, _from, gui) do
    new_model = Map.merge(gui, model, fn _k, v1, v2 -> v2 end)

    {:reply, new_model, new_model}
  end

  @impl true
  def handle_call({:current_model}, _from, gui) do
    {:reply, gui, gui}
  end

  @impl true
  def handle_info({:subscribe_server, model}, gui) do
    new_model = Map.merge(gui, model, fn _k, _v1, v2 -> v2 end)
    BlackjackCli.App.State.update(new_model, {:event, :subscribe_server})

    {:noreply, new_model}
  end
end
