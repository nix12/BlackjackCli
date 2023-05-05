defmodule BlackjackCli.Views.Friends do
  import Ratatouille.View

  alias BlackjackCli.Views.Friends.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    %{"friends" => friends} = model.data

    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "FRIENDS", height: 10 do
              viewport offset_y: scroll(model) do
                if friends == [] do
                  label(content: "No friends found.")
                else
                  render_friends(model, friends)
                end
              end
            end
          end

          column size: 8 do
            panel title: "USER DETAILS", height: 10 do
              friends
              |> Enum.sort_by(
                &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
                {:asc, NaiveDateTime}
              )
              |> Enum.with_index(fn %{
                                      "id" => id,
                                      "username" => username
                                    },
                                    index ->
                if model.input == index do
                  [
                    label(content: "id: #{id}"),
                    label(content: "username: #{username}")
                  ]
                end
              end)
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
    ["Find User", "Add Friend", "Back"]
  end

  def render_friends(model, friends) do
    if model.menu == false do
      friends
      |> Enum.sort_by(
        &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
        {:asc, NaiveDateTime}
      )
      |> Enum.slice(
        max(model.input - length(friends), 0),
        min(model.input + 7, length(friends))
      )
      |> Enum.with_index(fn %{"username" => username}, index ->
        if model.input == index do
          label(
            content: "#{username}",
            background: :white,
            color: :black
          )
        else
          label(content: "#{username}")
        end
      end)
    else
      friends
      |> Enum.sort_by(
        &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
        {:asc, NaiveDateTime}
      )
      |> Enum.slice(0, 7)
      |> Enum.map(fn %{"username" => username} ->
        label(content: "#{username}")
      end)
    end
  end
end
