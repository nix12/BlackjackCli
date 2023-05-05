defmodule BlackjackCli.Views.Server.State do
  require Logger

  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  def update(model, msg) do
    case msg do
      {:event, %{"server" => _} = server} ->
        # IO.puts("RECEIVED SERVER UPDATE SIGNAL")
        %{model | data: server}

      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})

      {:event, %{key: @down}} ->
        if model.menu == true do
          %{model | input: min(model.input + 1, length(menu()) - 1)}
        else
          update_cmd(%{
            model
            | input: min(model.input + 1, length(model.data) - 1)
          })
        end

      {:event, %{ch: ?s}} ->
        update_cmd(%{
          model
          | input: min(model.input + 1, length(model.data) - 1)
        })

      {:event, %{key: @up}} ->
        if model.menu == true do
          %{model | input: max(model.input - 1, 0)}
        else
          update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})
        end

      {:event, %{key: @enter}} ->
        if model.menu == false do
          # FETCH LIST OF TABLES
          # JOIN TABLE HERE

          %{model | screen: :server, data: []}
        else
          %{"server" => %{"server_name" => server_name}} = model.data
          BlackjackCli.leave_server(model.user, server_name, model.token)
          servers = BlackjackCli.get_servers(model.token)

          %{model | screen: match_menu(model), input: 0, data: servers}
        end

      _ ->
        model
    end
  end

  defp menu do
    [:create_table, :find_table, :servers]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  defp update_cmd(model) do
    # Setup to list tables
    list_servers =
      if Enum.count(model.data) > 0 and model.menu == false do
        %{data: %{body: body}} = BlackjackCli.get_servers(model.token)

        body
      else
        []
      end

    Command.new(fn -> list_servers end, :servers_updated)

    model
  end

  defp switch_menus(model) do
    %{model | menu: !model.menu}
  end
end
