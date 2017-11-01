defmodule Rexbug do
  @moduledoc """
  A thin Elixir wrapper for the redbug Erlang tracing debugger.
  """

  alias Rexbug.Translator


  @spec start(String.t, :return | :stack | [:return | :stack], Keyword.t)
    :: {:ok, {integer, integer}} | {:error, term}
  def start(trace_pattern, actions, options \\ []) do
    with {:ok, translated_mod_fun_arg_guards} <- Translator.translate(trace_pattern),
         {:ok, translated_actions} <- Translator.translate_actions(actions),
          rtp = translated_mod_fun_arg_guards ++ translated_actions
    do
      :redbug.start(rtp, options)
    end
  end


  def stop() do
    :redbug.stop()
  end


  def help() do
    # TODO replace with own help with elixir syntax
    :redbug.help()
  end


end
