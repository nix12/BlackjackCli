defmodule BlackjackCli.Views.FriendRequest do
  import Ratatouille.View

  alias BlackjackCli.Views.FriendRequest.State
  alias BlackjackCli.Views.FriendRequest.FriendRequestForm

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        if model.data |> Map.has_key?(:notice) do
          row do
            column size: 12 do
              panel title: "NOTICE" do
                label do
                  text(content: model.data.notice)
                end
              end
            end
          end
        else
          nil
        end

        row do
          column size: 12 do
            panel title: "FRIEND REQUEST | ENTER AN ID OR USERNAME" do
              label do
                text(content: FriendRequestForm.get_field(:requested_user))

                if !model.menu do
                  text(content: "W", color: :white, background: :white)
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

  def menu do
    ["Submit", "Back"]
  end
end
