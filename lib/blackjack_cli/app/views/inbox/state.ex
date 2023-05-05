defmodule BlackjackCli.Views.Inbox.State do
  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  @type model() :: Map.t()
  @type event() :: {atom(), map()}

  @doc """
     Takes a model and an event to evaluate and update menu view.
  """
  @spec update(model(), event()) :: map()
  def update(model, msg) do
    communications =
      model.data["messages"]
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
            | input: min(model.input + 1, length(communications) - 1)
          })
        end

      {:event, %{ch: ?s}} ->
        update_cmd(%{
          model
          | input: min(model.input + 1, length(communications) - 1)
        })

      {:event, %{key: @up}} ->
        if model.menu do
          %{model | input: max(model.input - 1, 0)}
        else
          update_cmd(%{model | input: max(model.input - 1, 0)})
        end

      {:event, %{key: @enter}} ->
        case model.menu do
          true ->
            %{model | screen: match_screen(model.input), menu: false}
            |> Map.merge(menu_actions(model))

          false ->
            %{model | screen: match_screen(model.input), menu: false}
            |> Map.merge(show_communication(model))
        end

      _ ->
        model
    end
  end

  defp menu do
    [:all_messages, :list_conversations, :view_notifications, :send_messages, :back]
  end

  defp match_screen(index) do
    Enum.find(menu(), &(menu() |> Enum.at(index) == &1))
  end

  def switch_menus(model) do
    %{model | menu: !model.menu}
  end

  def menu_actions(%{input: input} = model) do
    case match_screen(input) do
      :all_messages ->
        %{model | screen: :inbox, data: BlackjackCli.get_inbox(:all)}

      :list_conversations ->
        %{model | input: 0, screen: :inbox, data: BlackjackCli.get_inbox(:conversations)}
        |> merge_body()

      :view_notifications ->
        %{model | screen: :inbox, data: BlackjackCli.get_inbox(:notifications)}

      :send_messages ->
        nil

      :back ->
        %{model | input: :menu}
    end
  end

  def show_communication(model) do
    if model |> Map.has_key?(:show_communication) == false do
      %{model | data: render_communication(model, model.data["messages"])}
      |> Map.merge(%{show_communication: true})
    else
      model |> Map.drop([:show_communication])
    end
  end

  def render_communication(model, messages) do
    messages
    |> Enum.sort_by(
      &(&1["messages"]["inserted_at"] |> NaiveDateTime.from_iso8601!()),
      {:asc, NaiveDateTime}
    )
    |> Enum.slice(0, 7)
    |> Enum.at(model.input)
  end

  # Hiding the text should go by line or batch.
  defp update_cmd(model) do
    Command.new(
      fn -> model |> scroll_body() |> IO.puts() end,
      :scroll_communication
    )

    model
  end

  def merge_body(model) do
    data =
      model.data["messages"]
      |> Enum.flat_map(fn message ->
        message
      end)
      |> IO.inspect()

    %{model | data: data}
  end

  def scroll_body(model) do
    %{"messages" => %{"body" => %{"full_body" => full_body}}} =
      model.data["messages"] |> Enum.at(model.input)

    scroll_body = model |> transform_body() |> to_string()

    put_in(model, [:data, "messages", Access.all(), "messages"], %{
      "body" => %{
        "full_body" => full_body,
        "scroll_body" => scroll_body
      }
    })
    |> IO.inspect(label: "SOMETHING")
  end

  def decipher_body(communication) do
    case Map.has_key?(communication, "scroll_body") do
      true ->
        %{"scroll_body" => _} = scroll_body = communication

        scroll_body

      false ->
        %{"messages" => %{"body" => _} = body} = communication

        body
    end
  end

  def split_body(body_type) do
    IO.inspect(body_type, label: "BODY TYPE")

    case match?(%{"body" => %{"full_body" => _}}, body_type) do
      true ->
        %{"body" => %{"full_body" => full_body}} = body_type

        full_body |> IO.inspect(label: "BODY TYPE TRUE") |> String.split(" ")

      false ->
        %{"body" => body} = body_type

        body |> String.split(" ")
    end
  end

  def transform_body(model) do
    model.data["messages"]
    |> IO.inspect(label: "1")
    |> sort_messages()
    |> IO.inspect(label: "2")
    |> Enum.at(model.input)
    |> IO.inspect(label: "3")
    |> decipher_body()
    |> IO.inspect(label: "4")
    |> split_body()
    |> IO.inspect(label: "5")
    |> Enum.chunk_every(15)
    |> IO.inspect(label: "6")
    |> Enum.map(&Enum.join(&1, " "))
    |> IO.inspect(label: "7")
    |> then(fn lines ->
      lines
      |> Enum.slice(
        max(model.input - length(lines), 0),
        min(model.input + 6, length(lines))
      )
    end)
  end

  def sort_messages(messages) do
    Enum.sort_by(
      messages,
      &(&1["inserted_at"] |> NaiveDateTime.from_iso8601!()),
      {:asc, NaiveDateTime}
    )
  end
end
