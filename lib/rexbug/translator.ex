defmodule Rexbug.Translator do
  @moduledoc """
  Utility module for translating Elixir syntax to the one expected by
  `:redbug`.

  You probably don't need to use it directly.
  """

  @valid_guard_functions [
    :is_atom,
    :is_binary,
    :is_bitstring,
    :is_boolean,
    :is_float,
    :is_function,
    :is_integer,
    :is_list,
    :is_map,
    :is_nil,
    :is_number,
    :is_pid,
    :is_port,
    :is_reference,
    :is_tuple,
    :abs,
    :bit_size,
    :byte_size,
    :hd,
    :length,
    :map_size,
    :round,
    :tl,
    :trunc,
    :tuple_size,

    # erlang guard
    :size
  ]

  @infix_guards_mapping %{
    # comparison
    :== => :==,
    :!= => :"/=",
    :=== => :"=:=",
    :!== => :"=/=",
    :> => :>,
    :>= => :>=,
    :< => :<,
    :<= => :"=<"
  }

  @valid_infix_guards Map.keys(@infix_guards_mapping)

  @infix_guard_combinators_mapping %{
    :and => :andalso,
    :or => :orelse
  }

  @valid_infix_guard_combinators Map.keys(@infix_guard_combinators_mapping)

  # ===========================================================================
  # Public functions
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # Translating trace pattern
  # ---------------------------------------------------------------------------

  @spec translate(Rexbug.trace_pattern()) ::
          {:ok, charlist | atom} | {:ok, [charlist | atom]} | {:error, term}
  @doc """
  Translates the Elixir trace pattern(s) (understood by Rexbug) to the
  Erlang trace pattern charlist(s) understood by `:redbug`.

  The translated version is not necessarily the cleanest possible, but should
  be correct and functionally equivalent.

  ## Example
      iex> import Rexbug.Translator
      iex> translate(":cowboy.start_clear/3")
      {:ok, '\\'cowboy\\':\\'start_clear\\'/3'}
      iex> translate("MyModule.do_sth(_, [pretty: true])")
      {:ok, '\\'Elixir.MyModule\\':\\'do_sth\\'(_, [{\\'pretty\\', true}])'}
  """

  def translate(s) when s in [:send, "send"], do: {:ok, :send}
  def translate(r) when r in [:receive, "receive"], do: {:ok, :receive}

  def translate(patterns) when is_list(patterns) do
    patterns
    |> Enum.map(&translate/1)
    |> collapse_errors()
  end

  def translate(trace_pattern) when is_binary(trace_pattern) do
    with {mfag, actions} = split_to_mfag_and_actions!(trace_pattern),
         {:ok, quoted} <- Code.string_to_quoted(mfag),
         {:ok, {mfa, guards}} = split_quoted_into_mfa_and_guards(quoted),
         {:ok, {mfa, arity}} = split_mfa_into_mfa_and_arity(mfa),
         {:ok, {module, function, args}} = split_mfa_into_module_function_and_args(mfa),
         :ok <- validate_mfaa(module, function, args, arity),
         {:ok, translated_module} <- translate_module(module),
         {:ok, translated_function} <- translate_function(function),
         {:ok, translated_args} <- translate_args(args),
         {:ok, translated_arity} <- translate_arity(arity),
         {:ok, translated_guards} <- translate_guards(guards),
         translated_actions = translate_actions!(actions) do
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
            "#{translated_module}#{translated_function}#{translated_args}#{translated_guards}#{
              translated_actions
            }"
        end

      {:ok, String.to_charlist(translated)}
    end
  end

  def translate(_), do: {:error, :invalid_trace_pattern_type}

  @doc false
  def split_to_mfag_and_actions!(trace_pattern) do
    {mfag, actions} =
      case String.split(trace_pattern, " ::", parts: 2) do
        [mfag, actions] -> {mfag, actions}
        [mfag] -> {mfag, ""}
      end

    {String.trim(mfag), String.trim(actions)}
  end

  @spec translate_guards(term) :: {:ok, String.t()} | {:error, term}
  defp translate_guards(nil), do: {:ok, ""}

  defp translate_guards(els) do
    _translate_guards(els)
    |> map_success(fn guards -> " when #{guards}" end)
  end

  # ---------------------------------------------------------------------------
  # Translating options
  # ---------------------------------------------------------------------------

  @spec translate_options(Keyword.t()) :: {:ok, Keyword.t()} | {:error, term}
  @doc """
  Translates the options to be passed to `Rexbug.start/2` to the format expected by
  `:redbug`

  Relevant values passed as strings will be converted to charlists.
  """

  def translate_options(options) when is_list(options) do
    options
    |> Enum.map(&translate_option/1)
    |> collapse_errors()
  end

  def translate_options(_), do: {:error, :invalid_options}

  # ===========================================================================
  # Private functions
  # ===========================================================================

  @binary_to_charlist_options [:file, :print_file]

  defp translate_option({file_option, filename})
       when file_option in @binary_to_charlist_options and is_binary(filename) do
    {:ok, {file_option, String.to_charlist(filename)}}
  end

  defp translate_option({k, v}) do
    {:ok, {k, v}}
  end

  defp translate_option(_), do: {:error, :invalid_options}

  @spec collapse_errors([{:ok, term} | {:error, term}]) :: {:ok, [term]} | {:error, term}
  defp collapse_errors(tuples) do
    # we could probably play around with some monads for this
    first_error = Enum.find(tuples, :no_error_to_collapse, fn res -> !match?({:ok, _}, res) end)

    case first_error do
      :no_error_to_collapse ->
        results = Enum.map(tuples, fn {:ok, res} -> res end)
        {:ok, results}

      err ->
        err
    end
  end

  defp split_quoted_into_mfa_and_guards({:when, _line, [mfa, guards]}) do
    {:ok, {mfa, guards}}
  end

  defp split_quoted_into_mfa_and_guards(els) do
    {:ok, {els, nil}}
  end

  defp split_mfa_into_mfa_and_arity({:/, _line, [mfa, arity]}) do
    {:ok, {mfa, arity}}
  end

  defp split_mfa_into_mfa_and_arity(els) do
    {:ok, {els, nil}}
  end

  defp split_mfa_into_module_function_and_args({{:., _l1, [module, function]}, _l2, args}) do
    {:ok, {module, function, args}}
  end

  defp split_mfa_into_module_function_and_args(els) do
    {:ok, {els, nil, nil}}
  end

  # handling fringe cases that shouldn't happen
  defp validate_mfaa(module, function, args, arity)

  defp validate_mfaa(nil, _, _, _), do: {:error, :missing_module}

  defp validate_mfaa(_, nil, args, _) when not (args in [nil, []]),
    do: {:error, :missing_function}

  defp validate_mfaa(_, nil, _, arity) when arity != nil, do: {:error, :missing_function}

  defp validate_mfaa(_, _, args, arity)
       when not (args in [nil, []]) and arity != nil do
    {:error, :both_args_and_arity_provided}
  end

  defp validate_mfaa(_, _, _, _), do: :ok

  defp translate_module({:__aliases__, _line, elixir_module}) when is_list(elixir_module) do
    joined =
      [:"Elixir" | elixir_module]
      |> Enum.map(&Atom.to_string/1)
      |> Enum.join(".")

    {:ok, "'#{joined}'"}
  end

  defp translate_module(erlang_mod) when is_atom(erlang_mod) do
    {:ok, "\'#{Atom.to_string(erlang_mod)}\'"}
  end

  defp translate_module(module), do: {:error, {:invalid_module, module}}

  defp translate_function(nil) do
    {:ok, ""}
  end

  defp translate_function(f) when is_atom(f) do
    {:ok, ":'#{Atom.to_string(f)}'"}
  end

  defp translate_function(els) do
    {:error, {:invalid_function, els}}
  end

  defp translate_args(nil), do: {:ok, ""}

  defp translate_args(args) when is_list(args) do
    args
    |> Enum.map(&translate_arg/1)
    |> collapse_errors()
    |> map_success(&Enum.join(&1, ", "))
    |> map_success(fn res -> "(#{res})" end)
  end

  defp translate_args(els) do
    {:error, {:invalid_args, els}}
  end

  defp translate_arg(nil), do: {:ok, "nil"}

  defp translate_arg(boolean) when is_boolean(boolean) do
    {:ok, "#{boolean}"}
  end

  defp translate_arg(arg) when is_atom(arg) do
    {:ok, "'#{Atom.to_string(arg)}'"}
  end

  defp translate_arg(string) when is_binary(string) do
    # TODO: more strict ASCII checking here
    if String.printable?(string) && byte_size(string) == String.length(string) do
      {:ok, "<<\"#{string}\">>"}
    else
      translate_arg({:<<>>, [line: 1], [string]})
    end
  end

  defp translate_arg({:<<>>, _line, contents}) when is_list(contents) do
    contents
    |> Enum.map(&translate_binary_element/1)
    |> collapse_errors()
    |> map_success(&Enum.join(&1, ", "))
    |> map_success(fn res -> "<<#{res}>>" end)
  end

  # defp translate_arg(bs) when is_bitstring(bs) do
  #   :error
  # end

  defp translate_arg(ls) when is_list(ls) do
    ls
    |> Enum.map(&translate_arg/1)
    |> collapse_errors()
    |> map_success(fn elements -> "[#{Enum.join(elements, ", ")}]" end)
  end

  defp translate_arg({:-, _line, [num]}) when is_integer(num) do
    with {:ok, translated_num} = translate_arg(num),
      do: {:ok, "-#{translated_num}"}
  end

  defp translate_arg(num) when is_integer(num) do
    {:ok, "#{num}"}
  end

  defp translate_arg(f) when is_float(f) do
    {:error, {:bad_type, :float}}
  end

  defp translate_arg({:%{}, _line, kvs}) when is_list(kvs) do
    {ks, vs} = Enum.unzip(kvs)

    if Enum.any?(ks, &is_variable/1) do
      {:error, :variable_in_map_key}
    else
      key_args =
        ks
        |> Enum.map(&translate_arg/1)
        |> collapse_errors()

      value_args =
        vs
        |> Enum.map(&translate_arg/1)
        |> collapse_errors()

      [key_args, value_args]
      |> collapse_errors
      |> map_success(fn [keys, values] ->
        middle =
          keys
          |> Enum.zip(values)
          |> Enum.map(fn {k, v} -> "#{k} => #{v}" end)
          |> Enum.join(", ")

        "\#{#{middle}}"
      end)
    end
  end

  # there's a catch here:
  # iex(12)> Code.string_to_quoted!("{1,2,3}")
  # {:{}, [line: 1], [1, 2, 3]}
  # iex(13)> Code.string_to_quoted!("{1,2}")
  # {1, 2}
  defp translate_arg({:{}, _line, tuple_elements}) do
    tuple_elements
    |> Enum.map(&translate_arg/1)
    |> collapse_errors()
    |> map_success(fn elements -> "{#{Enum.join(elements, ", ")}}" end)
  end

  # the literally represented 2-tuples
  defp translate_arg({x, y}), do: translate_arg({:{}, [line: 1], [x, y]})

  # other atoms are just variable names
  defp translate_arg({var, _line, nil}) when is_atom(var) do
    var
    |> Atom.to_string()
    |> String.capitalize()
    |> wrap_in_ok()
  end

  defp translate_arg(arg) do
    {:error, {:invalid_arg, arg}}
  end

  defp is_variable({var, _line, nil}) when is_atom(var), do: true
  defp is_variable(_), do: false

  defp translate_binary_element(i) when is_integer(i) do
    {:ok, "#{i}"}
  end

  defp translate_binary_element(s) when is_binary(s) do
    res =
      s
      |> :binary.bin_to_list()
      |> Enum.join(", ")

    {:ok, res}
  end

  defp translate_binary_element(els), do: {:error, {:invalid_binary_element, els}}

  defp translate_arity({var, [line: 1], nil}) when is_atom(var) do
    {:ok, :any}
  end

  defp translate_arity(i) when is_integer(i) do
    {:ok, i}
  end

  defp translate_arity(none) when none in [nil, ""] do
    {:ok, nil}
  end

  defp translate_arity(els) do
    {:error, {:invalid_arity, els}}
  end

  defp translate_actions!(empty) when empty in [nil, ""] do
    ""
  end

  defp translate_actions!(actions) when is_binary(actions) do
    " -> #{actions}"
  end

  # ---------------------------------------------------------------------------
  # Guards
  # ---------------------------------------------------------------------------

  @spec _translate_guards(term) :: {:ok, String.t()} | {:error, term}
  defp _translate_guards({:not, _line, [arg]}) do
    _translate_guards(arg)
    |> map_success(fn guard -> "not #{guard}" end)
  end

  defp _translate_guards({combinator, _line, [a, b]})
       when combinator in @valid_infix_guard_combinators do
    erlang_combinator =
      @infix_guard_combinators_mapping[combinator]
      |> Atom.to_string()

    with {:ok, a_guards} <- _translate_guards(a),
         {:ok, b_guards} <- _translate_guards(b),
         do: {:ok, "(#{a_guards} #{erlang_combinator} #{b_guards})"}
  end

  defp _translate_guards(els), do: translate_guard(els)

  @spec translate_guard(term) :: {:ok, String.t()} | {:error, term}
  defp translate_guard({guard_fun, _line, args})
       when guard_fun in @valid_guard_functions do
    with translated_fun = Atom.to_string(guard_fun),
         {:ok, translated_args} <- translate_args(args),
         do: {:ok, "#{translated_fun}#{translated_args}"}
  end

  defp translate_guard({infix_guard_fun, _line, [a, b]})
       when infix_guard_fun in @valid_infix_guards do
    translated_infix_function =
      @infix_guards_mapping[infix_guard_fun]
      |> Atom.to_string()

    with {:ok, a_guard} <- translate_guard(a),
         {:ok, b_guard} <- translate_guard(b),
         do: {:ok, "#{a_guard} #{translated_infix_function} #{b_guard}"}
  end

  defp translate_guard(els) do
    translate_arg(els)
  end

  # ---------------------------------------------------------------------------
  # Helper functions
  # ---------------------------------------------------------------------------

  defp map_success({:ok, var}, fun) do
    {:ok, fun.(var)}
  end

  defp map_success(els, _), do: els

  defp wrap_in_ok(x), do: {:ok, x}
end
