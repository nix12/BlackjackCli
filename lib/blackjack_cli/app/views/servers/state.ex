defmodule BlackjackCli.Views.Servers.State do
  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  @spec update(any, any) :: any
  def update(model, msg) do
    servers =
      model.data.body["servers"]
      |> Enum.sort_by(
        &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
        {:asc, NaiveDateTime}
      )

    case msg do
      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        update_cmd(%{model | input: max(model.input - 1, 0)})

      {:event, %{key: @down}} ->
        if model.menu do
          %{
            model
            | input: min(model.input + 1, length(menu()) - 1)
          }
        else
          update_cmd(%{
            model
            | input: min(model.input + 1, length(servers) - 1)
          })
        end

      {:event, %{ch: ?s}} ->
        update_cmd(%{
          model
          | input: min(model.input + 1, length(servers) - 1)
        })

      {:event, %{key: @up}} ->
        if model.menu do
          %{model | input: max(model.input - 1, 0)}
        else
          update_cmd(%{model | input: max(model.input - 1, 0)})
        end

      {:event, %{key: @enter}} ->
        if model.menu == false do
          %{"server_name" => server_name} = match_servers(servers, model.input)

          %{
            model
            | screen: :server,
              data: BlackjackCli.join_server(model.user, server_name, model.token)
          }
        else
          case match_menu(model) do
            :menu ->
              %{model | screen: match_menu(model), input: 0}

            _ ->
              %{model | screen: match_menu(model), input: ""}
          end
        end

      _ ->
        model
    end
  end

  defp menu do
    [:create_server, :find_server, :menu]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  defp match_servers(servers, index) do
    servers
    |> Enum.find(fn server ->
      servers |> Enum.at(index) == server
    end)
  end

  defp update_cmd(model) do
    # IO.inpsect(label: "GET SERVERS")
    servers = model.data
    # BlackjackCli.get_servers()

    list_servers =
      if Enum.count(servers) > 0 and model.menu == false do
        servers
      else
        []
      end

    Command.new(fn -> list_servers end, :servers_updated)

    model
  end

  def switch_menus(model) do
    %{model | menu: !model.menu}
  end
end
