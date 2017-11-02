defmodule Rexbug.Translator do

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
         {:ok, translated_args} <- translate_args(args),
         {:ok, translated_arity} <- translate_arity(arity),
         translated_actions = translate_actions!(actions)
      do
      translated =
        case translated_arity do
          :any ->
            # no args, no arity
            "#{translated_module}#{translated_function}#{translated_actions}"
          arity when is_integer(arity) ->
            # no args, arity present
            "#{translated_module}#{translated_function}/#{arity}#{translated_actions}"
          nil ->
            # args present, no arity
            "#{translated_module}#{translated_function}#{translated_args}#{translated_actions}"
        end
      {:ok, String.to_charlist(translated)}
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


  def translate_args(nil), do: {:ok, ""}

  def translate_args(args) when is_list(args) do
    translated = Enum.map(args, &translate_arg/1)
    first_error = Enum.find(translated, :no_error, fn(res) -> !match?({:ok, _}, res) end)
    case first_error do
      :no_error ->
        string_args = translated
        |> Enum.map(fn {:ok, res} -> res end)
        |> Enum.join(", ")

        {:ok, "(#{string_args})"}
      err -> err
    end
  end

  def translate_args(els) do
    {:error, {:invalid_args, els}}
  end


  def translate_arg(arg) do
    {:error, :not_implemented}
  end


  def translate_arity({var, [line: 1], nil}) when is_atom(var) do
    {:ok, :any}
  end

  def translate_arity(i) when is_integer(i) do
    {:ok, i}
  end

  def translate_arity(none) when none in [nil, ""] do
    {:ok, nil}
  end

  def translate_arity(els) do
    {:error, {:invalid_arity, els}}
  end


  def translate_actions!(empty) when empty in [nil, ""] do
    ""
  end

  def translate_actions!(actions) when is_binary(actions) do
    " -> #{actions}"
  end

end
