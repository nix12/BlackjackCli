defmodule BlackjackCli.Views.Server do
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Server.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "TABLES", height: 10 do
              viewport offset_y: scroll(model) do
                if model.input == 0 and model.menu == false do
                  label(content: "LIST OF TABLES", background: :white, color: :black)
                else
                  label(content: "LIST OF TABLES")
                end

                # if model.menu == false do
                #   [model.data["server"]]
                #   # |> IO.inpsect()
                #   |> Enum.slice(
                #     max(model.input - length([model.data["server"]]), 0),
                #     min(model.input + 7, length([model.data["server"]]))
                #   )
                #   |> Enum.with_index(fn %{"server_name" => server_name}, index ->
                #     if model.input == index do
                #       label(
                #         content: "#{server_name}",
                #         background: :white,
                #         color: :black
                #       )
                #     else
                #       label(content: "#{server_name}")
                #     end
                #   end)
                # else
                #   [model.data["server"]]
                #   |> Enum.slice(0, 7)
                #   |> Enum.map(fn %{"server_name" => server_name} ->
                #     label(content: "#{server_name}")
                #   end)
                # end
              end
            end
          end

          column size: 8 do
            panel title: "SERVER", height: 10 do
              Enum.map(
                [model.data["server"]],
                fn %{
                     "server_name" => server_name,
                     "user_id" => user_id,
                     "player_count" => player_count,
                     "table_count" => table_count
                   } ->
                  [
                    label(content: "Server Name: #{server_name}"),
                    label(content: "Owner ID: #{user_id}"),
                    label(content: "Player Count: #{player_count}"),
                    label(content: "Table Count: #{table_count}")
                  ]
                end
              )
            end
          end
        end

        row do
          column size: 12 do
            panel title: "ACTIONS" do
              if model.input == 0 and model.menu == true do
                label(content: "Create Table", background: :white, color: :black)
              else
                label(content: "Create Table")
              end

              if model.input == 1 and model.menu == true do
                label(content: "Find Table", background: :white, color: :black)
              else
                label(content: "Find Table")
              end

              if model.input == 2 and model.menu == true do
                label(content: "Back", background: :white, color: :black)
              else
                label(content: "Back")
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
end
