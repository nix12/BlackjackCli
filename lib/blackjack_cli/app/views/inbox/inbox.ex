defmodule BlackjackCli.Views.Inbox do
  import Ratatouille.View

  alias BlackjackCli.Views.Inbox.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    %{"messages" => messages} = model.data

    view do
      panel title: "BLACKJACK" do
        if model |> Map.has_key?(:show_communication) and model.show_communication do
          %{"messages" => %{"body" => %{"scroll_body" => body}, "inserted_at" => inserted_at}} =
            model.data["messages"]

          row do
            column size: 12 do
              panel title: get_communication_title(model, model.data), height: 10 do
                viewport offset_y: scroll(model) do
                  label(content: "Timestamp: #{inserted_at}\nMessage: #{body}")
                end
              end
            end
          end
        else
          row do
            column size: 12 do
              panel title: "INBOX", height: 10 do
                viewport offset_y: scroll(model) do
                  if messages == [] do
                    label(content: "No messages found.")
                  else
                    render_communications(model, messages)
                  end
                end
              end
            end
          end
        end

        row do
          column size: 12 do
            panel title: "ACTIONS", height: 8 do
              for {option, i} <- menu() |> Enum.with_index() do
                if model.input == i and model.menu do
                  label(content: "#{i + 1}) #{option}", background: :white, color: :black)
                else
                  label(content: "#{i + 1}) #{option}")
                end
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

  def menu do
    ["All Messages", "List Conversations", "View Notifications", "Send Messages", "Back"]
  end

  def render_communications(model, messages) do
    if model.menu == false do
      messages
      |> Enum.sort_by(
        &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
        {:asc, NaiveDateTime}
      )
      |> Enum.slice(
        max(model.input - length(messages), 0),
        min(model.input + 7, length(messages))
      )
      |> Enum.with_index(fn %{"from" => from}, index ->
        if model.input == index do
          label(
            content: "#{from}",
            background: :white,
            color: :black
          )
        else
          label(content: "#{from}")
        end
      end)
    else
      messages
      |> Enum.sort_by(
        &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
        {:asc, NaiveDateTime}
      )
      |> Enum.slice(0, 7)
      |> Enum.map(fn %{"from" => from} ->
        label(content: "#{from}")
      end)
    end
  end

  defp get_communication_title(_model, %{"from" => from}), do: from
end
