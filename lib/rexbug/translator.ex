defmodule Rexbug.Translator do


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
    with {mfag, actions} = split_to_mfag_and_actions!(elixir_code),
         {:ok, quoted} <- Code.string_to_quoted(mfag),
         {:ok, {mfa, guards}} <- split_quoted_into_mfa_and_guards(quoted),
         {:ok, {mfa, arity}} <- split_mfa_into_mfa_and_arity(mfa),
         {:ok, {module, function, args}} <- split_mfa_into_module_function_and_args(mfa),
         {:ok, translated_module} <- translate_module(module),
         {:ok, translated_function} <- translate_function(function),
         translated_actions = translate_actions!(actions)
      do
      translated = "#{translated_module}#{translated_function}#{translated_actions}" |> String.to_charlist()
      {:ok, translated}
    end
  end


  def split_to_mfag_and_actions!(elixir_code) do
    {mfag, actions} =
      case String.split(elixir_code, " :: ", parts: 2) do
        [mfag, actions] -> {mfag, actions}
        [mfag] -> {mfag, ""}
      end

    {String.trim(mfag), String.trim(actions)}
  end


  def split_quoted_into_mfa_and_guards({:when, _line, [mfa, guards]}) do
   {:ok, {mfa, guards}}
  end

  def split_quoted_into_mfa_and_guards(els) do
    {:ok, {els, nil}}
  end


  def split_mfa_into_mfa_and_arity({:"/", _line, [mfa, arity]}) do
    {:ok, {mfa, arity}}
  end

  def split_mfa_into_mfa_and_arity(els) do
    {:ok, {els, nil}}
  end


  def split_mfa_into_module_function_and_args({{:".", _l1, [module, function]}, _l2, args}) do
    {:ok, {module, function, args}}
  end

  def split_mfa_into_module_function_and_args(els) do
    {:ok, {els, nil, nil}}
  end


  def translate_module({:__aliases__, _line, elixir_module}) when is_list(elixir_module) do
    joined = [:Elixir | elixir_module]
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(".")
    {:ok, "'#{joined}'"}
  end

  def translate_module(erlang_mod) when is_atom(erlang_mod) do
    {:ok, Atom.to_string(erlang_mod)}
  end

  def translate_module(module), do: {:error, {:invalid_module, module}}


  def translate_function(nil) do
    {:ok, ""}
  end

  def translate_function(f) when is_atom(f) do
    {:ok, ":'#{Atom.to_string(f)}'"}
  end


  def translate_function(els) do
    {:error, {:invalid_function, els}}
  end


  def translate_actions!(empty) when empty in [nil, ""] do
    ""
  end

  def translate_actions!(actions) when is_binary(actions) do
    " -> #{actions}"
  end

end
