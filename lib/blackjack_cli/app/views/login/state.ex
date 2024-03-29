defmodule BlackjackCli.Views.Login.State do
  @moduledoc """
    Updates the terminal view of the login view.
  """
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Login.LoginForm

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)
  @up key(:arrow_up)
  @down key(:arrow_down)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  @type model() :: Map.t()
  @type event() :: {atom(), map()}

  @doc """
    Takes a model and an event to evaluate and update login view.
  """
  @spec update(model(), event()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        current_tab = LoginForm.get_field(:tab_count)

        LoginForm.update_field(:tab_count, current_tab + 1)
        update_user(model)

      {:event, %{key: key}} when key in @delete_keys ->
        delete_input(model)

      {:event, %{key: @space_bar}} ->
        update_user(%{
          model
          | input: (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <> " "
        })

      {:event, %{ch: ch}} when ch > 0 ->
        ch_input(model, ch)

      {:event, %{ch: ?w}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{key: @up}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{ch: ?s}} ->
        %{model | input: min(model.input + 1, length(menu()) - 1)}

      {:event, %{key: @down}} ->
        %{model | input: min(model.input + 1, length(menu()) - 1)}

      {:event, %{key: @enter}} ->
        enter(model)

      _ ->
        update_user(model)
    end
  end

  def start_login do
    LoginForm.start_link(:ok)
  end

  defp menu do
    [:start, :login]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  defp update_user(%{input: input, screen: screen} = model) do
    case LoginForm.get_field(:tab_count) do
      0 ->
        LoginForm.update_field(:email, input)
        %{model | input: input, screen: screen}

      1 ->
        LoginForm.update_field(:password, input)
        %{model | input: input, screen: screen}

      2 ->
        tab_menu(model)

      _ ->
        LoginForm.update_field(:tab_count, 0)
        model
    end
  end

  defp login_request(user_params) do
    %{headers: headers, status: status} = BlackjackCli.login_path(user_params)
    # IO.inpsect(headers, label: "RESPONSE")
    {:ok, status, headers}
  end

  defp login_verify(model, status, [{"authorization", "Bearer " <> token} | _headers]) do
    case status do
      status when status >= 200 and status < 300 ->
        LoginForm.close_form()

        current_user =
          for(binary <- token |> decode(), do: <<binary::utf8>>)
          |> Enum.join()
          |> Jason.decode!()

        BlackjackCli.connect_user(current_user["user"], token)

        %{
          model
          | screen: :menu,
            token: token,
            input: 0,
            user: current_user["user"],
            menu: true
        }

      _ ->
        #        LoginForm.update_field(:errors, resource["errors"])
        %{model | screen: :login, token: ""}
    end
  end

  defp login(model) do
    user_params = %{
      user: %{
        email: LoginForm.get_field(:email),
        password_hash: LoginForm.get_field(:password)
      }
    }

    with :ok <- validate_email(user_params.user.email),
         :ok <- validate_password(user_params.user.password_hash),
         {:ok, status, headers} <- login_request(user_params) do
      login_verify(model, status, headers)
    else
      {:error, message} ->
        LoginForm.update_field(:errors, message)
        update_user(%{model | input: model.input, screen: :login})
    end
  end

  defp validate_email(email) do
    case BlackjackCli.blank?(email) do
      true ->
        {:error, "email cannot be blank."}

      _ ->
        :ok
    end
  end

  defp validate_password(password) do
    case BlackjackCli.blank?(password) do
      true ->
        {:error, "password cannot be blank."}

      _ ->
        :ok
    end
  end

  defp ch_input(model, ch) do
    case model.input do
      0 ->
        # Changes the input from integer to empty string to be operated on for input.
        update_user(%{model | input: "" <> <<ch::utf8>>})

      input ->
        # replace_prefix is meant to clear the string before each character input.
        update_user(%{model | input: String.replace_prefix(input, input, "") <> <<ch::utf8>>})
    end
  end

  @spec delete_input(map()) :: map()
  defp delete_input(model) do
    case LoginForm.get_field(:tab_count) do
      0 ->
        email = LoginForm.get_field(:email)

        LoginForm.update_field(:email, "")
        update_user(%{model | input: String.slice(email, 0..-2)})

      1 ->
        password = LoginForm.get_field(:password)

        LoginForm.update_field(:password, "")
        update_user(%{model | input: String.slice(password, 0..-2)})

      2 ->
        password_confirmation = LoginForm.get_field(:password_confirmation)

        LoginForm.update_field(:password_confirmation, "")
        update_user(%{model | input: String.slice(password_confirmation, 0..-2)})
    end
  end

  defp enter(model) do
    case model.menu do
      false ->
        login(model)

      _ ->
        if match_menu(model) == :login do
          login(model)
        else
          %{model | screen: match_menu(model), input: 0}
        end
    end
  end

  defp tab_menu(model) do
    case model.menu do
      true ->
        %{model | menu: false, input: ""}

      _ ->
        %{model | menu: true, input: 0}
    end
  end

  defp decode(token) do
    token
    |> String.split(".")
    |> Enum.at(1)
    |> String.replace("-", "+", global: true)
    |> String.replace("_", "/", global: true)
    |> Base.decode64!(padding: false)
    |> :binary.bin_to_list()
  end
end
