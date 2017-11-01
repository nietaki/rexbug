defmodule Rexbug.Translator do

  @valid_actions [:return, :stack]

  {:ok,
    {:when, [line: 44], [
      {
        {:., [line: 44], [
            {:__aliases__, [line: 44], [:Mainframe, :Server]},
            :foo
          ]
        },
        [line: 44], [
          1, :atom, {:a, [line: 44], nil}
        ]
      },
      {:and, [line: 44], [
          {:<, [line: 44], [{:a, [line: 44], nil}, 1]}, true]}]}}

  #===========================================================================
  # Public Functions
  #===========================================================================

  @spec translate(elixir_code :: String.t) :: {:ok, charlist} | {:error, atom}

  def translate(elixir_code) do
    with {:ok, quoted} <- Code.string_to_quoted(elixir_code),
         {:ok, translated_erlang_string} <- translate_quoted(quoted),
    do: {:ok, String.to_charlist(translated_erlang_string)}
  end

  #---------------------------------------------------------------------------
  # Actions
  #---------------------------------------------------------------------------

  @type action :: :return | :stack
  @spec translate_actions([action] | action) :: {:ok, charlist} | {:error, atom}

  def translate_actions(action) when action in [:return, :stack] do
    translate_actions([action])
  end

  def translate_actions(falsy) when falsy in [nil, false] do
    translate_actions([])
  end

  def translate_actions([]) do
    {:ok, ''}
  end

  def translate_actions(actions) when is_list(actions) do
    if Enum.all?(actions, &(&1 in @valid_actions)) do
      translated = actions
      |> Enum.uniq()
      |> Enum.map(&Atom.to_string/1)
      |> Enum.join(";")
      |> String.to_charlist()
      |> prepend_arrow()

      {:ok, translated}
    else
      {:error, :invalid_actions}
    end
  end

  def translate_actions(_), do: {:error, :invalid_actions}


  #---------------------------------------------------------------------------
  # Main translation
  #---------------------------------------------------------------------------

  ## top-level dispatcher
  def translate_quoted({{:., _line1, _modfun}, _line2, _args} = quoted) do
    translate_modfun(quoted)
  end


  def translate_modfun({{:., _line1, [mod, fun]}, _line2, args}) do
    # TODO look at the args
    with {:ok, mod_str} <- translate_mod(mod),
         {:ok, fun_str} <- translate_fun(fun)
    do
      {:ok, "#{mod_str}:#{fun_str}"}
    end
  end

  def translate_mod({:__aliases__, _line, elixir_module}) when is_list(elixir_module) do
    joined = [:Elixir | elixir_module]
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(".")
    {:ok, "'#{joined}'"}
  end

  def translate_mod(erlang_mod) when is_atom(erlang_mod) do
    {:ok, Atom.to_string(erlang_mod)}
  end


  def translate_fun(f) when is_atom(f) do
    {:ok, "'#{Atom.to_string(f)}'"} # TODO add quotes
  end

  #---------------------------------------------------------------------------
  # Internal Functions
  #---------------------------------------------------------------------------

  @spec prepend_arrow(action_spec :: charlist) :: charlist
  defp prepend_arrow(action_spec) do
    ' -> ' ++ action_spec
  end

end
