defmodule BlackjackCli.Views.Servers do
  import Ratatouille.View

  alias BlackjackCli.Views.Servers.State

  def update(model, msg) do
    State.update(model, msg)
  end

  def render(model) do
    %{"servers" => servers} =
      model.data
      |> Keyword.new()
      # |> IO.inpsect(label: "MODEL DATA")
      |> search_map([], "servers")

    # |> IO.inpsect(label: "MODEL DATA")

    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "SERVERS", height: 10 do
              viewport offset_y: scroll(model) do
                if model.menu == false do
                  servers
                  |> Enum.sort_by(
                    &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
                    {:asc, NaiveDateTime}
                  )
                  |> Enum.slice(
                    max(model.input - length(servers), 0),
                    min(model.input + 7, length(servers))
                  )
                  |> Enum.with_index(fn %{"server_name" => server_name}, index ->
                    if model.input == index do
                      label(
                        content: "#{server_name}",
                        background: :white,
                        color: :black
                      )
                    else
                      label(content: "#{server_name}")
                    end
                  end)
                else
                  servers
                  |> Enum.sort_by(
                    &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
                    {:asc, NaiveDateTime}
                  )
                  |> Enum.slice(0, 7)
                  |> Enum.map(fn %{"server_name" => server_name} ->
                    label(content: "#{server_name}")
                  end)
                end
              end
            end
          end

          column size: 8 do
            panel title: "SERVER INFO", height: 10 do
              # if model.menu == false do

              servers
              |> Enum.sort_by(
                &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
                {:asc, NaiveDateTime}
              )
              |> Enum.with_index(fn %{
                                      "server_name" => server_name,
                                      "player_count" => player_count,
                                      "table_count" => table_count
                                    },
                                    index ->
                if model.input == index do
                  [
                    label(content: "server_name: #{server_name}"),
                    label(content: "player_count: #{player_count}"),
                    label(content: "table_count: #{table_count}")
                  ]
                end
              end)

              # else
              #   Enum.with_index(
              #     model.data["servers"],
              #     fn %{
              #          "server_name" => server_name,
              #          "player_count" => player_count,
              #          "table_count" => table_count
              #        },
              #        index ->
              #       if 0 == index do
              #         [
              #           label(content: "server_name: #{server_name}"),
              #           label(content: "player_count: #{player_count}"),
              #           label(content: "table_count: #{table_count}")
              #         ]
              #       end
              #     end
              #   )
              # end
            end
          end
        end

        row do
          column size: 12 do
            panel title: "ACTIONS", height: 8 do
              if model.input == 0 and model.menu == true do
                label(content: "Create Server", background: :white, color: :black)
              else
                label(content: "Create Server")
              end

              if model.input == 1 and model.menu == true do
                label(content: "Find Server", background: :white, color: :black)
              else
                label(content: "Find Server")
              end

              if model.input == 2 and model.menu == true do
                label(content: "Main Menu", background: :white, color: :black)
              else
                label(content: "Main Menu")
              end
            end
          end
        end
      end
    end
  end

  defp scroll(model) do
    if model.menu == false do
      model.input
    end
  end

  defp search_map([map | enum], _acc, key) do
    case map do
      {^key, _} = servers ->
        # IO.puts("CATCH ALL")
        [servers] |> Map.new()

      {_k, v} when v |> is_map() ->
        # IO.puts("IS MAP")

        if v |> Map.has_key?(key) do
          search_map(v |> Map.to_list(), v, key)
        else
          search_map(enum, enum, key)
        end
    end
  end

  defp search_map(map, [], key) do
    if Map.has_key?(map, key), do: map |> Map.new(), else: :no_match
  end
end
