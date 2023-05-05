defmodule BlackjackCli.Views.Menu do
  import Ratatouille.View

  alias BlackjackCli.Views.Menu.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 6 do
            panel do
              label do
                text(content: "USERNAME: " <> (model.user["username"] |> to_string()))
              end
            end
          end

          column size: 6 do
            panel do
              label do
                text(content: "CURRENCY: N/A")
              end
            end
          end
        end

        for {option, i} <- menu() |> Enum.with_index() do
          if model.input == i do
            label(content: "#{i + 1}) #{option}", background: :white, color: :black)
          else
            label(content: "#{i + 1}) #{option}")
          end
        end
      end
    end
  end

  defp menu,
    do: ["Servers", "Search", "Friends", "Inbox", "Account", "Settings", "Exit"]
end
