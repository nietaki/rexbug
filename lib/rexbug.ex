defmodule Rexbug do
  @moduledoc """
  A thin Elixir wrapper for the redbug Erlang tracing debugger.
  """

  alias Rexbug.Translator


  @spec start(String.t, Keyword.t)
  :: {:ok, {integer, integer}} | {:error, term}

  def start(trace_pattern, options \\ []) do
    with {:ok, translated} <- Translator.translate(trace_pattern)
      do
      :redbug.start(translated, options)
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
