defmodule BlackjackCli.Views.Registration.State do
  @doc """
    Updates registration form state based on key and input actions
    and maintains form state by using an via RegistrationForm
  """
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Registration.RegistrationForm
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

  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        current_tab = RegistrationForm.get_field(:tab_count)

        RegistrationForm.update_field(:tab_count, current_tab + 1)
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

  defp menu do
    [:start, :registration]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  @doc """
    Starts a process for maintianing registration form state
  """
  @spec start_registration :: {:ok, pid()}
  def start_registration do
    {:ok, _} = RegistrationForm.start_link(:ok)
  end

  defp update_errors(message) do
    RegistrationForm.update_field(:errors, message)
  end

  @spec update_user(map()) :: map()
  defp update_user(%{input: input, screen: screen} = model) do
    case RegistrationForm.get_field(:tab_count) do
      0 ->
        RegistrationForm.update_field(:email, input)
        %{model | input: input, screen: screen}

      1 ->
        RegistrationForm.update_field(:username, input)
        %{model | input: input, screen: screen}

      2 ->
        RegistrationForm.update_field(:password, input)
        %{model | input: input, screen: screen}

      3 ->
        RegistrationForm.update_field(:password_confirmation, input)
        %{model | input: input, screen: screen}

      4 ->
        tab_menu(model)

      _ ->
        RegistrationForm.update_field(:tab_count, 0)
        model
    end
  end

  defp register_request(user_params) do
    %{status: status, body: body} = BlackjackCli.register_path(user_params)
    {:ok, status, body}
  end

  defp login_request(user_params) do
    %{body: body, status: status, headers: headers} = BlackjackCli.login_path(user_params)

    {:ok, status, body, headers}
  end

  defp register_verify(model, status, user) do
    user_params = %{
      user: %{
        email: RegistrationForm.get_field(:email),
        username: RegistrationForm.get_field(:username),
        password_hash: RegistrationForm.get_field(:password)
      }
    }

    case status do
      success when success >= 200 and success < 300 ->
        {:ok, _status, body, [{"authorization", "Bearer " <> token} | _headers]} =
          login_request(user_params)

        LoginForm.start_link(:ok)
        RegistrationForm.close_form()

        %{
          model
          | input: 0,
            screen: :menu,
            token: token,
            user: body["current_user"]
        }

      _fail ->
        update_errors(user["errors"])
        %{model | input: "", screen: :registration}
    end
  end

  def register(model) do
    password = RegistrationForm.get_field(:password)
    password_confirmation = RegistrationForm.get_field(:password_confirmation)

    user_params = %{
      user: %{
        email: RegistrationForm.get_field(:email),
        username: RegistrationForm.get_field(:username),
        password_hash: password
      }
    }

    with :ok <- validate_email(user_params.user.email),
         :ok <- validate_username(user_params.user.username),
         :ok <- validate_password(password, password_confirmation),
         {:ok, status, body} <- register_request(user_params) do
      register_verify(model, status, body)
    else
      {:error, message} ->
        update_errors(message)
        %{model | input: model.input, screen: :registration}
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

  defp validate_username(username) do
    case BlackjackCli.blank?(username) do
      true ->
        {:error, "username cannot be blank."}

      _ ->
        :ok
    end
  end

  defp validate_password(password, password_confirmation) do
    case BlackjackCli.blank?(password) or BlackjackCli.blank?(password_confirmation) do
      true ->
        {:error, "password and/or password confirmation cannot be blank."}

      _ ->
        if password == password_confirmation do
          :ok
        else
          {:error, "password and password_confirmation must match."}
        end
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
    case RegistrationForm.get_field(:tab_count) do
      0 ->
        email = RegistrationForm.get_field(:email)

        RegistrationForm.update_field(:email, "")
        update_user(%{model | input: String.slice(email, 0..-2)})

      1 ->
        username = RegistrationForm.get_field(:username)

        RegistrationForm.update_field(:username, "")
        update_user(%{model | input: String.slice(username, 0..-2)})

      2 ->
        password = RegistrationForm.get_field(:password)

        RegistrationForm.update_field(:password, "")
        update_user(%{model | input: String.slice(password, 0..-2)})

      3 ->
        password_confirmation = RegistrationForm.get_field(:password_confirmation)

        RegistrationForm.update_field(:password_confirmation, "")
        update_user(%{model | input: String.slice(password_confirmation, 0..-2)})
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

  defp enter(model) do
    case model.menu do
      false ->
        register(model)

      _ ->
        if match_menu(model) == :registration do
          register(model)
        else
          %{model | screen: match_menu(model), input: ""}
        end
    end
  end
end
